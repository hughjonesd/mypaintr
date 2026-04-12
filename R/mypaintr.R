#' @keywords internal
#' @useDynLib mypaintr, .registration = TRUE
"_PACKAGE"

brush_preset_table <- list(
  ink = c(
    opaque = 1.0,
    opaque_multiply = 1.0,
    radius_logarithmic = log(1.05),
    hardness = 0.92,
    anti_aliasing = 1.0,
    dabs_per_basic_radius = 2.2,
    dabs_per_actual_radius = 2.4,
    tracking_noise = 0.0,
    offset_by_random = 0.0
  ),
  pencil = c(
    opaque = 0.40,
    opaque_multiply = 0.85,
    radius_logarithmic = log(0.75),
    hardness = 0.38,
    anti_aliasing = 1.0,
    dabs_per_basic_radius = 1.5,
    dabs_per_actual_radius = 1.8,
    radius_by_random = 0.12,
    tracking_noise = 0.08,
    offset_by_random = 0.04
  ),
  chalk = c(
    opaque = 0.55,
    opaque_multiply = 0.95,
    radius_logarithmic = log(2.2),
    hardness = 0.18,
    anti_aliasing = 1.0,
    dabs_per_basic_radius = 1.8,
    dabs_per_actual_radius = 2.0,
    radius_by_random = 0.42,
    tracking_noise = 0.18,
    offset_by_random = 0.22,
    elliptical_dab_ratio = 1.25
  )
)

default_mypaint_brush_dirs <- function() {
  env <- strsplit(Sys.getenv("MYPAINT_BRUSH_PATH", ""), .Platform$path.sep, fixed = TRUE)[[1L]]
  env <- env[nzchar(env)]

  pkg_config <- character()
  pkg_config_bin <- Sys.which("pkg-config")
  if (nzchar(pkg_config_bin)) {
    pkg_config <- tryCatch(
      system2(
        pkg_config_bin,
        c("--variable=brushesdir", "mypaint-brushes-2.0"),
        stdout = TRUE,
        stderr = FALSE
      ),
      error = function(...) character()
    )
  }

  dirs <- unique(c(
    env,
    pkg_config,
    "/opt/homebrew/opt/mypaint-brushes/share/mypaint-data/2.0/brushes",
    "/usr/local/opt/mypaint-brushes/share/mypaint-data/2.0/brushes",
    "/usr/local/share/mypaint-data/2.0/brushes",
    "/usr/share/mypaint-data/2.0/brushes"
  ))

  dirs[dir.exists(dirs)]
}

resolve_mypaint_brush_file <- function(brush, paths = default_mypaint_brush_dirs()) {
  candidates <- unique(c(
    brush,
    if (endsWith(brush, ".myb")) character() else paste0(brush, ".myb")
  ))

  direct <- candidates[file.exists(candidates)]
  if (length(direct)) {
    return(normalizePath(direct[[1L]], winslash = "/", mustWork = TRUE))
  }

  for (path in paths) {
    matches <- file.path(path, candidates)
    hit <- matches[file.exists(matches)]
    if (length(hit)) {
      return(normalizePath(hit[[1L]], winslash = "/", mustWork = TRUE))
    }
  }

  NULL
}

read_mypaint_brush <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

normalize_settings <- function(settings) {
  if (is.null(settings)) {
    return(setNames(numeric(), character()))
  }
  if (is.list(settings)) {
    settings <- unlist(settings, recursive = FALSE, use.names = TRUE)
  }
  if (!is.numeric(settings) || is.null(names(settings)) || any(names(settings) == "")) {
    stop("brush settings must be a named numeric vector or named list", call. = FALSE)
  }
  storage.mode(settings) <- "double"
  settings
}

normalize_brush_spec <- function(brush, settings = NULL) {
  base_settings <- setNames(numeric(), character())
  json <- NULL

  if (is.null(brush)) {
    NULL
  } else if (is.character(brush) && length(brush) == 1L) {
    if (brush %in% names(brush_preset_table)) {
      base_settings <- brush_preset_table[[brush]]
    } else if (startsWith(trimws(brush), "{")) {
      json <- brush
    } else {
      brush_file <- resolve_mypaint_brush_file(brush)
      if (is.null(brush_file)) {
        stop("unknown brush preset or brush file: ", brush, call. = FALSE)
      }
      json <- read_mypaint_brush(brush_file)
    }
  } else if (is.numeric(brush) || is.list(brush)) {
    base_settings <- normalize_settings(brush)
  } else {
    stop("brush must be NULL, a preset name, a JSON string, or named settings", call. = FALSE)
  }

  override_settings <- normalize_settings(settings)
  if (length(override_settings)) {
    base_settings[names(override_settings)] <- override_settings
  }

  list(
    json = json,
    settings = base_settings
  )
}

normalize_render_style <- function(style) {
  if (is.null(style)) {
    return(NULL)
  }
  style <- match.arg(style, c("solid", "brush"))
  match(style, c("solid", "brush")) - 1L
}

rgba_int <- function(col) {
  rgba <- grDevices::col2rgb(col, alpha = TRUE)
  as.integer(rgba[, 1L])
}

#' Open a libmypaint-backed graphics device
#'
#' @param file Output PNG filename. If it contains `\%d`, pages are numbered.
#' @param width,height Device size in inches.
#' @param res Resolution in pixels per inch.
#' @param pointsize Base pointsize.
#' @param bg Background colour.
#' @param brush Stroke brush preset, installed mypaint brush name,
#'   `.myb` file path, JSON brush string, or named settings.
#' @param brush_settings Named settings overriding `brush`.
#' @param stroke_style Either `"brush"` or `"solid"`.
#' @param fill_style Either `"solid"` or `"brush"`.
#' @param fill_brush Optional fill brush spec. Defaults to `brush`.
#' @param fill_settings Named settings overriding `fill_brush`.
#' @param auto_solid_bg Draw large fills that match the device background using
#'   normal Cairo rendering even when `fill_style = "brush"`.
#' @return Opens a graphics device and returns `NULL` invisibly.
#' @examples
#' out <- tempfile("mypaint-basic-", fileext = "-%d.png")
#' mypaint_device(out, width = 4, height = 3, bg = "ivory")
#' plot(
#'   1:10,
#'   col = "steelblue",
#'   pch = 16,
#'   cex = 1.4,
#'   main = "Ink Lines"
#' )
#' lines(1:10, col = "firebrick", lwd = 3)
#' rect(2, 3, 5, 7, border = "black", col = rgb(0, 0.6, 0.3, 0.25))
#' text(6, 8, "hello", col = "black")
#' dev.off()
#' unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
#'
#' out <- tempfile("mypaint-brush-", fileext = "-%d.png")
#' mypaint_device(
#'   out,
#'   width = 4,
#'   height = 3,
#'   brush = "chalk",
#'   brush_settings = c(tracking_noise = 0.12),
#'   fill_style = "brush",
#'   fill_brush = "pencil",
#'   fill_settings = c(radius_by_random = 0.08)
#' )
#' plot.new()
#' plot.window(xlim = c(0, 10), ylim = c(0, 10))
#' polygon(
#'   c(2, 5, 8, 6, 3),
#'   c(2, 7, 6, 3, 1.5),
#'   border = "black",
#'   col = rgb(0.2, 0.7, 0.5, 0.6)
#' )
#' lines(c(1, 9), c(1, 9), col = "firebrick", lwd = 4)
#' title("Brush Fill")
#' box()
#' dev.off()
#' unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
#'
#' out <- tempfile("mypaint-mixed-", fileext = "-%d.png")
#' mypaint_device(out, width = 4, height = 3, stroke_style = "solid")
#' plot(1:5, 1:5, type = "n", main = "Mixed Styles")
#' mypaint_style(stroke_style = "brush", brush = "pencil")
#' lines(1:5, c(1, 3, 2, 5, 4), lwd = 3)
#' dev.off()
#' unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
#' @export
mypaint_device <- function(file,
                           width = 7,
                           height = 7,
                           res = 144,
                           pointsize = 12,
                           bg = "white",
                           brush = "ink",
                           brush_settings = NULL,
                           stroke_style = c("brush", "solid"),
                           fill_style = c("solid", "brush"),
                           fill_brush = brush,
                           fill_settings = NULL,
                           auto_solid_bg = TRUE) {
  stopifnot(
    is.character(file), length(file) == 1L,
    is.numeric(width), length(width) == 1L, width > 0,
    is.numeric(height), length(height) == 1L, height > 0,
    is.numeric(res), length(res) == 1L, res > 0,
    is.numeric(pointsize), length(pointsize) == 1L, pointsize > 0
  )

  stroke_style <- match.arg(stroke_style)
  fill_style <- match.arg(fill_style)
  stroke_spec <- normalize_brush_spec(brush, brush_settings)
  fill_spec <- normalize_brush_spec(fill_brush, fill_settings)

  invisible(.Call(
    mypaintr_device_open,
    enc2utf8(normalizePath(file, winslash = "/", mustWork = FALSE)),
    as.numeric(width),
    as.numeric(height),
    as.numeric(res),
    as.numeric(pointsize),
    rgba_int(bg),
    stroke_spec,
    fill_spec,
    match(stroke_style, c("solid", "brush")) - 1L,
    match(fill_style, c("solid", "brush")) - 1L,
    isTRUE(auto_solid_bg)
  ))
}

#' Update the active mypaintr device style
#'
#' @param brush Stroke brush preset, JSON brush string, or named settings.
#' @param brush_settings Named settings overriding `brush`.
#' @param stroke_style Either `"brush"` or `"solid"`.
#' @param fill_style Either `"solid"` or `"brush"`.
#' @param fill_brush Fill brush preset, JSON brush string, or named settings.
#' @param fill_settings Named settings overriding `fill_brush`.
#' @param auto_solid_bg Whether large fills matching the device background should
#'   be drawn normally.
#' @return `NULL`, invisibly.
#' @export
mypaint_style <- function(brush = NULL,
                          brush_settings = NULL,
                          stroke_style = NULL,
                          fill_style = NULL,
                          fill_brush = NULL,
                          fill_settings = NULL,
                          auto_solid_bg = NULL) {
  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }
  if (is.null(fill_brush) && !is.null(fill_settings)) {
    stop("fill_settings requires fill_brush", call. = FALSE)
  }

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) {
    NULL
  } else {
    normalize_brush_spec(brush, brush_settings)
  }
  fill_spec <- if (is.null(fill_brush) && is.null(fill_settings)) {
    NULL
  } else {
    normalize_brush_spec(fill_brush, fill_settings)
  }

  invisible(.Call(
    mypaintr_device_set_style,
    stroke_spec,
    fill_spec,
    normalize_render_style(stroke_style),
    normalize_render_style(fill_style),
    if (is.null(auto_solid_bg)) NULL else isTRUE(auto_solid_bg)
  ))
}

#' Built-in brush presets
#'
#' @export
brush_presets <- function() {
  brush_preset_table
}

#' Discover installed mypaint brush directories
#'
#' @return A character vector of directories containing `.myb` brushes.
#' @examples
#' brush_dirs()
#' @export
brush_dirs <- function() {
  default_mypaint_brush_dirs()
}

#' List installed mypaint brushes
#'
#' @param paths Optional brush directories. Defaults to locally discovered
#'   `mypaint-brushes` locations.
#' @return A character vector of brush names, relative to the brush root.
#' @examples
#' head(brushes())
#' @export
brushes <- function(paths = default_mypaint_brush_dirs()) {
  out <- character()

  for (path in paths) {
    files <- list.files(path, pattern = "[.]myb$", recursive = TRUE, full.names = FALSE)
    if (length(files)) {
      out <- c(out, sub("[.]myb$", "", files))
    }
  }

  sort(unique(out))
}

#' Load an installed mypaint brush
#'
#' @param brush Brush name like `"classic/pencil"` or a path to a `.myb` file.
#' @param paths Optional brush directories. Defaults to locally discovered
#'   `mypaint-brushes` locations.
#' @return A JSON brush string suitable for `mypaint_device(brush = ...)`.
#' @examples
#' if (length(brushes())) {
#'   x <- load_brush(brushes()[[1]])
#'   stopifnot(is.character(x), length(x) == 1L)
#' }
#' @export
load_brush <- function(brush, paths = default_mypaint_brush_dirs()) {
  stopifnot(is.character(brush), length(brush) == 1L, nzchar(brush))

  path <- resolve_mypaint_brush_file(brush, paths = paths)
  if (is.null(path)) {
    stop("could not find brush: ", brush, call. = FALSE)
  }

  read_mypaint_brush(path)
}

#' libmypaint brush setting metadata
#'
#' @export
brush_settings <- function() {
  as.data.frame(.Call(mypaintr_brush_settings_info), stringsAsFactors = FALSE)
}

#' libmypaint brush input metadata
#'
#' @export
brush_inputs <- function() {
  as.data.frame(.Call(mypaintr_brush_inputs_info), stringsAsFactors = FALSE)
}

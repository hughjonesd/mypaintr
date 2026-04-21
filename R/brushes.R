
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
  pkg_config_file <- system.file("mypaintr-config.dcf", package = "mypaintr", mustWork = FALSE)
  pkg_mode <- "auto"
  if (nzchar(pkg_config_file) && file.exists(pkg_config_file)) {
    dcf <- tryCatch(read.dcf(pkg_config_file), error = function(...) NULL)
    if (!is.null(dcf) && "brushes_mode" %in% colnames(dcf)) {
      pkg_mode <- dcf[1L, "brushes_mode"]
    }
  }

  mode <- tolower(Sys.getenv("MYPAINTR_BRUSHES", pkg_mode))
  if (!mode %in% c("auto", "system", "vendored")) {
    mode <- "auto"
  }

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

  bundled <- system.file("brushes", package = "mypaintr", mustWork = FALSE)
  if (nzchar(bundled)) {
    if (mode == "vendored") {
      dirs <- bundled
    } else if (mode == "auto") {
      dirs <- c(dirs, bundled)
    }
  } else if (mode == "vendored") {
    dirs <- character()
  } else if (mode == "system") {
    dirs <- dirs
  }

  unique(dirs[dir.exists(dirs)])
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

normalize_settings <- function(settings) {
  if (is.null(settings)) {
    return(numeric())
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
  base_settings <- numeric()
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

  spec <- list(
    json = json,
    settings = base_settings
  )
  spec
}

read_mypaint_brush <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}


json_brush_base_value <- function(json, setting) {
  pattern <- sprintf(
    '"%s"[[:space:]]*:[[:space:]]*\\{[^}]*"base_value"[[:space:]]*:[[:space:]]*([-+0-9.eE]+)',
    setting
  )
  match <- regexec(pattern, json, perl = TRUE)
  captures <- regmatches(json, match)[[1L]]
  if (length(captures) < 2L) {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(captures[[2L]]))
}

is_probably_pure_smudge_brush <- function(spec) {
  if (is.null(spec)) {
    return(FALSE)
  }

  settings <- spec$settings %||% numeric()
  json <- spec$json %||% ""

  value_for <- function(name, default = NA_real_) {
    if (name %in% names(settings)) {
      return(as.numeric(settings[[name]]))
    }
    value <- json_brush_base_value(json, name)
    if (is.na(value)) default else value
  }

  smudge <- value_for("smudge", default = 0)
  opaque_multiply <- value_for("opaque_multiply", default = 1)
  colorize <- value_for("colorize", default = 0)
  restore_color <- value_for("restore_color", default = 0)

  isTRUE(smudge >= 0.8 &&
           opaque_multiply <= 0.02 &&
           colorize <= 0.02 &&
           restore_color <= 0.02)
}

warn_if_pure_smudge_brush <- function(spec, type = c("stroke", "fill")) {
  type <- match.arg(type)
  if (!is_probably_pure_smudge_brush(spec)) {
    return(invisible(NULL))
  }

  if (type == "fill") {
    warning(
      "Pure smudge brush selected for fill: mypaintr falls back to solid fills; proper smudged fills are not supported.",
      call. = FALSE
    )
  } else {
    warning(
      "Pure smudge brush selected for stroke: mypaintr approximates this as a surface-sampled paint stroke; proper smudging is not yet supported.",
      call. = FALSE
    )
  }

  invisible(NULL)
}

#' Set the active mypaintr brush
#'
#' @param brush Brush preset, installed brush name, JSON brush string, named
#'   settings, or `NULL` to switch the selected type back to solid rendering.
#' @param settings Named settings overriding `brush`.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @param auto_solid_bg Optional override for background-like fills.
#' @return `NULL`, invisibly. If the active device is not `mypaintr`, the
#'   selected brush becomes the default for the next [mypaint_device()] opened
#'   in this R session.
#' @family brush management
#' @export
set_brush <- function(brush = NULL, settings = NULL, type = c("both", "stroke", "fill"), auto_solid_bg = NULL) {
  type <- match.arg(type)
  if (is.null(brush) && !is.null(settings)) {
    stop("settings requires brush", call. = FALSE)
  }

  spec <- if (is.null(brush) && is.null(settings)) NULL else normalize_brush_spec(brush, settings)
  if (type %in% c("both", "stroke")) {
    warn_if_pure_smudge_brush(spec, "stroke")
  }
  if (type %in% c("both", "fill")) {
    warn_if_pure_smudge_brush(spec, "fill")
  }
  stroke_spec <- fill_spec <- NULL
  stroke_style <- fill_style <- NULL

  if (type %in% c("both", "stroke")) {
    stroke_spec <- spec
    stroke_style <- !is.null(spec)
  }
  if (type %in% c("both", "fill")) {
    fill_spec <- spec
    fill_style <- !is.null(spec)
  }

  if (!is_mypaintr_device()) {
    update_default_device_style(
      stroke_spec = stroke_spec,
      fill_spec = fill_spec,
      stroke_style = if (is.null(stroke_style)) NULL else as.integer(stroke_style),
      fill_style = if (is.null(fill_style)) NULL else as.integer(fill_style),
      auto_solid_bg = auto_solid_bg,
      update_stroke = type %in% c("both", "stroke"),
      update_fill = type %in% c("both", "fill")
    )
    return(invisible(NULL))
  }

  invisible(.Call(
    mypaintr_device_set_brush,
    stroke_spec,
    fill_spec,
    if (is.null(stroke_style)) NULL else as.integer(stroke_style),
    if (is.null(fill_style)) NULL else as.integer(fill_style),
    if (is.null(auto_solid_bg)) NULL else isTRUE(auto_solid_bg)
  ))
}

#' Built-in brush presets
#'
#' @family brush management
#' @export
brush_presets <- function() {
  brush_preset_table
}

#' Discover installed mypaint brush directories
#'
#' @return A character vector of directories containing `.myb` brushes.
#' @examples
#' brush_dirs()
#' @family brush management
#' @export
brush_dirs <- function() {
  default_mypaint_brush_dirs()
}

#' List installed mypaint brushes
#'
#' @inheritParams mypaintr-brush-paths-param
#' @return A character vector of brush names, relative to the brush root.
#' @examples
#' head(brushes())
#' @family brush management
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
#' @inheritParams mypaintr-brush-paths-param
#' @return A JSON brush string suitable for `mypaint_device(brush = ...)`.
#' @examples
#' if (length(brushes())) {
#'   x <- load_brush(brushes()[[1]])
#'   stopifnot(is.character(x), length(x) == 1L)
#' }
#' @family brush management
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
#' @family brush management
#' @export
brush_settings <- function() {
  as.data.frame(.Call(mypaintr_brush_settings_info), stringsAsFactors = FALSE)
}

#' libmypaint brush input metadata
#'
#' @family brush management
#' @export
brush_inputs <- function() {
  as.data.frame(.Call(mypaintr_brush_inputs_info), stringsAsFactors = FALSE)
}

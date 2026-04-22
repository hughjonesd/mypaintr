
default_plot_brush_spec <- function() {
  structure(
    list(
      json = NULL,
      settings = c(
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
      source = "mypaintr-default",
      normalize = "none"
    ),
    class = "mypaintr_brush"
  )
}

new_mypaintr_brush <- function(json = NULL, settings = numeric(), source = NULL, normalize = "none") {
  structure(
    list(
      json = json,
      settings = settings,
      source = source,
      normalize = normalize
    ),
    class = "mypaintr_brush"
  )
}

normalize_mode <- function(normalize) {
  normalize <- tolower(normalize)
  if (!normalize %in% c("all", "size", "tracking", "none")) {
    stop("normalize must be one of \"all\", \"size\", \"tracking\", or \"none\"", call. = FALSE)
  }
  normalize
}

normalize_brush_source <- function(brush) {
  if (inherits(brush, "mypaintr_brush")) {
    return(brush)
  }
  if (!(is.character(brush) && length(brush) == 1L && nzchar(brush))) {
    stop("brush must be an installed brush name, .myb path, JSON brush string, or tweak_brush() object", call. = FALSE)
  }
  if (startsWith(trimws(brush), "{")) {
    return(new_mypaintr_brush(json = brush, source = "json"))
  }

  brush_file <- resolve_mypaint_brush_file(brush)
  if (is.null(brush_file)) {
    stop("unknown brush file: ", brush, call. = FALSE)
  }
  new_mypaintr_brush(
    json = read_mypaint_brush(brush_file),
    source = normalizePath(brush_file, winslash = "/", mustWork = TRUE)
  )
}

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
  if (length(settings) == 0L) {
    return(numeric())
  }
  if (!is.numeric(settings) || is.null(names(settings)) || any(names(settings) == "")) {
    stop("brush settings must be a named numeric vector or named list", call. = FALSE)
  }
  storage.mode(settings) <- "double"
  settings
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

normalize_adjustments <- function(brush, normalize = "none") {
  normalize <- normalize_mode(normalize)
  settings <- numeric()
  if (normalize %in% c("all", "tracking")) {
    settings[c("slow_tracking", "slow_tracking_per_dab")] <- 0
  }
  if (normalize %in% c("all", "size")) {
    current_radius <- if ("radius_logarithmic" %in% names(brush$settings %||% numeric())) {
      as.numeric(brush$settings[["radius_logarithmic"]])
    } else {
      json_brush_base_value(brush$json %||% "", "radius_logarithmic")
    }
    if (is.finite(current_radius) && current_radius > log(3)) {
      settings["radius_logarithmic"] <- log(3)
    }
  }
  settings
}

#' Create a reusable tweaked brush specification
#'
#' @param brush Installed brush name, `.myb` file path, JSON brush string, or
#'   another [tweak_brush()] object.
#' @param ... Named libmypaint base-value overrides.
#' @param normalize One of `"all"`, `"size"`, `"tracking"`, or `"none"`.
#' @return A reusable brush specification object.
#' @examples
#' if ("classic/pen" %in% brushes()) {
#'   tweak_brush("classic/pen", normalize = "tracking", radius_logarithmic = log(1.2))
#' }
#' @family brush management
#' @export
tweak_brush <- function(brush, ..., normalize = "all") {
  if (missing(brush) || is.null(brush)) {
    stop("tweak_brush() requires an explicit brush", call. = FALSE)
  }

  brush <- normalize_brush_source(brush)
  normalize <- normalize_mode(normalize)
  settings <- brush$settings %||% numeric()
  normalized <- normalize_adjustments(brush, normalize)
  settings[names(normalized)] <- normalized
  overrides <- normalize_settings(list(...))
  settings[names(overrides)] <- overrides

  new_mypaintr_brush(
    json = brush$json,
    settings = settings,
    source = brush$source,
    normalize = normalize
  )
}

normalize_brush_spec <- function(brush) {
  if (is.null(brush)) {
    return(NULL)
  }
  brush <- normalize_brush_source(brush)
  list(
    json = brush$json,
    settings = normalize_settings(brush$settings %||% numeric())
  )
}

is_probably_pure_smudge_brush <- function(spec) {
  FALSE
}

warn_if_pure_smudge_brush <- function(spec, type = c("stroke", "fill")) {
  type <- match.arg(type)
  invisible(NULL)
}

warn_no_mypaintr_device <- function(fn) {
  warning(
    sprintf("%s() has no effect unless the active graphics device is mypaint_device()", fn),
    call. = FALSE
  )
  invisible(NULL)
}

#' Set the active mypaintr brush
#'
#' @param brush Brush specification created with [tweak_brush()], an installed
#'   brush name, `.myb` file path, JSON brush string, or `NULL` to switch the
#'   selected type back to solid rendering.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @param auto_solid_bg Optional override for background-like fills.
#' @return `NULL`, invisibly. If the active graphics device is not
#'   [mypaint_device()], this emits a warning and has no effect.
#' @family brush management
#' @export
set_brush <- function(brush = NULL, type = c("both", "stroke", "fill"), auto_solid_bg = NULL) {
  type <- match.arg(type)
  spec <- if (is.null(brush)) NULL else normalize_brush_spec(brush)
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
    warn_no_mypaintr_device("set_brush")
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
#' @return A JSON brush string suitable for `tweak_brush()` or
#'   `mypaint_device(brush = ...)`.
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
#' @examples
#' head(brush_settings())
#' @family brush management
#' @export
brush_settings <- function() {
  as.data.frame(.Call(mypaintr_brush_settings_info), stringsAsFactors = FALSE)
}

#' libmypaint brush input metadata
#'
#' @examples
#' head(brush_inputs())
#' @family brush management
#' @export
brush_inputs <- function() {
  as.data.frame(.Call(mypaintr_brush_inputs_info), stringsAsFactors = FALSE)
}

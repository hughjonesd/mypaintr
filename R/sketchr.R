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
      stop("unknown brush preset: ", brush, call. = FALSE)
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
#' @param brush Stroke brush preset, JSON brush string, or named settings.
#' @param brush_settings Named settings overriding `brush`.
#' @param fill_style Either `"solid"` or `"brush"`.
#' @param fill_brush Optional fill brush spec. Defaults to `brush`.
#' @param fill_settings Named settings overriding `fill_brush`.
#' @return Opens a graphics device and returns `NULL` invisibly.
#' @export
sketch_device <- function(file,
                          width = 7,
                          height = 7,
                          res = 144,
                          pointsize = 12,
                          bg = "white",
                          brush = "ink",
                          brush_settings = NULL,
                          fill_style = c("solid", "brush"),
                          fill_brush = brush,
                          fill_settings = NULL) {
  stopifnot(
    is.character(file), length(file) == 1L,
    is.numeric(width), length(width) == 1L, width > 0,
    is.numeric(height), length(height) == 1L, height > 0,
    is.numeric(res), length(res) == 1L, res > 0,
    is.numeric(pointsize), length(pointsize) == 1L, pointsize > 0
  )

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
    match(fill_style, c("solid", "brush")) - 1L
  ))
}

#' Built-in brush presets
#'
#' @export
sketch_brush_presets <- function() {
  brush_preset_table
}

#' libmypaint brush setting metadata
#'
#' @export
sketch_brush_settings <- function() {
  as.data.frame(.Call(mypaintr_brush_settings_info), stringsAsFactors = FALSE)
}

#' libmypaint brush input metadata
#'
#' @export
sketch_brush_inputs <- function() {
  as.data.frame(.Call(mypaintr_brush_inputs_info), stringsAsFactors = FALSE)
}

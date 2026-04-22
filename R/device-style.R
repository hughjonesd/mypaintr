#' @keywords internal
#' @useDynLib mypaintr, .registration = TRUE
"_PACKAGE"


mypaintr_env <- new.env(parent = emptyenv())
mypaintr_env$style_stack <- list()

is_mypaintr_device <- function() {
  identical(names(grDevices::dev.cur()), "mypaintr")
}

current_device_style <- function() {
  if (!is_mypaintr_device()) {
    return(NULL)
  }
  .Call(mypaintr_device_get_style)
}

apply_device_style_state <- function(state) {
  if (is.null(state) || !is_mypaintr_device()) {
    return(invisible(NULL))
  }

  invisible(.Call(
    mypaintr_device_set_style,
    state$stroke_spec,
    state$fill_spec,
    state$stroke_style,
    state$fill_style,
    state$auto_solid_bg
  ))
  invisible(.Call(
    mypaintr_device_set_hand,
    state$stroke_hand,
    state$fill_hand,
    TRUE,
    TRUE
  ))
}

apply_device_style_override <- function(style) {
  if (is.null(style) || !is_mypaintr_device()) {
    return(invisible(NULL))
  }

  invisible(.Call(
    mypaintr_device_set_style,
    if (isTRUE(style$update_stroke)) style$stroke_spec else NULL,
    if (isTRUE(style$update_fill)) style$fill_spec else NULL,
    if (isTRUE(style$update_stroke)) style$stroke_style else NULL,
    if (isTRUE(style$update_fill)) style$fill_style else NULL,
    if (is.null(style$auto_solid_bg)) NULL else isTRUE(style$auto_solid_bg)
  ))
  invisible(.Call(
    mypaintr_device_set_hand,
    if (isTRUE(style$update_stroke_hand)) style$stroke_hand else NULL,
    if (isTRUE(style$update_fill_hand)) style$fill_hand else NULL,
    isTRUE(style$update_stroke_hand),
    isTRUE(style$update_fill_hand)
  ))
}

make_style_override <- function(update_stroke = FALSE,
                                stroke_spec = NULL,
                                stroke_style = NULL,
                                stroke_hand = NULL,
                                update_stroke_hand = update_stroke,
                                update_fill = FALSE,
                                fill_spec = NULL,
                                fill_style = NULL,
                                fill_hand = NULL,
                                update_fill_hand = update_fill,
                                auto_solid_bg = NULL) {
  list(
    update_stroke = update_stroke,
    stroke_spec = stroke_spec,
    stroke_style = stroke_style,
    stroke_hand = stroke_hand,
    update_stroke_hand = update_stroke_hand,
    update_fill = update_fill,
    fill_spec = fill_spec,
    fill_style = fill_style,
    fill_hand = fill_hand,
    update_fill_hand = update_fill_hand,
    auto_solid_bg = auto_solid_bg
  )
}

rgba_int <- function(col) {
  rgba <- grDevices::col2rgb(col, alpha = TRUE)
  as.integer(rgba[, 1L])
}

normalize_render_style <- function(style) {
  if (is.null(style)) {
    return(NULL)
  }
  style <- match.arg(style, c("solid", "brush"))
  match(style, c("solid", "brush")) - 1L
}

#' Open a libmypaint-backed graphics device
#'
#' @param filename Output PNG filename. If it contains `\%d`, pages are
#'   numbered.
#' @param file Deprecated compatibility alias for `filename`.
#' @param width,height Device size in inches.
#' @param res Resolution in pixels per inch.
#' @param pointsize Base pointsize.
#' @param bg Background colour.
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed mypaint brush name, `.myb` file path, JSON brush string, or
#'   `NULL` for solid strokes. If omitted, `mypaint_device()` uses an internal
#'   default plotting brush.
#' @param stroke_style Legacy override for whether stroke drawing uses the brush
#'   backend or solid Cairo rendering. When `NULL`, this is inferred from
#'   whether `brush` is `NULL`.
#' @param fill_style Legacy override for whether fill drawing uses the brush
#'   backend or solid Cairo rendering. When `NULL`, this is inferred from
#'   whether `fill_brush` is `NULL`.
#' @param fill_brush Optional fill brush spec. Defaults to `brush` when not
#'   supplied. Use explicit `NULL` for solid fills.
#' @param hand Optional hand-drawn geometry spec applied to both stroke and
#'   fill primitives by default.
#' @param stroke_hand Optional hand-drawn geometry spec for strokes.
#' @param fill_hand Optional hand-drawn geometry spec for fills.
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
#' if ("classic/pen" %in% brushes()) {
#'   out <- tempfile("mypaint-brush-", fileext = "-%d.png")
#'   mypaint_device(
#'     out,
#'     width = 4,
#'     height = 3,
#'     brush = tweak_brush("classic/pen", tracking_noise = 0.12),
#'     fill_style = "brush",
#'     fill_brush = tweak_brush("classic/pen", normalize = "size", radius_by_random = 0.08)
#'   )
#'   plot.new()
#'   plot.window(xlim = c(0, 10), ylim = c(0, 10))
#'   polygon(
#'     c(2, 5, 8, 6, 3),
#'     c(2, 7, 6, 3, 1.5),
#'     border = "black",
#'     col = rgb(0.2, 0.7, 0.5, 0.6)
#'   )
#'   lines(c(1, 9), c(1, 9), col = "firebrick", lwd = 4)
#'   title("Brush Fill")
#'   box()
#'   dev.off()
#'   unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
#' }
#'
#' out <- tempfile("mypaint-mixed-", fileext = "-%d.png")
#' mypaint_device(out, width = 4, height = 3, brush = NULL)
#' plot(1:5, 1:5, type = "n", main = "Mixed Styles")
#' if ("classic/pencil" %in% brushes()) {
#'   set_brush("classic/pencil", type = "stroke")
#' }
#' lines(1:5, c(1, 3, 2, 5, 4), lwd = 3)
#' dev.off()
#' unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
#' @export
mypaint_device <- function(filename = NULL,
                           file = NULL,
                           width = 7,
                           height = 7,
                           res = 144,
                           pointsize = 12,
                           bg = "white",
                           brush = NULL,
                           stroke_style = NULL,
                           fill_style = NULL,
                           fill_brush = NULL,
                           hand = NULL,
                           stroke_hand = NULL,
                           fill_hand = NULL,
                           auto_solid_bg = TRUE) {
  if (is.null(filename)) {
    filename <- file
  } else if (!is.null(file) && !identical(filename, file)) {
    stop("Specify only one of `filename` or `file`.", call. = FALSE)
  }

  supplied_args <- names(match.call(expand.dots = FALSE))
  brush_missing <- !("brush" %in% supplied_args)
  fill_brush_missing <- !("fill_brush" %in% supplied_args)
  stroke_style_missing <- !("stroke_style" %in% supplied_args)
  fill_style_missing <- !("fill_style" %in% supplied_args)
  hand_missing <- !("hand" %in% supplied_args)
  stroke_hand_missing <- !("stroke_hand" %in% supplied_args)
  fill_hand_missing <- !("fill_hand" %in% supplied_args)
  auto_solid_bg_missing <- !("auto_solid_bg" %in% supplied_args)

  stopifnot(
    is.character(filename), length(filename) == 1L,
    is.numeric(width), length(width) == 1L, width > 0,
    is.numeric(height), length(height) == 1L, height > 0,
    is.numeric(res), length(res) == 1L, res > 0,
    is.numeric(pointsize), length(pointsize) == 1L, pointsize > 0
  )

  if (fill_brush_missing) {
    fill_brush <- brush
  }
  if (stroke_hand_missing) {
    stroke_hand <- hand
  }
  if (fill_hand_missing) {
    fill_hand <- hand
  }

  stroke_spec <- if (brush_missing) {
    normalize_brush_spec(default_plot_brush_spec())
  } else if (is.null(brush)) {
    NULL
  } else {
    normalize_brush_spec(brush)
  }
  fill_spec <- if (fill_brush_missing && brush_missing) {
    stroke_spec
  } else if (fill_brush_missing) {
    stroke_spec
  } else if (is.null(fill_brush)) {
    NULL
  } else {
    normalize_brush_spec(fill_brush)
  }
  warn_if_pure_smudge_brush(stroke_spec, "stroke")
  warn_if_pure_smudge_brush(fill_spec, "fill")
  stroke_style <- if (stroke_style_missing || is.null(stroke_style)) {
    if (brush_missing) 1L else if (is.null(brush)) 0L else 1L
  } else {
    normalize_render_style(stroke_style)
  }
  fill_style <- if (fill_style_missing || is.null(fill_style)) {
    if (fill_brush_missing) {
      if (stroke_style == 1L) 1L else 0L
    } else if (is.null(fill_brush)) {
      0L
    } else {
      1L
    }
  } else {
    normalize_render_style(fill_style)
  }

  invisible(.Call(
    mypaintr_device_open,
    enc2utf8(normalizePath(filename, winslash = "/", mustWork = FALSE)),
    as.numeric(width),
    as.numeric(height),
    as.numeric(res),
    as.numeric(pointsize),
    rgba_int(bg),
    stroke_spec,
    fill_spec,
    stroke_style,
    fill_style,
    if (auto_solid_bg_missing) TRUE else isTRUE(auto_solid_bg),
    normalize_hand_spec(stroke_hand),
    normalize_hand_spec(fill_hand)
  ))
}

#' Update the active mypaintr device style
#'
#' @param brush Stroke brush specification created with [tweak_brush()], an
#'   installed brush name, `.myb` file path, JSON brush string, or `NULL` for
#'   solid strokes.
#' @param stroke_style Either `"brush"` or `"solid"`.
#' @param fill_style Either `"solid"` or `"brush"`.
#' @param fill_brush Fill brush specification created with [tweak_brush()], an
#'   installed brush name, `.myb` file path, JSON brush string, or `NULL` for
#'   solid fills.
#' @param auto_solid_bg Whether large fills matching the device background should
#'   be drawn normally.
#' @return `NULL`, invisibly.
#' @keywords internal
#' @noRd
mypaint_style <- function(brush = NULL,
                          stroke_style = NULL,
                          fill_style = NULL,
                          fill_brush = NULL,
                          auto_solid_bg = NULL) {
  supplied_args <- names(match.call(expand.dots = FALSE))
  brush_missing <- !("brush" %in% supplied_args)
  fill_brush_missing <- !("fill_brush" %in% supplied_args)
  stroke_spec <- if (brush_missing) NULL else if (is.null(brush)) NULL else normalize_brush_spec(brush)
  fill_spec <- if (fill_brush_missing) NULL else if (is.null(fill_brush)) NULL else normalize_brush_spec(fill_brush)

  stroke_style <- normalize_render_style(stroke_style)
  fill_style <- normalize_render_style(fill_style)

  if (!is_mypaintr_device()) {
    return(invisible(NULL))
  }

  invisible(.Call(
    mypaintr_device_set_style,
    stroke_spec,
    fill_spec,
    stroke_style,
    fill_style,
    if (is.null(auto_solid_bg)) NULL else isTRUE(auto_solid_bg)
  ))
}

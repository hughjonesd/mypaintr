#' @keywords internal
#' @useDynLib mypaintr, .registration = TRUE
"_PACKAGE"

`%||%` <- function(x, y) if (is.null(x)) y else x

mypaintr_env <- new.env(parent = emptyenv())
mypaintr_env$style_stack <- list()
mypaintr_env$default_style <- list(
  stroke_spec = NULL,
  fill_spec = NULL,
  stroke_style = NULL,
  fill_style = NULL,
  auto_solid_bg = NULL,
  stroke_hand = NULL,
  fill_hand = NULL
)

is_visible_col <- function(col) {
  !is.null(col) && !all(is.na(col)) && grDevices::col2rgb(col, alpha = TRUE)[4, 1] > 0
}

rotate_xy <- function(x, y, angle_deg) {
  theta <- angle_deg * pi / 180
  cth <- cos(theta)
  sth <- sin(theta)
  list(
    x = cth * x - sth * y,
    y = sth * x + cth * y
  )
}

rough_control_offsets <- function(t, amplitude) {
  ctrl_x <- c(0, 0.33, 0.66, 1)
  ctrl_y <- c(0, stats::rnorm(2, sd = amplitude), 0)
  stats::approx(ctrl_x, ctrl_y, xout = t, rule = 2)$y
}

rough_segment_path <- function(x0, y0, x1, y1, hand_spec) {
  dx <- x1 - x0
  dy <- y1 - y0
  len <- sqrt(dx * dx + dy * dy)
  if (!is.finite(len) || len <= 0) {
    return(list(x = c(x0), y = c(y0)))
  }

  ux <- dx / len
  uy <- dy / len
  px <- -uy
  py <- ux
  endpoint_sd <- hand_spec$endpoint_jitter * len
  bow_amp <- stats::rnorm(1, sd = hand_spec$bow * len)
  wobble_amp <- hand_spec$wobble * len
  n <- max(6L, ceiling(len * 12))
  t <- seq(0, 1, length.out = n)

  start_para <- stats::rnorm(1, sd = endpoint_sd)
  end_para <- stats::rnorm(1, sd = endpoint_sd)
  start_perp <- stats::rnorm(1, sd = endpoint_sd)
  end_perp <- stats::rnorm(1, sd = endpoint_sd)

  sx <- x0 + ux * start_para + px * start_perp
  sy <- y0 + uy * start_para + py * start_perp
  ex <- x1 + ux * end_para + px * end_perp
  ey <- y1 + uy * end_para + py * end_perp

  base_x <- sx + (ex - sx) * t
  base_y <- sy + (ey - sy) * t
  bow <- bow_amp * sin(pi * t)
  wobble <- rough_control_offsets(t, wobble_amp) * sin(pi * t)
  offset <- bow + wobble

  list(
    x = base_x + px * offset,
    y = base_y + py * offset
  )
}

roughen_vertex_path <- function(x, y, hand_spec, closed = FALSE) {
  n <- length(x)
  if (n < 2) {
    return(list(x = x, y = y))
  }

  seg_n <- if (closed) n else n - 1L
  out_x <- numeric()
  out_y <- numeric()

  for (i in seq_len(seg_n)) {
    j <- if (i == n) 1L else i + 1L
    seg <- rough_segment_path(x[i], y[i], x[j], y[j], hand_spec)
    if (length(out_x)) {
      seg$x <- seg$x[-1L]
      seg$y <- seg$y[-1L]
    }
    out_x <- c(out_x, seg$x)
    out_y <- c(out_y, seg$y)
  }

  list(x = out_x, y = out_y)
}

draw_path_strokes <- function(path, hand_spec, draw_fun, ..., closed = FALSE, base_path = NULL) {
  args <- list(...)
  strokes <- max(1L, as.integer(hand_spec$multi_stroke))
  for (i in seq_len(strokes)) {
    lwd <- args$lwd %||% graphics::par("lwd")
    jittered_lwd <- max(0.01, lwd * (1 + stats::rnorm(1, sd = hand_spec$width_jitter)))
    path_i <- if (i == 1L && !is.null(base_path)) {
      base_path
    } else {
      roughen_vertex_path(path$x, path$y, hand_spec, closed = closed)
    }
    args_i <- args
    args_i$x <- path_i$x
    args_i$y <- path_i$y
    args_i$lwd <- jittered_lwd
    do.call(draw_fun, args_i)
  }
}

polygon_intersections <- function(x, y, yy) {
  n <- length(x)
  cuts <- numeric()
  for (i in seq_len(n)) {
    j <- if (i == n) 1L else i + 1L
    y0 <- y[i]
    y1 <- y[j]
    if (y0 == y1) {
      next
    }
    if (yy >= min(y0, y1) && yy < max(y0, y1)) {
      x0 <- x[i]
      x1 <- x[j]
      cuts <- c(cuts, x0 + (yy - y0) * (x1 - x0) / (y1 - y0))
    }
  }
  sort(cuts)
}

split_polypath <- function(x, y = NULL, id = NULL) {
  xy <- grDevices::xy.coords(x, y)
  if (is.null(id)) {
    id <- rep.int(1L, length(xy$x))
  }
  id <- as.integer(id)
  if (length(id) != length(xy$x)) {
    stop("id must have the same length as x and y", call. = FALSE)
  }

  groups <- split(seq_along(id), id)
  lapply(groups, function(idx) list(x = xy$x[idx], y = xy$y[idx]))
}

join_polypath_na <- function(paths) {
  x <- unlist(lapply(paths, function(path) c(path$x, NA_real_)), use.names = FALSE)
  y <- unlist(lapply(paths, function(path) c(path$y, NA_real_)), use.names = FALSE)
  if (length(x)) {
    x <- x[-length(x)]
    y <- y[-length(y)]
  }
  list(x = x, y = y)
}

rough_segments_data <- function(x0, y0, x1, y1, hand_spec) {
  n <- max(length(x0), length(y0), length(x1), length(y1))
  x0 <- rep_len(x0, n)
  y0 <- rep_len(y0, n)
  x1 <- rep_len(x1, n)
  y1 <- rep_len(y1, n)

  out_x <- numeric()
  out_y <- numeric()
  out_id <- integer()
  for (i in seq_len(n)) {
    seg <- rough_segment_path(x0[i], y0[i], x1[i], y1[i], hand_spec)
    out_x <- c(out_x, seg$x)
    out_y <- c(out_y, seg$y)
    out_id <- c(out_id, rep.int(i, length(seg$x)))
  }

  list(x = out_x, y = out_y, id = out_id)
}

rough_path_intersections <- function(paths, yy) {
  cuts <- numeric()
  delta <- integer()

  for (path in paths) {
    n <- length(path$x)
    if (n < 2L) next
    for (i in seq_len(n)) {
      j <- if (i == n) 1L else i + 1L
      y0 <- path$y[i]
      y1 <- path$y[j]
      if (y0 == y1) next
      if (yy >= min(y0, y1) && yy < max(y0, y1)) {
        x0 <- path$x[i]
        x1 <- path$x[j]
        cuts <- c(cuts, x0 + (yy - y0) * (x1 - x0) / (y1 - y0))
        delta <- c(delta, if (y1 > y0) 1L else -1L)
      }
    }
  }

  if (!length(cuts)) {
    return(list(x = numeric(), delta = integer()))
  }

  ord <- order(cuts)
  list(x = cuts[ord], delta = delta[ord])
}

offset_id <- function(id, by = 0L) {
  if (!length(id)) {
    return(id)
  }
  as.integer(id + by)
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

normalize_render_style <- function(style) {
  if (is.null(style)) {
    return(NULL)
  }
  style <- match.arg(style, c("solid", "brush"))
  match(style, c("solid", "brush")) - 1L
}

is_mypaintr_device <- function() {
  identical(names(grDevices::dev.cur()), "mypaintr")
}

current_device_style <- function() {
  if (!is_mypaintr_device()) {
    return(NULL)
  }
  .Call(mypaintr_device_get_style)
}

default_device_style <- function() {
  mypaintr_env$default_style
}

update_default_device_style <- function(stroke_spec = NULL,
                                        fill_spec = NULL,
                                        stroke_style = NULL,
                                        fill_style = NULL,
                                        auto_solid_bg = NULL,
                                        stroke_hand = NULL,
                                        fill_hand = NULL,
                                        update_stroke = FALSE,
                                        update_fill = FALSE) {
  defaults <- default_device_style()

  if (update_stroke) {
    defaults$stroke_spec <- stroke_spec
    defaults$stroke_style <- stroke_style
    defaults$stroke_hand <- stroke_hand
  }
  if (update_fill) {
    defaults$fill_spec <- fill_spec
    defaults$fill_style <- fill_style
    defaults$fill_hand <- fill_hand
  }
  if (!is.null(auto_solid_bg)) {
    defaults$auto_solid_bg <- isTRUE(auto_solid_bg)
  }

  mypaintr_env$default_style <- defaults
  invisible(NULL)
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

alpha_colour <- function(col, alpha = NA_real_) {
  if (is.null(col) || all(is.na(col))) {
    return(col)
  }
  if (is.list(col)) {
    stop("pattern fills are not supported by mypaint geoms", call. = FALSE)
  }
  alpha <- rep_len(alpha, length(col))
  out <- col
  keep <- !is.na(col)
  keep[keep] <- is.na(alpha[keep]) | alpha[keep] >= 0
  out[keep] <- grDevices::adjustcolor(col[keep], alpha.f = ifelse(is.na(alpha[keep]), 1, alpha[keep]))
  out
}

as_optional_hand <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  normalize_hand_spec(x)
}

closed_rect_path <- function(xmin, xmax, ymin, ymax) {
  list(
    x = c(xmin, xmax, xmax, xmin, xmin),
    y = c(ymin, ymin, ymax, ymax, ymin)
  )
}

outline_path <- function(x, y, hand_spec = NULL, closed = TRUE) {
  if (is.null(hand_spec)) {
    return(list(x = x, y = y))
  }
  with_hand_seed(hand_spec$seed, {
    roughen_vertex_path(x, y, hand_spec, closed = closed)
  })
}

segment_data <- function(x0, y0, x1, y1, hand_spec = NULL) {
  n <- max(length(x0), length(y0), length(x1), length(y1))
  x0 <- rep_len(x0, n)
  y0 <- rep_len(y0, n)
  x1 <- rep_len(x1, n)
  y1 <- rep_len(y1, n)

  if (is.null(hand_spec)) {
    return(list(
      x = c(rbind(x0, x1)),
      y = c(rbind(y0, y1)),
      id = rep(seq_len(n), each = 2L)
    ))
  }

  rough_segments_data(x0, y0, x1, y1, hand_spec)
}

rough_hachure_data <- function(paths, hand_spec = NULL, angle = 45, density = NULL,
                               rule = c("winding", "evenodd"), cross = FALSE) {
  fill_pattern <- if (cross || (!is.null(hand_spec) && identical(hand_spec$hachure_method, "cross"))) {
    crosshatch(angle = angle)
  } else {
    hatch(angle = angle)
  }
  rough_fill_pattern_data(
    paths,
    hand_spec = hand_spec,
    fill_pattern = fill_pattern,
    rule = rule
  )
}

rgba_int <- function(col) {
  rgba <- grDevices::col2rgb(col, alpha = TRUE)
  as.integer(rgba[, 1L])
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
#' @param brush Stroke brush preset, installed mypaint brush name,
#'   `.myb` file path, JSON brush string, named settings, or `NULL` for solid
#'   strokes.
#' @param brush_settings Named settings overriding `brush`.
#' @param stroke_style Legacy override for whether stroke drawing uses the brush
#'   backend or solid Cairo rendering. When `NULL`, this is inferred from
#'   whether `brush` is `NULL`.
#' @param fill_style Legacy override for whether fill drawing uses the brush
#'   backend or solid Cairo rendering. When `NULL`, this is inferred from
#'   whether `fill_brush` is `NULL`.
#' @param fill_brush Optional fill brush spec. Defaults to `brush` when not
#'   supplied. Use explicit `NULL` for solid fills.
#' @param fill_settings Named settings overriding `fill_brush`.
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
#' mypaint_device(out, width = 4, height = 3, brush = NULL)
#' plot(1:5, 1:5, type = "n", main = "Mixed Styles")
#' set_brush("pencil", type = "stroke")
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
                           brush = "ink",
                           brush_settings = NULL,
                           stroke_style = NULL,
                           fill_style = NULL,
                           fill_brush = NULL,
                           fill_settings = NULL,
                           hand = NULL,
                           stroke_hand = NULL,
                           fill_hand = NULL,
                           auto_solid_bg = TRUE) {
  if (is.null(filename)) {
    filename <- file
  } else if (!is.null(file) && !identical(filename, file)) {
    stop("Specify only one of `filename` or `file`.", call. = FALSE)
  }

  brush_missing <- missing(brush)
  fill_brush_missing <- missing(fill_brush)
  stroke_style_missing <- missing(stroke_style)
  fill_style_missing <- missing(fill_style)
  hand_missing <- missing(hand)
  stroke_hand_missing <- missing(stroke_hand)
  fill_hand_missing <- missing(fill_hand)
  auto_solid_bg_missing <- missing(auto_solid_bg)
  defaults <- default_device_style()

  stopifnot(
    is.character(filename), length(filename) == 1L,
    is.numeric(width), length(width) == 1L, width > 0,
    is.numeric(height), length(height) == 1L, height > 0,
    is.numeric(res), length(res) == 1L, res > 0,
    is.numeric(pointsize), length(pointsize) == 1L, pointsize > 0
  )

  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }
  if (missing(fill_brush)) {
    fill_brush <- brush
  }
  if (is.null(fill_brush) && !is.null(fill_settings)) {
    stop("fill_settings requires fill_brush", call. = FALSE)
  }
  if (missing(stroke_hand)) {
    stroke_hand <- hand
  }
  if (missing(fill_hand)) {
    fill_hand <- hand
  }

  stroke_spec <- if (brush_missing && is.null(brush_settings) && !is.null(defaults$stroke_spec)) {
    defaults$stroke_spec
  } else if (is.null(brush) && is.null(brush_settings)) {
    NULL
  } else {
    normalize_brush_spec(brush, brush_settings)
  }
  fill_spec <- if (fill_brush_missing && is.null(fill_settings) && !is.null(defaults$fill_spec)) {
    defaults$fill_spec
  } else if (fill_brush_missing && is.null(fill_settings) && brush_missing && !is.null(defaults$stroke_spec)) {
    defaults$stroke_spec
  } else if (is.null(fill_brush) && is.null(fill_settings)) {
    NULL
  } else {
    normalize_brush_spec(fill_brush, fill_settings)
  }
  warn_if_pure_smudge_brush(stroke_spec, "stroke")
  warn_if_pure_smudge_brush(fill_spec, "fill")
  stroke_style <- if (stroke_style_missing && !is.null(defaults$stroke_style)) {
    defaults$stroke_style
  } else if (is.null(stroke_style)) {
    if (is.null(brush)) 0L else 1L
  } else {
    normalize_render_style(stroke_style)
  }
  fill_style <- if (fill_style_missing && !is.null(defaults$fill_style)) {
    defaults$fill_style
  } else if (fill_style_missing && fill_brush_missing && !is.null(defaults$stroke_style)) {
    defaults$stroke_style
  } else if (is.null(fill_style)) {
    if (is.null(fill_brush)) 0L else 1L
  } else {
    normalize_render_style(fill_style)
  }
  if (stroke_hand_missing && hand_missing && !is.null(defaults$stroke_hand)) {
    stroke_hand <- defaults$stroke_hand
  }
  if (fill_hand_missing && hand_missing && !is.null(defaults$fill_hand)) {
    fill_hand <- defaults$fill_hand
  }
  if (auto_solid_bg_missing && !is.null(defaults$auto_solid_bg)) {
    auto_solid_bg <- defaults$auto_solid_bg
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
    isTRUE(auto_solid_bg),
    normalize_hand_spec(stroke_hand),
    normalize_hand_spec(fill_hand)
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
#' @return `NULL`, invisibly. If the active device is not `mypaintr`, the style
#'   becomes the default for the next [mypaint_device()] opened in this R
#'   session.
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

  stroke_style <- normalize_render_style(stroke_style)
  fill_style <- normalize_render_style(fill_style)

  if (!is_mypaintr_device()) {
    update_default_device_style(
      stroke_spec = stroke_spec,
      fill_spec = fill_spec,
      stroke_style = stroke_style,
      fill_style = fill_style,
      auto_solid_bg = auto_solid_bg,
      update_stroke = !is.null(brush) || !is.null(brush_settings) || !is.null(stroke_style),
      update_fill = !is.null(fill_brush) || !is.null(fill_settings) || !is.null(fill_style)
    )
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

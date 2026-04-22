
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

#' Compute a rough polygon outline
#'
#' @param x,y Polygon coordinates.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @return A list with `x` and `y` components containing a roughened closed
#'   outline suitable for plotting with [graphics::lines()].
#' @examples
#' rough_polygon(c(2, 5, 8, 3), c(2, 7, 5, 1))
#' @export
rough_polygon <- function(x, y = NULL, hand = NULL) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)

  with_hand_seed(hand_spec$seed, {
    roughen_vertex_path(xy$x, xy$y, hand_spec, closed = TRUE)
  })
}

#' Compute a rough rectangle outline
#'
#' @param x0,y0 Rectangle corner.
#' @param x1,y1 Opposite rectangle corner.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @return A list with `x` and `y` components containing a roughened closed
#'   outline suitable for plotting with [graphics::lines()].
#' @examples
#' rough_rect(2, 2, 5, 6)
#' @export
rough_rect <- function(x0, y0, x1, y1, hand = NULL) {
  rough_polygon(
    c(x0, x1, x1, x0),
    c(y0, y0, y1, y1),
    hand = hand
  )
}

#' Compute rough segment geometry
#'
#' @param x0,y0 Segment starts.
#' @param x1,y1 Segment ends.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @return A list with `x`, `y`, and `id` components describing roughened
#'   polyline geometry for each segment.
#' @examples
#' rough_segments(1:2, 1:2, 2:3, 3:2)
#' @export
rough_segments <- function(x0, y0, x1, y1, hand = NULL) {
  hand_spec <- as_hand(hand)
  with_hand_seed(hand_spec$seed, {
    rough_segments_data(x0, y0, x1, y1, hand_spec)
  })
}

arrow_unit_scale <- function() {
  usr <- graphics::par("usr")
  pin <- graphics::par("pin")
  c(
    x = abs(usr[2] - usr[1]) / pin[1],
    y = abs(usr[4] - usr[3]) / pin[2]
  )
}

arrowhead_segments <- function(x0, y0, x1, y1, length = 0.25, angle = 30, code = 2) {
  head_length <- length
  n <- max(base::length(x0), base::length(y0), base::length(x1), base::length(y1))
  x0 <- rep_len(x0, n)
  y0 <- rep_len(y0, n)
  x1 <- rep_len(x1, n)
  y1 <- rep_len(y1, n)
  code <- rep_len(as.integer(code), n)
  angle <- rep_len(angle, n)

  scale <- arrow_unit_scale()
  seg_x0 <- numeric()
  seg_y0 <- numeric()
  seg_x1 <- numeric()
  seg_y1 <- numeric()

  add_head <- function(base_x, base_y, tip_x, tip_y, head_angle) {
    dx <- (tip_x - base_x) / scale["x"]
    dy <- (tip_y - base_y) / scale["y"]
    seg_len <- sqrt(dx * dx + dy * dy)
    if (!is.finite(seg_len) || seg_len <= 0) {
      return()
    }

    head_len <- min(head_length, seg_len / 2)
    theta <- atan2(dy, dx)
    spread <- head_angle * pi / 180
    for (phi in c(theta + pi - spread, theta + pi + spread)) {
      hx <- tip_x + cos(phi) * head_len * scale["x"]
      hy <- tip_y + sin(phi) * head_len * scale["y"]
      seg_x0 <<- c(seg_x0, tip_x)
      seg_y0 <<- c(seg_y0, tip_y)
      seg_x1 <<- c(seg_x1, hx)
      seg_y1 <<- c(seg_y1, hy)
    }
  }

  for (i in seq_len(n)) {
    if (code[i] %in% c(1L, 3L)) {
      add_head(x1[i], y1[i], x0[i], y0[i], angle[i])
    }
    if (code[i] %in% c(2L, 3L)) {
      add_head(x0[i], y0[i], x1[i], y1[i], angle[i])
    }
  }

  list(x0 = seg_x0, y0 = seg_y0, x1 = seg_x1, y1 = seg_y1)
}

rough_polypath_data <- function(paths, hand_spec, rule) {
  out_x <- numeric()
  out_y <- numeric()
  out_id <- integer()
  for (i in seq_along(paths)) {
    path <- roughen_vertex_path(paths[[i]]$x, paths[[i]]$y, hand_spec, closed = TRUE)
    out_x <- c(out_x, path$x)
    out_y <- c(out_y, path$y)
    out_id <- c(out_id, rep.int(i, length(path$x)))
  }
  list(x = out_x, y = out_y, id = out_id, rule = rule)
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

#' Compute a rough multipath outline
#'
#' @param x,y Coordinates as for [graphics::polypath()].
#' @param id Optional path ids. Consecutive points with the same `id` belong to
#'   one closed ring.
#' @param rule Fill rule, `"winding"` or `"evenodd"`.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @return A list with `x`, `y`, `id`, and `rule` components describing
#'   roughened closed rings.
#' @examples
#' rough_polypath(c(2, 4, 4, 2, 2.5, 3.5, 3.5, 2.5),
#'                c(2, 2, 4, 4, 2.5, 2.5, 3.5, 3.5),
#'                id = c(rep(1, 4), rep(2, 4)),
#'                rule = "evenodd")
#' @export
rough_polypath <- function(x, y = NULL, id = NULL, rule = c("winding", "evenodd"), hand = NULL) {
  hand_spec <- as_hand(hand)
  rule <- match.arg(rule)
  paths <- split_polypath(x, y, id)

  with_hand_seed(hand_spec$seed, {
    rough_polypath_data(paths, hand_spec, rule)
  })
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

#' Draw rough connected lines
#'
#' @param x,y Coordinates as for [graphics::lines()].
#' @inheritParams mypaintr-rough-hand
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' y <- c(2, 5, 4, 7, 6, 8)
#' plot(1:6, y, type = "n")
#' draw_rough_lines(1:6, y, hand = hand(multi_stroke = 2), lwd = 2)
#' @family rough drawing helpers
#' @export
draw_rough_lines <- function(x, y = NULL, hand = NULL, ...) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)
  ok <- stats::complete.cases(xy$x, xy$y)
  groups <- cumsum(!ok)

  invisible(with_hand_seed(hand_spec$seed, {
    for (g in unique(groups[ok])) {
      keep <- ok & groups == g
      if (sum(keep) >= 2L) {
        draw_path_strokes(
          list(x = xy$x[keep], y = xy$y[keep]),
          hand_spec,
          graphics::lines,
          ...
        )
      }
    }
    NULL
  }))
}

#' Draw rough segments
#'
#' @param x0,y0 Segment starts.
#' @param x1,y1 Segment ends.
#' @inheritParams mypaintr-rough-hand
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_segments(1:3, 2:4, 4:6, c(8, 5, 7), lwd = 2)
#' @family rough drawing helpers
#' @export
draw_rough_segments <- function(x0, y0, x1, y1, hand = NULL, ...) {
  hand_spec <- as_hand(hand)
  invisible(with_hand_seed(hand_spec$seed, {
    for (j in seq_len(max(1L, hand_spec$multi_stroke))) {
      geom <- rough_segments_data(x0, y0, x1, y1, hand_spec)
      for (i in unique(geom$id)) {
        keep <- geom$id == i
        graphics::lines(geom$x[keep], geom$y[keep], ...)
      }
    }
    NULL
  }))
}

#' Draw rough arrows
#'
#' @param x0,y0 Arrow starts.
#' @param x1,y1 Arrow ends.
#' @param length Arrowhead length in inches, as in [graphics::arrows()].
#' @param angle Arrowhead angle in degrees.
#' @param code Integer code indicating where heads are drawn:
#'   `0` for none, `1` at the start, `2` at the end, `3` at both ends.
#' @inheritParams mypaintr-rough-hand
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_arrows(2, 2, 8, 8, lwd = 2)
#' draw_rough_arrows(8, 2, 2, 8, code = 3, hand = hand(multi_stroke = 2))
#' @family rough drawing helpers
#' @export
draw_rough_arrows <- function(x0, y0, x1, y1, length = 0.25, angle = 30, code = 2,
                              hand = NULL, ...) {
  hand_spec <- as_hand(hand)
  hand_draw <- hand_spec
  hand_draw$seed <- NULL

  invisible(with_hand_seed(hand_spec$seed, {
    draw_rough_segments(x0, y0, x1, y1, hand = hand_draw, ...)
    heads <- arrowhead_segments(x0, y0, x1, y1, length = length, angle = angle, code = code)
    if (base::length(heads$x0)) {
      draw_rough_segments(heads$x0, heads$y0, heads$x1, heads$y1, hand = hand_draw, ...)
    }
    NULL
  }))
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

#' Draw a rough multipath with optional holes
#'
#' @param x,y Coordinates as for [graphics::polypath()].
#' @param id Optional path ids. Consecutive points with the same `id` belong to
#'   one closed ring.
#' @param rule Fill rule, `"winding"` or `"evenodd"`.
#' @inheritParams mypaintr-rough-hand
#' @inheritParams mypaintr-rough-fill
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_polypath(c(2, 8, 8, 2, 4, 6, 6, 4),
#'                     c(2, 2, 8, 8, 4, 4, 6, 6),
#'                     id = c(rep(1, 4), rep(2, 4)),
#'                     rule = "evenodd",
#'                     col = "grey90",
#'                     fill_pattern = hatch(density = 9))
#' @family rough drawing helpers
#' @export
draw_rough_polypath <- function(x, y = NULL, id = NULL, rule = c("winding", "evenodd"),
                                hand = NULL, col = NA, border = graphics::par("fg"),
                                fill_pattern = NULL, ...) {
  hand_spec <- as_hand(hand)
  rule <- match.arg(rule)
  paths0 <- split_polypath(x, y, id)
  fill_pattern <- as_fill_pattern(fill_pattern, hand_spec = hand_spec)

  invisible(with_hand_seed(hand_spec$seed, {
    geom <- rough_polypath_data(paths0, hand_spec, rule)
    paths <- split_polypath(geom$x, geom$y, geom$id)

    if (is_visible_col(col)) {
      if (is.null(fill_pattern)) {
        solid_path <- join_polypath_na(paths)
        do.call(
          graphics::polypath,
          c(
            list(x = solid_path$x, y = solid_path$y, rule = geom$rule, col = col, border = NA),
            list(...)
          )
        )
      } else {
        draw_rough_fill_pattern(
          paths,
          hand_spec,
          col = col,
          fill_pattern = fill_pattern,
          rule = geom$rule,
          ...
        )
      }
    }
    if (is_visible_col(border)) {
      for (j in seq_len(max(1L, hand_spec$multi_stroke))) {
        paths_j <- if (j == 1L) {
          paths
        } else {
          geom_j <- rough_polypath_data(paths0, hand_spec, rule)
          split_polypath(geom_j$x, geom_j$y, geom_j$id)
        }
        for (path in paths_j) {
          graphics::lines(path$x, path$y, col = border, ...)
        }
      }
    }
    NULL
  }))
}

#' Draw rough polygons
#'
#' @param x,y Polygon coordinates.
#' @inheritParams mypaintr-rough-hand
#' @inheritParams mypaintr-rough-fill
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_polygons(c(2, 5, 8, 3), c(2, 7, 5, 1),
#'                     col = "grey90",
#'                     fill_pattern = zigzag())
#' @family rough drawing helpers
#' @export
draw_rough_polygons <- function(x, y = NULL, hand = NULL, col = NA, border = graphics::par("fg"),
                                fill_pattern = NULL, ...) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)
  fill_pattern <- as_fill_pattern(fill_pattern, hand_spec = hand_spec)

  invisible(with_hand_seed(hand_spec$seed, {
    rough_outline <- roughen_vertex_path(xy$x, xy$y, hand_spec, closed = TRUE)
    if (is_visible_col(col)) {
      if (is.null(fill_pattern)) {
        do.call(
          graphics::polygon,
          c(
            list(x = rough_outline$x, y = rough_outline$y, col = col, border = NA),
            list(...)
          )
        )
      } else {
        draw_rough_fill_pattern(
          list(rough_outline),
          hand_spec,
          col = col,
          fill_pattern = fill_pattern,
          ...
        )
      }
    }
    if (is_visible_col(border)) {
      draw_path_strokes(
        list(x = xy$x, y = xy$y),
        hand_spec,
        graphics::lines,
        col = border,
        base_path = rough_outline,
        closed = TRUE,
        ...
      )
    }
    NULL
  }))
}

#' Draw a rough rectangle
#'
#' @param x0,y0 Rectangle corner.
#' @param x1,y1 Opposite rectangle corner.
#' @inheritParams mypaintr-rough-hand
#' @inheritParams mypaintr-rough-fill
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_rect(2, 2, 8, 7, col = "grey90",
#'                 fill_pattern = crosshatch(padding = 0.05))
#' @family rough drawing helpers
#' @export
draw_rough_rect <- function(x0, y0, x1, y1, hand = NULL, col = NA, border = graphics::par("fg"),
                            fill_pattern = NULL, ...) {
  x <- c(x0, x1, x1, x0)
  y <- c(y0, y0, y1, y1)
  draw_rough_polygons(
    x, y,
    hand = hand,
    col = col,
    border = border,
    fill_pattern = fill_pattern,
    ...
  )
}


#' Draw rough points
#'
#' @param x,y Point coordinates as for [graphics::points()].
#' @inheritParams mypaintr-rough-hand
#' @param ... Graphics parameters passed to [graphics::points()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_points(1:10, 1:10, pch = 16, cex = 1.4)
#' @family rough drawing helpers
#' @export
draw_rough_points <- function(x, y = NULL, hand = NULL, ...) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)
  usr <- graphics::par("usr")
  scale <- 0.01 * sqrt((usr[2] - usr[1]) * (usr[4] - usr[3]))

  invisible(with_hand_seed(hand_spec$seed, {
    for (i in seq_len(max(1L, hand_spec$multi_stroke))) {
      graphics::points(
        xy$x + stats::rnorm(length(xy$x), sd = hand_spec$endpoint_jitter * scale),
        xy$y + stats::rnorm(length(xy$y), sd = hand_spec$endpoint_jitter * scale),
        ...
      )
    }
    NULL
  }))
}

new_fill_pattern <- function(style,
                             density = NULL,
                             angle = NULL,
                             clip = TRUE,
                             padding = 0,
                             strokes = NULL,
                             step = NULL,
                             curl = NULL,
                             radius = NULL,
                             wobble = NULL) {
  structure(
    list(
      style = style,
      density = density,
      angle = angle,
      clip = isTRUE(clip),
      padding = padding,
      strokes = strokes,
      step = step,
      curl = curl,
      radius = radius,
      wobble = wobble
    ),
    class = "mypaintr_fill_pattern"
  )
}

#' Hatch fill pattern
#'
#' @inheritParams mypaintr-fill-pattern-params
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @examples
#' plot.new()
#' plot.window(xlim = c(0, 10), ylim = c(0, 10))
#' draw_rough_rect(2, 2, 8, 8, col = "red",
#'                 fill_pattern = hatch(density = 10))
#' @family fill patterns
#' @export
hatch <- function(angle = 45, density = 8, clip = TRUE, padding = 0) {
  new_fill_pattern("lines", density = density, angle = angle, clip = clip, padding = padding)
}

#' Cross-hatch fill pattern
#'
#' @inheritParams mypaintr-fill-pattern-params
#' @param angle One or two hatch angles in degrees. If a single angle is
#'   supplied, the second pass defaults to `angle + 90`.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @examples
#' plot.new()
#' plot.window(xlim = c(0, 10), ylim = c(0, 10))
#' draw_rough_rect(
#'   2, 2, 8, 8,
#'   col = "grey90",
#'   fill_pattern = crosshatch(angle = c(30, 120), density = 9)
#' )
#' @family fill patterns
#' @export
crosshatch <- function(angle = 45, density = 7, clip = TRUE, padding = 0) {
  if (!length(angle) %in% c(1L, 2L)) {
    stop("angle must have length 1 or 2", call. = FALSE)
  }
  new_fill_pattern("cross", density = density, angle = angle, clip = clip, padding = padding)
}

#' Zigzag fill pattern
#'
#' @inheritParams mypaintr-fill-pattern-params
#' @param clip When `TRUE`, zigzag endpoints stay on the shape boundary to
#'   reduce overshoot.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @examples
#' plot.new()
#' plot.window(xlim = c(0, 10), ylim = c(0, 10))
#' draw_rough_rect(2, 2, 8, 8, col = "red",
#'                 fill_pattern = zigzag(density = 7))
#' @family fill patterns
#' @export
zigzag <- function(angle = 45, density = 6, clip = TRUE, padding = 0) {
  new_fill_pattern("zigzag", density = density, angle = angle, clip = clip, padding = padding)
}

#' Jumble fill pattern
#'
#' @param angle Base angle in degrees for the underlying guide lines.
#' @param density Approximate line density in lines per inch. Larger
#'   values give denser fills.
#' @param radius Loop radius in inches. Defaults to `0.76 / density`, so the
#'   loops are sized as a fraction of the line spacing.
#' @param wobble Amount of irregularity in the loop shapes, spacing, and size.
#'   Larger values give less even, more varied loops.
#' @param padding Inset from the polygon edge in inches. Positive values leave a
#'   small gap between the fill pattern and the boundary.
#' @param clip When `TRUE`, split loop paths at the shape boundary.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @examples
#' plot.new()
#' plot.window(xlim = c(0, 10), ylim = c(0, 10))
#' draw_rough_rect(2, 2, 8, 8, col = "red", fill_pattern = jumble())
#' @family fill patterns
#' @export
jumble <- function(angle = 0, density = 5, radius = 0.76 / density, wobble = 0.2,
                   clip = TRUE, padding = 0) {
  new_fill_pattern(
    "jumble",
    density = density,
    angle = angle,
    clip = clip,
    padding = padding,
    radius = radius,
    wobble = wobble
  )
}

as_fill_pattern <- function(fill_pattern = NULL, hand_spec = NULL) {
  if (is.null(fill_pattern)) {
    return(NULL)
  }

  if (!inherits(fill_pattern, "mypaintr_fill_pattern")) {
    stop("fill_pattern must be created with hatch(), crosshatch(), zigzag(), or jumble()", call. = FALSE)
  }

  fill_pattern
}

gap_inches_per_data_unit <- function(angle = 0) {
  metrics <- tryCatch(
    list(usr = graphics::par("usr"), pin = graphics::par("pin")),
    error = function(...) NULL
  )
  if (is.null(metrics)) {
    return(1)
  }

  usr <- metrics$usr
  pin <- metrics$pin
  x_in_per_unit <- pin[1] / max(usr[2] - usr[1], .Machine$double.eps)
  y_in_per_unit <- pin[2] / max(usr[4] - usr[3], .Machine$double.eps)
  theta <- angle * pi / 180
  sqrt((x_in_per_unit * sin(theta))^2 + (y_in_per_unit * cos(theta))^2)
}

resolve_inches_per_data_unit <- function(inches_per_data_unit, angle = 0) {
  if (is.null(inches_per_data_unit)) {
    return(NULL)
  }
  if (is.function(inches_per_data_unit)) {
    return(inches_per_data_unit(angle))
  }
  inches_per_data_unit
}

fill_pattern_gap <- function(fill_pattern, paths, hand_spec = NULL, angle = NULL,
                             inches_per_data_unit = NULL) {
  gap <- NULL
  if (is.null(gap)) {
    density <- fill_pattern$density %||% 25
    gap <- 1 / max(1, density)
    in_per_gap_unit <- resolve_inches_per_data_unit(inches_per_data_unit, angle %||% 0)
    if (is.null(in_per_gap_unit) && !is.null(angle)) {
      in_per_gap_unit <- gap_inches_per_data_unit(angle)
    }
    if (!is.null(in_per_gap_unit) && is.finite(in_per_gap_unit) && in_per_gap_unit > 0) {
      gap <- gap / in_per_gap_unit
    }
  }
  max(gap, .Machine$double.eps)
}

fill_pattern_padding <- function(fill_pattern, angle = 0, inches_per_data_unit = NULL) {
  padding <- fill_pattern$padding %||% 0
  if (!is.finite(padding) || padding <= 0) {
    return(0)
  }

  in_per_unit <- resolve_inches_per_data_unit(inches_per_data_unit, angle)
  if (is.null(in_per_unit)) {
    in_per_unit <- gap_inches_per_data_unit(angle)
  }
  if (!is.finite(in_per_unit) || in_per_unit <= 0) {
    return(0)
  }

  padding / in_per_unit
}

line_fill_angles <- function(fill_pattern) {
  if (identical(fill_pattern$style, "cross")) {
    angle <- as.numeric(fill_pattern$angle)
    if (length(angle) == 1L) c(angle, angle + 90) else angle
  } else {
    fill_pattern$angle
  }
}

clipped_hatch_hand <- function(hand_spec, clip = TRUE) {
  hand_fill <- hand_spec
  hand_fill$seed <- NULL
  if (isTRUE(clip)) {
    hand_fill$endpoint_jitter <- 0
  }
  hand_fill
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


point_in_paths <- function(paths, x, y, rule = c("winding", "evenodd")) {
  rule <- match.arg(rule)
  x <- rep_len(x, max(length(x), length(y)))
  y <- rep_len(y, max(length(x), length(y)))
  vapply(seq_along(x), function(i) {
    cuts <- rough_path_intersections(paths, y[i])
    keep <- cuts$x < x[i]
    if (!any(keep)) {
      return(FALSE)
    }
    if (identical(rule, "evenodd")) {
      sum(keep) %% 2L == 1L
    } else {
      sum(cuts$delta[keep]) != 0L
    }
  }, logical(1))
}

path_bbox <- function(paths) {
  xs <- unlist(lapply(paths, `[[`, "x"), use.names = FALSE)
  ys <- unlist(lapply(paths, `[[`, "y"), use.names = FALSE)
  list(
    xmin = min(xs),
    xmax = max(xs),
    ymin = min(ys),
    ymax = max(ys)
  )
}

sample_point_in_paths <- function(paths, rule = c("winding", "evenodd"), max_tries = 200L) {
  rule <- match.arg(rule)
  box <- path_bbox(paths)
  for (i in seq_len(max_tries)) {
    x <- stats::runif(1L, box$xmin, box$xmax)
    y <- stats::runif(1L, box$ymin, box$ymax)
    if (point_in_paths(paths, x, y, rule)) {
      return(c(x = x, y = y))
    }
  }
  c(x = mean(c(box$xmin, box$xmax)), y = mean(c(box$ymin, box$ymax)))
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

scanline_intervals <- function(paths, angle = 45, gap = NULL, rule = c("winding", "evenodd"),
                               jitter_gap = 0, padding = 0) {
  rule <- match.arg(rule)
  rot_paths <- lapply(paths, function(path) rotate_xy(path$x, path$y, -angle))
  yr <- unlist(lapply(rot_paths, `[[`, "y"), use.names = FALSE)
  if (!length(yr)) {
    return(data.frame(row = integer(), interval = integer(), y = numeric(), x0 = numeric(), x1 = numeric()))
  }

  span <- diff(range(yr))
  gap <- gap %||% (if (span <= 0) 1 else span / 25)
  gap <- max(gap, .Machine$double.eps)
  ymin <- min(yr) + padding
  ymax <- max(yr) - padding
  if (ymax < ymin) {
    return(data.frame(row = integer(), interval = integer(), y = numeric(), x0 = numeric(), x1 = numeric()))
  }

  yy <- ymin
  row <- 1L
  out <- data.frame(row = integer(), interval = integer(), y = numeric(), x0 = numeric(), x1 = numeric())
  while (yy <= ymax) {
    cuts <- rough_path_intersections(rot_paths, yy)
    if (length(cuts$x) >= 2L) {
      intervals <- list()
      if (identical(rule, "evenodd")) {
        for (i in seq(1L, length(cuts$x) - 1L, by = 2L)) {
          intervals[[length(intervals) + 1L]] <- c(cuts$x[i], cuts$x[i + 1L])
        }
      } else {
        winding <- 0L
        for (i in seq_len(length(cuts$x) - 1L)) {
          winding <- winding + cuts$delta[i]
          if (winding != 0L && cuts$x[i + 1L] > cuts$x[i]) {
            intervals[[length(intervals) + 1L]] <- c(cuts$x[i], cuts$x[i + 1L])
          }
        }
      }
      if (length(intervals)) {
        mat <- do.call(rbind, intervals)
        out <- rbind(
          out,
          data.frame(
            row = rep.int(row, nrow(mat)),
            interval = seq_len(nrow(mat)),
            y = rep.int(yy, nrow(mat)),
            x0 = mat[, 1L],
            x1 = mat[, 2L]
          )
        )
      }
    }
    row <- row + 1L
    step <- gap * (1 + jitter_gap)
    yy <- yy + max(step, gap / 5, .Machine$double.eps)
  }

  out
}

polyline_data <- function(paths, hand_spec = NULL) {
  out_x <- numeric()
  out_y <- numeric()
  out_id <- integer()

  for (i in seq_along(paths)) {
    path <- paths[[i]]
    if (length(path$x) < 2L) next
    if (is.null(hand_spec)) {
      out_x <- c(out_x, path$x)
      out_y <- c(out_y, path$y)
      out_id <- c(out_id, rep.int(i, length(path$x)))
    } else {
      rough <- roughen_vertex_path(path$x, path$y, hand_spec, closed = FALSE)
      out_x <- c(out_x, rough$x)
      out_y <- c(out_y, rough$y)
      out_id <- c(out_id, rep.int(i, length(rough$x)))
    }
  }

  list(x = out_x, y = out_y, id = out_id)
}

clip_polyline_to_paths <- function(paths, x, y, rule = c("winding", "evenodd")) {
  rule <- match.arg(rule)
  keep <- point_in_paths(paths, x, y, rule = rule)
  if (!any(keep)) {
    return(list())
  }

  runs <- rle(keep)
  ends <- cumsum(runs$lengths)
  starts <- c(1L, utils::head(ends, -1L) + 1L)
  out <- list()
  for (i in seq_along(runs$values)) {
    if (!runs$values[i] || runs$lengths[i] < 2L) next
    idx <- starts[i]:ends[i]
    out[[length(out) + 1L]] <- list(x = x[idx], y = y[idx])
  }
  out
}

offset_id <- function(id, by = 0L) {
  if (!length(id)) {
    return(id)
  }
  as.integer(id + by)
}

combine_polyline_data <- function(parts) {
  parts <- Filter(function(x) !is.null(x) && length(x$x), parts)
  if (!length(parts)) {
    return(list(x = numeric(), y = numeric(), id = integer()))
  }

  out <- list(x = numeric(), y = numeric(), id = integer())
  next_id <- 0L
  for (part in parts) {
    ids <- match(part$id, unique(part$id))
    out$x <- c(out$x, part$x)
    out$y <- c(out$y, part$y)
    out$id <- c(out$id, offset_id(ids, next_id))
    next_id <- max(out$id)
  }
  out
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

rough_fill_pattern_data <- function(paths, hand_spec = NULL, fill_pattern = NULL,
                                    rule = c("winding", "evenodd"),
                                    inches_per_data_unit = NULL) {
  rule <- match.arg(rule)
  fill_pattern <- as_fill_pattern(fill_pattern, hand_spec = hand_spec)
  if (is.null(fill_pattern)) {
    return(list(x = numeric(), y = numeric(), id = integer()))
  }

  fill_hand <- if (is.null(hand_spec)) NULL else clipped_hatch_hand(hand_spec, clip = fill_pattern$clip)

  build_lines <- function(base_angle) {
    gap <- fill_pattern_gap(
      fill_pattern,
      paths,
      hand_spec,
      angle = base_angle,
      inches_per_data_unit = inches_per_data_unit
    )
    padding_normal <- fill_pattern_padding(fill_pattern, angle = base_angle, inches_per_data_unit = inches_per_data_unit)
    padding_along <- fill_pattern_padding(fill_pattern, angle = base_angle + 90, inches_per_data_unit = inches_per_data_unit)
    rows <- scanline_intervals(
      paths,
      angle = base_angle,
      gap = gap,
      rule = rule,
      jitter_gap = 0,
      padding = padding_normal
    )
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    rows$x0 <- rows$x0 + padding_along
    rows$x1 <- rows$x1 - padding_along
    rows <- rows[rows$x1 > rows$x0, , drop = FALSE]
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    starts <- rotate_xy(rows$x0, rows$y, base_angle)
    ends <- rotate_xy(rows$x1, rows$y, base_angle)
    segment_data(starts$x, starts$y, ends$x, ends$y, hand_spec = fill_hand)
  }

  build_zigzag <- function(base_angle) {
    gap <- fill_pattern_gap(
      fill_pattern,
      paths,
      hand_spec,
      angle = base_angle,
      inches_per_data_unit = inches_per_data_unit
    )
    padding_normal <- fill_pattern_padding(fill_pattern, angle = base_angle, inches_per_data_unit = inches_per_data_unit)
    padding_along <- fill_pattern_padding(fill_pattern, angle = base_angle + 90, inches_per_data_unit = inches_per_data_unit)
    rows <- scanline_intervals(
      paths,
      angle = base_angle,
      gap = gap,
      rule = rule,
      jitter_gap = 0,
      padding = padding_normal
    )
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    rows$x0 <- rows$x0 + padding_along
    rows$x1 <- rows$x1 - padding_along
    rows <- rows[rows$x1 > rows$x0, , drop = FALSE]
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    split_rows <- split(rows, rows$interval)
    polylines <- list()
    for (grp in split_rows) {
      grp <- grp[order(grp$row), , drop = FALSE]
      if (!nrow(grp)) next
      px <- numeric()
      py <- numeric()
      for (i in seq_len(nrow(grp))) {
        px <- c(px, grp$x0[i], grp$x1[i])
        py <- c(py, grp$y[i], grp$y[i])
      }
      xy <- rotate_xy(px, py, base_angle)
      polylines[[length(polylines) + 1L]] <- list(x = xy$x, y = xy$y)
    }
    polyline_data(polylines, hand_spec = fill_hand)
  }

  build_jumble <- function() {
    base_angle <- fill_pattern$angle %||% 45
    gap <- fill_pattern_gap(
      fill_pattern,
      paths,
      hand_spec,
      angle = base_angle,
      inches_per_data_unit = inches_per_data_unit
    )
    padding_normal <- fill_pattern_padding(fill_pattern, angle = base_angle, inches_per_data_unit = inches_per_data_unit)
    padding_along <- fill_pattern_padding(fill_pattern, angle = base_angle + 90, inches_per_data_unit = inches_per_data_unit)
    rows <- scanline_intervals(
      paths,
      angle = base_angle,
      gap = gap,
      rule = rule,
      jitter_gap = 0,
      padding = padding_normal
    )
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    rows$x0 <- rows$x0 + padding_along
    rows$x1 <- rows$x1 - padding_along
    rows <- rows[rows$x1 > rows$x0, , drop = FALSE]
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }

    radius <- fill_pattern$radius
    in_per_gap_unit <- resolve_inches_per_data_unit(inches_per_data_unit, base_angle)
    if (is.null(in_per_gap_unit)) {
      in_per_gap_unit <- gap_inches_per_data_unit(base_angle)
    }
    if (is.finite(in_per_gap_unit) && in_per_gap_unit > 0) {
      radius <- radius / in_per_gap_unit
    }
    radius <- max(radius, .Machine$double.eps)
    wobble <- fill_pattern$wobble %||% 0.08
    parts <- list()

    for (i in seq_len(nrow(rows))) {
      row <- rows[i, , drop = FALSE]
      row_radius <- radius * max(0.45, 1 + stats::rnorm(1L, sd = 0.45 * wobble))
      row_advance <- max(
        1.3 * row_radius,
        2 * row_radius * max(0.55, 1 + stats::rnorm(1L, sd = 0.55 * wobble))
      )

      length_row <- row$x1 - row$x0
      usable <- length_row - 2 * row_radius
      if (usable <= row_radius) next

      n_loops <- max(1L, floor(usable / row_advance))
      phase0 <- stats::runif(1L, 0, 2 * pi)
      overscan_loops <- 0.75
      theta_start <- phase0 - 2 * pi * overscan_loops
      theta_end <- phase0 + 2 * pi * (n_loops + overscan_loops)
      n_points <- max(40L, ceiling(24L * (n_loops + 2 * overscan_loops)))
      theta <- seq(theta_start, theta_end, length.out = n_points)
      phase1 <- stats::runif(1L, 0, 2 * pi)
      phase2 <- stats::runif(1L, 0, 2 * pi)
      phase3 <- stats::runif(1L, 0, 2 * pi)
      phase4 <- stats::runif(1L, 0, 2 * pi)
      phase5 <- stats::runif(1L, 0, 2 * pi)

      radius_x <- row_radius * (
        1 +
          wobble * 0.45 * sin(0.55 * theta + phase1) +
          wobble * 0.18 * sin(1.8 * theta + phase2)
      )
      radius_y <- row_radius * (
        1 +
          wobble * 0.35 * sin(0.45 * theta + phase3) +
          wobble * 0.15 * sin(1.35 * theta + phase4)
      )
      center_drift <- wobble * row_advance * (
        0.14 * sin(0.35 * theta + phase2) +
          0.06 * sin(0.9 * theta + phase5)
      )
      local_x <- row$x0 + row_radius - row_advance * phase0 / (2 * pi) +
        row_advance * theta / (2 * pi) +
        center_drift +
        radius_x * cos(theta)
      local_y <- row$y +
        radius_y * sin(theta) +
        wobble * row_radius * 0.18 * sin(3 * theta + phase5)

      xy <- rotate_xy(local_x, local_y, base_angle)
      if (isTRUE(fill_pattern$clip)) {
        clipped <- clip_polyline_to_paths(paths, xy$x, xy$y, rule = rule)
        if (length(clipped)) {
          parts[[length(parts) + 1L]] <- polyline_data(clipped, hand_spec = fill_hand)
        }
      } else {
        parts[[length(parts) + 1L]] <- polyline_data(list(list(x = xy$x, y = xy$y)), hand_spec = fill_hand)
      }
    }

    combine_polyline_data(parts)
  }

  if (identical(fill_pattern$style, "jumble")) {
    return(build_jumble())
  }

  parts <- lapply(
    line_fill_angles(fill_pattern),
    function(base_angle) {
      if (identical(fill_pattern$style, "zigzag")) build_zigzag(base_angle) else build_lines(base_angle)
    }
  )
  combine_polyline_data(parts)
}

draw_rough_fill_pattern <- function(paths, hand_spec, col, fill_pattern = NULL,
                                    rule = c("winding", "evenodd"), xpd = NULL, ...) {
  geom <- rough_fill_pattern_data(paths, hand_spec = hand_spec, fill_pattern = fill_pattern, rule = rule)
  if (!length(geom$x)) {
    return(invisible(NULL))
  }
  for (i in unique(geom$id)) {
    keep <- geom$id == i
    graphics::lines(geom$x[keep], geom$y[keep], col = col, xpd = xpd, ...)
  }
  invisible(NULL)
}

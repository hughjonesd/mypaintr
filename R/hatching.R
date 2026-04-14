new_fill_pattern <- function(style,
                             density = NULL,
                             angle = NULL,
                             clip = TRUE,
                             strokes = NULL,
                             step = NULL,
                             curl = NULL) {
  structure(
    list(
      style = style,
      density = density,
      angle = angle,
      clip = isTRUE(clip),
      strokes = strokes,
      step = step,
      curl = curl
    ),
    class = "mypaintr_fill_pattern"
  )
}

#' Hatch fill pattern
#'
#' @param angle Base hatch angle in degrees.
#' @param density Approximate line density. Larger values give denser fills.
#' @param clip When `TRUE`, hatch endpoints stay on the shape boundary to reduce
#'   overshoot.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @export
hatch <- function(angle = 45, density = 8, clip = TRUE) {
  new_fill_pattern("lines", density = density, angle = angle, clip = clip)
}

#' Cross-hatch fill pattern
#'
#' @param angle One or two hatch angles in degrees. If a single angle is
#'   supplied, the second pass defaults to `angle + 90`.
#' @param density Approximate line density. Larger values give denser fills.
#' @param clip When `TRUE`, hatch endpoints stay on the shape boundary to reduce
#'   overshoot.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @export
crosshatch <- function(angle = 45, density = 7, clip = TRUE) {
  if (!length(angle) %in% c(1L, 2L)) {
    stop("angle must have length 1 or 2", call. = FALSE)
  }
  new_fill_pattern("cross", density = density, angle = angle, clip = clip)
}

#' Zigzag fill pattern
#'
#' @param angle Base zigzag angle in degrees.
#' @param density Approximate line density. Larger values give denser fills.
#' @param clip When `TRUE`, zigzag endpoints stay on the shape boundary to
#'   reduce overshoot.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @export
zigzag <- function(angle = 45, density = 6, clip = TRUE) {
  new_fill_pattern("zigzag", density = density, angle = angle, clip = clip)
}

#' Jumble fill pattern
#'
#' @param density Approximate scribble density. Larger values give more strokes.
#' @param strokes Approximate number of jumble strokes. When `NULL`, a
#'   default based on the shape size is used.
#' @param step Jumble step size in data units.
#' @param curl How tightly the jumble curls as it wanders. Larger values produce
#'   rounder, loopier scribbles.
#' @return A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.
#' @export
jumble <- function(density = 5, strokes = NULL, step = NULL, curl = 0.35) {
  new_fill_pattern("jumble", density = density, strokes = strokes, step = step, curl = curl, clip = TRUE)
}

as_fill_pattern <- function(fill_pattern = NULL, hand_spec = NULL, default_when_missing = FALSE) {
  if (is.null(fill_pattern)) {
    if (default_when_missing) {
      if (!is.null(hand_spec) && identical(hand_spec$hachure_method, "cross")) {
        return(crosshatch(angle = hand_spec$hachure_angle))
      }
      return(hatch(angle = if (is.null(hand_spec)) 45 else hand_spec$hachure_angle))
    }
    return(NULL)
  }

  if (!inherits(fill_pattern, "mypaintr_fill_pattern")) {
    stop("fill_pattern must be created with hatch(), crosshatch(), zigzag(), or jumble()", call. = FALSE)
  }

  fill_pattern
}

fill_pattern_gap <- function(fill_pattern, paths, hand_spec = NULL) {
  box <- path_bbox(paths)
  span <- max(box$xmax - box$xmin, box$ymax - box$ymin)
  gap <- NULL
  if (!is.null(hand_spec) && !is.null(hand_spec$hachure_gap) && is.null(fill_pattern$density)) {
    gap <- hand_spec$hachure_gap
  }
  if (is.null(gap)) {
    gap <- if (is.null(fill_pattern$density)) span / 25 else span / max(1, fill_pattern$density)
  }
  max(gap, .Machine$double.eps)
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
                               jitter_gap = 0) {
  rule <- match.arg(rule)
  rot_paths <- lapply(paths, function(path) rotate_xy(path$x, path$y, -angle))
  yr <- unlist(lapply(rot_paths, `[[`, "y"), use.names = FALSE)
  if (!length(yr)) {
    return(data.frame(row = integer(), interval = integer(), y = numeric(), x0 = numeric(), x1 = numeric()))
  }

  span <- diff(range(yr))
  gap <- gap %||% (if (span <= 0) 1 else span / 25)
  gap <- max(gap, .Machine$double.eps)

  yy <- min(yr)
  row <- 1L
  out <- data.frame(row = integer(), interval = integer(), y = numeric(), x0 = numeric(), x1 = numeric())
  while (yy <= max(yr)) {
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
                                    rule = c("winding", "evenodd")) {
  rule <- match.arg(rule)
  fill_pattern <- as_fill_pattern(fill_pattern, hand_spec = hand_spec, default_when_missing = FALSE)
  if (is.null(fill_pattern)) {
    return(list(x = numeric(), y = numeric(), id = integer()))
  }

  fill_hand <- if (is.null(hand_spec)) NULL else clipped_hatch_hand(hand_spec, clip = fill_pattern$clip)
  gap <- fill_pattern_gap(fill_pattern, paths, hand_spec)
  jitter_gap <- if (is.null(hand_spec)) 0 else hand_spec$hachure_gap_jitter
  jitter_angle <- if (is.null(hand_spec)) 0 else hand_spec$hachure_angle_jitter

  build_lines <- function(base_angle) {
    rows <- scanline_intervals(
      paths,
      angle = base_angle,
      gap = gap,
      rule = rule,
      jitter_gap = if (jitter_gap == 0) 0 else stats::rnorm(1, sd = jitter_gap)
    )
    if (!nrow(rows)) {
      return(list(x = numeric(), y = numeric(), id = integer()))
    }
    starts <- rotate_xy(rows$x0, rows$y, base_angle)
    ends <- rotate_xy(rows$x1, rows$y, base_angle)
    segment_data(starts$x, starts$y, ends$x, ends$y, hand_spec = fill_hand)
  }

  build_zigzag <- function(base_angle) {
    rows <- scanline_intervals(
      paths,
      angle = base_angle,
      gap = gap,
      rule = rule,
      jitter_gap = if (jitter_gap == 0) 0 else stats::rnorm(1, sd = jitter_gap)
    )
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
    box <- path_bbox(paths)
    span <- max(box$xmax - box$xmin, box$ymax - box$ymin)
    step <- fill_pattern$step %||% max(gap / 2, span / 35)
    n_strokes <- fill_pattern$strokes %||% max(1L, round(span / step))
    n_steps <- max(12L, round(2 * span / step))
    curl <- fill_pattern$curl %||% 0.35
    turn_sd <- max(0.03, 0.22 - 0.35 * pmin(curl, 0.45))
    polylines <- vector("list", n_strokes)

    smooth_path <- function(x, y, passes = 2L) {
      if (length(x) < 3L) {
        return(list(x = x, y = y))
      }
      for (pass in seq_len(passes)) {
        x[2:(length(x) - 1L)] <- (x[1:(length(x) - 2L)] + 2 * x[2:(length(x) - 1L)] + x[3:length(x)]) / 4
        y[2:(length(y) - 1L)] <- (y[1:(length(y) - 2L)] + 2 * y[2:(length(y) - 1L)] + y[3:length(y)]) / 4
      }
      list(x = x, y = y)
    }

    for (s in seq_len(n_strokes)) {
      p <- sample_point_in_paths(paths, rule = rule)
      theta <- stats::runif(1L, 0, 2 * pi)
      omega <- sample(c(-1, 1), 1L) * stats::runif(1L, curl / 2, curl * 1.5)
      px <- numeric(n_steps)
      py <- numeric(n_steps)
      px[1] <- p[1]
      py[1] <- p[2]
      for (i in 2:n_steps) {
        accepted <- FALSE
        for (attempt in seq_len(12L)) {
          omega_try <- 0.85 * omega + stats::rnorm(1L, mean = 0, sd = turn_sd)
          theta_try <- theta + omega_try + if (attempt > 1L) stats::rnorm(1L, mean = 0, sd = pi / 5) else 0
          cand_x <- px[i - 1L] + step * cos(theta_try)
          cand_y <- py[i - 1L] + step * sin(theta_try)
          if (point_in_paths(paths, cand_x, cand_y, rule)) {
            theta <- theta_try
            omega <- omega_try
            px[i] <- cand_x
            py[i] <- cand_y
            accepted <- TRUE
            break
          }
        }
        if (!accepted) {
          p <- sample_point_in_paths(paths, rule = rule)
          px[i] <- p[1]
          py[i] <- p[2]
          theta <- stats::runif(1L, 0, 2 * pi)
          omega <- -0.7 * omega
        }
      }
      polylines[[s]] <- smooth_path(px, py)
    }

    polyline_data(polylines, hand_spec = fill_hand)
  }

  if (identical(fill_pattern$style, "jumble")) {
    return(build_jumble())
  }

  parts <- lapply(
    line_fill_angles(fill_pattern),
    function(base_angle) {
      if (jitter_angle != 0) {
        base_angle <- base_angle + stats::rnorm(1, sd = jitter_angle)
      }
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

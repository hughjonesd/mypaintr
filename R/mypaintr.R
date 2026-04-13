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

`%||%` <- function(x, y) if (is.null(x)) y else x

mypaintr_env <- new.env(parent = emptyenv())
mypaintr_env$style_stack <- list()

with_hand_seed <- function(seed, expr) {
  if (is.null(seed)) {
    return(force(expr))
  }

  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    has_seed <- TRUE
  } else {
    has_seed <- FALSE
  }

  on.exit({
    if (has_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  set.seed(seed)
  force(expr)
}

as_hand <- function(x = NULL) {
  if (is.null(x)) {
    return(hand())
  }
  if (!inherits(x, "mypaintr_hand")) {
    stop("hand must be created with hand()", call. = FALSE)
  }
  x
}

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

draw_rough_hachure_fill <- function(paths, hand_spec, col, angle = 45, density = NULL, rule = c("winding", "evenodd"), xpd = NULL, ...) {
  rule <- match.arg(rule)
  rot_paths <- lapply(paths, function(path) rotate_xy(path$x, path$y, -angle))
  yr <- unlist(lapply(rot_paths, `[[`, "y"), use.names = FALSE)
  span <- diff(range(yr))
  gap <- hand_spec$hachure_gap %||% if (is.null(density)) span / 25 else span / max(1, density)
  gap <- max(gap, .Machine$double.eps)

  draw_pass <- function(base_angle) {
    hand_fill <- hand_spec
    hand_fill$seed <- NULL
    rot_pass <- lapply(paths, function(path) rotate_xy(path$x, path$y, -base_angle))
    yr_pass <- unlist(lapply(rot_pass, `[[`, "y"), use.names = FALSE)
    yy <- min(yr_pass)
    while (yy <= max(yr_pass)) {
      cuts <- rough_path_intersections(rot_pass, yy)
      if (length(cuts$x) >= 2L) {
        if (identical(rule, "evenodd")) {
          for (i in seq(1L, length(cuts$x) - 1L, by = 2L)) {
            seg <- rotate_xy(c(cuts$x[i], cuts$x[i + 1L]), c(yy, yy), base_angle)
            draw_rough_segments(
              seg$x[1], seg$y[1], seg$x[2], seg$y[2],
              hand = hand_fill,
              col = col,
              xpd = xpd,
              ...
            )
          }
        } else {
          winding <- 0L
          for (i in seq_len(length(cuts$x) - 1L)) {
            winding <- winding + cuts$delta[i]
            if (winding != 0L && cuts$x[i + 1L] > cuts$x[i]) {
              seg <- rotate_xy(c(cuts$x[i], cuts$x[i + 1L]), c(yy, yy), base_angle)
              draw_rough_segments(
                seg$x[1], seg$y[1], seg$x[2], seg$y[2],
                hand = hand_fill,
                col = col,
                xpd = xpd,
                ...
              )
            }
          }
        }
      }
      yy <- yy + gap * (1 + stats::rnorm(1, sd = hand_spec$hachure_gap_jitter))
    }
  }

  draw_pass(angle + stats::rnorm(1, sd = hand_spec$hachure_angle_jitter))
  if (identical(hand_spec$hachure_method, "cross")) {
    draw_pass(angle + 90 + stats::rnorm(1, sd = hand_spec$hachure_angle_jitter))
  }
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

normalize_hand_spec <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  as_hand(x)
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

require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 must be installed to use mypaint theme elements", call. = FALSE)
  }
}

require_knitr <- function() {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    stop("knitr must be installed to use knitr_chunk_hook()", call. = FALSE)
  }
}

#' Create a knitr chunk hook for live mypaint rendering
#'
#' The returned hook opens [mypaint_device()] before chunk evaluation and
#' injects the generated PNG files afterward. This avoids knitr's normal plot
#' replay path, which does not preserve device-local style changes such as
#' [set_hand()] and [set_brush()].
#'
#' Register it with `knitr::knit_hooks$set(mypaint = knitr_chunk_hook(...))`
#' and then enable it for chunks with `mypaint = TRUE`. Chunks should also set
#' `fig.keep = "none"` and `fig.ext = "png"`.
#'
#' @param ... Default arguments passed through to [mypaint_device()] when the
#'   hook opens a device. Chunk-specific overrides can be supplied in the chunk
#'   option `mypaint.args` as a named list.
#' @return A function suitable for `knitr::knit_hooks$set()`.
#' @examples
#' if (requireNamespace("knitr", quietly = TRUE)) {
#'   hook <- knitr_chunk_hook(brush = "deevad/2B_pencil")
#'   print(is.function(hook))
#' }
#' @export
knitr_chunk_hook <- function(...) {
  require_knitr()
  device_defaults <- list(...)

  function(before, options, envir) {
    if (!isTRUE(options$mypaint)) {
      return()
    }

    stem <- knitr::fig_path("", options = options, number = NULL)
    pattern <- paste0(stem, "-%d.png")
    files_glob <- paste0(stem, "-*.png")

    if (before) {
      dir.create(dirname(stem), recursive = TRUE, showWarnings = FALSE)
      unlink(Sys.glob(files_glob))

      dev_args <- c(
        list(
          file = pattern,
          width = options$fig.width[1],
          height = options$fig.height[1]
        ),
        device_defaults
      )
      if (is.list(options$mypaint.args)) {
        dev_args[names(options$mypaint.args)] <- options$mypaint.args
      }
      do.call(mypaint_device, dev_args)
      return()
    }

    if (identical(names(grDevices::dev.cur()), "mypaintr")) {
      grDevices::dev.off()
    }

    files <- sort(Sys.glob(files_glob))
    if (!length(files)) {
      return("")
    }

    options$fig.num <- length(files)
    pieces <- character(length(files))
    for (i in seq_along(files)) {
      options$fig.cur <- i
      pieces[[i]] <- knitr::hook_plot_md(files[[i]], options)
    }
    paste0(pieces, collapse = "")
  }
}

new_mypaintr_element <- function(element, class_name, style) {
  attr(element, "mypaintr_style") <- style
  class(element) <- c(class_name, class(element))
  element
}

base_element <- function(element, class_name) {
  out <- element
  attr(out, "mypaintr_style") <- NULL
  class(out) <- setdiff(class(out), class_name)
  out
}

wrap_mypaintr_style_grob <- function(child, style) {
  grid::gTree(
    children = grid::gList(child),
    mypaintr_style = style,
    cl = "mypaintr_style_grob"
  )
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
  rule <- match.arg(rule)
  rot_paths <- lapply(paths, function(path) rotate_xy(path$x, path$y, -angle))
  yr <- unlist(lapply(rot_paths, `[[`, "y"), use.names = FALSE)
  span <- diff(range(yr))
  gap <- if (!is.null(hand_spec) && !is.null(hand_spec$hachure_gap)) {
    hand_spec$hachure_gap
  } else if (is.null(density)) {
    span / 25
  } else {
    span / max(1, density)
  }
  gap <- max(gap, .Machine$double.eps)

  add_segments <- function(base_angle, jitter_angle = 0, jitter_gap = 0) {
    rot_pass <- lapply(paths, function(path) rotate_xy(path$x, path$y, -base_angle))
    yr_pass <- unlist(lapply(rot_pass, `[[`, "y"), use.names = FALSE)
    yy <- min(yr_pass)
    seg_x0 <- numeric()
    seg_y0 <- numeric()
    seg_x1 <- numeric()
    seg_y1 <- numeric()

    while (yy <= max(yr_pass)) {
      cuts <- rough_path_intersections(rot_pass, yy)
      if (length(cuts$x) >= 2L) {
        if (identical(rule, "evenodd")) {
          for (i in seq(1L, length(cuts$x) - 1L, by = 2L)) {
            seg <- rotate_xy(c(cuts$x[i], cuts$x[i + 1L]), c(yy, yy), base_angle)
            seg_x0 <- c(seg_x0, seg$x[1])
            seg_y0 <- c(seg_y0, seg$y[1])
            seg_x1 <- c(seg_x1, seg$x[2])
            seg_y1 <- c(seg_y1, seg$y[2])
          }
        } else {
          winding <- 0L
          for (i in seq_len(length(cuts$x) - 1L)) {
            winding <- winding + cuts$delta[i]
            if (winding != 0L && cuts$x[i + 1L] > cuts$x[i]) {
              seg <- rotate_xy(c(cuts$x[i], cuts$x[i + 1L]), c(yy, yy), base_angle)
              seg_x0 <- c(seg_x0, seg$x[1])
              seg_y0 <- c(seg_y0, seg$y[1])
              seg_x1 <- c(seg_x1, seg$x[2])
              seg_y1 <- c(seg_y1, seg$y[2])
            }
          }
        }
      }
      yy <- yy + gap * (1 + jitter_gap)
    }

    segment_data(seg_x0, seg_y0, seg_x1, seg_y1, hand_spec = hand_spec)
  }

  build <- function(base_angle) {
    jitter_angle <- if (is.null(hand_spec)) 0 else stats::rnorm(1, sd = hand_spec$hachure_angle_jitter)
    jitter_gap <- if (is.null(hand_spec)) 0 else stats::rnorm(1, sd = hand_spec$hachure_gap_jitter)
    add_segments(base_angle + jitter_angle, jitter_angle, jitter_gap)
  }

  out <- build(angle)
  if (cross || (!is.null(hand_spec) && identical(hand_spec$hachure_method, "cross"))) {
    other <- build(angle + 90)
    if (length(out$x)) {
      other$id <- other$id + max(out$id)
      out$x <- c(out$x, other$x)
      out$y <- c(out$y, other$y)
      out$id <- c(out$id, other$id)
    } else {
      out <- other
    }
  }
  out
}

make_stroke_style <- function(brush = NULL, settings = NULL) {
  spec <- if (is.null(brush) && is.null(settings)) NULL else normalize_brush_spec(brush, settings)
  make_style_override(
    update_stroke = TRUE,
    stroke_spec = spec,
    stroke_style = if (is.null(spec)) 0L else 1L,
    stroke_hand = NULL,
    update_stroke_hand = FALSE
  )
}

line_gp <- function(colour, linewidth, linetype = 1, linejoin = "mitre", lineend = "butt") {
  pt <- getFromNamespace(".pt", "ggplot2")
  grid::gpar(
    col = colour,
    fill = NA,
    lwd = linewidth * pt,
    lty = linetype,
    linejoin = linejoin,
    lineend = lineend
  )
}

build_mypaint_rect_grob <- function(data, params, default.units = "native") {
  child_list <- list()
  border_brush <- params$brush
  border_settings <- params$brush_settings
  fill_brush <- if (is.null(params$fill_brush) && is.null(params$fill_settings)) params$brush else params$fill_brush
  fill_settings <- params$fill_settings
  outline_hand <- params$stroke_hand
  hatch_hand <- params$fill_hand %||% outline_hand

  for (i in seq_len(nrow(data))) {
    row <- data[i, , drop = FALSE]
    fill_col <- alpha_colour(row$fill, row$alpha)
    border_col <- alpha_colour(row$colour, row$alpha)
    linewidth <- row$linewidth %||% 0.5
    linetype <- row$linetype %||% 1

    path <- outline_path(
      closed_rect_path(row$xmin, row$xmax, row$ymin, row$ymax)$x,
      closed_rect_path(row$xmin, row$xmax, row$ymin, row$ymax)$y,
      hand_spec = outline_hand,
      closed = FALSE
    )

    if (is_visible_col(fill_col)) {
      hatch <- if (is.null(hatch_hand)) {
        rough_hachure_data(list(path), hand_spec = NULL, angle = params$angle, density = params$density)
      } else {
        with_hand_seed(hatch_hand$seed, {
          rough_hachure_data(list(path), hand_spec = hatch_hand, angle = params$angle, density = params$density)
        })
      }
      if (length(hatch$x)) {
        hatch_grob <- grid::polylineGrob(
          x = hatch$x,
          y = hatch$y,
          id = hatch$id,
          default.units = default.units,
          gp = line_gp(fill_col, linewidth, linetype, params$linejoin, params$lineend)
        )
        child_list[[length(child_list) + 1L]] <- wrap_mypaintr_style_grob(
          hatch_grob,
          make_stroke_style(fill_brush, fill_settings)
        )
      }
    }

    if (is_visible_col(border_col)) {
      border_grob <- grid::polylineGrob(
        x = path$x,
        y = path$y,
        default.units = default.units,
        gp = line_gp(border_col, linewidth, linetype, params$linejoin, params$lineend)
      )
      child_list[[length(child_list) + 1L]] <- wrap_mypaintr_style_grob(
        border_grob,
        make_stroke_style(border_brush, border_settings)
      )
    }
  }

  if (!length(child_list)) {
    return(grid::nullGrob())
  }
  grid::gTree(children = do.call(grid::gList, child_list))
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
mypaint_device <- function(file,
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
  stopifnot(
    is.character(file), length(file) == 1L,
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

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) NULL else normalize_brush_spec(brush, brush_settings)
  fill_spec <- if (is.null(fill_brush) && is.null(fill_settings)) NULL else normalize_brush_spec(fill_brush, fill_settings)
  stroke_style <- if (is.null(stroke_style)) {
    if (is.null(brush)) 0L else 1L
  } else {
    normalize_render_style(stroke_style)
  }
  fill_style <- if (is.null(fill_style)) {
    if (is.null(fill_brush)) 0L else 1L
  } else {
    normalize_render_style(fill_style)
  }

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
    stroke_style,
    fill_style,
    isTRUE(auto_solid_bg),
    normalize_hand_spec(stroke_hand),
    normalize_hand_spec(fill_hand)
  ))
}

#' Set the active mypaintr brush
#'
#' @param brush Brush preset, installed brush name, JSON brush string, named
#'   settings, or `NULL` to switch the selected type back to solid rendering.
#' @param settings Named settings overriding `brush`.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @param auto_solid_bg Optional override for background-like fills.
#' @return `NULL`, invisibly.
#' @export
set_brush <- function(brush = NULL, settings = NULL, type = c("both", "stroke", "fill"), auto_solid_bg = NULL) {
  type <- match.arg(type)
  if (is.null(brush) && !is.null(settings)) {
    stop("settings requires brush", call. = FALSE)
  }

  spec <- if (is.null(brush) && is.null(settings)) NULL else normalize_brush_spec(brush, settings)
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

  invisible(.Call(
    mypaintr_device_set_brush,
    stroke_spec,
    fill_spec,
    if (is.null(stroke_style)) NULL else as.integer(stroke_style),
    if (is.null(fill_style)) NULL else as.integer(fill_style),
    if (is.null(auto_solid_bg)) NULL else isTRUE(auto_solid_bg)
  ))
}

#' Set the active mypaintr hand-drawn geometry
#'
#' @param hand Hand-drawn geometry created with [hand()], or `NULL` to disable
#'   it for the selected type.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @return `NULL`, invisibly.
#' @export
set_hand <- function(hand = NULL, type = c("both", "stroke", "fill")) {
  type <- match.arg(type)
  invisible(.Call(
    mypaintr_device_set_hand,
    if (type %in% c("both", "stroke")) normalize_hand_spec(hand) else NULL,
    if (type %in% c("both", "fill")) normalize_hand_spec(hand) else NULL,
    type %in% c("both", "stroke"),
    type %in% c("both", "fill")
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

#' Hand-drawn geometry settings
#'
#' @param seed Optional random seed used for repeatable geometry.
#' @param bow Typical bowing of long strokes as a proportion of segment length.
#' @param wobble Low-frequency path wobble as a proportion of segment length.
#' @param multi_stroke Number of overdrawn strokes to use.
#' @param width_jitter Relative variation in line width between overdrawn
#'   strokes.
#' @param endpoint_jitter Relative endpoint jitter as a proportion of segment
#'   length.
#' @param hachure_gap Optional gap between hatch lines. When `NULL`, a default
#'   based on polygon size is used.
#' @param hachure_angle Base hatch angle in degrees.
#' @param hachure_angle_jitter Random angle variation for hatch passes.
#' @param hachure_gap_jitter Relative jitter in hatch spacing.
#' @param hachure_method Either `"parallel"` or `"cross"`.
#' @return An object describing how rough geometry should be generated.
#' @examples
#' hand()
#' hand(seed = 1, bow = 0.02, wobble = 0.01)
#' @export
hand <- function(seed = NULL,
                 bow = 0.015,
                 wobble = 0.006,
                 multi_stroke = 1L,
                 width_jitter = 0.08,
                 endpoint_jitter = 0.01,
                 hachure_gap = NULL,
                 hachure_angle = 45,
                 hachure_angle_jitter = 12,
                 hachure_gap_jitter = 0.15,
                 hachure_method = c("parallel", "cross")) {
  hachure_method <- match.arg(hachure_method)

  structure(
    list(
      seed = seed,
      bow = bow,
      wobble = wobble,
      multi_stroke = as.integer(multi_stroke),
      width_jitter = width_jitter,
      endpoint_jitter = endpoint_jitter,
      hachure_gap = hachure_gap,
      hachure_angle = hachure_angle,
      hachure_angle_jitter = hachure_angle_jitter,
      hachure_gap_jitter = hachure_gap_jitter,
      hachure_method = hachure_method
    ),
    class = "mypaintr_hand"
  )
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

#' Draw rough connected lines
#'
#' @param x,y Coordinates as for [graphics::lines()].
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, cumsum(rnorm(10)), type = "n")
#' draw_rough_lines(1:10, cumsum(rnorm(10)))
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
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_segments(1:3, 1:3, 2:4, 3:1)
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
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_arrows(2, 2, 8, 8)
#' draw_rough_arrows(8, 2, 2, 8, code = 3, hand = hand(multi_stroke = 2))
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

#' Draw a rough multipath with optional holes
#'
#' @param x,y Coordinates as for [graphics::polypath()].
#' @param id Optional path ids. Consecutive points with the same `id` belong to
#'   one closed ring.
#' @param rule Fill rule, `"winding"` or `"evenodd"`.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param col Fill colour. When visible, a hachure fill is drawn.
#' @param border Border colour.
#' @param density Hatch density. When `NULL`, a default density is used.
#' @param angle Hatch angle in degrees.
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_polypath(c(2, 8, 8, 2, 4, 6, 6, 4),
#'                     c(2, 2, 8, 8, 4, 4, 6, 6),
#'                     id = c(rep(1, 4), rep(2, 4)),
#'                     rule = "evenodd",
#'                     col = "grey80")
#' @export
draw_rough_polypath <- function(x, y = NULL, id = NULL, rule = c("winding", "evenodd"),
                                hand = NULL, col = NA, border = graphics::par("fg"),
                                density = NULL, angle = 45, ...) {
  hand_spec <- as_hand(hand)
  rule <- match.arg(rule)
  paths0 <- split_polypath(x, y, id)

  invisible(with_hand_seed(hand_spec$seed, {
    geom <- rough_polypath_data(paths0, hand_spec, rule)
    paths <- split_polypath(geom$x, geom$y, geom$id)

    if (is_visible_col(col)) {
      draw_rough_hachure_fill(
        paths,
        hand_spec,
        col = col,
        angle = angle,
        density = density,
        rule = geom$rule,
        ...
      )
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
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param col Fill colour. When visible, a hachure fill is drawn.
#' @param border Border colour.
#' @param density Hatch density. When `NULL`, a default density is used.
#' @param angle Hatch angle in degrees.
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_polygons(c(2, 5, 8, 3), c(2, 7, 5, 1), col = "grey80")
#' @export
draw_rough_polygons <- function(x, y = NULL, hand = NULL, col = NA, border = graphics::par("fg"),
                                density = NULL, angle = 45, ...) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)

  invisible(with_hand_seed(hand_spec$seed, {
    rough_outline <- roughen_vertex_path(xy$x, xy$y, hand_spec, closed = TRUE)
    if (is_visible_col(col)) {
      draw_rough_hachure_fill(
        list(rough_outline),
        hand_spec,
        col = col,
        angle = angle,
        density = density,
        ...
      )
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
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param col Fill colour. When visible, a hachure fill is drawn.
#' @param border Border colour.
#' @param density Hatch density. When `NULL`, a default density is used.
#' @param angle Hatch angle in degrees.
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_rect(2, 2, 5, 6, col = "grey80")
#' @export
draw_rough_rect <- function(x0, y0, x1, y1, hand = NULL, col = NA, border = graphics::par("fg"),
                            density = NULL, angle = 45, ...) {
  x <- c(x0, x1, x1, x0)
  y <- c(y0, y0, y1, y1)
  draw_rough_polygons(x, y, hand = hand, col = col, border = border, density = density, angle = angle, ...)
}


#' Draw rough points
#'
#' @param x,y Point coordinates as for [graphics::points()].
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param ... Graphics parameters passed to [graphics::points()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_points(1:10, 1:10, pch = 16)
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

#' Theme line element with scoped mypaint rendering
#'
#' Uses the current `mypaint` device for drawing, but temporarily overrides the
#' stroke settings while the theme line is drawn. This is useful for keeping
#' axes, ticks, or panel grid lines solid while data layers use rough or brush
#' rendering.
#'
#' @param brush Stroke brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid strokes.
#' @param brush_settings Named settings overriding `brush`.
#' @param hand Optional hand-drawn geometry created with [hand()].
#' @param colour,linewidth,linetype,lineend,linejoin,arrow,arrow.fill,inherit.blank,size
#'   Passed through to [ggplot2::element_line()].
#' @return A ggplot theme element.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::theme(axis.line = element_mypaint_line())
#' }
#' @export
element_mypaint_line <- function(brush = NULL,
                                 brush_settings = NULL,
                                 hand = NULL,
                                 colour = NULL,
                                 linewidth = NULL,
                                 linetype = NULL,
                                 lineend = NULL,
                                 color = NULL,
                                 linejoin = NULL,
                                 arrow = FALSE,
                                 arrow.fill = NULL,
                                 inherit.blank = FALSE,
                                 size = NULL,
                                 ...) {
  require_ggplot2()
  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) NULL else normalize_brush_spec(brush, brush_settings)
  style <- make_style_override(
    update_stroke = TRUE,
    stroke_spec = stroke_spec,
    stroke_style = if (is.null(stroke_spec)) 0L else 1L,
    stroke_hand = normalize_hand_spec(hand)
  )
  args <- list(
    colour = colour,
    linewidth = linewidth,
    linetype = linetype,
    lineend = lineend,
    color = color,
    linejoin = linejoin,
    arrow = arrow,
    arrow.fill = arrow.fill,
    inherit.blank = inherit.blank,
    ...
  )
  if (!is.null(size)) {
    args$size <- size
  }
  element <- do.call(ggplot2::element_line, args)
  new_mypaintr_element(element, "mypaintr_element_line", style)
}

#' Theme rectangle element with scoped mypaint rendering
#'
#' Uses the current `mypaint` device for drawing, but temporarily overrides the
#' stroke and fill settings while the rectangle is drawn. This is useful for
#' panel backgrounds, panel borders, and legend keys in ggplot2 themes.
#'
#' @param brush Stroke brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid borders.
#' @param brush_settings Named settings overriding `brush`.
#' @param fill_brush Fill brush preset, installed brush name, JSON brush string,
#'   named settings, or `NULL` for solid fills.
#' @param fill_settings Named settings overriding `fill_brush`.
#' @param hand Optional hand-drawn geometry applied to both stroke and fill by
#'   default.
#' @param stroke_hand Optional hand-drawn geometry for the border.
#' @param fill_hand Optional hand-drawn geometry for the fill.
#' @param auto_solid_bg Optional override for background-like fills.
#' @param fill,colour,linewidth,linetype,color,linejoin,inherit.blank,size
#'   Passed through to [ggplot2::element_rect()].
#' @return A ggplot theme element.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::theme(panel.background = element_mypaint_rect())
#' }
#' @export
element_mypaint_rect <- function(brush = NULL,
                                 brush_settings = NULL,
                                 fill_brush = NULL,
                                 fill_settings = NULL,
                                 hand = NULL,
                                 stroke_hand = hand,
                                 fill_hand = hand,
                                 auto_solid_bg = NULL,
                                 fill = NULL,
                                 colour = NULL,
                                 linewidth = NULL,
                                 linetype = NULL,
                                 color = NULL,
                                 linejoin = NULL,
                                 inherit.blank = FALSE,
                                 size = NULL,
                                 ...) {
  require_ggplot2()
  if (missing(fill_brush)) {
    fill_brush <- brush
  }
  if (is.null(brush) && !is.null(brush_settings)) {
    stop("brush_settings requires brush", call. = FALSE)
  }
  if (is.null(fill_brush) && !is.null(fill_settings)) {
    stop("fill_settings requires fill_brush", call. = FALSE)
  }

  stroke_spec <- if (is.null(brush) && is.null(brush_settings)) NULL else normalize_brush_spec(brush, brush_settings)
  fill_spec <- if (is.null(fill_brush) && is.null(fill_settings)) NULL else normalize_brush_spec(fill_brush, fill_settings)
  style <- make_style_override(
    update_stroke = TRUE,
    stroke_spec = stroke_spec,
    stroke_style = if (is.null(stroke_spec)) 0L else 1L,
    stroke_hand = normalize_hand_spec(stroke_hand),
    update_fill = TRUE,
    fill_spec = fill_spec,
    fill_style = if (is.null(fill_spec)) 0L else 1L,
    fill_hand = normalize_hand_spec(fill_hand),
    auto_solid_bg = auto_solid_bg
  )
  args <- list(
    fill = fill,
    colour = colour,
    linewidth = linewidth,
    linetype = linetype,
    color = color,
    linejoin = linejoin,
    inherit.blank = inherit.blank,
    ...
  )
  if (!is.null(size)) {
    args$size <- size
  }
  element <- do.call(ggplot2::element_rect, args)
  new_mypaintr_element(element, "mypaintr_element_rect", style)
}

#' @exportS3Method ggplot2::element_grob
element_grob.mypaintr_element_line <- function(element, ...) {
  child <- ggplot2::element_grob(base_element(element, "mypaintr_element_line"), ...)
  wrap_mypaintr_style_grob(child, attr(element, "mypaintr_style", exact = TRUE))
}

#' @exportS3Method ggplot2::element_grob
element_grob.mypaintr_element_rect <- function(element, ...) {
  child <- ggplot2::element_grob(base_element(element, "mypaintr_element_rect"), ...)
  wrap_mypaintr_style_grob(child, attr(element, "mypaintr_style", exact = TRUE))
}

#' @exportS3Method grid::preDrawDetails
preDrawDetails.mypaintr_style_grob <- function(x) {
  if (!is_mypaintr_device()) {
    return()
  }

  mypaintr_env$style_stack <- c(mypaintr_env$style_stack, list(current_device_style()))
  apply_device_style_override(x$mypaintr_style)
}

#' @exportS3Method grid::postDrawDetails
postDrawDetails.mypaintr_style_grob <- function(x) {
  if (!is_mypaintr_device()) {
    return()
  }

  n <- length(mypaintr_env$style_stack)
  if (!n) {
    return()
  }

  state <- mypaintr_env$style_stack[[n]]
  mypaintr_env$style_stack <- mypaintr_env$style_stack[-n]
  apply_device_style_state(state)
}

draw_key_mypaint_rect <- function(data, params, size) {
  data$xmin <- 0.1
  data$xmax <- 0.9
  data$ymin <- 0.1
  data$ymax <- 0.9
  build_mypaint_rect_grob(data, params, default.units = "npc")
}

GeomMypaintCol <- ggplot2::ggproto(
  "GeomMypaintCol",
  ggplot2::GeomCol,
  extra_params = c(
    "na.rm", "just", "orientation", "lineend", "linejoin",
    "density", "angle", "brush", "brush_settings",
    "fill_brush", "fill_settings", "hand", "stroke_hand",
    "fill_hand", "auto_solid_bg"
  ),
  draw_panel = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "mitre", just = 0.5, na.rm = FALSE,
                        density = NULL, angle = 45,
                        brush = NULL, brush_settings = NULL,
                        fill_brush = NULL, fill_settings = NULL,
                        hand = NULL, stroke_hand = hand, fill_hand = hand,
                        auto_solid_bg = NULL) {
    if (!coord$is_linear()) {
      stop("geom_mypaint_col() currently only supports linear coordinates", call. = FALSE)
    }

    data <- getFromNamespace("fix_linewidth", "ggplot2")(data, "geom_mypaint_col")
    coords <- coord$transform(data, panel_params)
    build_mypaint_rect_grob(
      coords,
      list(
        density = density,
        angle = angle,
        lineend = lineend,
        linejoin = linejoin,
        brush = brush,
        brush_settings = brush_settings,
        fill_brush = fill_brush,
        fill_settings = fill_settings,
        stroke_hand = as_optional_hand(stroke_hand),
        fill_hand = as_optional_hand(fill_hand),
        auto_solid_bg = auto_solid_bg
      )
    )
  },
  draw_key = draw_key_mypaint_rect
)

GeomMypaintBar <- ggplot2::ggproto(
  "GeomMypaintBar",
  ggplot2::GeomBar,
  extra_params = GeomMypaintCol$extra_params,
  draw_panel = GeomMypaintCol$draw_panel,
  draw_key = draw_key_mypaint_rect
)

#' Draw rough, brush-rendered columns in ggplot2
#'
#' This geom owns both the bar outline and the hatch fill, so the shading lines
#' follow the same rough outline rather than the underlying true rectangle.
#'
#' @param mapping,data,position,just,lineend,linejoin,na.rm,show.legend,inherit.aes
#'   As for [ggplot2::geom_col()].
#' @param density Optional hatch density. When `NULL`, a default density is used.
#' @param angle Hatch angle in degrees.
#' @param brush,brush_settings Stroke brush spec and overrides.
#' @param fill_brush,fill_settings Fill-hatch brush spec and overrides.
#' @param hand Optional hand-drawn geometry applied to both outline and hatch by
#'   default.
#' @param stroke_hand Optional hand-drawn geometry for the outline.
#' @param fill_hand Optional hand-drawn geometry for the hatch strokes.
#' @param auto_solid_bg Reserved for future parity with device-level style
#'   controls.
#' @param ... Other arguments passed to [ggplot2::layer()].
#' @return A ggplot layer.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
#'     geom_mypaint_bar(density = 12)
#' }
#' @export
geom_mypaint_col <- function(mapping = NULL, data = NULL, position = "stack",
                             ..., just = 0.5, lineend = "butt", linejoin = "mitre",
                             na.rm = FALSE, show.legend = NA, inherit.aes = TRUE,
                             density = NULL, angle = 45,
                             brush = NULL, brush_settings = NULL,
                             fill_brush = NULL, fill_settings = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = "identity",
    geom = GeomMypaintCol,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      just = just,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      density = density,
      angle = angle,
      brush = brush,
      brush_settings = brush_settings,
      fill_brush = fill_brush,
      fill_settings = fill_settings,
      hand = hand,
      stroke_hand = stroke_hand,
      fill_hand = fill_hand,
      auto_solid_bg = auto_solid_bg,
      ...
    )
  )
}

#' Draw rough, brush-rendered bars in ggplot2
#'
#' @inheritParams geom_mypaint_col
#' @param stat The statistical transformation to use. Defaults to `"count"`.
#' @return A ggplot layer.
#' @export
geom_mypaint_bar <- function(mapping = NULL, data = NULL, stat = "count",
                             position = "stack", ..., just = 0.5,
                             lineend = "butt", linejoin = "mitre", na.rm = FALSE,
                             show.legend = NA, inherit.aes = TRUE,
                             density = NULL, angle = 45,
                             brush = NULL, brush_settings = NULL,
                             fill_brush = NULL, fill_settings = NULL,
                             hand = NULL, stroke_hand = hand, fill_hand = hand,
                             auto_solid_bg = NULL) {
  require_ggplot2()
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomMypaintBar,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      just = just,
      lineend = lineend,
      linejoin = linejoin,
      na.rm = na.rm,
      density = density,
      angle = angle,
      brush = brush,
      brush_settings = brush_settings,
      fill_brush = fill_brush,
      fill_settings = fill_settings,
      hand = hand,
      stroke_hand = stroke_hand,
      fill_hand = fill_hand,
      auto_solid_bg = auto_solid_bg,
      ...
    )
  )
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

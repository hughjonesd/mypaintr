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

draw_path_strokes <- function(path, hand_spec, draw_fun, ..., closed = FALSE) {
  args <- list(...)
  strokes <- max(1L, as.integer(hand_spec$multi_stroke))
  for (i in seq_len(strokes)) {
    lwd <- args$lwd %||% graphics::par("lwd")
    jittered_lwd <- max(0.01, lwd * (1 + stats::rnorm(1, sd = hand_spec$width_jitter)))
    path_i <- roughen_vertex_path(path$x, path$y, hand_spec, closed = closed)
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

draw_rough_hachure_fill <- function(x, y, hand_spec, col, angle = 45, density = NULL, xpd = NULL, ...) {
  rot <- rotate_xy(x, y, -angle)
  xr <- rot$x
  yr <- rot$y
  span <- diff(range(yr))
  gap <- hand_spec$hachure_gap %||% if (is.null(density)) span / 25 else span / max(1, density)
  gap <- max(gap, .Machine$double.eps)

  draw_pass <- function(base_angle) {
    hand_fill <- hand_spec
    hand_fill$seed <- NULL
    rot_pass <- rotate_xy(x, y, -base_angle)
    xr_pass <- rot_pass$x
    yr_pass <- rot_pass$y
    yy <- min(yr_pass)
    while (yy <= max(yr_pass)) {
      cuts <- polygon_intersections(xr_pass, yr_pass, yy)
      if (length(cuts) >= 2L) {
        for (i in seq(1L, length(cuts) - 1L, by = 2L)) {
          seg <- rotate_xy(c(cuts[i], cuts[i + 1L]), c(yy, yy), base_angle)
          draw_rough_segments(
            seg$x[1], seg$y[1], seg$x[2], seg$y[2],
            hand = hand_fill,
            col = col,
            xpd = xpd,
            ...
          )
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

#' Draw a rough single segment
#'
#' @param x0,y0 Segment start.
#' @param x1,y1 Segment end.
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @param ... Graphics parameters passed to [graphics::lines()].
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_line(1, 1, 10, 9)
#' @export
draw_rough_line <- function(x0, y0, x1, y1, hand = NULL, ...) {
  hand_spec <- as_hand(hand)

  invisible(with_hand_seed(hand_spec$seed, {
    draw_path_strokes(
      list(x = c(x0, x1), y = c(y0, y1)),
      hand_spec,
      graphics::lines,
      ...
    )
    NULL
  }))
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
  n <- max(length(x0), length(y0), length(x1), length(y1))
  x0 <- rep_len(x0, n)
  y0 <- rep_len(y0, n)
  x1 <- rep_len(x1, n)
  y1 <- rep_len(y1, n)

  invisible(with_hand_seed(hand_spec$seed, {
    for (i in seq_len(n)) {
      draw_path_strokes(
        list(x = c(x0[i], x1[i]), y = c(y0[i], y1[i])),
        hand_spec,
        graphics::lines,
        ...
      )
    }
    NULL
  }))
}

#' Draw a rough polygon
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
#' draw_rough_polygon(c(2, 5, 8, 3), c(2, 7, 5, 1), col = "grey80")
#' @export
draw_rough_polygon <- function(x, y = NULL, hand = NULL, col = NA, border = graphics::par("fg"),
                               density = NULL, angle = 45, ...) {
  hand_spec <- as_hand(hand)
  xy <- grDevices::xy.coords(x, y)

  invisible(with_hand_seed(hand_spec$seed, {
    if (is_visible_col(col)) {
      draw_rough_hachure_fill(
        xy$x,
        xy$y,
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
        closed = TRUE,
        ...
      )
    }
    NULL
  }))
}

#' Draw rough polygons
#'
#' Convenience alias for [draw_rough_polygon()].
#'
#' @inheritParams draw_rough_polygon
#' @return Draws on the current device and returns `NULL` invisibly.
#' @examples
#' plot(1:10, 1:10, type = "n")
#' draw_rough_polygons(c(2, 5, 8, 3), c(2, 7, 5, 1), col = "grey80")
#' @export
draw_rough_polygons <- function(x, y = NULL, hand = NULL, col = NA, border = graphics::par("fg"),
                                density = NULL, angle = 45, ...) {
  draw_rough_polygon(
    x = x,
    y = y,
    hand = hand,
    col = col,
    border = border,
    density = density,
    angle = angle,
    ...
  )
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
  draw_rough_polygon(x, y, hand = hand, col = col, border = border, density = density, angle = angle, ...)
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

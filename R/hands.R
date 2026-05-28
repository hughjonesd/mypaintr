
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

normalize_hand_spec <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  as_hand(x)
}

as_hand <- function(x = NULL) {
  if (is.null(x)) {
    return(hand())
  }
  if (!inherits(x, "mypaintr_hand")) {
    stop("hand must be created with hand() or human_hand()", call. = FALSE)
  }
  x
}

clamp01 <- function(x) {
  pmax(0, pmin(1, x))
}

check_finite_scalar <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop(name, " must be a finite numeric scalar", call. = FALSE)
  }
  x
}

check_positive_scalar <- function(x, name) {
  x <- check_finite_scalar(x, name)
  if (x <= 0) {
    stop(name, " must be greater than 0", call. = FALSE)
  }
  x
}

new_pressure_profile <- function(fun) {
  stopifnot(is.function(fun))
  structure(
    fun,
    class = c("mypaintr_pressure_profile", class(fun))
  )
}

as_pressure_profile <- function(x = NULL) {
  if (is.null(x)) {
    return(pressure_flat())
  }
  if (!is.function(x)) {
    stop("pressure must be a function, such as pressure_flat(), pressure_smooth(), or pressure_human()", call. = FALSE)
  }
  if (inherits(x, "mypaintr_pressure_profile")) {
    return(x)
  }

  args <- names(formals(x))
  if (is.null(args) || !(length(args) >= 2L || "..." %in% args)) {
    stop("pressure functions must accept two arguments: t and turn", call. = FALSE)
  }

  new_pressure_profile(x)
}

#' Pressure profiles for hand-drawn strokes
#'
#' @param value Maximum pressure supplied to the brush, in the range `0` to
#'   `1`.
#' @param taper How strongly pressure changes over the stroke. `0` keeps the
#'   pressure flat; `1` applies the full profile shape.
#' @param turn_taper How strongly pressure is reduced at sharp turns.
#' @param start,end Relative pressure at the start and end of a human-style
#'   stroke when `taper = 1`.
#' @param peak Position of peak pressure along the stroke, in the range `0` to
#'   `1`.
#' @return A pressure-profile function for the `pressure` argument of [hand()]
#'   and [human_hand()]. Custom functions can also be supplied directly; they
#'   must accept `t` in the range `0` to `1` and `turn` in the range `0` to
#'   `1`. `turn` describes local path curvature: `0` is straight, larger values
#'   are sharper corners, and values near `1` are near reversals.
#' @examples
#' plot.new()
#' plot.window(c(0, 10), c(0, 10))
#' draw_rough_lines(c(1, 9), c(8, 8), lwd = 5,
#'                  hand = hand(pressure = pressure_flat(0.5)))
#' draw_rough_lines(c(1, 9), c(5, 5), lwd = 5,
#'                  hand = hand(pressure = pressure_smooth()))
#' draw_rough_lines(c(1, 9), c(2, 2), lwd = 5,
#'                  hand = hand(pressure = pressure_human()))
#' @family pressure profiles
#' @export
pressure_flat <- function(value = 1) {
  value <- clamp01(value)
  new_pressure_profile(
    function(t, turn) {
      rep(value, length(t))
    }
  )
}

#' @rdname pressure_flat
#' @export
pressure_smooth <- function(value = 1, taper = 1, turn_taper = 0.35) {
  value <- clamp01(value)
  taper <- clamp01(taper)
  turn_taper <- clamp01(turn_taper)
  new_pressure_profile(
    function(t, turn) {
      tt <- clamp01(t)
      pressure <- value * ((1 - taper) + taper * sin(pi * tt))
      pressure <- pressure * (1 - turn_taper * taper * clamp01(turn))
      clamp01(pressure)
    }
  )
}

#' @rdname pressure_flat
#' @export
pressure_human <- function(value = 1,
                           taper = 0.6,
                           start = 0.35,
                           end = 0.55,
                           peak = 0.45,
                           turn_taper = 0.35) {
  value <- clamp01(value)
  taper <- clamp01(taper)
  start <- clamp01(start)
  end <- clamp01(end)
  peak <- max(0.01, min(0.99, peak))
  turn_taper <- clamp01(turn_taper)

  new_pressure_profile(
    function(t, turn) {
      tt <- clamp01(t)
      smoothstep <- function(x) x * x * (3 - 2 * x)
      shape <- ifelse(
        tt <= peak,
        start + (1 - start) * smoothstep(tt / peak),
        1 - (1 - end) * smoothstep((tt - peak) / (1 - peak))
      )
      pressure <- value * ((1 - taper) + taper * shape)
      pressure <- pressure * (1 - turn_taper * taper * clamp01(turn))
      clamp01(pressure)
    }
  )
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
#' @param pressure Pressure profile function, typically created with
#'   [pressure_flat()], [pressure_smooth()], or [pressure_human()].
#' @param speed Synthetic brush speed multiplier for [mypaint_device()] brush
#'   rendering. `1` preserves the default distance-based timing heuristic;
#'   values greater than `1` draw faster, and values below `1` draw slower.
#' @param xtilt,ytilt Stylus tilt inputs passed to libmypaint, in its normalized
#'   `-1` to `1` range.
#' @param barrel_rotation Stylus barrel rotation, in degrees.
#' @details
#' `hand()` defaults to plain, base-R-like geometry with no bowing, wobble, or
#' jitter and flat pressure. [human_hand()] has different, more human-like
#' defaults, including [pressure_human()].
#'
#' As of now, pressure profiles only apply to open lines, not shape outlines. On
#' base R devices, they are simulated and affect line width.
#'
#' The `speed`, `xtilt`, `ytilt`, and `barrel_rotation` arguments affect only
#' brush rendering on [mypaint_device()]. They are ignored by standard graphics
#' devices.
#'
#' @return An object describing how rough geometry should be generated.
#' @examples
#' plot.new()
#' plot.window(c(0, 10), c(0, 10))
#' draw_rough_lines(c(0, 10), c(8, 8), lwd = 4, hand = hand())
#' draw_rough_lines(c(0, 10), c(6, 6), lwd = 4, hand = human_hand())
#' draw_rough_lines(c(0, 10), c(4, 4), lwd = 4,
#'                  hand = human_hand(seed = 1,
#'                    bow = 0.02, wobble = 0.01))
#' draw_rough_lines(c(0, 10), c(2, 2), lwd = 4,
#'                  hand = human_hand(seed = 1,
#'                    pressure = pressure_smooth(0.7, taper = 0.5)))
#' draw_rough_lines(c(0, 10), c(1, 1), lwd = 4,
#'                  hand = human_hand(seed = 1,
#'                    pressure = pressure_human()))
#' @export
hand <- function(seed = NULL,
                 bow = 0,
                 wobble = 0,
                 multi_stroke = 1L,
                 width_jitter = 0,
                 endpoint_jitter = 0,
                 pressure = pressure_flat(),
                 speed = 1,
                 xtilt = 0,
                 ytilt = 0,
                 barrel_rotation = 0) {
  pressure <- as_pressure_profile(pressure)
  speed <- check_positive_scalar(speed, "speed")
  xtilt <- check_finite_scalar(xtilt, "xtilt")
  ytilt <- check_finite_scalar(ytilt, "ytilt")
  barrel_rotation <- check_finite_scalar(barrel_rotation, "barrel_rotation")
  structure(
    list(
      seed = seed,
      bow = bow,
      wobble = wobble,
      multi_stroke = as.integer(multi_stroke),
      width_jitter = width_jitter,
      endpoint_jitter = endpoint_jitter,
      pressure = pressure,
      speed = speed,
      xtilt = xtilt,
      ytilt = ytilt,
      barrel_rotation = barrel_rotation
    ),
    class = "mypaintr_hand"
  )
}

#' Hand-drawn geometry settings with rough human-style defaults
#'
#' `human_hand()` is the same as [hand()], but starts from rougher defaults with
#' bow, wobble, width jitter, and a human-style pressure profile enabled.
#'
#' @return An object describing how rough geometry should be generated.
#' @rdname hand
#' @export
human_hand <- function(seed = NULL,
                       bow = 0.004,
                       wobble = 0.004,
                       multi_stroke = 1L,
                       width_jitter = 0.08,
                       endpoint_jitter = 0,
                       pressure = pressure_human(),
                       speed = 1,
                       xtilt = 0,
                       ytilt = 0,
                       barrel_rotation = 0) {
  hand(
    seed = seed,
    bow = bow,
    wobble = wobble,
    multi_stroke = multi_stroke,
    width_jitter = width_jitter,
    endpoint_jitter = endpoint_jitter,
    pressure = pressure,
    speed = speed,
    xtilt = xtilt,
    ytilt = ytilt,
    barrel_rotation = barrel_rotation
  )
}

#' Set the active hand
#'
#' @param hand Hand-drawn geometry created with [hand()], or `NULL` to disable
#'   it for the selected type. This disables rough path perturbation only; it
#'   does not disable the active brush, and note that some brushes have
#'   their own internal wobbly pathing! Use [set_brush()] as well if you want
#'   fully plain, solid rendering.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @return `NULL`, invisibly. If the active graphics device is not
#'   [mypaint_device()], this emits a warning and has no effect.
#' @examples
#' ex_file <- tempfile(fileext = ".png")
#' mypaint_device(ex_file)
#'
#' plot.new()
#' plot.window(c(0, 10), c(0, 10))
#' set_hand(hand())
#' rect(1, 1, 5, 5, col = "darkred", density = 5)
#' set_hand(human_hand())
#' rect(5, 5, 9, 9, col = "darkgreen", density = 5)
#'
#' dev.off()
#' img <- png::readPNG(ex_file)
#' grid::grid.raster(img)
#' @export
set_hand <- function(hand = NULL, type = c("both", "stroke", "fill")) {
  type <- match.arg(type)
  stroke_hand <- if (type %in% c("both", "stroke")) normalize_hand_spec(hand) else NULL
  fill_hand <- if (type %in% c("both", "fill")) normalize_hand_spec(hand) else NULL

  if (!is_mypaintr_device()) {
    warn_no_mypaintr_device("set_hand")
    return(invisible(NULL))
  }

  invisible(.Call(
    mypaintr_device_set_hand,
    stroke_hand,
    fill_hand,
    type %in% c("both", "stroke"),
    type %in% c("both", "fill")
  ))
}


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
#' @param pressure Base pressure to use for mypaint brush strokes. Ignored on
#'   non-mypaint devices.
#' @param pressure_taper Amount of tapering applied to pressure at the start
#'   and end of mypaint brush strokes. `0` means constant pressure;
#'   `1` means strong tapering. Ignored on non-mypaint devices.
#' @details
#' `hand()` defaults to plain, base-R-like geometry with no bowing, wobble, or
#' jitter. Use [human_hand()] for the older rougher defaults.
#' @return An object describing how rough geometry should be generated.
#' @examples
#' plot.new()
#' plot.window(c(0, 10), c(0, 10))
#' draw_rough_lines(c(1, 10), c(9, 9), lwd = 2, hand = hand())
#' draw_rough_lines(c(1, 10), c(7, 7), lwd = 2, hand = human_hand())
#' draw_rough_lines(c(1, 10), c(5, 5), lwd = 2,
#'                  hand = human_hand(seed = 1,
#'                    bow = 0.03, wobble = 0.01))
#' draw_rough_lines(c(1, 10), c(3, 3), lwd = 2,
#'                  hand = human_hand(seed = 1, pressure_taper = 1))
#' @export
hand <- function(seed = NULL,
                 bow = 0,
                 wobble = 0,
                 multi_stroke = 1L,
                 width_jitter = 0,
                 endpoint_jitter = 0,
                 pressure = 1,
                 pressure_taper = 0) {
  structure(
    list(
      seed = seed,
      bow = bow,
      wobble = wobble,
      multi_stroke = as.integer(multi_stroke),
      width_jitter = width_jitter,
      endpoint_jitter = endpoint_jitter,
      pressure = pressure,
      pressure_taper = pressure_taper
    ),
    class = "mypaintr_hand"
  )
}

#' Hand-drawn geometry settings with rough human-style defaults
#'
#' `human_hand()` is the same as [hand()], but starts from the older rougher
#' defaults with bow, wobble, and width jitter already enabled.
#'
#' @return An object describing how rough geometry should be generated.
#' @rdname hand
#' @export
human_hand <- function(seed = NULL,
                       bow = 0.01,
                       wobble = 0.006,
                       multi_stroke = 1L,
                       width_jitter = 0.08,
                       endpoint_jitter = 0,
                       pressure = 1,
                       pressure_taper = 0) {
  hand(
    seed = seed,
    bow = bow,
    wobble = wobble,
    multi_stroke = multi_stroke,
    width_jitter = width_jitter,
    endpoint_jitter = endpoint_jitter,
    pressure = pressure,
    pressure_taper = pressure_taper
  )
}

#' Set the active mypaintr hand-drawn geometry
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

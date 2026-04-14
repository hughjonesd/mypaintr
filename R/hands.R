
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
    stop("hand must be created with hand()", call. = FALSE)
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

#' Set the active mypaintr hand-drawn geometry
#'
#' @param hand Hand-drawn geometry created with [hand()], or `NULL` to disable
#'   it for the selected type. This disables rough path perturbation only; it
#'   does not disable the active brush. Use [set_brush()] as well if you want
#'   fully plain, solid rendering.
#' @param type Which rendering channel to update: `"both"`, `"stroke"`, or
#'   `"fill"`.
#' @return `NULL`, invisibly. If the active device is not `mypaintr`, the
#'   selected hand settings become the default for the next [mypaint_device()]
#'   opened in this R session.
#' @export
set_hand <- function(hand = NULL, type = c("both", "stroke", "fill")) {
  type <- match.arg(type)
  stroke_hand <- if (type %in% c("both", "stroke")) normalize_hand_spec(hand) else NULL
  fill_hand <- if (type %in% c("both", "fill")) normalize_hand_spec(hand) else NULL

  if (!is_mypaintr_device()) {
    update_default_device_style(
      stroke_hand = stroke_hand,
      fill_hand = fill_hand,
      update_stroke = type %in% c("both", "stroke"),
      update_fill = type %in% c("both", "fill")
    )
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

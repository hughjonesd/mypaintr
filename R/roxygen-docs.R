#' Rough drawing hand parameter
#'
#' @name mypaintr-rough-hand
#' @param hand Hand-drawn geometry settings created with [hand()].
#' @keywords internal
NULL

#' Rough drawing fill parameters
#'
#' @name mypaintr-rough-fill
#' @param col Fill colour. When visible and `fill_pattern` is `NULL`, a solid
#'   fill is drawn.
#' @param border Border colour.
#' @param fill_pattern Optional fill pattern created with [hatch()],
#'   [crosshatch()], [zigzag()], or [jumble()].
#' @keywords internal
NULL

#' Fill pattern parameters
#'
#' @name mypaintr-fill-pattern-params
#' @param angle Base hatch angle in degrees.
#' @param density Approximate line density in lines per inch. Larger
#'   values give denser fills.
#' @param padding Inset from the polygon edge in inches. Positive values leave a
#'   small gap between the fill pattern and the boundary.
#' @param clip When `TRUE`, hatch endpoints stay on the shape boundary to reduce
#'   overshoot.
#' @keywords internal
NULL

#' Brush paths parameter
#'
#' @name mypaintr-brush-paths-param
#' @param paths Optional brush directories. Defaults to locally discovered
#'   `mypaint-brushes` locations.
#' @keywords internal
NULL

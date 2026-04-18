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
#' @param clip When `TRUE`, hatch endpoints stay on the shape boundary to reduce
#'   overshoot.
#' @keywords internal
NULL

#' Jumble fill pattern parameters
#'
#' @name mypaintr-jumble-params
#' @param angle Base angle in degrees for the underlying guide lines.
#' @param density Approximate line density in lines per inch. Larger
#'   values give denser fills.
#' @param radius Loop radius in inches. Defaults to `0.38 / density`, so the
#'   loops are sized as a fraction of the line spacing.
#' @param wobble Amount of irregularity in the loop shapes. Larger values give
#'   less even circles.
#' @param clip When `TRUE`, split loop paths at the shape boundary.
#' @keywords internal
NULL

#' Brush parameter
#'
#' @name mypaintr-brush-param
#' @param brush Brush preset, installed brush name, JSON brush string, named
#'   settings, or `NULL` to switch the selected type back to solid rendering.
#' @keywords internal
NULL

#' Brush settings parameter
#'
#' @name mypaintr-brush-settings-param
#' @param settings Named settings overriding `brush`.
#' @keywords internal
NULL

#' Brush paths parameter
#'
#' @name mypaintr-brush-paths-param
#' @param paths Optional brush directories. Defaults to locally discovered
#'   `mypaint-brushes` locations.
#' @keywords internal
NULL

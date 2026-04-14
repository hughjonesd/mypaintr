
`%||%` <- function(x, y) if (is.null(x)) y else x

is_visible_col <- function(col) {
  !is.null(col) && !all(is.na(col)) && grDevices::col2rgb(col, alpha = TRUE)[4, 1] > 0
}

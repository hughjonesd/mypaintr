# Compute or draw rough connected lines

Compute or draw rough connected lines

## Usage

``` r
rough_lines(x, y = NULL, hand = NULL)

draw_rough_lines(x, y = NULL, hand = NULL, ...)
```

## Arguments

- x, y:

  Coordinates as for
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## Value

A list with `x`, `y`, and `id` components describing roughened polyline
geometry for each connected run.

## See also

Other rough drawing helpers:
[`rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/rough_arrows.md),
[`rough_points()`](https://hughjonesd.github.io/mypaintr/reference/rough_points.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
y <- c(2, 5, 4, 7, 6, 8)
plot(1:6, y, type = "n")
draw_rough_lines(1:6, y, hand = human_hand(multi_stroke = 2))
```

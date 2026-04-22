# Draw rough points

Draw rough points

## Usage

``` r
draw_rough_points(x, y = NULL, hand = NULL, ...)
```

## Arguments

- x, y:

  Point coordinates as for
  [`graphics::points()`](https://rdrr.io/r/graphics/points.html).

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::points()`](https://rdrr.io/r/graphics/points.html).

## Value

Draws on the current device and returns `NULL` invisibly.

## See also

Other rough drawing helpers:
[`draw_rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_arrows.md),
[`draw_rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_lines.md),
[`draw_rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polygons.md),
[`draw_rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polypath.md),
[`draw_rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_rect.md),
[`draw_rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_points(1:10, 1:10, pch = 16, cex = 1.4)
```

# Draw rough segments

Draw rough segments

## Usage

``` r
draw_rough_segments(x0, y0, x1, y1, hand = NULL, ...)
```

## Arguments

- x0, y0:

  Segment starts.

- x1, y1:

  Segment ends.

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## Value

Draws on the current device and returns `NULL` invisibly.

## See also

Other rough drawing helpers:
[`draw_rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_arrows.md),
[`draw_rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_lines.md),
[`draw_rough_points()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_points.md),
[`draw_rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polygons.md),
[`draw_rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polypath.md),
[`draw_rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_rect.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_segments(1:3, 2:4, 4:6, c(8, 5, 7), lwd = 2)
```

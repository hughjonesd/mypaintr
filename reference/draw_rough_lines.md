# Draw rough connected lines

Draw rough connected lines

## Usage

``` r
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

Draws on the current device and returns `NULL` invisibly.

## See also

Other rough drawing helpers:
[`draw_rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_arrows.md),
[`draw_rough_points()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_points.md),
[`draw_rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polygons.md),
[`draw_rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polypath.md),
[`draw_rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_rect.md),
[`draw_rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_segments.md)

## Examples

``` r
y <- c(2, 5, 4, 7, 6, 8)
plot(1:6, y, type = "n")
draw_rough_lines(1:6, y, hand = hand(multi_stroke = 2), lwd = 2)
```

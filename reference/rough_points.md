# Compute or draw rough points

Compute or draw rough points

## Usage

``` r
rough_points(x, y = NULL, hand = NULL)

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

A list with jittered `x` and `y` point locations.

## See also

Other rough drawing helpers:
[`rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/rough_arrows.md),
[`rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/rough_lines.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_points(1:10, 1:10,
                  hand = human_hand(),
                  pch = 16, cex = 1.4)
```

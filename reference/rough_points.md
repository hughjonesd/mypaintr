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
plot(1:5, 1:5, type = "n")

rough_points(1:5, 1:5, hand = hand(endpoint_jitter = 0.02))
#> $x
#> [1] 0.9994946 2.0000600 3.0000342 4.0000343 4.9989411
#> 
#> $y
#> [1] 1.001120 1.999837 2.999783 4.000629 5.000030
#> 
plot(1:10, 1:10, type = "n")
draw_rough_points(1:10, 1:10, pch = 16, cex = 1.4)
```

# Compute or draw rough segments

Compute or draw rough segments

## Usage

``` r
rough_segments(x0, y0, x1, y1, hand = NULL)

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

A list with `x`, `y`, and `id` components describing roughened polyline
geometry for each segment.

## See also

Other rough drawing helpers:
[`rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/rough_arrows.md),
[`rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/rough_lines.md),
[`rough_points()`](https://hughjonesd.github.io/mypaintr/reference/rough_points.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md)

## Examples

``` r
rough_segments(1:2, 1:2, 2:3, 3:2)
#> $x
#>  [1] 1.000000 1.038462 1.076923 1.115385 1.153846 1.192308 1.230769 1.269231
#>  [9] 1.307692 1.346154 1.384615 1.423077 1.461538 1.500000 1.538462 1.576923
#> [17] 1.615385 1.653846 1.692308 1.730769 1.769231 1.807692 1.846154 1.884615
#> [25] 1.923077 1.961538 2.000000 2.000000 2.090909 2.181818 2.272727 2.363636
#> [33] 2.454545 2.545455 2.636364 2.727273 2.818182 2.909091 3.000000
#> 
#> $y
#>  [1] 1.000000 1.076923 1.153846 1.230769 1.307692 1.384615 1.461538 1.538462
#>  [9] 1.615385 1.692308 1.769231 1.846154 1.923077 2.000000 2.076923 2.153846
#> [17] 2.230769 2.307692 2.384615 2.461538 2.538462 2.615385 2.692308 2.769231
#> [25] 2.846154 2.923077 3.000000 2.000000 2.000000 2.000000 2.000000 2.000000
#> [33] 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000
#> 
#> $id
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2
#> [39] 2
#> 
plot(1:10, 1:10, type = "n")
draw_rough_segments(1:3, 2:4, 4:6, c(8, 5, 7), lwd = 2)
```

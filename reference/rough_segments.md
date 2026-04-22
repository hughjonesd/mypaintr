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
#>  [1] 1.000000 1.034754 1.069582 1.104536 1.139668 1.175025 1.210651 1.246585
#>  [9] 1.282863 1.319663 1.357095 1.394970 1.433282 1.472021 1.511167 1.550698
#> [17] 1.590583 1.630788 1.670558 1.710575 1.750974 1.791739 1.832846 1.874265
#> [25] 1.915959 1.957887 2.000000 2.000000 2.090909 2.181818 2.272727 2.363636
#> [33] 2.454545 2.545455 2.636364 2.727273 2.818182 2.909091 3.000000
#> 
#> $y
#>  [1] 1.000000 1.078777 1.157517 1.236193 1.314781 1.393257 1.471598 1.549784
#>  [9] 1.627799 1.705553 1.782991 1.860207 1.937205 2.013990 2.090570 2.166959
#> [17] 2.243170 2.319221 2.395490 2.471636 2.547590 2.623361 2.698962 2.774406
#> [25] 2.849713 2.924903 3.000000 2.000000 2.003310 2.005442 2.006335 2.007967
#> [33] 2.012509 2.016350 2.018554 2.014986 2.009568 2.004385 2.000000
#> 
#> $id
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2
#> [39] 2
#> 
plot(1:10, 1:10, type = "n")
draw_rough_segments(1:3, 2:4, 4:6, c(8, 5, 7), lwd = 2)
```

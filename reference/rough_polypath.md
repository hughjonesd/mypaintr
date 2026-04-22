# Compute or draw a rough multipath

Compute or draw a rough multipath

## Usage

``` r
rough_polypath(
  x,
  y = NULL,
  id = NULL,
  rule = c("winding", "evenodd"),
  hand = NULL
)

draw_rough_polypath(
  x,
  y = NULL,
  id = NULL,
  rule = c("winding", "evenodd"),
  hand = NULL,
  col = NA,
  border = graphics::par("fg"),
  fill_pattern = NULL,
  ...
)
```

## Arguments

- x, y:

  Coordinates as for
  [`graphics::polypath()`](https://rdrr.io/r/graphics/polypath.html).

- id:

  Optional path ids. Consecutive points with the same `id` belong to one
  closed ring.

- rule:

  Fill rule, `"winding"` or `"evenodd"`.

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- col:

  Fill colour. When visible and `fill_pattern` is `NULL`, a solid fill
  is drawn.

- border:

  Border colour.

- fill_pattern:

  Optional fill pattern created with
  [`hatch()`](https://hughjonesd.github.io/mypaintr/reference/hatch.md),
  [`crosshatch()`](https://hughjonesd.github.io/mypaintr/reference/crosshatch.md),
  [`zigzag()`](https://hughjonesd.github.io/mypaintr/reference/zigzag.md),
  or
  [`jumble()`](https://hughjonesd.github.io/mypaintr/reference/jumble.md).

- ...:

  Graphics parameters passed to
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## Value

A list with `x`, `y`, `id`, and `rule` components describing roughened
closed rings.

## See also

Other rough drawing helpers:
[`rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/rough_arrows.md),
[`rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/rough_lines.md),
[`rough_points()`](https://hughjonesd.github.io/mypaintr/reference/rough_points.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
rough_polypath(c(2, 4, 4, 2, 2.5, 3.5, 3.5, 2.5),
               c(2, 2, 4, 4, 2.5, 2.5, 3.5, 3.5),
               id = c(rep(1, 4), rep(2, 4)),
               rule = "evenodd")
#> $x
#>   [1] 2.000000 2.086957 2.173913 2.260870 2.347826 2.434783 2.521739 2.608696
#>   [9] 2.695652 2.782609 2.869565 2.956522 3.043478 3.130435 3.217391 3.304348
#>  [17] 3.391304 3.478261 3.565217 3.652174 3.739130 3.826087 3.913043 4.000000
#>  [25] 4.004811 4.009318 4.013443 4.017119 4.020290 4.022915 4.024966 4.027319
#>  [33] 4.030552 4.033368 4.035653 4.037305 4.038232 4.038354 4.037611 4.034291
#>  [41] 4.030066 4.025436 4.020508 4.015392 4.010198 4.005033 4.000000 3.913043
#>  [49] 3.826087 3.739130 3.652174 3.565217 3.478261 3.391304 3.304348 3.217391
#>  [57] 3.130435 3.043478 2.956522 2.869565 2.782609 2.695652 2.608696 2.521739
#>  [65] 2.434783 2.347826 2.260870 2.173913 2.086957 2.000000 1.999907 2.000481
#>  [73] 2.001695 2.003493 2.005801 2.008522 2.011544 2.012645 2.010329 2.007521
#>  [81] 2.004391 2.001119 1.997886 1.994875 1.992258 1.992921 1.994243 1.995526
#>  [89] 1.996725 1.997803 1.998724 1.999463 2.000000 2.500000 2.590909 2.681818
#>  [97] 2.772727 2.863636 2.954545 3.045455 3.136364 3.227273 3.318182 3.409091
#> [105] 3.500000 3.498838 3.496704 3.493902 3.492950 3.496505 3.500682 3.504465
#> [113] 3.503319 3.501195 3.500008 3.500000 3.409091 3.318182 3.227273 3.136364
#> [121] 3.045455 2.954545 2.863636 2.772727 2.681818 2.590909 2.500000 2.502852
#> [129] 2.504259 2.504255 2.505014 2.508924 2.512393 2.514577 2.512117 2.508008
#> [137] 2.503829 2.500000
#> 
#> $y
#>   [1] 2.000000 2.004555 2.009064 2.013441 2.017603 2.021469 2.024966 2.028025
#>   [9] 2.029686 2.029317 2.028190 2.026409 2.024093 2.021371 2.018380 2.015258
#>  [17] 2.015115 2.015068 2.014346 2.012911 2.010743 2.007846 2.004248 2.000000
#>  [25] 2.086957 2.173913 2.260870 2.347826 2.434783 2.521739 2.608696 2.695652
#>  [33] 2.782609 2.869565 2.956522 3.043478 3.130435 3.217391 3.304348 3.391304
#>  [41] 3.478261 3.565217 3.652174 3.739130 3.826087 3.913043 4.000000 3.998347
#>  [49] 3.997540 3.997571 3.998402 3.999965 4.002167 4.004890 4.005971 4.003939
#>  [57] 4.001602 3.999094 3.996556 3.994129 3.991953 3.990158 3.990261 3.990950
#>  [65] 3.991893 3.993085 3.994514 3.996160 3.997999 4.000000 3.913043 3.826087
#>  [73] 3.739130 3.652174 3.565217 3.478261 3.391304 3.304348 3.217391 3.130435
#>  [81] 3.043478 2.956522 2.869565 2.782609 2.695652 2.608696 2.521739 2.434783
#>  [89] 2.347826 2.260870 2.173913 2.086957 2.000000 2.500000 2.503006 2.506454
#>  [97] 2.509982 2.511713 2.509715 2.506686 2.503360 2.503162 2.503202 2.502158
#> [105] 2.500000 2.590909 2.681818 2.772727 2.863636 2.954545 3.045455 3.136364
#> [113] 3.227273 3.318182 3.409091 3.500000 3.502831 3.504915 3.506148 3.506595
#> [121] 3.506420 3.505663 3.504510 3.504530 3.504143 3.502630 3.500000 3.409091
#> [129] 3.318182 3.227273 3.136364 3.045455 2.954545 2.863636 2.772727 2.681818
#> [137] 2.590909 2.500000
#> 
#> $id
#>   [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [38] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [75] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
#> [112] 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2
#> 
#> $rule
#> [1] "evenodd"
#> 
plot(1:10, 1:10, type = "n")
draw_rough_polypath(c(2, 8, 8, 2, 4, 6, 6, 4),
                    c(2, 2, 8, 8, 4, 4, 6, 6),
                    id = c(rep(1, 4), rep(2, 4)),
                    rule = "evenodd",
                    col = "grey90",
                    fill_pattern = hatch(density = 9))
```

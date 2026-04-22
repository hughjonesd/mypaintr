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
#>  [25] 3.988261 3.976116 3.963811 3.951602 3.939757 3.928547 3.918237 3.910622
#>  [33] 3.906940 3.905166 3.905264 3.907162 3.910753 3.915902 3.922444 3.929184
#>  [41] 3.936941 3.945798 3.955581 3.966099 3.977149 3.988521 4.000000 3.913043
#>  [49] 3.826087 3.739130 3.652174 3.565217 3.478261 3.391304 3.304348 3.217391
#>  [57] 3.130435 3.043478 2.956522 2.869565 2.782609 2.695652 2.608696 2.521739
#>  [65] 2.434783 2.347826 2.260870 2.173913 2.086957 2.000000 2.000236 2.000746
#>  [73] 2.001513 2.002510 2.003700 2.005040 2.006477 2.007777 2.008761 2.009632
#>  [81] 2.010353 2.010891 2.011216 2.011303 2.011129 2.009297 2.007202 2.005256
#>  [89] 2.003535 2.002103 2.001012 2.000303 2.000000 2.500000 2.590909 2.681818
#>  [97] 2.772727 2.863636 2.954545 3.045455 3.136364 3.227273 3.318182 3.409091
#> [105] 3.500000 3.506967 3.513491 3.519029 3.523051 3.525135 3.525187 3.523194
#> [113] 3.519130 3.513539 3.506979 3.500000 3.409091 3.318182 3.227273 3.136364
#> [121] 3.045455 2.954545 2.863636 2.772727 2.681818 2.590909 2.500000 2.495775
#> [129] 2.492747 2.491056 2.488571 2.482946 2.478329 2.475842 2.480686 2.487802
#> [137] 2.494487 2.500000
#> 
#> $y
#>   [1] 2.000000 1.999915 1.999941 2.000076 2.000310 2.000634 2.001032 2.001486
#>   [9] 2.001733 2.001592 2.001397 2.001161 2.000899 2.000625 2.000354 2.000100
#>  [17] 1.999959 1.999861 1.999791 1.999755 1.999756 1.999797 1.999879 2.000000
#>  [25] 2.086957 2.173913 2.260870 2.347826 2.434783 2.521739 2.608696 2.695652
#>  [33] 2.782609 2.869565 2.956522 3.043478 3.130435 3.217391 3.304348 3.391304
#>  [41] 3.478261 3.565217 3.652174 3.739130 3.826087 3.913043 4.000000 3.994564
#>  [49] 3.989595 3.985176 3.981371 3.978228 3.975777 3.974029 3.972642 3.971372
#>  [57] 3.970675 3.970548 3.970978 3.971940 3.973401 3.975319 3.976192 3.977435
#>  [65] 3.979421 3.982157 3.985628 3.989799 3.994616 4.000000 3.913043 3.826087
#>  [73] 3.739130 3.652174 3.565217 3.478261 3.391304 3.304348 3.217391 3.130435
#>  [81] 3.043478 2.956522 2.869565 2.782609 2.695652 2.608696 2.521739 2.434783
#>  [89] 2.347826 2.260870 2.173913 2.086957 2.000000 2.500000 2.497607 2.496271
#>  [97] 2.495992 2.497474 2.501323 2.505394 2.508699 2.504937 2.500537 2.498719
#> [105] 2.500000 2.590909 2.681818 2.772727 2.863636 2.954545 3.045455 3.136364
#> [113] 3.227273 3.318182 3.409091 3.500000 3.498812 3.497899 3.497313 3.496044
#> [121] 3.493014 3.490332 3.488651 3.491329 3.495045 3.498068 3.500000 3.409091
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

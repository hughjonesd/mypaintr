# Compute or draw rough arrows

Compute or draw rough arrows

## Usage

``` r
rough_arrows(x0, y0, x1, y1, length = 0.25, angle = 30, code = 2, hand = NULL)

draw_rough_arrows(
  x0,
  y0,
  x1,
  y1,
  length = 0.25,
  angle = 30,
  code = 2,
  hand = NULL,
  ...
)
```

## Arguments

- x0, y0:

  Arrow starts.

- x1, y1:

  Arrow ends.

- length:

  Arrowhead length in inches, as in
  [`graphics::arrows()`](https://rdrr.io/r/graphics/arrows.html).

- angle:

  Arrowhead angle in degrees.

- code:

  Integer code indicating where heads are drawn: `0` for none, `1` at
  the start, `2` at the end, `3` at both ends.

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## Value

A list with `x`, `y`, and `id` components describing roughened polyline
geometry for arrow shafts and heads.

## See also

Other rough drawing helpers:
[`rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/rough_lines.md),
[`rough_points()`](https://hughjonesd.github.io/mypaintr/reference/rough_points.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
rough_arrows(2, 2, 8, 8, hand = hand(multi_stroke = 2))
#> $x
#>   [1] 2.000000 2.062053 2.124066 2.186038 2.247966 2.309847 2.371680 2.433462
#>   [9] 2.495191 2.556866 2.618483 2.680043 2.741542 2.802979 2.864353 2.925662
#>  [17] 2.986905 3.048080 3.109187 3.170224 3.231191 3.292086 3.352909 3.413660
#>  [25] 3.474336 3.534939 3.595468 3.655922 3.716301 3.776606 3.836835 3.896990
#>  [33] 3.957071 4.017077 4.078325 4.140202 4.202068 4.263918 4.325746 4.387548
#>  [41] 4.449317 4.511049 4.572738 4.634379 4.695966 4.757495 4.818960 4.880356
#>  [49] 4.941678 5.002920 5.064078 5.125148 5.186123 5.246999 5.307773 5.368438
#>  [57] 5.428991 5.489428 5.549744 5.609935 5.669997 5.729928 5.789722 5.849377
#>  [65] 5.908890 5.968256 6.027475 6.085740 6.142353 6.198900 6.255386 6.311814
#>  [73] 6.368191 6.424519 6.480805 6.537052 6.593264 6.649447 6.705605 6.761742
#>  [81] 6.817863 6.873972 6.930074 6.986173 7.042273 7.098379 7.154494 7.210624
#>  [89] 7.266771 7.322940 7.379135 7.435359 7.491617 7.547911 7.604246 7.660625
#>  [97] 7.717051 7.773528 7.830058 7.886645 7.943291 8.000000 8.000000 7.911332
#> [105] 7.823051 7.734946 7.647955 7.561438 8.000000 7.980505 7.956889 7.926846
#> [113] 7.894820 7.859034
#> 
#> $y
#>   [1] 2.000000 2.056759 2.113558 2.170398 2.227282 2.284212 2.341191 2.398221
#>   [9] 2.455304 2.512441 2.569635 2.626888 2.684201 2.741575 2.799013 2.856516
#>  [17] 2.914085 2.971722 3.029427 3.087201 3.145047 3.202963 3.260952 3.319014
#>  [25] 3.377149 3.435358 3.493641 3.551999 3.610432 3.668939 3.727521 3.786178
#>  [33] 3.844909 3.903715 3.961279 4.018214 4.075160 4.132122 4.189105 4.246116
#>  [41] 4.303158 4.360238 4.417361 4.474532 4.531757 4.589040 4.646387 4.703803
#>  [49] 4.761293 4.818862 4.876516 4.934258 4.992095 5.050030 5.108069 5.166215
#>  [57] 5.224474 5.282849 5.341345 5.399966 5.458715 5.517597 5.576615 5.635771
#>  [65] 5.695071 5.754516 5.814109 5.874656 5.936855 5.999120 6.061446 6.123829
#>  [73] 6.186265 6.248748 6.311274 6.373839 6.436439 6.499068 6.561722 6.624397
#>  [81] 6.687087 6.749790 6.812500 6.875213 6.937925 7.000631 7.063327 7.126010
#>  [89] 7.188675 7.251318 7.313935 7.376522 7.439076 7.501594 7.564070 7.626503
#>  [97] 7.688889 7.751224 7.813506 7.875731 7.937897 8.000000 8.000000 7.983786
#> [105] 7.965904 7.947265 7.923819 7.898328 8.000000 7.901863 7.804941 7.709916
#> [113] 7.615476 7.522144
#> 
#> $id
#>   [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [38] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#>  [75] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 3 3 3
#> [112] 3 3 3
#> 
plot(1:10, 1:10, type = "n")
draw_rough_arrows(2, 2, 8, 8, lwd = 2)
draw_rough_arrows(8, 2, 2, 8, code = 3, hand = hand(multi_stroke = 2))
```

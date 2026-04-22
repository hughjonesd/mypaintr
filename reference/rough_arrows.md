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
#>   [1] 2.000000 2.056800 2.113684 2.170656 2.227716 2.284868 2.342112 2.399451
#>   [9] 2.456886 2.514419 2.572049 2.629780 2.687610 2.745542 2.803575 2.861709
#>  [17] 2.919946 2.978284 3.036723 3.095264 3.153905 3.212646 3.271486 3.330424
#>  [25] 3.389459 3.448589 3.507813 3.567129 3.626535 3.686031 3.745612 3.805278
#>  [33] 3.865026 3.924853 3.982677 4.039463 4.096222 4.152961 4.209687 4.266406
#>  [41] 4.323126 4.379851 4.436591 4.493350 4.550136 4.606956 4.663816 4.720723
#>  [49] 4.777685 4.834706 4.891795 4.948958 5.006201 5.063531 5.120953 5.178475
#>  [57] 5.236103 5.293842 5.351698 5.409677 5.467785 5.526027 5.584409 5.642934
#>  [65] 5.701609 5.760438 5.819426 5.879506 5.941492 6.003544 6.065659 6.127831
#>  [73] 6.190057 6.252333 6.314654 6.377017 6.439418 6.501851 6.564314 6.626802
#>  [81] 6.689311 6.751836 6.814375 6.876922 6.939474 7.002027 7.064577 7.127120
#>  [89] 7.189652 7.252170 7.314669 7.377147 7.439600 7.502024 7.564417 7.626773
#>  [97] 7.689092 7.751368 7.813601 7.875785 7.937919 8.000000 8.000000 7.914192
#> [105] 7.827791 7.739653 7.650792 7.561438 8.000000 7.973325 7.945992 7.915266
#> [113] 7.887204 7.859034
#> 
#> $y
#>   [1] 2.000000 2.062012 2.123939 2.185780 2.247531 2.309192 2.370759 2.432232
#>   [9] 2.493609 2.554888 2.616069 2.677151 2.738132 2.799012 2.859791 2.920469
#>  [17] 2.981044 3.041518 3.101890 3.162162 3.222332 3.282403 3.342375 3.402249
#>  [25] 3.462026 3.521708 3.581296 3.640792 3.700197 3.759514 3.818744 3.877890
#>  [33] 3.936954 3.995939 4.056927 4.118953 4.181006 4.243079 4.305164 4.367257
#>  [41] 4.429350 4.491436 4.553508 4.615561 4.677587 4.739579 4.801530 4.863435
#>  [49] 4.925286 4.987076 5.048799 5.110448 5.172017 5.233499 5.294888 5.356178
#>  [57] 5.417362 5.478435 5.539391 5.600224 5.660927 5.721497 5.781928 5.842214
#>  [65] 5.902351 5.962334 6.022158 6.080890 6.137716 6.194475 6.251173 6.307813
#>  [73] 6.364399 6.420935 6.477425 6.533874 6.590285 6.646663 6.703013 6.759337
#>  [81] 6.815640 6.871926 6.928199 6.984464 7.040724 7.096983 7.153245 7.209514
#>  [89] 7.265794 7.322088 7.378400 7.434734 7.491093 7.547480 7.603900 7.660355
#>  [97] 7.716849 7.773384 7.829964 7.886591 7.943269 8.000000 8.000000 7.971450
#> [105] 7.945459 7.926960 7.911582 7.898328 8.000000 7.903981 7.808156 7.713332
#> [113] 7.617722 7.522144
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

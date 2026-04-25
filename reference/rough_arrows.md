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
draw_rough_arrows(8, 2, 2, 8, hand = human_hand())
```

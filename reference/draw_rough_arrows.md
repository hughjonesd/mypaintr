# Draw rough arrows

Draw rough arrows

## Usage

``` r
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

Draws on the current device and returns `NULL` invisibly.

## See also

Other rough drawing helpers:
[`draw_rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_lines.md),
[`draw_rough_points()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_points.md),
[`draw_rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polygons.md),
[`draw_rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polypath.md),
[`draw_rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_rect.md),
[`draw_rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_arrows(2, 2, 8, 8)
draw_rough_arrows(8, 2, 2, 8, code = 3, hand = hand(multi_stroke = 2))
```

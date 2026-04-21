# Draw a rough multipath with optional holes

Draw a rough multipath with optional holes

## Usage

``` r
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

Draws on the current device and returns `NULL` invisibly.

## See also

Other rough drawing helpers:
[`draw_rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_arrows.md),
[`draw_rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_lines.md),
[`draw_rough_points()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_points.md),
[`draw_rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_polygons.md),
[`draw_rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_rect.md),
[`draw_rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/draw_rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_polypath(c(2, 8, 8, 2, 4, 6, 6, 4),
                    c(2, 2, 8, 8, 4, 4, 6, 6),
                    id = c(rep(1, 4), rep(2, 4)),
                    rule = "evenodd",
                    col = "grey80")
```

# Compute or draw a rough rectangle

Compute or draw a rough rectangle

## Usage

``` r
rough_rect(x0, y0, x1, y1, hand = NULL)

draw_rough_rect(
  x0,
  y0,
  x1,
  y1,
  hand = NULL,
  col = NA,
  border = graphics::par("fg"),
  fill_pattern = NULL,
  ...
)
```

## Arguments

- x0, y0:

  Rectangle corner.

- x1, y1:

  Opposite rectangle corner.

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

A list with `x` and `y` components containing a roughened closed outline
suitable for plotting with
[`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## See also

Other rough drawing helpers:
[`rough_arrows()`](https://hughjonesd.github.io/mypaintr/reference/rough_arrows.md),
[`rough_lines()`](https://hughjonesd.github.io/mypaintr/reference/rough_lines.md),
[`rough_points()`](https://hughjonesd.github.io/mypaintr/reference/rough_points.md),
[`rough_polygons()`](https://hughjonesd.github.io/mypaintr/reference/rough_polygons.md),
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_rect(2, 2, 8, 7,
                hand = human_hand(),
                col = "grey90",
                fill_pattern = crosshatch(padding = 0.05))
```

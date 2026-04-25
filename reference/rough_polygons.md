# Compute or draw rough polygons

Compute or draw rough polygons

## Usage

``` r
rough_polygons(x, y = NULL, hand = NULL)

draw_rough_polygons(
  x,
  y = NULL,
  hand = NULL,
  col = NA,
  border = graphics::par("fg"),
  fill_pattern = NULL,
  ...
)
```

## Arguments

- x, y:

  Polygon coordinates.

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
[`rough_polypath()`](https://hughjonesd.github.io/mypaintr/reference/rough_polypath.md),
[`rough_rect()`](https://hughjonesd.github.io/mypaintr/reference/rough_rect.md),
[`rough_segments()`](https://hughjonesd.github.io/mypaintr/reference/rough_segments.md)

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_polygons(c(2, 5, 8, 3), c(2, 7, 5, 1),
                    hand = human_hand(),
                    col = "grey90",
                    fill_pattern = zigzag())
```

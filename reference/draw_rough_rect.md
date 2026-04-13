# Draw a rough rectangle

Draw a rough rectangle

## Usage

``` r
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

Draws on the current device and returns `NULL` invisibly.

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_rect(2, 2, 5, 6, col = "grey80")
```

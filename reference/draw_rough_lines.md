# Draw rough connected lines

Draw rough connected lines

## Usage

``` r
draw_rough_lines(x, y = NULL, hand = NULL, ...)
```

## Arguments

- x, y:

  Coordinates as for
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::lines()`](https://rdrr.io/r/graphics/lines.html).

## Value

Draws on the current device and returns `NULL` invisibly.

## Examples

``` r
plot(1:10, cumsum(rnorm(10)), type = "n")
draw_rough_lines(1:10, cumsum(rnorm(10)))
```

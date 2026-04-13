# Draw rough points

Draw rough points

## Usage

``` r
draw_rough_points(x, y = NULL, hand = NULL, ...)
```

## Arguments

- x, y:

  Point coordinates as for
  [`graphics::points()`](https://rdrr.io/r/graphics/points.html).

- hand:

  Hand-drawn geometry settings created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- ...:

  Graphics parameters passed to
  [`graphics::points()`](https://rdrr.io/r/graphics/points.html).

## Value

Draws on the current device and returns `NULL` invisibly.

## Examples

``` r
plot(1:10, 1:10, type = "n")
draw_rough_points(1:10, 1:10, pch = 16)
```

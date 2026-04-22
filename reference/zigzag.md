# Zigzag fill pattern

Zigzag fill pattern

## Usage

``` r
zigzag(angle = 45, density = 6, clip = TRUE, padding = 0)
```

## Arguments

- angle:

  Base hatch angle in degrees.

- density:

  Approximate line density in lines per inch. Larger values give denser
  fills.

- clip:

  When `TRUE`, zigzag endpoints stay on the shape boundary to reduce
  overshoot.

- padding:

  Inset from the polygon edge in inches. Positive values leave a small
  gap between the fill pattern and the boundary.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

## See also

Other fill patterns:
[`crosshatch()`](https://hughjonesd.github.io/mypaintr/reference/crosshatch.md),
[`hatch()`](https://hughjonesd.github.io/mypaintr/reference/hatch.md),
[`jumble()`](https://hughjonesd.github.io/mypaintr/reference/jumble.md)

## Examples

``` r
plot.new()
plot.window(xlim = c(0, 10), ylim = c(0, 10))
draw_rough_rect(2, 2, 8, 8, col = "grey90", fill_pattern = zigzag(density = 7))
```

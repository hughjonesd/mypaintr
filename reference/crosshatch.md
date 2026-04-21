# Cross-hatch fill pattern

Cross-hatch fill pattern

## Usage

``` r
crosshatch(angle = 45, density = 7, clip = TRUE, padding = 0)
```

## Arguments

- angle:

  One or two hatch angles in degrees. If a single angle is supplied, the
  second pass defaults to `angle + 90`.

- density:

  Approximate line density in lines per inch. Larger values give denser
  fills.

- clip:

  When `TRUE`, hatch endpoints stay on the shape boundary to reduce
  overshoot.

- padding:

  Inset from the polygon edge in inches. Positive values leave a small
  gap between the fill pattern and the boundary.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

## See also

Other fill patterns:
[`hatch()`](https://hughjonesd.github.io/mypaintr/reference/hatch.md),
[`jumble()`](https://hughjonesd.github.io/mypaintr/reference/jumble.md),
[`zigzag()`](https://hughjonesd.github.io/mypaintr/reference/zigzag.md)

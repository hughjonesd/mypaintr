# Cross-hatch fill pattern

Cross-hatch fill pattern

## Usage

``` r
crosshatch(angle = 45, density = 7, clip = TRUE)
```

## Arguments

- angle:

  One or two hatch angles in degrees. If a single angle is supplied, the
  second pass defaults to `angle + 90`.

- density:

  Approximate line density. Larger values give denser fills.

- clip:

  When `TRUE`, hatch endpoints stay on the shape boundary to reduce
  overshoot.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

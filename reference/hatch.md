# Hatch fill pattern

Hatch fill pattern

## Usage

``` r
hatch(angle = 45, density = 8, clip = TRUE)
```

## Arguments

- angle:

  Base hatch angle in degrees.

- density:

  Approximate line density. Larger values give denser fills.

- clip:

  When `TRUE`, hatch endpoints stay on the shape boundary to reduce
  overshoot.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

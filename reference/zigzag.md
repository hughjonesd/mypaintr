# Zigzag fill pattern

Zigzag fill pattern

## Usage

``` r
zigzag(angle = 45, density = 6, clip = TRUE)
```

## Arguments

- angle:

  Base zigzag angle in degrees.

- density:

  Approximate line density. Larger values give denser fills.

- clip:

  When `TRUE`, zigzag endpoints stay on the shape boundary to reduce
  overshoot.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

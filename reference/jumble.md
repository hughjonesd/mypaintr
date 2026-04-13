# Jumble fill pattern

Jumble fill pattern

## Usage

``` r
jumble(density = 5, strokes = NULL, step = NULL, curl = 0.35)
```

## Arguments

- density:

  Approximate scribble density. Larger values give more strokes.

- strokes:

  Approximate number of jumble strokes. When `NULL`, a default based on
  the shape size is used.

- step:

  Jumble step size in data units.

- curl:

  How tightly the jumble curls as it wanders. Larger values produce
  rounder, loopier scribbles.

## Value

A fill-pattern object for `draw_rough_*()` helpers and mypaint geoms.

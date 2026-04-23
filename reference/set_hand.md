# Set the active mypaintr hand-drawn geometry

Set the active mypaintr hand-drawn geometry

## Usage

``` r
set_hand(hand = NULL, type = c("both", "stroke", "fill"))
```

## Arguments

- hand:

  Hand-drawn geometry created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md),
  or `NULL` to disable it for the selected type. This disables rough
  path perturbation only; it does not disable the active brush, and note
  that some brushes have their own internal wobbly pathing! Use
  [`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)
  as well if you want fully plain, solid rendering.

- type:

  Which rendering channel to update: `"both"`, `"stroke"`, or `"fill"`.

## Value

`NULL`, invisibly. If the active graphics device is not
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md),
this emits a warning and has no effect.

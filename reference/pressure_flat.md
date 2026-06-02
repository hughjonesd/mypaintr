# Pressure profiles for hand-drawn strokes

Pressure profiles for hand-drawn strokes

## Usage

``` r
pressure_flat(value = 1)

pressure_smooth(value = 1, taper = 1, turn_taper = 0.35)

pressure_human(
  value = 1,
  taper = 0.6,
  start = 0.35,
  end = 0.55,
  peak = 0.45,
  turn_taper = 0.35
)

pressure_dashed(value = 1, pattern = c(24, 12))

pressure_dashed_smooth(value = 1, pattern = c(24, 12), taper = 1)
```

## Arguments

- value:

  Maximum pressure supplied to the brush, in the range `0` to `1`.

- taper:

  How strongly pressure changes over the stroke. `0` keeps the pressure
  flat; `1` applies the full profile shape.

- turn_taper:

  How strongly pressure is reduced at sharp turns.

- start, end:

  Relative pressure at the start and end of a human-style stroke when
  `taper = 1`.

- peak:

  Position of peak pressure along the stroke, in the range `0` to `1`.

- pattern:

  Alternating on/off dash lengths in device units. The default uses a
  2:1 on/off ratio like base R's dashed line, at a moderate brush-scale
  length.

## Value

A pressure-profile function for the `pressure` argument of
[`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md) and
[`human_hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).
Custom functions can also be supplied directly; they must accept `t`,
normalized stroke progress in the range `0` to `1`, `turn` in the range
`0` to `1`, and `length`, the total stroke length in device units.
`turn` describes local path curvature: `0` is straight, larger values
are sharper corners, and values near `1` are near reversals. Custom
functions must be vectorized over `t` and `turn`, and return either
length `1` or `length(t)`.

## Examples

``` r
plot.new()
plot.window(c(0, 10), c(0, 10))
draw_rough_lines(c(1, 9), c(8, 8), lwd = 5,
                 hand = hand(pressure = pressure_flat(0.5)))
draw_rough_lines(c(1, 9), c(5, 5), lwd = 5,
                 hand = hand(pressure = pressure_smooth()))
draw_rough_lines(c(1, 9), c(2, 2), lwd = 5,
                 hand = hand(pressure = pressure_human()))
```

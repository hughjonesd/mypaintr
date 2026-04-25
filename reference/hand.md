# Hand-drawn geometry settings

`human_hand()` is the same as `hand()`, but starts from the older
rougher defaults with bow, wobble, and width jitter already enabled.

## Usage

``` r
hand(
  seed = NULL,
  bow = 0,
  wobble = 0,
  multi_stroke = 1L,
  width_jitter = 0,
  endpoint_jitter = 0,
  pressure = 1,
  pressure_taper = 0
)

human_hand(
  seed = NULL,
  bow = 0.012,
  wobble = 0.008,
  multi_stroke = 1L,
  width_jitter = 0.08,
  endpoint_jitter = 0,
  pressure = 1,
  pressure_taper = 0
)
```

## Arguments

- seed:

  Optional random seed used for repeatable geometry.

- bow:

  Typical bowing of long strokes as a proportion of segment length.

- wobble:

  Low-frequency path wobble as a proportion of segment length.

- multi_stroke:

  Number of overdrawn strokes to use.

- width_jitter:

  Relative variation in line width between overdrawn strokes.

- endpoint_jitter:

  Relative endpoint jitter as a proportion of segment length.

- pressure:

  Base pressure to use for mypaint brush strokes.

- pressure_taper:

  Amount of tapering applied to pressure at the start and end of brush
  strokes. `0` means constant pressure; `1` means strong tapering.

## Value

An object describing how rough geometry should be generated.

An object describing how rough geometry should be generated.

## Details

`hand()` defaults to plain, base-R-like geometry with no bowing, wobble,
or jitter. `human_hand()` has different, more human-like defaults.

As of now, `pressure` and `pressure_taper` only apply to lines, not
shape outlines. On base R devices, they are simulated and affect line
width.

## Examples

``` r
plot.new()
plot.window(c(0, 10), c(0, 10))
draw_rough_lines(c(0, 10), c(8, 8), lwd = 4, hand = hand())
draw_rough_lines(c(0, 10), c(6, 6), lwd = 4, hand = human_hand())
draw_rough_lines(c(0, 10), c(4, 4), lwd = 4,
                 hand = human_hand(seed = 1,
                   bow = 0.02, wobble = 0.01))
draw_rough_lines(c(0, 10), c(2, 2), lwd = 4,
                 hand = human_hand(seed = 1,
                   pressure = 0.7, pressure_taper = 0.5))
```

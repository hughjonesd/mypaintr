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
  bow = 0.01,
  wobble = 0.006,
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

  Base pressure to use for mypaint brush strokes. Ignored on non-mypaint
  devices.

- pressure_taper:

  Amount of tapering applied to pressure at the start and end of mypaint
  brush strokes. `0` means constant pressure; `1` means strong tapering.
  Ignored on non-mypaint devices.

## Value

An object describing how rough geometry should be generated.

An object describing how rough geometry should be generated.

## Details

`hand()` defaults to plain, base-R-like geometry with no bowing, wobble,
or jitter. Use `human_hand()` for the older rougher defaults.

## Examples

``` r
hand()
#> $seed
#> NULL
#> 
#> $bow
#> [1] 0
#> 
#> $wobble
#> [1] 0
#> 
#> $multi_stroke
#> [1] 1
#> 
#> $width_jitter
#> [1] 0
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 1
#> 
#> $pressure_taper
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
human_hand()
#> $seed
#> NULL
#> 
#> $bow
#> [1] 0.01
#> 
#> $wobble
#> [1] 0.006
#> 
#> $multi_stroke
#> [1] 1
#> 
#> $width_jitter
#> [1] 0.08
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 1
#> 
#> $pressure_taper
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
human_hand(seed = 1, bow = 0.02, wobble = 0.01)
#> $seed
#> [1] 1
#> 
#> $bow
#> [1] 0.02
#> 
#> $wobble
#> [1] 0.01
#> 
#> $multi_stroke
#> [1] 1
#> 
#> $width_jitter
#> [1] 0.08
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 1
#> 
#> $pressure_taper
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
hand(pressure = 0.7, pressure_taper = 0.5)
#> $seed
#> NULL
#> 
#> $bow
#> [1] 0
#> 
#> $wobble
#> [1] 0
#> 
#> $multi_stroke
#> [1] 1
#> 
#> $width_jitter
#> [1] 0
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 0.7
#> 
#> $pressure_taper
#> [1] 0.5
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
human_hand()
#> $seed
#> NULL
#> 
#> $bow
#> [1] 0.01
#> 
#> $wobble
#> [1] 0.006
#> 
#> $multi_stroke
#> [1] 1
#> 
#> $width_jitter
#> [1] 0.08
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 1
#> 
#> $pressure_taper
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
human_hand(seed = 1, multi_stroke = 2)
#> $seed
#> [1] 1
#> 
#> $bow
#> [1] 0.01
#> 
#> $wobble
#> [1] 0.006
#> 
#> $multi_stroke
#> [1] 2
#> 
#> $width_jitter
#> [1] 0.08
#> 
#> $endpoint_jitter
#> [1] 0
#> 
#> $pressure
#> [1] 1
#> 
#> $pressure_taper
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
```

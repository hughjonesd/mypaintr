# Hand-drawn geometry settings

Hand-drawn geometry settings

## Usage

``` r
hand(
  seed = NULL,
  bow = 0.015,
  wobble = 0.006,
  multi_stroke = 1L,
  width_jitter = 0.08,
  endpoint_jitter = 0.01,
  hachure_gap = NULL,
  hachure_angle = 45,
  hachure_angle_jitter = 12,
  hachure_gap_jitter = 0.15,
  hachure_method = c("parallel", "cross")
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

- hachure_gap:

  Optional gap between hatch lines. When `NULL`, a default based on
  polygon size is used.

- hachure_angle:

  Base hatch angle in degrees.

- hachure_angle_jitter:

  Random angle variation for hatch passes.

- hachure_gap_jitter:

  Relative jitter in hatch spacing.

- hachure_method:

  Either `"parallel"` or `"cross"`.

## Value

An object describing how rough geometry should be generated.

## Examples

``` r
hand()
#> $seed
#> NULL
#> 
#> $bow
#> [1] 0.015
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
#> [1] 0.01
#> 
#> $hachure_gap
#> NULL
#> 
#> $hachure_angle
#> [1] 45
#> 
#> $hachure_angle_jitter
#> [1] 12
#> 
#> $hachure_gap_jitter
#> [1] 0.15
#> 
#> $hachure_method
#> [1] "parallel"
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
hand(seed = 1, bow = 0.02, wobble = 0.01)
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
#> [1] 0.01
#> 
#> $hachure_gap
#> NULL
#> 
#> $hachure_angle
#> [1] 45
#> 
#> $hachure_angle_jitter
#> [1] 12
#> 
#> $hachure_gap_jitter
#> [1] 0.15
#> 
#> $hachure_method
#> [1] "parallel"
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
```

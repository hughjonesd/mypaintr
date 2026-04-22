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
  endpoint_jitter = 0
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
#> [1] 0
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
#> [1] 0
#> 
#> attr(,"class")
#> [1] "mypaintr_hand"
```

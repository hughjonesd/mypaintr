# Create a reusable tweaked brush specification

Create a reusable tweaked brush specification

## Usage

``` r
tweak_brush(brush, ..., normalize = "all")
```

## Arguments

- brush:

  Installed brush name, `.myb` file path, JSON brush string, or another
  `tweak_brush()` object.

- ...:

  Named libmypaint base-value overrides.

- normalize:

  One of `"all"`, `"size"`, `"tracking"`, or `"none"`.

## Value

A reusable brush specification object.

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)

## Examples

``` r
if ("classic/pen" %in% brushes()) {
  tweak_brush("classic/pen", normalize = "tracking", radius_logarithmic = log(1.2))
}
#> $json
#> [1] "{\n    \"comment\": \"MyPaint brush file\", \n    \"description\": \"\", \n    \"group\": \"\", \n    \"notes\": \"\", \n    \"parent_brush_name\": \"classic/pen\", \n    \"settings\": {\n        \"anti_aliasing\": {\n            \"base_value\": 1.0, \n            \"inputs\": {}\n        }, \n        \"change_color_h\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"change_color_hsl_s\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"change_color_hsv_s\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"change_color_l\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"change_color_v\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"color_h\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"color_s\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"color_v\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"colorize\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"custom_input\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"custom_input_slowness\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"dabs_per_actual_radius\": {\n            \"base_value\": 2.2, \n            \"inputs\": {}\n        }, \n        \"dabs_per_basic_radius\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"dabs_per_second\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"direction_filter\": {\n            \"base_value\": 2.0, \n            \"inputs\": {}\n        }, \n        \"elliptical_dab_angle\": {\n            \"base_value\": 90.0, \n            \"inputs\": {}\n        }, \n        \"elliptical_dab_ratio\": {\n            \"base_value\": 1.0, \n            \"inputs\": {}\n        }, \n        \"eraser\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"hardness\": {\n            \"base_value\": 0.9, \n            \"inputs\": {\n                \"pressure\": [\n                    [\n                        0.0, \n                        0.0\n                    ], \n                    [\n                        1.0, \n                        0.05\n                    ]\n                ], \n                \"speed1\": [\n                    [\n                        0.0, \n                        -0.0\n                    ], \n                    [\n                        1.0, \n                        -0.09\n                    ]\n                ]\n            }\n        }, \n        \"lock_alpha\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"offset_by_random\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"offset_by_speed\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"offset_by_speed_slowness\": {\n            \"base_value\": 1.0, \n            \"inputs\": {}\n        }, \n        \"opaque\": {\n            \"base_value\": 1.0, \n            \"inputs\": {}\n        }, \n        \"opaque_linearize\": {\n            \"base_value\": 0.9, \n            \"inputs\": {}\n        }, \n        \"opaque_multiply\": {\n            \"base_value\": 0.0, \n            \"inputs\": {\n                \"pressure\": [\n                    [\n                        0.0, \n                        0.0\n                    ], \n                    [\n                        0.015, \n                        0.0\n                    ], \n                    [\n                        0.015, \n                        1.0\n                    ], \n                    [\n                        1.0, \n                        1.0\n                    ]\n                ]\n            }\n        }, \n        \"pressure_gain_log\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"radius_by_random\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"radius_logarithmic\": {\n            \"base_value\": 0.96, \n            \"inputs\": {\n                \"pressure\": [\n                    [\n                        0.0, \n                        0.0\n                    ], \n                    [\n                        1.0, \n                        0.5\n                    ]\n                ], \n                \"speed1\": [\n                    [\n                        0.0, \n                        -0.0\n                    ], \n                    [\n                        1.0, \n                        -0.15\n                    ]\n                ]\n            }\n        }, \n        \"restore_color\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"slow_tracking\": {\n            \"base_value\": 0.65, \n            \"inputs\": {}\n        }, \n        \"slow_tracking_per_dab\": {\n            \"base_value\": 0.8, \n            \"inputs\": {}\n        }, \n        \"smudge\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"smudge_length\": {\n            \"base_value\": 0.5, \n            \"inputs\": {}\n        }, \n        \"smudge_radius_log\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"snap_to_pixel\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"speed1_gamma\": {\n            \"base_value\": 2.87, \n            \"inputs\": {}\n        }, \n        \"speed1_slowness\": {\n            \"base_value\": 0.04, \n            \"inputs\": {}\n        }, \n        \"speed2_gamma\": {\n            \"base_value\": 4.0, \n            \"inputs\": {}\n        }, \n        \"speed2_slowness\": {\n            \"base_value\": 0.8, \n            \"inputs\": {}\n        }, \n        \"stroke_duration_logarithmic\": {\n            \"base_value\": 4.0, \n            \"inputs\": {}\n        }, \n        \"stroke_holdtime\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"stroke_threshold\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }, \n        \"tracking_noise\": {\n            \"base_value\": 0.0, \n            \"inputs\": {}\n        }\n    }, \n    \"version\": 3\n}"
#> 
#> $settings
#>         slow_tracking slow_tracking_per_dab    radius_logarithmic 
#>             0.0000000             0.0000000             0.1823216 
#> 
#> $source
#> [1] "/usr/local/lib/R/site-library/mypaintr/brushes/classic/pen.myb"
#> 
#> $normalize
#> [1] "tracking"
#> 
#> attr(,"class")
#> [1] "mypaintr_brush"
```

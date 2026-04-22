# libmypaint brush input metadata

libmypaint brush input metadata

## Usage

``` r
brush_inputs()
```

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md),
[`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md)

## Examples

``` r
head(brush_inputs())
#>       cname      hard_min soft_min normal soft_max     hard_max
#> 1  pressure  0.000000e+00        0    0.4        1 3.402823e+38
#> 2    speed1 -3.402823e+38        0    0.5        4 3.402823e+38
#> 3    speed2 -3.402823e+38        0    0.5        4 3.402823e+38
#> 4    random  0.000000e+00        0    0.5        1 1.000000e+00
#> 5    stroke  0.000000e+00        0    0.5        1 1.000000e+00
#> 6 direction  0.000000e+00        0    0.0      180 1.800000e+02
#>                                                                                                                                                                                                       tooltip
#> 1      The pressure reported by the tablet. Usually between 0.0 and 1.0, but it may get larger when a pressure gain is used. If you use the mouse, it will be 0.5 when a button is pressed and 0.0 otherwise.
#> 2          How fast you currently move. This can change very quickly. Try 'print input values' from the 'help' menu to get a feeling for the range; negative values are rare but possible for very low speed.
#> 3                                                                                                                      Same as fine speed, but changes slower. Also look at the 'gross speed filter' setting.
#> 4                                                                                                                         Fast random noise, changing at each evaluation. Evenly distributed between 0 and 1.
#> 5 This input slowly goes from zero to one while you draw a stroke. It can also be configured to jump back to zero periodically while you move. Look at the 'stroke duration' and 'stroke hold time' settings.
#> 6                                                                                  The angle of the stroke, in degrees. The value will stay between 0.0 and 180.0, effectively ignoring turns of 180 degrees.
```

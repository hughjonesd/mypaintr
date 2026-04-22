# libmypaint brush setting metadata

libmypaint brush setting metadata

## Usage

``` r
brush_settings()
```

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_presets()`](https://hughjonesd.github.io/mypaintr/reference/brush_presets.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)

## Examples

``` r
head(brush_settings())
#>                cname              name min default max constant
#> 1             opaque           Opacity   0     1.0   2    FALSE
#> 2    opaque_multiply  Opacity multiply   0     0.0   2    FALSE
#> 3   opaque_linearize Opacity linearize   0     0.9   2     TRUE
#> 4 radius_logarithmic            Radius  -2     2.0   6    FALSE
#> 5           hardness          Hardness   0     0.8   1    FALSE
#> 6      anti_aliasing     Pixel feather   0     1.0   5    FALSE
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 tooltip
#> 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                       0 means brush is transparent, 1 fully visible\n(also known as alpha or opacity)
#> 2                                                                                                                                                                                                                                                      This gets multiplied with opaque. You should only change the pressure input of this setting. Use 'opaque' instead to make opacity depend on speed.\nThis setting is responsible to stop painting when there is zero pressure. This is just a convention, the behaviour is identical to 'opaque'.
#> 3 Correct the nonlinearity introduced by blending multiple dabs on top of each other. This correction should get you a linear ("natural") pressure response when pressure is mapped to opaque_multiply, as it is usually done. 0.9 is good for standard strokes, set it smaller if your brush scatters a lot, or higher if you use dabs_per_second.\n0.0 the opaque value above is for the individual dabs\n1.0 the opaque value above is for the final brush stroke, assuming each pixel gets (dabs_per_radius*2) brushdabs on average during a stroke
#> 4                                                                                                                                                                                                                                                                                                                                                                                                                                                                           Basic brush radius (logarithmic)\n 0.7 means 2 pixels\n 3.0 means 20 pixels
#> 5                                                                                                                                                                                                                                                                                                                                                                                                                      Hard brush-circle borders (setting to zero will draw nothing). To reach the maximum hardness, you need to disable Pixel feather.
#> 6                                                                                                                                                                                                                                                                         This setting decreases the hardness when necessary to prevent a pixel staircase effect (aliasing) by making the dab more blurred.\n 0.0 disable (for very strong erasers and pixel brushes)\n 1.0 blur one pixel (good value)\n 5.0 notable blur, thin strokes will disappear
```

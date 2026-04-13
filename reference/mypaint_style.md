# Update the active mypaintr device style

Update the active mypaintr device style

## Usage

``` r
mypaint_style(
  brush = NULL,
  brush_settings = NULL,
  stroke_style = NULL,
  fill_style = NULL,
  fill_brush = NULL,
  fill_settings = NULL,
  auto_solid_bg = NULL
)
```

## Arguments

- brush:

  Stroke brush preset, JSON brush string, or named settings.

- brush_settings:

  Named settings overriding `brush`.

- stroke_style:

  Either `"brush"` or `"solid"`.

- fill_style:

  Either `"solid"` or `"brush"`.

- fill_brush:

  Fill brush preset, JSON brush string, or named settings.

- fill_settings:

  Named settings overriding `fill_brush`.

- auto_solid_bg:

  Whether large fills matching the device background should be drawn
  normally.

## Value

`NULL`, invisibly. If the active device is not `mypaintr`, the style
becomes the default for the next
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
opened in this R session.

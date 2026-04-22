# Set the active mypaintr brush

Set the active mypaintr brush

## Usage

``` r
set_brush(
  brush = NULL,
  type = c("both", "stroke", "fill"),
  auto_solid_bg = NULL
)
```

## Arguments

- brush:

  Brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed brush name, `.myb` file path, JSON brush string, or
  `NULL` to switch the selected type back to solid rendering.

- type:

  Which rendering channel to update: `"both"`, `"stroke"`, or `"fill"`.

- auto_solid_bg:

  Optional override for background-like fills.

## Value

`NULL`, invisibly. If the active device is not `mypaintr`, the selected
brush becomes the default for the next
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
opened in this R session.

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md)

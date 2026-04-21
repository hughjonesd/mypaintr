# Set the active mypaintr brush

Set the active mypaintr brush

## Usage

``` r
set_brush(
  brush = NULL,
  settings = NULL,
  type = c("both", "stroke", "fill"),
  auto_solid_bg = NULL
)
```

## Arguments

- brush:

  Brush preset, installed brush name, JSON brush string, named settings,
  or `NULL` to switch the selected type back to solid rendering.

- settings:

  Named settings overriding `brush`.

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
[`brush_presets()`](https://hughjonesd.github.io/mypaintr/reference/brush_presets.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md)

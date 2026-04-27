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

`NULL`, invisibly. If the active graphics device is not
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md),
this emits a warning and has no effect.

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md)

## Examples

``` r
ex_file <- tempfile(fileext = ".png")
mypaint_device(ex_file)

plot.new()
plot.window(c(0, 10), c(0, 10))
brushes <- c("classic/pen", "classic/charcoal", "classic/ink_blot",
             "ramon/2B_pencil")
for (idx in seq_along(brushes)) {
  set_brush(brushes[idx])
  lines(c(1, 9), c(2 * idx, 2 * idx), lwd = 2)
}

dev.off()
#> agg_record_3521ef842cd 
#>                      2 
img <- png::readPNG(ex_file)
#> Error in loadNamespace(x): there is no package called ‘png’
grid::grid.raster(img)
#> Error: object 'img' not found
```

# Load an installed mypaint brush

Load an installed mypaint brush

## Usage

``` r
load_brush(brush, paths = default_mypaint_brush_dirs())
```

## Arguments

- brush:

  Brush name like `"classic/pencil"` or a path to a `.myb` file.

- paths:

  Optional brush directories. Defaults to locally discovered
  `mypaint-brushes` locations.

## Value

A JSON brush string suitable for `mypaint_device(brush = ...)`.

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_presets()`](https://hughjonesd.github.io/mypaintr/reference/brush_presets.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`brushes()`](https://hughjonesd.github.io/mypaintr/reference/brushes.md),
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)

## Examples

``` r
if (length(brushes())) {
  x <- load_brush(brushes()[[1]])
  stopifnot(is.character(x), length(x) == 1L)
}
```

# List installed mypaint brushes

List installed mypaint brushes

## Usage

``` r
brushes(paths = default_mypaint_brush_dirs())
```

## Arguments

- paths:

  Optional brush directories. Defaults to locally discovered
  `mypaint-brushes` locations.

## Value

A character vector of brush names, relative to the brush root.

## See also

Other brush management:
[`brush_dirs()`](https://hughjonesd.github.io/mypaintr/reference/brush_dirs.md),
[`brush_inputs()`](https://hughjonesd.github.io/mypaintr/reference/brush_inputs.md),
[`brush_presets()`](https://hughjonesd.github.io/mypaintr/reference/brush_presets.md),
[`brush_settings()`](https://hughjonesd.github.io/mypaintr/reference/brush_settings.md),
[`load_brush()`](https://hughjonesd.github.io/mypaintr/reference/load_brush.md),
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)

## Examples

``` r
head(brushes())
#> [1] "Dieterle/8B_Pencil#1" "Dieterle/Blender"     "Dieterle/Dissolver"  
#> [4] "Dieterle/Eraser"      "Dieterle/Fan#1"       "Dieterle/Flat2#1"    
```

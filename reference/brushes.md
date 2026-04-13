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

## Examples

``` r
head(brushes())
#> [1] "Dieterle/8B_Pencil#1" "Dieterle/Blender"     "Dieterle/Dissolver"  
#> [4] "Dieterle/Eraser"      "Dieterle/Fan#1"       "Dieterle/Flat2#1"    
```

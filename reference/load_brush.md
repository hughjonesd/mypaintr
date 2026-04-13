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

## Examples

``` r
if (length(brushes())) {
  x <- load_brush(brushes()[[1]])
  stopifnot(is.character(x), length(x) == 1L)
}
```

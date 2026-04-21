# Wrap a grid grob or ggplot layer with scoped mypaint styling

`mypaint_wrap()` applies temporary mypaintr brush and hand settings
while the wrapped object is drawn, then restores the previous device
style. It can wrap either a grid grob or a ggplot2 layer. This makes it
useful both for direct
[`grid::grid.draw()`](https://rdrr.io/r/grid/grid.draw.html) workflows
and for ggplot calls such as
`ggplot(...) + mypaint_wrap(geom_line(...), ...)`.

## Usage

``` r
mypaint_wrap(
  object,
  brush = NULL,
  brush_settings = NULL,
  fill_brush = NULL,
  fill_settings = NULL,
  hand = NULL,
  stroke_hand = hand,
  fill_hand = hand,
  auto_solid_bg = NULL
)
```

## Arguments

- object:

  A grid grob or a ggplot2 layer object.

- brush:

  Stroke brush preset, installed brush name, JSON brush string, named
  settings, or `NULL` for solid strokes.

- brush_settings:

  Named settings overriding `brush`.

- fill_brush:

  Fill brush preset, installed brush name, JSON brush string, named
  settings, or `NULL` for solid fills.

- fill_settings:

  Named settings overriding `fill_brush`.

- hand:

  Optional hand-drawn geometry applied to both stroke and fill by
  default.

- stroke_hand:

  Optional hand-drawn geometry for strokes.

- fill_hand:

  Optional hand-drawn geometry for fills.

- auto_solid_bg:

  Optional override for background-like fills.

## Value

An object of the same general kind as `object`: a wrapped grob for grid
inputs or a wrapped layer for ggplot2 inputs.

## Examples

``` r
line <- grid::linesGrob(c(0.1, 0.9), c(0.2, 0.8))
wrapped <- mypaint_wrap(line, brush = "ink", hand = hand())

if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    mypaint_wrap(ggplot2::geom_line(), brush = "ink", hand = hand())
}
```

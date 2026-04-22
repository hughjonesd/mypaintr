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
  fill_brush = NULL,
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

  Stroke brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed mypaint brush name, `.myb` file path, JSON brush string,
  or `NULL` for solid strokes.

- fill_brush:

  Fill brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed mypaint brush name, `.myb` file path, JSON brush string,
  or `NULL` for solid fills.

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
if ("classic/pen" %in% brushes()) {
  wrapped <- mypaint_wrap(line, brush = "classic/pen", hand = hand())
}

if (requireNamespace("ggplot2", quietly = TRUE) &&
    "classic/pen" %in% brushes()) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    mypaint_wrap(ggplot2::geom_line(), brush = "classic/pen", hand = hand())
}
```

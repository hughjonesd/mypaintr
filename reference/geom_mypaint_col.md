# Draw rough, brush-rendered columns in ggplot2

This geom owns both the bar outline and the hatch fill, so the shading
lines follow the same rough outline rather than the underlying true
rectangle.

## Usage

``` r
geom_mypaint_col(
  mapping = NULL,
  data = NULL,
  position = "stack",
  ...,
  just = 0.5,
  lineend = "butt",
  linejoin = "mitre",
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE,
  fill_pattern = NULL,
  brush = NULL,
  fill_brush = NULL,
  hand = NULL,
  stroke_hand = hand,
  fill_hand = hand,
  auto_solid_bg = NULL
)
```

## Arguments

- mapping, data, position, just, lineend, linejoin, na.rm, show.legend,
  inherit.aes:

  As for
  [`ggplot2::geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html).

- ...:

  Other arguments passed to
  [`ggplot2::layer()`](https://ggplot2.tidyverse.org/reference/layer.html).

- fill_pattern:

  Optional fill pattern created with
  [`hatch()`](https://hughjonesd.github.io/mypaintr/reference/hatch.md),
  [`crosshatch()`](https://hughjonesd.github.io/mypaintr/reference/crosshatch.md),
  [`zigzag()`](https://hughjonesd.github.io/mypaintr/reference/zigzag.md),
  or
  [`jumble()`](https://hughjonesd.github.io/mypaintr/reference/jumble.md).

- brush:

  Stroke brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed mypaint brush name, `.myb` file path, JSON brush string,
  or `NULL` for solid borders.

- fill_brush:

  Fill brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed mypaint brush name, `.myb` file path, JSON brush string,
  or `NULL` for solid fills.

- hand:

  Optional hand-drawn geometry applied to both outline and hatch by
  default.

- stroke_hand:

  Optional hand-drawn geometry for the outline.

- fill_hand:

  Optional hand-drawn geometry for the hatch strokes.

- auto_solid_bg:

  Reserved for future parity with device-level style controls.

## Value

A ggplot layer.

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
    geom_mypaint_bar(fill_pattern = hatch())
}
```

# Draw rough, brush-rendered bars in ggplot2

Draw rough, brush-rendered bars in ggplot2

## Usage

``` r
geom_mypaint_bar(
  mapping = NULL,
  data = NULL,
  stat = "count",
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

- mapping, data, position, just, lineend, linejoin, na.rm, show.legend,
  inherit.aes:

  As for
  [`ggplot2::geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html).

- stat:

  The statistical transformation to use. Defaults to `"count"`.

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
  When omitted, bars use a simple hatch fill by default.

- brush, brush_settings:

  Stroke brush spec and overrides.

- fill_brush, fill_settings:

  Fill-hatch brush spec and overrides.

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

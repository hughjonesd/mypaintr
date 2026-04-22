# Theme rectangle element with scoped mypaint rendering

Uses the current `mypaint` device for drawing, but temporarily overrides
the stroke and fill settings while the rectangle is drawn. This is
useful for panel backgrounds, panel borders, and legend keys in ggplot2
themes.

## Usage

``` r
element_mypaint_rect(
  brush = NULL,
  fill_brush = NULL,
  hand = NULL,
  stroke_hand = hand,
  fill_hand = hand,
  auto_solid_bg = NULL,
  fill = NULL,
  colour = NULL,
  linewidth = NULL,
  linetype = NULL,
  color = NULL,
  linejoin = NULL,
  inherit.blank = FALSE,
  size = NULL,
  ...
)
```

## Arguments

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

  Optional hand-drawn geometry applied to both stroke and fill by
  default.

- stroke_hand:

  Optional hand-drawn geometry for the border.

- fill_hand:

  Optional hand-drawn geometry for the fill.

- auto_solid_bg:

  Optional override for background-like fills.

- fill, colour, color, linewidth, linetype, linejoin, inherit.blank,
  size, ...:

  Passed through to
  [`ggplot2::element_rect()`](https://ggplot2.tidyverse.org/reference/element.html).

## Value

A ggplot theme element.

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::theme(panel.background = element_mypaint_rect())
}
#> <theme> List of 1
#>  $ panel.background: <mypaintr_element_rect>
#>   ..@ fill         : NULL
#>   ..@ colour       : NULL
#>   ..@ linewidth    : NULL
#>   ..@ linetype     : NULL
#>   ..@ linejoin     : NULL
#>   ..@ inherit.blank: logi FALSE
#>  @ complete: logi FALSE
#>  @ validate: logi TRUE
```

# Theme line element with scoped mypaint rendering

Uses the current `mypaint` device for drawing, but temporarily overrides
the stroke settings while the theme line is drawn. This is useful for
keeping axes, ticks, or panel grid lines solid while data layers use
rough or brush rendering.

## Usage

``` r
element_mypaint_line(
  brush = NULL,
  hand = NULL,
  colour = NULL,
  linewidth = NULL,
  linetype = NULL,
  lineend = NULL,
  color = NULL,
  linejoin = NULL,
  arrow = FALSE,
  arrow.fill = NULL,
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
  or `NULL` for solid strokes.

- hand:

  Optional hand-drawn geometry created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md).

- colour, color, linewidth, linetype, lineend, linejoin, arrow,
  arrow.fill, inherit.blank, size, ...:

  Passed through to
  [`ggplot2::element_line()`](https://ggplot2.tidyverse.org/reference/element.html).

## Value

A ggplot theme element.

## Examples

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::theme(axis.line = element_mypaint_line())
}
#> <theme> List of 1
#>  $ axis.line: <mypaintr_element_line>
#>   ..@ colour       : NULL
#>   ..@ linewidth    : NULL
#>   ..@ linetype     : NULL
#>   ..@ lineend      : NULL
#>   ..@ linejoin     : NULL
#>   ..@ arrow        : logi FALSE
#>   ..@ arrow.fill   : NULL
#>   ..@ inherit.blank: logi FALSE
#>  @ complete: logi FALSE
#>  @ validate: logi TRUE
```

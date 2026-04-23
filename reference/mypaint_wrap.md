# Wrap a grid grob, ggplot layer, or ggplot theme element with scoped mypaint styling

`mypaint_wrap()` applies temporary mypaintr brush and hand settings
while the wrapped object is drawn, then restores the previous device
style. It can wrap grid grobs, ggplot2 layers, and ggplot2 theme
elements. This makes it useful for direct
[`grid::grid.draw()`](https://rdrr.io/r/grid/grid.draw.html) workflows,
for ggplot calls such as
`ggplot(...) + mypaint_wrap(geom_line(...), ...)`, and for theme
elements such as
`theme(panel.grid = mypaint_wrap(element_line(), ...))`.

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

  A grid grob, ggplot2 layer, or ggplot2 theme element.

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

An object of the same general kind as `object`.

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

  ggplot2::theme(
    panel.grid = mypaint_wrap(ggplot2::element_line(), brush = "classic/pen")
  )
}
#> <theme> List of 1
#>  $ panel.grid: <mypaintr_element_line>
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

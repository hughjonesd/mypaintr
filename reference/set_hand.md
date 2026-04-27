# Set the active hand

Set the active hand

## Usage

``` r
set_hand(hand = NULL, type = c("both", "stroke", "fill"))
```

## Arguments

- hand:

  Hand-drawn geometry created with
  [`hand()`](https://hughjonesd.github.io/mypaintr/reference/hand.md),
  or `NULL` to disable it for the selected type. This disables rough
  path perturbation only; it does not disable the active brush, and note
  that some brushes have their own internal wobbly pathing! Use
  [`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)
  as well if you want fully plain, solid rendering.

- type:

  Which rendering channel to update: `"both"`, `"stroke"`, or `"fill"`.

## Value

`NULL`, invisibly. If the active graphics device is not
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md),
this emits a warning and has no effect.

## Examples

``` r
ex_file <- tempfile(fileext = ".png")
mypaint_device(ex_file)

plot.new()
plot.window(c(0, 10), c(0, 10))
set_hand(hand())
rect(1, 1, 5, 5, col = "darkred", density = 5)
set_hand(human_hand())
rect(5, 5, 9, 9, col = "darkgreen", density = 5)

dev.off()
#> agg_record_35259e04d7a 
#>                      2 
img <- png::readPNG(ex_file)
#> Error in loadNamespace(x): there is no package called ‘png’
grid::grid.raster(img)
#> Error: object 'img' not found
```

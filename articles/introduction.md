# Introduction to mypaintr

mypaintr is a package for creating artistic sketch-like plots in R. It
has three components:

- An R interface to the
  [libmypaint](https://github.com/mypaint/libmypaint) library, which
  lets you create and import Mypaint brushes. There’s a
  [`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
  graphics device.
- R functions to draw lines and shapes with a “rough”, hand-drawn look.
- ggplot2 geoms and theme elements, so you can use Mypaint brushes and
  hand-drawn paths in ggplot graphs

Here are some demos.

``` r
library(mypaintr)
knitr::knit_hooks$set(mypaint = knitr_mypaint_hook())

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.ext = "png",
  fig.width = 5
)
```

To use mypaintr from the command line, open the
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
graphics device:

``` r
mypaint_device("output.png")
```

And close the device with
[`dev.off()`](https://rdrr.io/r/grDevices/dev.html) to print your plot
to the output file:

``` r
dev.off()
```

## Brushes

With the device active, you can use normal plot, grid and ggplot
commands. You can also customize how lines and fills are drawn, using
brushes.

Brushes are from the `mypaint-brushes` package, which you can install
via your package manager (e.g. `apt` or `brew`).

``` r

set_brush("tanda/marker-01")
barplot(VADeaths, beside = TRUE, col = NA, cex.names = 0.8)
```

![](introduction_files/figure-html/unnamed-chunk-1-1.png)

If you want different plot elements to look different, you can use
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md)
between calls. Here we set the brush to `NULL` to print an axis using
(close to) standard R graphics:

``` r

set_brush("experimental/bubble")
barplot(VADeaths, axes = FALSE, 
        beside = TRUE, col = palette.colors(5), border = NA,
        cex.names = 0.8)
set_brush(NULL)
axis(side = 2, at = seq(0, 60, 20))
```

![](introduction_files/figure-html/unnamed-chunk-2-1.png)

## Hands

The other way to customize plotting is to set the “hand”. While brushes
change what is plotted along a given path, hands change the path itself,
by adding jitter, multiple lines and other human-like quirks:

``` r
set_hand(hand(bow = 0.03, wobble = 0))
barplot(VADeaths, beside = TRUE, col = NA, cex.names = 0.8)
```

![](introduction_files/figure-html/unnamed-chunk-3-1.png)

``` r
set_hand(hand(bow = 0, wobble = 0.01, multi_stroke = 2))
barplot(VADeaths, beside = TRUE, col = NA, cex.names = 0.8)
```

![](introduction_files/figure-html/unnamed-chunk-4-1.png)

Combining brushes and hands, you can turn any R graphics into a sketch.

``` r

set_brush("experimental/bubble")
set_hand(hand(seed = 1))
filled.contour(volcano, asp = 1, plot.title = "Maunga Whau",
               xlab = "Metres North", ylab = "Metres West") 
```

![](introduction_files/figure-html/unnamed-chunk-5-1.png)

## Rough lines and polygons

There is one glitch with the mypaint_device:as you may have spotted,
borders and fills don’t always match up. Below, both rectangle border
and fills are plotted roughly, but the random roughness is computed
separately for each of them.

``` r


set_hand(hand(seed = 1))
plot(1:10, 1:10, type = "n")
rect(2, 2, 8, 8, col = "green4", border = "black")
```

![](introduction_files/figure-html/unnamed-chunk-6-1.png)

The `draw_rough_*` functions do two useful things:

- They always fill roughly drawn shapes correctly.
- They can be used with any graphics device,

However, note that while hands can work with any graphics device,
mypaint brushes can only be used with the
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
graphics device.

The next chunks use knitr’s standard `"png"` device.

``` r
knitr::opts_chunk$get("dev")
#> [1] "ragg_png"

plot(1:10, 1:10, type = "n")
draw_rough_polygons(c(2, 4, 6), c(4, 2, 6), col = "red")
draw_rough_rect(8, 4, 5, 8, col = "blue3", fill_pattern = hatch())

draw_rough_arrows(1, 9, 8, 9, col = "grey40")
```

![](introduction_files/figure-html/unnamed-chunk-7-1.png)

Control lines and fills with the `hand` argument:

``` r

plot(1:10, 1:10, type = "n")

my_hand <- hand(wobble = 0.01, multi_stroke = 2)
draw_rough_polygons(c(2, 4, 6), c(4, 2, 6), col = "red", hand = my_hand)
draw_rough_rect(8, 4, 5, 8, col = "blue3", hand = my_hand, fill_pattern = hatch())

draw_rough_arrows(1, 9, 8, 9, col = "grey40", hand = my_hand)
```

![](introduction_files/figure-html/unnamed-chunk-8-1.png)

``` r

plot(c(0.01, 0.11), c(0.01, 0.11), type = "n", 
     xlab = "bow", ylab = "wobble", 
     mar = rep(0.1, 4))

for (wobble in 1:5 * 0.02) for (bow in 1:5 * 0.02) {
  my_hand <- hand(wobble = wobble, bow = bow)
  draw_rough_rect(
    bow - 0.008, wobble - 0.008,
    bow + 0.008, wobble + 0.008,
    hand = my_hand,
    col = "red"
  )
}
```

![](introduction_files/figure-html/unnamed-chunk-9-1.png)

## Fills

Use the `fill_pattern` argument to fill a polygon using hand-sketched
lines. mypaintr knows four ways to do this. Again, these work with base
graphics devices via the `draw_rough_*` functions:

``` r

plot(0:10, 0:10, type = "n")

draw_rough_rect(0, 1, 4, 5, col = "blue", fill_pattern = hatch())
draw_rough_rect(0, 6, 4, 10, col = "green4", fill_pattern = crosshatch())
draw_rough_rect(6, 1, 10, 5, col = "red3", fill_pattern = zigzag())
draw_rough_rect(6, 6, 10, 10, col = "grey30", fill_pattern = jumble())
text(c(2, 2, 8, 8), c(0.5, 5.5, 0.5, 5.5), 
     labels = c("hatch", "crosshatch", "zigzag", "jumble"))
```

![](introduction_files/figure-html/unnamed-chunk-10-1.png)

## Rough drawing and `mypaint_device`

You can still use the `draw_rough_*` functions with `mypaint_device`
active. This lets you use both hands and brushes.

The next chunk also shows how to use different brushes for stroke and
fill:

``` r

plot(1:10, 1:10, type = "n")

set_brush("experimental/bubble", type = "fill")
set_brush(NULL, type = "stroke")
my_hand <- hand(wobble = 0.01, multi_stroke = 2)

draw_rough_polygons(c(2, 4, 6), c(4, 2, 6), col = "red", hand = my_hand)

set_brush("deevad/ballpen")
draw_rough_rect(8, 4, 5, 8, col = "blue3", hand = my_hand, fill_pattern = hatch())

draw_rough_arrows(1, 9, 8, 9, col = "grey40", hand = my_hand)
```

![](introduction_files/figure-html/unnamed-chunk-11-1.png)

## ggplot2

You can use ggplot2 with a mypaint output device:

``` r

library(ggplot2)

# At the console, do this:
# mypaint_device("output.png")
set_hand(hand())
set_brush("experimental/bubble")

ggplot(diamonds) + 
  geom_bar(aes(cut, fill = cut)) + 
   theme_minimal() 
```

![](introduction_files/figure-html/unnamed-chunk-12-1.png)

This is fine, but we can do better:

- We probably don’t want a special brush to render the white plot
  background rectangle.
- We might want to have some “normal” elements mixed in with the sketch
  elements.

mypaintr provides
[`element_mypaint_line()`](https://hughjonesd.github.io/mypaintr/reference/element_mypaint_line.md),
[`element_mypaint_rect()`](https://hughjonesd.github.io/mypaintr/reference/element_mypaint_rect.md),
[`geom_mypaint_bar()`](https://hughjonesd.github.io/mypaintr/reference/geom_mypaint_bar.md),
[`geom_mypaint_col()`](https://hughjonesd.github.io/mypaintr/reference/geom_mypaint_col.md)
to modify the brush and hand used for individual plot elements. By
default these will use “normal” drawing.

Here’s the same picture as above but with a clean background and
straight grid lines:

``` r

set_hand(hand())
set_brush("experimental/bubble")

ggplot(diamonds) + 
  geom_bar(aes(cut, fill = cut)) + 
   theme_minimal() +
   theme(
     # fill=NULL and hand=NULL by default, i.e. no special effects
     plot.background = element_mypaint_rect(fill = "white"),
     # the same
     panel.grid = element_mypaint_line()
   )
```

![](introduction_files/figure-html/unnamed-chunk-13-1.png)

Or you can go the other way and only set `hand` and `brush` inside
[`geom_mypaint_bar()`](https://hughjonesd.github.io/mypaintr/reference/geom_mypaint_bar.md):

``` r


ggplot(diamonds) + 
  geom_mypaint_bar(aes(cut, fill = cut, colour = cut), 
                   brush = "deevad/ballpen",
                   fill_pattern = zigzag(density = 12),
                   hand = hand(multi_stroke = 2)) + 
   theme_minimal() 
```

![](introduction_files/figure-html/unnamed-chunk-14-1.png)

Some more fancy examples:

``` r

set_brush("experimental/hard_blot", type = "fill")
ggplot(diamonds) + 
  geom_violin(aes(cut, price, fill = cut, colour = cut)) +
  theme_minimal() +
  theme(
    panel.grid = element_mypaint_line()
  )
```

![](introduction_files/figure-html/unnamed-chunk-15-1.png)

## Using mypaintr in knitr

Knitr replays graphics on its own device. To make this work while
dynamically updating the device within chunks, you must install a
special hook:

``` r
knitr::knit_hooks$set(mypaint = knitr_mypaint_hook())
```

Then in chunks where you use `mypaint_device`, you need to set chunk
options `mypaint=TRUE, fig.keep="none"`.

Don’t set `dev` explicitly: the hook will do it for you.

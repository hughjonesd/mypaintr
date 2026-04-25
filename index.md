# mypaintr

mypaintr is an R package that lets you plot graphics in a human-like,
sketched way, using brushes from the
[libmypaint](https://github.com/mypaint/libmypaint) library and
algorithms for “rough” lines and polygons.

Installation:

``` r
# install.packages("pak")
pak::pak("hughjonesd/mypaintr")
```

A base R barplot using a custom brush, plus a hand-drawn axis:

``` r
library(mypaintr)

# on the command line, do: 
# mypaint_device("output.png")

set_brush("tanda/acrylic-05-paint")
barplot(VADeaths, axes = FALSE, 
        beside = TRUE, col = palette.colors(5), border = NA,
        cex.names = 0.8)

set_brush(NULL)
set_hand(hand(wobble = 0))
axis(side = 2, at = seq(0, 60, 20))

# dev.off()
```

![](reference/figures/README-unnamed-chunk-2-1.png)

A ggplot using a custom element:

``` r
library(ggplot2)
#> Warning: package 'ggplot2' was built under R version 4.5.2

ggplot(diamonds) +
  mypaint_wrap(
    geom_bar(aes(cut, fill = cut)),
    brush = "experimental/bubble"
  ) +
  theme_minimal() 

# ggsave("output.png", device = mypaint_device)
```

![](reference/figures/README-unnamed-chunk-3-1.png)

Sketchy lines using the ordinary base R device:

``` r

plot(1:10, 1:10, type = "n", xlab = "", ylab = "", axes = FALSE)

draw_rough_polygons(5 + 3 * sin(2*pi * 1:5/5), 5 + 3 * cos(2*pi * 1:5/5),
                    border = "darkred", col = "red3", lwd = 2,
                    hand = hand(seed = 1, multi_stroke = 3),
                    fill_pattern = crosshatch())

draw_rough_arrows(8, 8.5, 5.5, 5.5, lwd = 2, hand = hand(seed = 1, bow = 0.05))
text(8, 9, "A pentagon", family = "Chalkboard")
```

![](reference/figures/README-unnamed-chunk-4-1.png)

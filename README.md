# mypaintr

`mypaintr` is an R package that opens a raster graphics device backed by
`libmypaint` for strokes and Cairo for text and solid fills.

Current state:

- Base graphics primitives such as lines, rectangles, polygons, circles and text work.
- Stroke rendering uses `libmypaint` brush settings, so preset and custom brushes affect the output.
- Fill rendering supports either solid Cairo fills or brush-hatched fills.
- The device writes PNG files and supports multi-page output through filenames containing `%d`.

Limitations in this first version:

- Dashed line types are not yet honoured.
- Text is rendered by Cairo rather than `libmypaint`.
- Complex path fills with `fill_style = "brush"` fall back to solid filling unless the path is a single polygon.

Example:

```r
library(mypaintr)

mypaint_device(
  "sketch-%d.png",
  brush = "chalk",
  fill_style = "brush"
)

plot(1:10, col = "grey30", pch = 16, cex = 1.4)
polygon(c(2, 5, 8, 6, 3), c(2, 7, 6, 3, 1.5),
        border = "black", col = rgb(0.2, 0.7, 0.5, 0.6))
lines(1:10, col = "firebrick", lwd = 4)
title("chalk")
dev.off()
```

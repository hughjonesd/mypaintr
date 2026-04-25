# Open a libmypaint-backed graphics device

Open a libmypaint-backed graphics device

## Usage

``` r
mypaint_device(
  filename = NULL,
  file = NULL,
  width = 7,
  height = 7,
  res = 144,
  pointsize = 12,
  bg = "white",
  brush = NULL,
  stroke_style = NULL,
  fill_style = NULL,
  fill_brush = NULL,
  hand = NULL,
  stroke_hand = NULL,
  fill_hand = NULL,
  auto_solid_bg = TRUE
)
```

## Arguments

- filename:

  Output PNG filename. If it contains `\%d`, pages are numbered.

- file:

  Deprecated compatibility alias for `filename`.

- width, height:

  Device size in inches.

- res:

  Resolution in pixels per inch.

- pointsize:

  Base pointsize.

- bg:

  Background colour.

- brush:

  Stroke brush specification created with
  [`tweak_brush()`](https://hughjonesd.github.io/mypaintr/reference/tweak_brush.md),
  an installed mypaint brush name, `.myb` file path, JSON brush string,
  or `NULL` for solid strokes. If omitted, `mypaint_device()` uses an
  internal default plotting brush.

- stroke_style:

  Legacy override for whether stroke drawing uses the brush backend or
  solid Cairo rendering. When `NULL`, this is inferred from whether
  `brush` is `NULL`.

- fill_style:

  Legacy override for whether fill drawing uses the brush backend or
  solid Cairo rendering. When `NULL`, this is inferred from whether
  `fill_brush` is `NULL`.

- fill_brush:

  Optional fill brush spec. Defaults to `brush` when not supplied. Use
  explicit `NULL` for solid fills.

- hand:

  Optional hand-drawn geometry spec applied to both stroke and fill
  primitives by default.

- stroke_hand:

  Optional hand-drawn geometry spec for strokes.

- fill_hand:

  Optional hand-drawn geometry spec for fills.

- auto_solid_bg:

  Draw large fills that match the device background using normal Cairo
  rendering even when `fill_style = "brush"`.

## Value

Opens a graphics device and returns `NULL` invisibly.

## Examples

``` r
out <- tempfile("mypaint-basic-", fileext = "-%d.png")
mypaint_device(out, width = 4, height = 3, bg = "ivory")
plot(
  1:10,
  col = "steelblue",
  pch = 16,
  cex = 1.4,
  main = "Ink Lines"
)
lines(1:10, col = "firebrick", lwd = 3)
rect(2, 3, 5, 7, border = "black", col = rgb(0, 0.6, 0.3, 0.25))
text(6, 8, "hello", col = "black")
dev.off()
#> agg_record_3521daf26a0 
#>                      2 
unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))

if ("classic/pen" %in% brushes()) {
  out <- tempfile("mypaint-brush-", fileext = "-%d.png")
  mypaint_device(
    out,
    width = 4,
    height = 3,
    brush = tweak_brush("classic/pen", tracking_noise = 0.12),
    fill_style = "brush",
    fill_brush = tweak_brush("classic/pen", normalize = "size", radius_by_random = 0.08)
  )
  plot.new()
  plot.window(xlim = c(0, 10), ylim = c(0, 10))
  polygon(
    c(2, 5, 8, 6, 3),
    c(2, 7, 6, 3, 1.5),
    border = "black",
    col = rgb(0.2, 0.7, 0.5, 0.6)
  )
  lines(c(1, 9), c(1, 9), col = "firebrick", lwd = 4)
  title("Brush Fill")
  box()
  dev.off()
  unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
}

out <- tempfile("mypaint-mixed-", fileext = "-%d.png")
mypaint_device(out, width = 4, height = 3, brush = NULL)
plot(1:5, 1:5, type = "n", main = "Mixed Styles")
if ("classic/pencil" %in% brushes()) {
  set_brush("classic/pencil", type = "stroke")
}
lines(1:5, c(1, 3, 2, 5, 4), lwd = 3)
dev.off()
#> agg_record_3521daf26a0 
#>                      2 
unlink(Sys.glob(sub("%d", "*", out, fixed = TRUE)))
```

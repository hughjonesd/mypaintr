# Open a libmypaint-backed graphics device

Open a libmypaint-backed graphics device

## Usage

``` r
mypaint_device(
  filename = NULL,
  width = 7,
  height = 7,
  res = 144,
  pointsize = 12,
  bg = "white",
  brush = NULL,
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
out <- tempfile("mypaint.png")
mypaint_device(out, width = 4, height = 3, bg = "ivory")
try(set_brush("classic/pen"), silent = TRUE)
plot(
  1:10,
  col = "steelblue",
  pch = 16,
  cex = 1.4
)
dev.off()
#> agg_record_352296c4fe0 
#>                      2 
unlink(out)
```

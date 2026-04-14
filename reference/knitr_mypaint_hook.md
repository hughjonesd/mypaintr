# Create a knitr chunk hook for live mypaint rendering

The returned hook opens
[`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
before chunk evaluation and injects the generated PNG files afterward.
This avoids knitr's normal plot replay path, which does not preserve
device-local style changes such as
[`set_hand()`](https://hughjonesd.github.io/mypaintr/reference/set_hand.md)
and
[`set_brush()`](https://hughjonesd.github.io/mypaintr/reference/set_brush.md).

## Usage

``` r
knitr_mypaint_hook(...)
```

## Arguments

- ...:

  Default arguments passed through to
  [`mypaint_device()`](https://hughjonesd.github.io/mypaintr/reference/mypaint_device.md)
  when the hook opens a device. Chunk-specific overrides can be supplied
  in the chunk option `mypaint.args` as a named list.

## Value

A function suitable for `knitr::knit_hooks$set()`.

## Details

Register it with
`knitr::knit_hooks$set(mypaint = knitr_mypaint_hook(...))` and then
enable it for chunks with `mypaint = TRUE`. Chunks should also set
`fig.keep = "none"` and `fig.ext = "png"`. If a chunk explicitly sets
`dev=`, the hook is skipped and knitr's normal device handling is used.

## Examples

``` r
if (requireNamespace("knitr", quietly = TRUE)) {
  hook <- knitr_mypaint_hook(brush = "deevad/2B_pencil")
  print(is.function(hook))
}
#> [1] TRUE
```

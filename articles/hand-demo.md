# Hand demo

``` r
plot_with_hand(NULL)
```

![](hand-demo_files/figure-html/unnamed-chunk-2-1.png)

``` r
plot_with_hand()
```

![](hand-demo_files/figure-html/unnamed-chunk-3-1.png)

``` r
plot_with_hand(bow = 0)
```

![](hand-demo_files/figure-html/unnamed-chunk-4-1.png)

``` r
plot_with_hand(wobble = 0)
```

![](hand-demo_files/figure-html/unnamed-chunk-5-1.png)

``` r
plot_with_hand(multi_stroke = 2)
```

![](hand-demo_files/figure-html/unnamed-chunk-6-1.png)

``` r
plot_with_hand(width_jitter = 0.24, multi_stroke = 2)
```

![](hand-demo_files/figure-html/unnamed-chunk-7-1.png)

``` r
plot_with_hand(endpoint_jitter = 0)
```

![](hand-demo_files/figure-html/unnamed-chunk-8-1.png)

``` r
plot_with_hand(endpoint_jitter = 0.02)
```

![](hand-demo_files/figure-html/unnamed-chunk-9-1.png)

## Pressure using `mypaint_device`

``` r
set_brush("classic/pen")
plot_with_hand(pressure = 0.5)
```

![](hand-demo_files/figure-html/unnamed-chunk-10-1.png)

``` r
set_brush("classic/pen")
plot_with_hand(pressure_taper = 1)
```

![](hand-demo_files/figure-html/unnamed-chunk-11-1.png)

# Brush gallery

``` r

do_plot <- function(brush) {
  brush <- load_brush(brush, normalize = "all")
  set_brush(brush)
  rect(1, 1, 5, 5, col = "orange", border = NA)
  rect(5, 5, 9, 9, col = "pink", border = NA)
  lines(c(0, 6), c(0, 6), col = "darkblue")
  lines(c(1, 7), c(0, 6), col = "red3")
  draw_rough_rect(1, 5, 5, 9, hand = hand(), fill_pattern = zigzag(),
                  col = "darkgreen", border = "grey30")
}
```

![](brush-gallery_files/brushes/brush-1.png)

`classic/blend+paint`

![](brush-gallery_files/brushes/brush-2.png)

`classic/blending_knife`

![](brush-gallery_files/brushes/brush-3.png)

`classic/blur`

![](brush-gallery_files/brushes/brush-4.png)

`classic/brush`

![](brush-gallery_files/brushes/brush-5.png)

`classic/bulk`

![](brush-gallery_files/brushes/brush-6.png)

`classic/calligraphy`

![](brush-gallery_files/brushes/brush-7.png)

`classic/charcoal`

![](brush-gallery_files/brushes/brush-8.png)

`classic/coarse_bulk_1`

![](brush-gallery_files/brushes/brush-9.png)

`classic/coarse_bulk_2`

![](brush-gallery_files/brushes/brush-10.png)

`classic/coarse_bulk_3`

![](brush-gallery_files/brushes/brush-11.png)

`classic/dry_brush`

![](brush-gallery_files/brushes/brush-12.png)

`classic/imp_blending`

![](brush-gallery_files/brushes/brush-13.png)

`classic/imp_details`

![](brush-gallery_files/brushes/brush-14.png)

`classic/impressionism`

![](brush-gallery_files/brushes/brush-15.png)

`classic/ink_blot`

![](brush-gallery_files/brushes/brush-16.png)

`classic/ink_eraser`

![](brush-gallery_files/brushes/brush-17.png)

`classic/kabura`

![](brush-gallery_files/brushes/brush-18.png)

`classic/knife`

![](brush-gallery_files/brushes/brush-19.png)

`classic/long_grass`

![](brush-gallery_files/brushes/brush-20.png)

`classic/marker_fat`

![](brush-gallery_files/brushes/brush-21.png)

`classic/marker_small`

![](brush-gallery_files/brushes/brush-22.png)

`classic/modelling`

![](brush-gallery_files/brushes/brush-23.png)

`classic/modelling2`

![](brush-gallery_files/brushes/brush-24.png)

`classic/pen`

![](brush-gallery_files/brushes/brush-25.png)

`classic/pencil`

![](brush-gallery_files/brushes/brush-26.png)

`classic/pointy_ink`

![](brush-gallery_files/brushes/brush-27.png)

`classic/puantilism`

![](brush-gallery_files/brushes/brush-28.png)

`classic/puantilism2`

![](brush-gallery_files/brushes/brush-29.png)

`classic/rounded`

![](brush-gallery_files/brushes/brush-30.png)

`classic/short_grass`

![](brush-gallery_files/brushes/brush-31.png)

`classic/slow_ink`

![](brush-gallery_files/brushes/brush-32.png)

`classic/smudge`

![](brush-gallery_files/brushes/brush-33.png)

`classic/smudge+paint`

![](brush-gallery_files/brushes/brush-34.png)

`classic/textured_ink`

![](brush-gallery_files/brushes/brush-35.png)

`classic/wet_knife`

![](brush-gallery_files/brushes/brush-36.png)

`deevad/2B_pencil`

![](brush-gallery_files/brushes/brush-37.png)

`deevad/4H_pencil`

![](brush-gallery_files/brushes/brush-38.png)

`deevad/airbrush`

![](brush-gallery_files/brushes/brush-39.png)

`deevad/ballpen`

![](brush-gallery_files/brushes/brush-40.png)

`deevad/basic_digital_brush`

![](brush-gallery_files/brushes/brush-41.png)

`deevad/basic_digital_brush_smudging`

![](brush-gallery_files/brushes/brush-42.png)

`deevad/basic_digital_knife`

![](brush-gallery_files/brushes/brush-43.png)

`deevad/basic_digital_knife_smudging`

![](brush-gallery_files/brushes/brush-44.png)

`deevad/blending`

![](brush-gallery_files/brushes/brush-45.png)

`deevad/brush`

![](brush-gallery_files/brushes/brush-46.png)

`deevad/chalk`

![](brush-gallery_files/brushes/brush-47.png)

`deevad/detail_brush_large`

![](brush-gallery_files/brushes/brush-48.png)

`deevad/detail_brush_large_glazing`

![](brush-gallery_files/brushes/brush-49.png)

`deevad/detail_brush_thin`

![](brush-gallery_files/brushes/brush-50.png)

`deevad/detail_brush_thin_glazing`

![](brush-gallery_files/brushes/brush-51.png)

`deevad/fill`

![](brush-gallery_files/brushes/brush-52.png)

`deevad/grainy_blending`

![](brush-gallery_files/brushes/brush-53.png)

`deevad/kneaded_eraser`

![](brush-gallery_files/brushes/brush-54.png)

`deevad/kneaded_eraser_large`

![](brush-gallery_files/brushes/brush-55.png)

`deevad/large_hard_eraser`

![](brush-gallery_files/brushes/brush-56.png)

`deevad/large_watercolor_fringe`

![](brush-gallery_files/brushes/brush-57.png)

`deevad/liner`

![](brush-gallery_files/brushes/brush-58.png)

`deevad/only_water_fringe`

![](brush-gallery_files/brushes/brush-59.png)

`deevad/pen`

![](brush-gallery_files/brushes/brush-60.png)

`deevad/pen-note`

![](brush-gallery_files/brushes/brush-61.png)

`deevad/rigger_brush`

![](brush-gallery_files/brushes/brush-62.png)

`deevad/rigger_brush_thin`

![](brush-gallery_files/brushes/brush-63.png)

`deevad/rough`

![](brush-gallery_files/brushes/brush-64.png)

`deevad/soft-dip-pen`

![](brush-gallery_files/brushes/brush-65.png)

`deevad/sponge_smudging`

![](brush-gallery_files/brushes/brush-66.png)

`deevad/spray`

![](brush-gallery_files/brushes/brush-67.png)

`deevad/spray2`

![](brush-gallery_files/brushes/brush-68.png)

`deevad/thin_hard_eraser`

![](brush-gallery_files/brushes/brush-69.png)

`deevad/thin_watercolor`

![](brush-gallery_files/brushes/brush-70.png)

`deevad/watercolor_expressive`

![](brush-gallery_files/brushes/brush-71.png)

`deevad/watercolor_glazing`

![](brush-gallery_files/brushes/brush-72.png)

`Dieterle/8B_Pencil#1`

![](brush-gallery_files/brushes/brush-73.png)

`Dieterle/arrow#1`

![](brush-gallery_files/brushes/brush-74.png)

`Dieterle/Blender`

![](brush-gallery_files/brushes/brush-75.png)

`Dieterle/Dissolver`

![](brush-gallery_files/brushes/brush-76.png)

`Dieterle/Eraser`

![](brush-gallery_files/brushes/brush-77.png)

`Dieterle/Fan#1`

![](brush-gallery_files/brushes/brush-78.png)

`Dieterle/Flat2#1`

![](brush-gallery_files/brushes/brush-79.png)

`Dieterle/Flight_Feathers`

![](brush-gallery_files/brushes/brush-80.png)

`Dieterle/Fount-offset#1`

![](brush-gallery_files/brushes/brush-81.png)

`Dieterle/Fountain_SF#1`

![](brush-gallery_files/brushes/brush-82.png)

`Dieterle/HalfTone#1`

![](brush-gallery_files/brushes/brush-83.png)

`Dieterle/HalfToneCMY#1`

![](brush-gallery_files/brushes/brush-84.png)

`Dieterle/Pencil-_Left_Handed`

![](brush-gallery_files/brushes/brush-85.png)

`Dieterle/Posterizer`

![](brush-gallery_files/brushes/brush-86.png)

`Dieterle/Round#1`

![](brush-gallery_files/brushes/brush-87.png)

`Dieterle/Splash`

![](brush-gallery_files/brushes/brush-88.png)

`Dieterle/Tail_Feathers`

![](brush-gallery_files/brushes/brush-89.png)

`Dieterle/Tail_Feathers2`

![](brush-gallery_files/brushes/brush-90.png)

`Dieterle/WateryFlatbrush`

![](brush-gallery_files/brushes/brush-91.png)

`experimental/1pixel`

![](brush-gallery_files/brushes/brush-92.png)

`experimental/basic`

![](brush-gallery_files/brushes/brush-93.png)

`experimental/bubble`

![](brush-gallery_files/brushes/brush-94.png)

`experimental/DNA_brush`

![](brush-gallery_files/brushes/brush-95.png)

`experimental/fur`

![](brush-gallery_files/brushes/brush-96.png)

`experimental/glow`

![](brush-gallery_files/brushes/brush-97.png)

`experimental/hard_blot`

![](brush-gallery_files/brushes/brush-98.png)

`experimental/hard_sting`

![](brush-gallery_files/brushes/brush-99.png)

`experimental/irregular_ink`

![](brush-gallery_files/brushes/brush-100.png)

`experimental/leaves`

![](brush-gallery_files/brushes/brush-101.png)

`experimental/particules_3`

![](brush-gallery_files/brushes/brush-102.png)

`experimental/particules_eraser`

![](brush-gallery_files/brushes/brush-103.png)

`experimental/pick_and_drag`

![](brush-gallery_files/brushes/brush-104.png)

`experimental/pixel_hardink`

![](brush-gallery_files/brushes/brush-105.png)

`experimental/pixelblocking`

![](brush-gallery_files/brushes/brush-106.png)

`experimental/sewing`

![](brush-gallery_files/brushes/brush-107.png)

`experimental/small_blot`

![](brush-gallery_files/brushes/brush-108.png)

`experimental/soft`

![](brush-gallery_files/brushes/brush-109.png)

`experimental/soft_irregular`

![](brush-gallery_files/brushes/brush-110.png)

`experimental/spaced-blot`

![](brush-gallery_files/brushes/brush-111.png)

`experimental/speed_blot`

![](brush-gallery_files/brushes/brush-112.png)

`experimental/subtle_pencil`

![](brush-gallery_files/brushes/brush-113.png)

`experimental/track`

![](brush-gallery_files/brushes/brush-114.png)

`kaerhon_v1/airbruch_press_a`

![](brush-gallery_files/brushes/brush-115.png)

`kaerhon_v1/Airbrush_a`

![](brush-gallery_files/brushes/brush-116.png)

`kaerhon_v1/airsmudge_a`

![](brush-gallery_files/brushes/brush-117.png)

`kaerhon_v1/airsmudgeultimate_sk`

![](brush-gallery_files/brushes/brush-118.png)

`kaerhon_v1/classic_sk`

![](brush-gallery_files/brushes/brush-119.png)

`kaerhon_v1/classicroundblock_static_c`

![](brush-gallery_files/brushes/brush-120.png)

`kaerhon_v1/Dirty_Transparent_sk`

![](brush-gallery_files/brushes/brush-121.png)

`kaerhon_v1/extreme_round_l`

![](brush-gallery_files/brushes/brush-122.png)

`kaerhon_v1/fill_c`

![](brush-gallery_files/brushes/brush-123.png)

`kaerhon_v1/flat_bar_l`

![](brush-gallery_files/brushes/brush-124.png)

`kaerhon_v1/ink_slow_s`

![](brush-gallery_files/brushes/brush-125.png)

`kaerhon_v1/ink-slowline_s`

![](brush-gallery_files/brushes/brush-126.png)

`kaerhon_v1/inkster_l`

![](brush-gallery_files/brushes/brush-127.png)

`kaerhon_v1/paint_barrr_sm`

![](brush-gallery_files/brushes/brush-128.png)

`kaerhon_v1/paint_radius_2_sm`

![](brush-gallery_files/brushes/brush-129.png)

`kaerhon_v1/paint_sm`

![](brush-gallery_files/brushes/brush-130.png)

`kaerhon_v1/Sketcher2_sk`

![](brush-gallery_files/brushes/brush-131.png)

`kaerhon_v1/Smear_sm`

![](brush-gallery_files/brushes/brush-132.png)

`kaerhon_v1/smudge_ink(0.7)_sm`

![](brush-gallery_files/brushes/brush-133.png)

`kaerhon_v1/wet_paint_sm`

![](brush-gallery_files/brushes/brush-134.png)

`ramon/100%_Opaque`

![](brush-gallery_files/brushes/brush-135.png)

`ramon/2B_pencil`

![](brush-gallery_files/brushes/brush-136.png)

`ramon/B-pencil`

![](brush-gallery_files/brushes/brush-137.png)

`ramon/Beamlight`

![](brush-gallery_files/brushes/brush-138.png)

`ramon/BigAirbrush`

![](brush-gallery_files/brushes/brush-139.png)

`ramon/Blur_Fast`

![](brush-gallery_files/brushes/brush-140.png)

`ramon/Classic_Paint`

![](brush-gallery_files/brushes/brush-141.png)

`ramon/Clouds`

![](brush-gallery_files/brushes/brush-142.png)

`ramon/Delayed_`

![](brush-gallery_files/brushes/brush-143.png)

`ramon/Dirty_Noise`

![](brush-gallery_files/brushes/brush-144.png)

`ramon/Glow_Airbrush`

![](brush-gallery_files/brushes/brush-145.png)

`ramon/Grain`

![](brush-gallery_files/brushes/brush-146.png)

`ramon/Hard_Eraser`

![](brush-gallery_files/brushes/brush-147.png)

`ramon/Knife`

![](brush-gallery_files/brushes/brush-148.png)

`ramon/Marker`

![](brush-gallery_files/brushes/brush-149.png)

`ramon/P._Shade`

![](brush-gallery_files/brushes/brush-150.png)

`ramon/Pastel_1`

![](brush-gallery_files/brushes/brush-151.png)

`ramon/Pen`

![](brush-gallery_files/brushes/brush-152.png)

`ramon/PenBrush`

![](brush-gallery_files/brushes/brush-153.png)

`ramon/Round`

![](brush-gallery_files/brushes/brush-154.png)

`ramon/Round_Bl`

![](brush-gallery_files/brushes/brush-155.png)

`ramon/RS_blendOP`

![](brush-gallery_files/brushes/brush-156.png)

`ramon/Sketch_1`

![](brush-gallery_files/brushes/brush-157.png)

`ramon/Smear`

![](brush-gallery_files/brushes/brush-158.png)

`ramon/Soft_Eraser`

![](brush-gallery_files/brushes/brush-159.png)

`ramon/Thin_Pen`

![](brush-gallery_files/brushes/brush-160.png)

`ramon/Wet_Direction`

![](brush-gallery_files/brushes/brush-161.png)

`ramon/wet_round`

![](brush-gallery_files/brushes/brush-162.png)

`tanda/acrylic-03-only-water`

![](brush-gallery_files/brushes/brush-163.png)

`tanda/acrylic-03-paint`

![](brush-gallery_files/brushes/brush-164.png)

`tanda/acrylic-03-with-water`

![](brush-gallery_files/brushes/brush-165.png)

`tanda/acrylic-04-only-water`

![](brush-gallery_files/brushes/brush-166.png)

`tanda/acrylic-04-paint`

![](brush-gallery_files/brushes/brush-167.png)

`tanda/acrylic-04-with-water`

![](brush-gallery_files/brushes/brush-168.png)

`tanda/acrylic-05-only-water`

![](brush-gallery_files/brushes/brush-169.png)

`tanda/acrylic-05-paint`

![](brush-gallery_files/brushes/brush-170.png)

`tanda/acrylic-05-with-water`

![](brush-gallery_files/brushes/brush-171.png)

`tanda/charcoal-01`

![](brush-gallery_files/brushes/brush-172.png)

`tanda/charcoal-03`

![](brush-gallery_files/brushes/brush-173.png)

`tanda/charcoal-04`

![](brush-gallery_files/brushes/brush-174.png)

`tanda/charcoal-blur1`

![](brush-gallery_files/brushes/brush-175.png)

`tanda/marker-01`

![](brush-gallery_files/brushes/brush-176.png)

`tanda/marker-05`

![](brush-gallery_files/brushes/brush-177.png)

`tanda/oil-01-clean`

![](brush-gallery_files/brushes/brush-178.png)

`tanda/oil-01-paint`

![](brush-gallery_files/brushes/brush-179.png)

`tanda/oil-03-clean`

![](brush-gallery_files/brushes/brush-180.png)

`tanda/oil-03-paint`

![](brush-gallery_files/brushes/brush-181.png)

`tanda/oil-06-clean`

![](brush-gallery_files/brushes/brush-182.png)

`tanda/oil-06-paint`

![](brush-gallery_files/brushes/brush-183.png)

`tanda/oil-mop`

![](brush-gallery_files/brushes/brush-184.png)

`tanda/pencil-2b`

![](brush-gallery_files/brushes/brush-185.png)

`tanda/pencil-8b`

![](brush-gallery_files/brushes/brush-186.png)

`tanda/splatter-02`

![](brush-gallery_files/brushes/brush-187.png)

`tanda/splatter-04`

![](brush-gallery_files/brushes/brush-188.png)

`tanda/texture-03`

![](brush-gallery_files/brushes/brush-189.png)

`tanda/texture-06`

![](brush-gallery_files/brushes/brush-190.png)

`tanda/texture-12`

![](brush-gallery_files/brushes/brush-191.png)

`tanda/water-01`

![](brush-gallery_files/brushes/brush-192.png)

`tanda/water-02`

![](brush-gallery_files/brushes/brush-193.png)

`tanda/water-05`

![](brush-gallery_files/brushes/brush-194.png)

`tanda/water-06`

![](brush-gallery_files/brushes/brush-195.png)

`tanda/watercolor-02-paint`

![](brush-gallery_files/brushes/brush-196.png)

`tanda/watercolor-02-water`

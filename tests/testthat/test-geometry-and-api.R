open_test_plot <- function() {
  grDevices::png(tempfile(fileext = ".png"), width = 4, height = 3, units = "in", res = 96)
  setup_plot_window()
}

test_that("rough geometry helpers return finite seeded output", {
  h <- human_hand(seed = 11)

  geoms <- list(
    rough_lines(c(1, 2, NA, 4, 5), c(1, 3, NA, 5, 8), hand = h),
    rough_segments(1:2, 2:3, 7:8, 5:6, hand = h),
    rough_polygons(c(1, 5, 9), c(1, 8, 2), hand = h),
    rough_polypath(
      c(1, 9, 9, 1, 3, 7, 7, 3),
      c(1, 1, 9, 9, 3, 3, 7, 7),
      id = c(rep(1, 4), rep(2, 4)),
      hand = h
    ),
    rough_rect(1, 1, 9, 8, hand = h)
  )

  for (geom in geoms) {
    expect_true(is.numeric(geom$x))
    expect_true(is.numeric(geom$y))
    expect_equal(length(geom$x), length(geom$y))
    expect_true(all(is.finite(geom$x)))
    expect_true(all(is.finite(geom$y)))
  }

  points_path <- rough_segments(1, 1, 1, 1, hand = h)
  expect_equal(points_path$id, 1L)
})

test_that("rough_lines returns roughened connected runs", {
  open_test_plot()
  on.exit(grDevices::dev.off(), add = TRUE)
  geom <- rough_lines(c(1, 2, NA, 4, 5), c(1, 3, NA, 5, 8), hand = human_hand(seed = 12))

  expect_equal(unique(geom$id), 1:2)
  expect_gt(length(geom$x), 4L)
  expect_false(identical(geom$x, c(1, 2, 4, 5)))
})

test_that("private rough builders share first-stroke geometry with exported helpers", {
  open_test_plot()
  on.exit(grDevices::dev.off(), add = TRUE)
  h <- human_hand(seed = 13, multi_stroke = 3)

  first_ids <- function(geom, n) {
    keep <- geom$id %in% seq_len(n)
    out <- list(x = geom$x[keep], y = geom$y[keep], id = geom$id[keep])
    if (!is.null(geom$rule)) out$rule <- geom$rule
    out
  }

  seg_export <- rough_segments(1:2, 2:3, 7:8, 5:6, hand = h)
  seg_private <- with_hand_seed(h$seed, {
    rough_segment_data(1:2, 2:3, 7:8, 5:6, h, strokes = h$multi_stroke)
  })
  expect_equal(first_ids(seg_private, max(seg_export$id)), seg_export)

  line_x <- c(1, 2, NA, 4, 5)
  line_y <- c(1, 3, NA, 5, 8)
  line_export <- rough_lines(line_x, line_y, hand = h)
  line_private <- with_hand_seed(h$seed, {
    rough_line_data(line_x, line_y, h, strokes = h$multi_stroke)
  })
  expect_equal(first_ids(line_private, max(line_export$id)), line_export)

  arrow_export <- rough_arrows(1, 2, 8, 7, code = 2, hand = h)
  arrow_private <- with_hand_seed(h$seed, {
    rough_arrow_data(1, 2, 8, 7, code = 2, hand_spec = h, strokes = h$multi_stroke)
  })
  expect_equal(first_ids(arrow_private, max(arrow_export$id)), arrow_export)

  paths <- split_polypath(
    c(1, 9, 9, 1, 3, 7, 7, 3),
    c(1, 1, 9, 9, 3, 3, 7, 7),
    id = c(rep(1, 4), rep(2, 4))
  )
  poly_export <- rough_polypath(
    c(1, 9, 9, 1, 3, 7, 7, 3),
    c(1, 1, 9, 9, 3, 3, 7, 7),
    id = c(rep(1, 4), rep(2, 4)),
    hand = h
  )
  poly_private <- with_hand_seed(h$seed, {
    rough_polypath_data(paths, h, rule = "winding", strokes = h$multi_stroke)
  })
  expect_equal(first_ids(poly_private, max(poly_export$id)), poly_export)

  polygon_export <- rough_polygons(c(1, 5, 9), c(1, 8, 2), hand = h)
  polygon_private <- with_hand_seed(h$seed, {
    rough_polygon_data(c(1, 5, 9), c(1, 8, 2), h, strokes = h$multi_stroke)
  })
  expect_equal(list(x = polygon_private$x[polygon_private$id == 1L], y = polygon_private$y[polygon_private$id == 1L]), polygon_export)

  points_export <- rough_points(1:3, c(2, 8, 4), hand = h)
  points_private <- with_hand_seed(h$seed, {
    rough_points_data(1:3, c(2, 8, 4), h, strokes = h$multi_stroke)
  })
  expect_equal(list(x = points_private$x[points_private$id == 1L], y = points_private$y[points_private$id == 1L]), points_export)
})

test_that("seeded rough geometry is reproducible without consuming R's RNG", {
  set.seed(123)
  old_seed <- .Random.seed
  first <- rough_segments(1, 1, 9, 8, hand = human_hand(seed = 99))
  expect_identical(.Random.seed, old_seed)
  second <- rough_segments(1, 1, 9, 8, hand = human_hand(seed = 99))
  expect_equal(first, second)

  rough_lines(c(1, 2, NA, 4, 5), c(1, 3, NA, 5, 8), hand = human_hand(seed = 99))
  expect_identical(.Random.seed, old_seed)

  open_test_plot()
  on.exit(grDevices::dev.off(), add = TRUE)
  rough_points(1:3, c(2, 8, 4), hand = human_hand(seed = 99))
  expect_identical(.Random.seed, old_seed)
})

test_that("constructors validate inputs", {
  expect_s3_class(hand(seed = 1), "mypaintr_hand")
  expect_s3_class(human_hand(seed = 1), "mypaintr_hand")
  expect_s3_class(pressure_flat(), "mypaintr_pressure_profile")
  expect_s3_class(pressure_smooth(), "mypaintr_pressure_profile")
  expect_s3_class(pressure_dashed(), "mypaintr_pressure_profile")
  expect_s3_class(pressure_human(), "mypaintr_pressure_profile")
  expect_s3_class(speed_flat(), "mypaintr_speed_profile")
  expect_s3_class(speed_human(), "mypaintr_speed_profile")
  expect_s3_class(hatch(), "mypaintr_fill_pattern")
  expect_s3_class(crosshatch(), "mypaintr_fill_pattern")
  expect_s3_class(zigzag(), "mypaintr_fill_pattern")
  expect_s3_class(jumble(), "mypaintr_fill_pattern")

  expect_error(hand(pressure = "bad"), "pressure")
  expect_error(hand(speed = 0), "speed|value")
  expect_error(speed_flat(0), "greater than 0")
  expect_error(pressure_dashed(pattern = 1), "pattern")
  expect_error(tweak_brush(NULL), "requires an explicit brush")
  expect_error(tweak_brush("classic/pen", normalize = "bad"), "normalize")
})

test_that("brush APIs work and device setters warn outside mypaint devices", {
  expect_type(brush_dirs(), "character")
  expect_true("classic/pen" %in% brushes())

  pen <- load_brush("classic/pen")
  expect_s3_class(pen, "mypaintr_brush")
  expect_s3_class(tweak_brush(pen, radius_logarithmic = 1.2), "mypaintr_brush")
  expect_s3_class(brush_settings(), "data.frame")
  expect_s3_class(brush_inputs(), "data.frame")

  expect_warning(set_brush("classic/pen"), "no effect")
  expect_warning(set_hand(hand()), "no effect")
})

test_that("brush and hand setters do not error inside mypaint devices", {
  expect_error(
    render_mypaintr_png("mypaint", {
      set_brush("classic/pen")
      set_hand(human_hand(seed = 42))
      setup_plot_window()
      graphics::lines(c(1, 9), c(1, 9), col = "black", lwd = 3)
    }),
    NA
  )
})

test_that("rough geometry helpers return finite seeded output", {
  h <- human_hand(seed = 11)
  arrow_geom <- local({
    # rough_arrows() computes arrowhead geometry from the active device aspect
    # ratio, so use an explicit temporary device rather than creating Rplots.pdf.
    path <- tempfile(fileext = ".png")
    grDevices::png(
      filename = path,
      width = 4,
      height = 3,
      units = "in",
      res = 96,
      pointsize = 10,
      bg = "white",
      type = "cairo"
    )
    on.exit(grDevices::dev.off(), add = TRUE)
    setup_plot_window()
    rough_arrows(1, 1, 9, 8, hand = h)
  })

  geoms <- list(
    rough_lines(c(1, 2, NA, 4, 5), c(1, 3, NA, 5, 8), hand = h),
    rough_segments(1:2, 2:3, 7:8, 5:6, hand = h),
    arrow_geom,
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

test_that("seeded rough geometry is reproducible without consuming R's RNG", {
  set.seed(123)
  old_seed <- .Random.seed
  first <- rough_segments(1, 1, 9, 8, hand = human_hand(seed = 99))
  expect_identical(.Random.seed, old_seed)
  second <- rough_segments(1, 1, 9, 8, hand = human_hand(seed = 99))
  expect_equal(first, second)
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
  testthat::skip_if(
    Sys.getenv("RUNNER_OS") == "macOS",
    "diagnosing macOS graphics state corruption"
  )

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

for (file in c(
  "draw-rough-lines-base.png",
  "draw-rough-segments-base.png",
  "draw-rough-arrows-base.png",
  "draw-rough-polygons-base.png",
  "draw-rough-polypath-base.png",
  "draw-rough-rect-base.png",
  "draw-rough-points-base.png",
  "draw-rough-lines-mypaint.png",
  "draw-rough-segments-mypaint.png",
  "draw-rough-arrows-mypaint.png",
  "draw-rough-polygons-mypaint.png",
  "draw-rough-polypath-mypaint.png",
  "draw-rough-rect-mypaint.png",
  "draw-rough-points-mypaint.png"
)) {
  testthat::announce_snapshot_file(name = file)
}
skip_visual_snapshot_file()

test_that("draw_rough helpers snapshot on base device", {
  expect_mypaintr_snapshot("draw-rough-lines", "base", {
    setup_plot_window()
    draw_rough_lines(c(1, 2, 4, 6, 8, 9), c(2, 7, 4, 8, 3, 6),
      hand = human_hand(seed = 101, multi_stroke = 2),
      col = "firebrick", lwd = 3
    )
  })

  expect_mypaintr_snapshot("draw-rough-segments", "base", {
    setup_plot_window()
    draw_rough_segments(c(1, 2, 3), c(2, 8, 4), c(8, 7, 9), c(7, 2, 5),
      hand = human_hand(seed = 102),
      col = "navy", lwd = 3
    )
  })

  expect_mypaintr_snapshot("draw-rough-arrows", "base", {
    setup_plot_window()
    draw_rough_arrows(c(1, 8), c(2, 8), c(8, 2), c(8, 3),
      code = c(2, 3),
      hand = human_hand(seed = 103),
      col = "grey25", lwd = 3
    )
  })

  expect_mypaintr_snapshot("draw-rough-polygons", "base", {
    setup_plot_window()
    draw_rough_polygons(c(1, 3.5, 8.5, 7, 2), c(2, 8.5, 7, 2.5, 1.5),
      hand = human_hand(seed = 104, bow = 0.035, wobble = 0.025, endpoint_jitter = 0.01, multi_stroke = 2),
      col = grDevices::rgb(0.8, 0.2, 0.1, 0.45),
      border = "grey20",
      lwd = 2
    )
  })

  expect_mypaintr_snapshot("draw-rough-polypath", "base", {
    setup_plot_window()
    draw_rough_polypath(
      c(1, 9, 9, 1, 3.5, 6.5, 6.5, 3.5),
      c(1, 1, 9, 9, 3.5, 3.5, 6.5, 6.5),
      id = c(rep(1, 4), rep(2, 4)),
      rule = "evenodd",
      hand = human_hand(seed = 105),
      col = grDevices::rgb(0.2, 0.5, 0.75, 0.55),
      border = "grey20",
      lwd = 2
    )
  })

  expect_mypaintr_snapshot("draw-rough-rect", "base", {
    setup_plot_window()
    draw_rough_rect(1.5, 2, 8.5, 8,
      hand = human_hand(seed = 106),
      col = "palegreen3",
      border = "darkgreen",
      lwd = 2
    )
  })

  expect_mypaintr_snapshot("draw-rough-points", "base", {
    setup_plot_window()
    draw_rough_points(1:9, c(2, 8, 4, 7, 5, 6, 3, 8, 2),
      hand = human_hand(seed = 107),
      col = "purple4",
      pch = 16,
      cex = 1.8
    )
  })
})

test_that("draw_rough helpers snapshot on mypaint device", {
  brush <- deterministic_brush("classic/pen")

  expect_mypaintr_snapshot("draw-rough-lines", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_lines(c(1, 2, 4, 6, 8, 9), c(2, 7, 4, 8, 3, 6),
      hand = human_hand(seed = 201, multi_stroke = 2),
      col = "firebrick", lwd = 1.2
    )
  })

  expect_mypaintr_snapshot("draw-rough-segments", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_segments(c(1, 2, 3), c(2, 8, 4), c(8, 7, 9), c(7, 2, 5),
      hand = human_hand(seed = 202),
      col = "navy", lwd = 1.2
    )
  })

  expect_mypaintr_snapshot("draw-rough-arrows", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_arrows(c(1, 8), c(2, 8), c(8, 2), c(8, 3),
      code = c(2, 3),
      hand = human_hand(seed = 203),
      col = "grey25", lwd = 1.2
    )
  })

  expect_mypaintr_snapshot("draw-rough-polygons", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_polygons(c(1, 3.5, 8.5, 7, 2), c(2, 8.5, 7, 2.5, 1.5),
      hand = human_hand(seed = 204, bow = 0.035, wobble = 0.025, endpoint_jitter = 0.01, multi_stroke = 2),
      col = grDevices::rgb(0.8, 0.2, 0.1, 0.45),
      border = "grey20",
      lwd = 0.5
    )
  })

  expect_mypaintr_snapshot("draw-rough-polypath", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_polypath(
      c(1, 9, 9, 1, 3.5, 6.5, 6.5, 3.5),
      c(1, 1, 9, 9, 3.5, 3.5, 6.5, 6.5),
      id = c(rep(1, 4), rep(2, 4)),
      rule = "evenodd",
      hand = human_hand(seed = 205),
      col = grDevices::rgb(0.2, 0.5, 0.75, 0.55),
      border = "grey20",
      lwd = 0.5
    )
  })

  expect_mypaintr_snapshot("draw-rough-rect", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_rect(1.5, 2, 8.5, 8,
      hand = human_hand(seed = 206),
      col = "palegreen3",
      border = "darkgreen",
      lwd = 0.5
    )
  })

  expect_mypaintr_snapshot("draw-rough-points", "mypaint", brush = brush, {
    setup_plot_window()
    draw_rough_points(1:9, c(2, 8, 4, 7, 5, 6, 3, 8, 2),
      hand = human_hand(seed = 207),
      col = "purple4",
      pch = 16,
      cex = 1.2
    )
  })
})

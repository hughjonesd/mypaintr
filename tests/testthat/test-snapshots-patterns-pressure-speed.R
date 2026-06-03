for (file in c(
  "fill-patterns-base-base.png",
  "fill-patterns-mypaint-mypaint.png",
  "pressure-profiles-base.png",
  "pressure-profiles-mypaint.png"
)) {
  testthat::announce_snapshot_file(name = file)
}
skip_visual_snapshot_file()

test_that("fill patterns snapshot on base and mypaint devices", {
  for (device in c("base", "mypaint")) {
    expect_mypaintr_snapshot(paste0("fill-patterns-", device), device,
                             brush = deterministic_brush("classic/pencil"), {
      setup_plot_window()
      draw_rough_rect(0.8, 5.8, 4.4, 9.2,
        hand = human_hand(seed = 301),
        col = "tomato",
        border = "grey20",
        fill_pattern = hatch(density = 8),
        lwd = 1
      )
      draw_rough_rect(5.6, 5.8, 9.2, 9.2,
        hand = human_hand(seed = 302),
        col = "seagreen3",
        border = "grey20",
        fill_pattern = crosshatch(density = 7),
        lwd = 1
      )
      draw_rough_rect(0.8, 0.8, 4.4, 4.2,
        hand = human_hand(seed = 303),
        col = "royalblue2",
        border = "grey20",
        fill_pattern = zigzag(density = 6),
        lwd = 1
      )
      draw_rough_rect(5.6, 0.8, 9.2, 4.2,
        hand = human_hand(seed = 304),
        col = "goldenrod2",
        border = "grey20",
        fill_pattern = jumble(density = 7),
        lwd = 1
      )
    })
  }
})

test_that("pressure profiles snapshot on base device", {
  expect_mypaintr_snapshot("pressure-profiles", "base", {
    setup_plot_window()
    profiles <- list(
      pressure_flat(0.8),
      pressure_smooth(value = 1, taper = 0.35),
      pressure_smooth(value = 1, taper = 1, turn_taper = 0.7),
      pressure_dashed(pattern = c(14, 8)),
      pressure_dashed_smooth(),
      pressure_human(start = 0.15, end = 0.35, peak = 0.35),
      pressure_human(start = 0.6, end = 0.2, peak = 0.7, turn_taper = 0.7)
    )
    ys <- c(8.8, 7.4, 6, 4.6, 3.2, 1.8, 0.4)
    for (i in seq_along(profiles)) {
      draw_rough_lines(c(1, 2.5, 4.5, 6.5, 9), c(ys[i], ys[i] + 0.8, ys[i] - 0.6, ys[i] + 0.5, ys[i]),
        hand = hand(seed = 400 + i, pressure = profiles[[i]]),
        col = "grey20",
        lwd = 3
      )
    }
  })
})

test_that("pressure profiles snapshot on mypaint device", {
  pressure_brush <- deterministic_brush("classic/pen")
  expect_mypaintr_snapshot("pressure-profiles", "mypaint", brush = pressure_brush, {
    setup_plot_window()
    graphics::rect(0, 0, 10, 10, col = "white", border = NA)
    profiles <- list(
      pressure_flat(0.8),
      pressure_smooth(value = 1, taper = 0.35),
      pressure_smooth(value = 1, taper = 1, turn_taper = 0.7),
      pressure_dashed(pattern = c(14, 8)),
      pressure_dashed_smooth(),
      pressure_human(start = 0.15, end = 0.35, peak = 0.35),
      pressure_human(start = 0.6, end = 0.2, peak = 0.7, turn_taper = 0.7)
    )
    ys <- c(8.8, 7.4, 6, 4.6, 3.2, 1.8, 0.4)
    for (i in seq_along(profiles)) {
      set_hand(hand(seed = 500 + i, pressure = profiles[[i]]))
      lines(c(1, 2.5, 4.5, 6.5, 9), c(ys[i], ys[i] + 0.8, ys[i] - 0.6, ys[i] + 0.5, ys[i]),
        col = "grey20", lwd = 0.2
      )
    }
  })
})

test_that("speed profiles render on mypaint device", {
  speed_brush <- deterministic_brush("experimental/fur")
  path <- render_mypaintr_png("mypaint", brush = speed_brush, {
    setup_plot_window()
    speeds <- list(speed_flat(0.02), speed_flat(1),
                   speed_human(value = 0.05, peak = 6))
    ys <- c(7, 5, 3)
    for (i in seq_along(speeds)) {
      set_hand(hand(seed = 600 + i, speed = speeds[[i]], pressure = pressure_human()))

      lines(c(1, 2.2, 4.5, 6.8, 9), c(ys[i], ys[i] + 1.2, ys[i] - 1, ys[i] + 1, ys[i]),
        col = "steelblue4"
      )
    }
  })
  testthat::expect_true(file.exists(path))
})

test_that("speed profiles do not error on base device", {
  expect_no_error(
    render_mypaintr_png("base", {
      setup_plot_window()
      draw_rough_lines(c(1, 3, 6, 9), c(3, 7, 4, 8),
        hand = hand(seed = 701, speed = speed_human()),
        col = "grey20",
        lwd = 3
      )
    })
  )
})

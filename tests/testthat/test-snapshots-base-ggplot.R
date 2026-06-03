for (file in c(
  "base-graphics-functions-mypaint.png",
  "base-graphics-brushes-mypaint.png",
  "default-null-hand-brush-mypaint.png",
  "ggplot-wrapped-layer-mypaint.png",
  "ggplot-mypaint-col-mypaint.png",
  "ggplot-mypaint-bar-mypaint.png",
  "ggplot-wrapped-theme-mypaint.png"
)) {
  testthat::announce_snapshot_file(name = file)
}
skip_visual_snapshot_file()

test_that("base graphics functions snapshot on mypaint device", {
  testthat::skip_if(identical(Sys.getenv("RUNNER_OS"), "macOS"), "diagnosing macOS crash before ggplot load")
  expect_mypaintr_snapshot("base-graphics-polygons", "mypaint", brush = deterministic_brush("classic/pen"), {
    setup_plot_window()
    graphics::rect(0.5, 0.5, 9.5, 9.5, col = "#f8f3df", border = NA)
    graphics::polygon(c(1.2, 4.8, 3.6, 1.8), c(2, 1.4, 5.5, 6.2), col = "#77b7b2", border = "#345995", lwd = 0.8)
    graphics::rect(5.5, 1.2, 8.8, 4.3, col = "#f2c14e", border = "#5c4d3c", lwd = 0.8)
    graphics::polypath(c(1.2, 4.8, 3.6, 1.8, NA, 2.4, 3.5, 3.0, 2.0),
                       c(7, 6.4, 9.5, 9.0, NA, 8, 7, 7.2, 7.5), col = "red")
  })
  expect_mypaintr_snapshot("base-graphics-lines", "mypaint", brush = deterministic_brush("classic/pen"), {
    setup_plot_window()
    graphics::segments(c(1, 2, 3), c(8.5, 8, 7.5), c(8, 7, 6), c(8.5, 8, 7.5), col = "#9b2226", lwd = 1, lty = c(1, 2, 3))
    graphics::arrows(7.5, 5.2, 2.5, 7, col = "#3a0ca3", lwd = 1, lty = 2, length = 0.12)
    graphics::lines(c(1, 2.5, 4, 6, 8.5), c(3.5, 6, 4.5, 6.5, 5.4), col = "#22223b", lwd = 1, lty = "dashed")
    graphics::points(c(2, 4, 6, 8), c(2, 3, 2.2, 3.3), pch = c(16, 17, 15, 18), cex = 1, col = "#bc4749")
  })
})

test_that("mypaint device snapshots cover brush switching with base graphics lines", {
  testthat::skip_if(identical(Sys.getenv("RUNNER_OS"), "macOS"), "diagnosing macOS crash before ggplot load")
  expect_mypaintr_snapshot("base-graphics-brushes", "mypaint", {
    setup_striped_plot_window()
    brushes <- list(
      deterministic_brush("classic/pen"),
      deterministic_brush("deevad/2B_pencil"),
      deterministic_brush("classic/smudge+paint"),
      deterministic_brush("ramon/Marker")
    )
    ys <- c(8, 6, 4, 2)
    cols <- c("white", "black", "white", "black")
    for (i in seq_along(brushes)) {
      set_brush(brushes[[i]])
      graphics::lines(c(0.7, 9.3), c(ys[[i]], ys[[i]]), col = cols[[i]], lwd = 2.5)
    }
  })
})

test_that("mypaint device snapshots default NULL brush and default rough hand", {
  testthat::skip_if(identical(Sys.getenv("RUNNER_OS"), "macOS"), "diagnosing macOS crash before ggplot load")
  expect_mypaintr_snapshot("default-null-hand-brush", "mypaint", brush = NULL, {
    setup_plot_window()
    graphics::rect(1, 1, 9, 9, col = "#f8f3df", border = NA)
    graphics::lines(c(1.2, 8.8), c(2.2, 7.8), col = "#345995", lwd = 1.1)
    graphics::segments(c(1.5, 2.5, 3.5), c(8.4, 8.0, 7.6), c(8.2, 7.2, 6.2), c(8.3, 7.1, 8.1),
      col = "#9b2226", lwd = 0.9, lty = c(1, 2, 3)
    )
    draw_rough_lines(c(1.5, 3.5, 6.5, 8.5), c(4, 6.2, 3.8, 5.8),
      col = "#22223b",
      lwd = 1.1
    )
  })
})

test_that("mypaint_wrap snapshots a ggplot layer on mypaint device", {
  testthat::skip_if_not_installed("ggplot2")
  expect_mypaintr_snapshot("ggplot-wrapped-layer", "mypaint", brush = deterministic_brush("classic/pen"), {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
      mypaint_wrap(
        ggplot2::geom_line(ggplot2::aes(group = cyl), linewidth = 0.55, colour = "#345995"),
        brush = deterministic_brush("classic/pen"),
        hand = human_hand(seed = 901, bow = 0.02, wobble = 0.015)
      ) +
      ggplot2::geom_point(size = 1.8, colour = "#bc4749") +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
    print(p)
  })
})

test_that("geom_mypaint_col snapshots rough columns on mypaint device", {
  testthat::skip_if_not_installed("ggplot2")
  expect_mypaintr_snapshot("ggplot-mypaint-col", "mypaint", brush = deterministic_brush("classic/pen"), {
    p <- ggplot2::ggplot(
      data.frame(wt = c(2.1, 3.1, 4.1), value = c(24, 20, 16)),
      ggplot2::aes(x = wt, y = value)
    ) +
      geom_mypaint_col(
        fill = "#f2c14e",
        colour = "#22223b",
        linewidth = 0.4,
        fill_pattern = hatch(density = 7),
        brush = deterministic_brush("classic/pen"),
        hand = human_hand(seed = 902, bow = 0.018, wobble = 0.012)
      ) +
      ggplot2::coord_cartesian(ylim = c(0, 28)) +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
    print(p)
  })
})

test_that("geom_mypaint_bar snapshots rough count bars on mypaint device", {
  testthat::skip_if_not_installed("ggplot2")
  expect_mypaintr_snapshot("ggplot-mypaint-bar", "mypaint", brush = deterministic_brush("classic/pen"), {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
      geom_mypaint_bar(
        fill = "#77b7b2",
        colour = "#22223b",
        linewidth = 0.4,
        fill_pattern = crosshatch(density = 6),
        brush = deterministic_brush("classic/pen"),
        hand = human_hand(seed = 904, bow = 0.018, wobble = 0.012)
      ) +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
    print(p)
  })
})

test_that("mypaint_wrap snapshots ggplot theme elements on mypaint device", {
  testthat::skip_if_not_installed("ggplot2")
  expect_mypaintr_snapshot("ggplot-wrapped-theme", "mypaint", brush = deterministic_brush("classic/pen"), {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
      ggplot2::geom_point(size = 1.8, colour = "#bc4749") +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(
        panel.grid.major = mypaint_wrap(
          ggplot2::element_line(colour = "#c9c1ad", linewidth = 0.35),
          brush = deterministic_brush("classic/pen"),
          hand = human_hand(seed = 903)
        ),
        panel.grid.minor = ggplot2::element_blank(),
        panel.background = mypaint_wrap(
          ggplot2::element_rect(fill = "#f8f3df", colour = "#22223b", linewidth = 0.35),
          brush = deterministic_brush("classic/pen"),
          hand = human_hand(seed = 905, bow = 0.01, wobble = 0.008)
        )
      )
    print(p)
  })
})

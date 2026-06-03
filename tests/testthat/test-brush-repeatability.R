snapshot_brushes <- c(
  "classic/pen",
  "classic/pencil",
  "classic/calligraphy",
  "classic/smudge+paint",
  "deevad/2B_pencil",
  "deevad/4H_pencil",
  "deevad/chalk",
  "ramon/Marker",
  "ramon/Pen",
  "ramon/Classic_Paint"
)

for (file in paste0("brush-", gsub("[^A-Za-z0-9]+", "-", snapshot_brushes), "-mypaint.png")) {
  testthat::announce_snapshot_file(name = file)
}

test_that("representative brushes render repeatably on the canonical snapshot platform", {
  if (!can_run_visual_snapshots()) {
    return(invisible(NULL))
  }
  available <- brushes()
  for (brush in snapshot_brushes) {
    testthat::skip_if_not(brush %in% available, paste("brush is unavailable:", brush))
    stable_brush <- deterministic_brush(brush)
    ci_trace("repeatability", brush, "first")
    first <- render_brush_scene(stable_brush)
    ci_trace("repeatability", brush, "second")
    second <- render_brush_scene(stable_brush)
    ci_trace("repeatability", brush, "compare")
    testthat::expect_true(
      compare_png_stable(first, second),
      info = paste("brush should render repeatably:", brush)
    )
    ci_trace("repeatability", brush, "done")
  }
})

test_that("stable brush snapshots cover a representative brush matrix", {
  available <- brushes()
  for (brush in snapshot_brushes) {
    testthat::skip_if_not(brush %in% available, paste("brush is unavailable:", brush))
    ci_trace("snapshot", brush, "start")
    expect_mypaintr_snapshot(
      paste0("brush-", gsub("[^A-Za-z0-9]+", "-", brush)),
      "mypaint",
      {
        setup_striped_plot_window()
        set_brush(deterministic_brush(brush))
        graphics::lines(c(0.6, 9.4), c(5, 5), col = "white")
        graphics::lines(c(0.6, 9.4), c(4, 4), col = "black")
        graphics::lines(c(0.6, 9.4), c(3, 3), col = adjustcolor("white", 0.5))
        graphics::points(c(2, 5, 8), c(7.5, 2.5, 7.5), pch = 16, cex = 1.6,
                         col = "white")
        set_hand(human_hand(seed = 101L))
        graphics::lines(c(0.6, 9.4), c(2, 2), col = "yellow")
      }
    )
    ci_trace("snapshot", brush, "done")
  }
})

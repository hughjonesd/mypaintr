smoke_only_brushes <- c(
  "classic/pencil",
  "classic/charcoal",
  "classic/textured_ink",
  "deevad/basic_digital_brush",
  "deevad/chalk",
  "deevad/pen",
  "deevad/watercolor_expressive",
  "deevad/spray",
  "ramon/Dirty_Noise",
  "ramon/Sketch_1"
)

test_that("non-gating representative brushes remain smoke-covered", {
  available <- brushes()
  for (brush in smoke_only_brushes) {
    testthat::skip_if_not(brush %in% available, paste("brush is unavailable:", brush))
    expect_no_error(render_brush_scene(brush))
  }
})

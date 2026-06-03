can_run_visual_snapshots <- function() {
  identical(Sys.info()[["sysname"]], "Darwin") &&
    identical(Sys.info()[["machine"]], "arm64") &&
    requireNamespace("png", quietly = TRUE)
}

ci_trace <- function(...) {
  if (!identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
    return(invisible(NULL))
  }
  cat("mypaintr-ci:", ..., "\n", file = stderr())
  flush(stderr())
  invisible(NULL)
}

skip_visual_snapshot_file <- function() {
  testthat::skip_if_not(
    can_run_visual_snapshots(),
    "visual snapshot tests run only on macOS arm64"
  )
}

compare_png_stable <- function(old, new) {
  channel_tolerance <- 1 / 255
  mean_tolerance <- 0.002
  changed_tolerance <- 0.02
  large_tolerance <- 0.005

  old_img <- png::readPNG(old)
  new_img <- png::readPNG(new)
  if (!identical(dim(old_img), dim(new_img))) {
    return(FALSE)
  }

  diff <- abs(old_img - new_img)
  mean(diff) <= mean_tolerance &&
    mean(diff > channel_tolerance) <= changed_tolerance &&
    mean(diff > 16 * channel_tolerance) <= large_tolerance
}

render_mypaintr_png <- function(device = c("base", "mypaint"),
                                code,
                                brush = NULL,
                                width = 4,
                                height = 3,
                                res = 96,
                                bg = "white") {
  device <- match.arg(device)
  path <- tempfile(fileext = ".png")
  if (identical(device, "base")) {
    grDevices::png(
      filename = path,
      width = width,
      height = height,
      units = "in",
      res = res,
      pointsize = 10,
      bg = bg,
      type = "cairo"
    )
  } else {
    mypaint_device(
      filename = path,
      width = width,
      height = height,
      res = res,
      pointsize = 10,
      bg = bg,
      brush = brush
    )
  }
  on.exit({
    while (names(grDevices::dev.cur()) != "null device") {
      grDevices::dev.off()
    }
  }, add = TRUE)

  force(code)
  grDevices::dev.off()
  path
}

expect_mypaintr_snapshot <- function(name,
                                     device = c("base", "mypaint"),
                                     code,
                                     brush = NULL) {
  device <- match.arg(device)
  name <- paste0(name, "-", device, ".png")
  testthat::announce_snapshot_file(name = name)
  if (!can_run_visual_snapshots()) {
    return(invisible(NULL))
  }
  path <- render_mypaintr_png(
    device = device,
    brush = brush,
    code = code
  )
  testthat::expect_snapshot_file(
    path,
    name = name,
    compare = compare_png_stable,
    variant = "macos-26-arm64"
  )
}

setup_plot_window <- function() {
  graphics::par(mar = c(2.5, 2.5, 0.5, 0.5), xaxs = "i", yaxs = "i")
  graphics::plot.new()
  graphics::plot.window(c(0, 10), c(0, 10))
  graphics::box(col = "grey80")
}

setup_striped_plot_window <- function() {
  graphics::par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  graphics::plot.new()
  graphics::plot.window(c(0, 10), c(0, 10))
  stripe_cols <- c("#e84a5f", "#f9c74f", "#43aa8b", "#577590", "#7b2cbf")
  for (i in seq_along(stripe_cols)) {
    graphics::rect((i - 1) * 2, 0, i * 2, 10, col = stripe_cols[[i]], border = NA)
  }
}

render_brush_scene <- function(brush) {
  render_mypaintr_png("mypaint", {
    setup_striped_plot_window()
    set_brush(brush)
    graphics::lines(c(0.6, 9.4), c(5, 5), col = "white", lwd = 3)
    graphics::lines(c(0.6, 9.4), c(2.5, 7.5), col = "black", lwd = 2)
    graphics::points(c(2, 5, 8), c(7.5, 2.5, 7.5), pch = 16, cex = 1.6, col = "white")
  })
}

deterministic_brush <- function(brush) {
  tweak_brush(
    brush,
    offset_by_random = 0,
    radius_by_random = 0,
    tracking_noise = 0
  )
}

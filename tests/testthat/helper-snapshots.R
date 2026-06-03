can_run_visual_snapshots <- function() {
  mac_version <- tryCatch(
    system2("sw_vers", "-productVersion", stdout = TRUE, stderr = FALSE),
    error = function(e) ""
  )

  identical(Sys.info()[["sysname"]], "Darwin") &&
    identical(Sys.info()[["machine"]], "arm64") &&
    length(mac_version) > 0 &&
    startsWith(mac_version[[1]], "26.") &&
    requireNamespace("png", quietly = TRUE)
}

can_open_base_png_device <- local({
  ok <- NULL

  function() {
    if (!is.null(ok)) {
      return(ok)
    }

    path <- tempfile(fileext = ".png")
    start_device <- grDevices::dev.cur()
    ok <<- isTRUE(tryCatch({
      suppressWarnings(grDevices::png(
        filename = path,
        width = 1,
        height = 1,
        units = "in",
        res = 72,
        pointsize = 10,
        bg = "white",
        type = "cairo"
      ))
      if (identical(unname(grDevices::dev.cur()), unname(start_device))) {
        stop("base PNG device did not open", call. = FALSE)
      }
      graphics::plot.new()
      grDevices::dev.off()
      file.exists(path)
    }, error = function(e) {
      FALSE
    }))

    while (!identical(unname(grDevices::dev.cur()), unname(start_device))) {
      grDevices::dev.off()
    }
    unlink(path)
    ok
  }
})

skip_visual_snapshot_file <- function() {
  testthat::skip_if_not(
    can_run_visual_snapshots(),
    "visual snapshot tests run only on macOS 26 arm64"
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
    testthat::skip_if_not(
      can_open_base_png_device(),
      "base PNG snapshots require a working Cairo PNG device"
    )
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
  if (identical(device, "base")) {
    testthat::skip_if_not(
      can_open_base_png_device(),
      "base PNG snapshots require a working Cairo PNG device"
    )
  }
  path <- render_mypaintr_png(
    device = device,
    brush = brush,
    code = code
  )
  if (identical(Sys.getenv("CI"), "true")) {
    testthat::expect_true(file.exists(path))
    return(invisible(path))
  }
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

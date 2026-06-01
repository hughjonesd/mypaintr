library(mypaintr)

args <- commandArgs(trailingOnly = TRUE)
reps_arg <- if (length(args)) args[[1]] else Sys.getenv("MYPAINTR_BENCH_REPS", "1")
reps <- suppressWarnings(as.integer(reps_arg))
if (!is.finite(reps) || reps < 1L) {
  reps <- 1L
}
case_filter <- args[-1]

bench_dir <- Sys.getenv(
  "MYPAINTR_BENCH_DIR",
  file.path(tempdir(), "mypaintr-benchmark")
)
dir.create(bench_dir, recursive = TRUE, showWarnings = FALSE)

palette("Dark 2")

slugify <- function(x) gsub("[^A-Za-z0-9._-]+", "-", x)

with_mypaint_device <- function(name, expr, width = 6, height = 4, res = 144) {
  path <- file.path(bench_dir, paste0(slugify(name), ".png"))
  mypaint_device(path, width = width, height = height, res = res)
  on.exit({
    if (identical(names(grDevices::dev.cur()), "mypaintr")) {
      grDevices::dev.off()
    }
  }, add = TRUE)
  force(expr)
  grDevices::dev.off()
  path
}

with_png_device <- function(name, expr, width = 800, height = 600, res = 144) {
  path <- file.path(bench_dir, paste0(slugify(name), ".png"))
  grDevices::png(path, width = width, height = height, res = res)
  on.exit({
    if (grDevices::dev.cur() > 1) {
      grDevices::dev.off()
    }
  }, add = TRUE)
  force(expr)
  grDevices::dev.off()
  path
}

time_case <- function(expr) {
  gc(FALSE)
  timing <- system.time(force(expr))
  c(
    cpu_seconds = unname(timing[["user.self"]] + timing[["sys.self"]]),
    elapsed_seconds = unname(timing[["elapsed"]])
  )
}

render_gallery_strokes <- function(brush) {
  with_mypaint_device(paste0("gallery-strokes-", brush), {
    plot.new()
    plot.window(c(0, 10), c(0, 10))
    title("Strokes")
    rect(1, 0, 4, 10, col = "#ffc0cb", border = NA)
    rect(4, 0, 7, 10, col = "#fffcf8", border = NA)
    rect(7, 0, 10, 10, col = "#7e3f12", border = NA)
    set_brush(brush)

    line_col <- adjustcolor("darkred", alpha.f = 0.66)

    text(1, 9.5, "Flat", adj = 0)
    set_hand(hand())
    segments(1, 7:9, 10, 7:9, lwd = (1:3) / 2, col = line_col)

    text(1, 6.5, "Human (flat speed)", adj = 0)
    set_hand(human_hand(speed = 1, pressure = pressure_human()))
    segments(1, 4:6, 10, 4:6, lwd = (1:3) / 2, col = line_col)

    text(1, 3.5, "Human (variable speed)", adj = 0)
    set_hand(human_hand(speed = speed_human(), pressure = pressure_human()))
    segments(1, 1:3, 10, 1:3, lwd = (1:3) / 2, col = line_col)
  })
}

render_gallery_fills <- function(brush) {
  with_mypaint_device(paste0("gallery-fills-", brush), {
    plot.new()
    plot.window(c(0, 10), c(0, 10))
    title("Fills")
    set_brush(brush)
    rect(2, 2, 7, 7, col = "red")
    lines(c(1, 9), c(1, 9), col = "blue", lwd = 2)
    draw_rough_rect(1, 4, 4, 9, fill_pattern = zigzag(), col = "orange3")
    draw_rough_lines(c(0.5, 9.5), c(9.5, 9.5), hand = human_hand())
  })
}

plot_intro_hand_barplot <- function() {
  with_mypaint_device("intro-hand-barplot", {
    set_hand(human_hand())
    barplot(VADeaths, beside = TRUE, col = NA, cex.names = 0.8)
  }, width = 7, height = 5)
}

plot_intro_mtcars <- function() {
  with_mypaint_device("intro-mtcars-marker", {
    set_brush("classic/marker_small")
    set_hand(human_hand(xtilt = 0.5, ytilt = -0.2))
    plot(mpg ~ hp, data = mtcars, col = factor(mtcars$gear))
    legend(
      "topright",
      legend = 3:5,
      title = "Gears",
      col = 1:3,
      horiz = TRUE,
      bg = "transparent",
      inset = 0.05,
      pch = 1
    )
  }, width = 5, height = 5)
}

plot_readme_rough_shape <- function() {
  with_png_device("readme-rough-crosshatch", {
    plot(1:10, 1:10, type = "n", xlab = "", ylab = "", axes = FALSE)
    draw_rough_polygons(
      5 + 3 * sin(2 * pi * 1:5 / 5),
      5 + 3 * cos(2 * pi * 1:5 / 5),
      border = "darkred",
      col = "red3",
      lwd = 2,
      hand = human_hand(seed = 1, multi_stroke = 3),
      fill_pattern = crosshatch()
    )
    draw_rough_arrows(
      8, 8.5, 5.5, 5.5,
      lwd = 2,
      hand = human_hand(seed = 1, bow = 0.05)
    )
    text(8, 9, "A pentagon")
  })
}

plot_ggplot_bubble_bar <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for this benchmark case", call. = FALSE)
  }
  with_mypaint_device("ggplot-bubble-bar", {
    print(
      ggplot2::ggplot(ggplot2::diamonds) +
        mypaint_wrap(
          ggplot2::geom_bar(ggplot2::aes(cut, fill = cut)),
          brush = "experimental/bubble"
        ) +
        ggplot2::theme_minimal()
    )
  })
}

cases <- list(
  gallery_fill_coarse_bulk_1 = function() render_gallery_fills("classic/coarse_bulk_1"),
  gallery_fill_charcoal_01 = function() render_gallery_fills("tanda/charcoal-01"),
  gallery_strokes_coarse_bulk_1 = function() render_gallery_strokes("classic/coarse_bulk_1"),
  ggplot_bubble_bar = plot_ggplot_bubble_bar,
  intro_hand_barplot = plot_intro_hand_barplot,
  intro_mtcars_marker = plot_intro_mtcars,
  readme_rough_crosshatch = plot_readme_rough_shape
)

if (length(case_filter)) {
  unknown <- setdiff(case_filter, names(cases))
  if (length(unknown)) {
    stop(
      "unknown benchmark case(s): ", paste(unknown, collapse = ", "),
      "\nAvailable cases: ", paste(names(cases), collapse = ", "),
      call. = FALSE
    )
  }
  cases <- cases[case_filter]
}

cat("Running", length(cases), "benchmark cases with", reps, "repetition(s).\n")
cat("Output directory:", bench_dir, "\n\n")

# One small warmup keeps package/device initialization out of the first slow case.
invisible(with_mypaint_device("warmup", {
  plot.new()
  plot.window(c(0, 1), c(0, 1))
  set_brush("classic/pen")
  lines(c(0.1, 0.9), c(0.5, 0.5), lwd = 2)
}, width = 2, height = 2))

rows <- list()
idx <- 1L
for (case_name in names(cases)) {
  for (rep in seq_len(reps)) {
    cat(sprintf("[%s] rep %d/%d\n", case_name, rep, reps))
    timing <- time_case(cases[[case_name]]())
    rows[[idx]] <- data.frame(
      case = case_name,
      rep = rep,
      cpu_seconds = timing[["cpu_seconds"]],
      elapsed_seconds = timing[["elapsed_seconds"]],
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}

raw <- do.call(rbind, rows)
summary <- aggregate(
  cbind(cpu_seconds, elapsed_seconds) ~ case,
  raw,
  median
)
summary <- summary[order(summary$cpu_seconds, decreasing = TRUE), ]

cat("\nMedian timings by case:\n")
print(summary, row.names = FALSE, digits = 4)

raw_csv <- file.path(bench_dir, "benchmark-raw.csv")
summary_csv <- file.path(bench_dir, "benchmark-summary.csv")
write.csv(raw, raw_csv, row.names = FALSE)
write.csv(summary, summary_csv, row.names = FALSE)

cat("\nRaw timings:", raw_csv, "\n")
cat("Summary:", summary_csv, "\n")

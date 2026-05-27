
mypaint_device("tmp.png", bg = "grey")
plot.new()
plot.window(c(-6, 6), c(-6, 6))
set_brush("tanda/acrylic-05-paint")

idx <- 0
cols <- rep(c("red4", "blue4"), 3)
for (angle in seq(1/3, 2, len = 6) * pi) {
  t <- seq(angle, 2 * pi + angle, len = 20) %% (2 * pi)
  step <- seq(0, 5, len = 20)
  lines(sin(t) * step, cos(t) * step, lwd = 6, col = cols[[idx <- idx + 1]])
}

dev.off()
system("open tmp.png")

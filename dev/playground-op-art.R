
mypaint_device("tmp.png", res = 288, bg = hsv(0.7, 0.2, 0.4))


par(mar = rep(0, 4))
plot.new()
plot.window(c(0, 10), c(0, 10))

cols <- hsv(0.7, seq(0.2, 0.9, length.out = 13), 0.4)
rect(0, 0, 10, 10, col = "white", border = NA)
rect(2^seq(-3, 3, 0.5), 0, 2^seq(-2.7, 3.3, 0.5), 10,
     col = cols, border = NA)

set_brush("deevad/blending")
set_hand(hand(pressure = pressure_human()))
for (r in -5:5) {
  slant <- seq(0, r * 0.7, length.out = 21)
  xspline(seq(0, 10, 0.5), 5.5 + cumsum(rnorm(21, 0, 0.2)) + slant,
          lwd = 4, border = "white")
}

dev.off()
system("open tmp.png")

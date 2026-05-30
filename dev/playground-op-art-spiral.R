
mypaint_device("tmp.png", res = 288, bg = hsv(0.7, 0.2, 0.4))


par(mar = rep(0, 4), xaxs = "i", yaxs = "i")
plot.new()
plot.window(c(-5, 5), c(-5, 5))

cols <- hsv(seq(0.3, 0.8, length.out = 13), seq(0.4, 0.9, length.out = 13), 0.3)
rect(-5, -5, 5, 15, col = "white", border = NA)
rect(-5 +2^seq(-3, 3, 0.5), -5, -5 + 2^seq(-2.7, 3.3, 0.5), 5,
     col = cols, border = NA)

set_brush("Dieterle/Blender")
set_hand(hand(speed = 0.5))

theta <- seq(0, 10 * pi, length.out = 300)
r <- seq(0, 6, length.out = 300)
x <- sin(theta) * r
y <- cos(theta) * r
lines(x, y, lwd = 0.5, col = "grey90")

dev.off()
system("open tmp.png")

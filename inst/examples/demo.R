library(mypaintr)

mypaint_device(
  "demo-%d.png",
  width = 5,
  height = 4,
  brush = "chalk",
  fill_style = "brush"
)

plot(1:10, col = "grey30", pch = 16, cex = 1.5)
polygon(
  c(2, 5, 8, 6, 3),
  c(2, 7, 6, 3, 1.5),
  border = "black",
  col = rgb(0.2, 0.7, 0.5, 0.6)
)
lines(1:10, col = "firebrick", lwd = 4)
title("chalk")

dev.off()

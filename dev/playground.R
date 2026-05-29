
mypaint_device("tmp.png", res = 288)


set_brush("classic/marker_fat")
set_hand(human_hand(xtilt = 0.5, ytilt = -0.4))
plot(mpg ~ hp, data = mtcars, col = mtcars$gear, pch = 5)
set_brush("classic/marker_small")
legend("top", legend = 3:5, title = "Gears", col = 3:5, pch = 5, horiz = TRUE)
dev.off()
system("open tmp.png")

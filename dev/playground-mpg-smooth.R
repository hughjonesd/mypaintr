

library(ggplot2)
library(mypaintr)
mypaint_device("tmp.png")

print(ggplot(mpg, aes(displ, hwy)) +
  mypaint_wrap(
    geom_point(colour = "grey15", shape = "circle open"),
    brush = "classic/pencil",
    hand = human_hand(wobble = 0.02)
  ) +
  mypaint_wrap(
    geom_smooth(color = "grey20", fill = "grey60"),
    brush = "classic/pencil",
    hand = human_hand(wobble = 0, bow = 0)
  ) +
  labs(
    title = "Fuel efficiency of 38 cars",
    x = "Engine size",
    y = "Highway mpg"
  ) +
  theme_minimal(paper = "linen") +
  theme(
    panel.grid = mypaint_wrap(element_line(colour = "lightblue"),
                              brush = "classic/pencil")
  ))

dev.off()
system("open tmp.png")


library(ggplot2)
library(mypaintr)
mypaint_device("tmp.png")

print(ggplot(faithfuld, aes(waiting, eruptions, z = density)) +
  mypaint_wrap(
    geom_contour_filled(),
    brush = "experimental/hard_blot"
  ) +
  scale_fill_viridis_d(option = "F", direction = -1) +
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    axis.text = element_blank(),
    margins = margin(),
    legend.position = "none"
  ))

dev.off()
system("open tmp.png")


library(ggplot2)
library(mypaintr)
mypaint_device("tmp.png")

print(ggplot(economics |> filter(date < "2000-01-01"), aes(unemploy/pop, psavert, colour = as.numeric(date))) +
  mypaint_wrap(geom_path(aes(linewidth = as.numeric(date))),
               brush = "experimental/glow",
               hand = hand(pressure = pressure_human(peak = 1))) +
  mypaint_wrap(geom_path(linewidth = 0.5, colour = "white"),
               brush = "classic/marker_small",
               hand = human_hand(pressure = pressure_human(peak = 1))) +
  scale_linewidth_continuous(range = c(0.2, 1.2)) +
  scale_color_viridis_c(option = "inferno", end = 0.8) +
  scale_x_log10() + scale_y_log10() +
  labs(
    title = "Unemployment & savings, 1967-2000",
    x = "Unemployment (log scale)",
    y = "Personal savings rate (log scale)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none"
  ))

dev.off()
system("open tmp.png")

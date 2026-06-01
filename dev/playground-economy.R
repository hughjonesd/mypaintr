
library(ggplot2)
library(mypaintr)
mypaint_device("tmp.png")

# gratuitous overkill: a functional
new_years <- function (yr_gap) {
  function (x) filter(x, date %in% paste0(seq(1965, 2000, yr_gap), "-01-01"))
}

print(ggplot(economics |> filter(date <= "2000-01-01"),
             aes(unemploy/pop, psavert, colour = as.numeric(date))) +

  mypaint_wrap(geom_path(aes(linewidth = as.numeric(date))),
               brush = "experimental/glow",
               hand = hand(pressure = pressure_human(peak = 1))) +

  mypaint_wrap(geom_path(linewidth = 0.5, colour = "white"),
               brush = "classic/marker_small",
               hand = human_hand(pressure = pressure_human(peak = 1))) +

  geom_point(data = new_years(5), aes(size = as.numeric(date)), color = "grey35") +

  geom_label(data = new_years(5), aes(label = format(date, "%Y")),
             adj = -0.2, fill = scales::alpha("white", 0.75), color = "grey35",
             label.padding = unit(0.1, "lines"), linewidth = 0) +

  scale_linewidth_continuous(range = c(0.2, 1.2)) +
  scale_radius(range = c(0.2, 1.2)) +
  scale_color_viridis_c(option = "inferno", end = 0.8) +
  scale_x_log10() +
  scale_y_log10() +

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

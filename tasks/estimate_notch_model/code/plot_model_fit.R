# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

cell_fit <- read_csv("../output/cell_fit.csv", show_col_types = FALSE,
  col_types = cols(buildings = col_character())) |>
  filter(specification == "notch_and_kink", size_bin != "under 50")
estimate <- read_csv("../output/estimates.csv", show_col_types = FALSE) |>
  filter(specification == "notch_and_kink")
profiles <- read_csv("../output/parameter_profiles.csv", show_col_types = FALSE) |>
  filter(specification == "notch_and_kink")

bins <- unique(cell_fit$size_bin)
plot_data <- cell_fit |>
  mutate(size_bin = factor(size_bin, levels = bins),
    buildings = factor(paste(buildings, if_else(buildings == "1", "building", "buildings")),
      levels = c("1 building", "2 buildings", "3+ buildings")))

figure <- ggplot(plot_data, aes(size_bin)) +
  geom_col(aes(y = observed, fill = "Observed after 485-x"), width = 0.75) +
  geom_point(aes(y = benchmark, shape = "Historical benchmark"), color = "grey40", size = 2) +
  geom_point(aes(y = fitted, shape = "Model"), color = "#BF3A25", size = 2.4) +
  facet_wrap(~buildings, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = "#9CC3E4") +
  scale_shape_manual(values = c("Historical benchmark" = 1, "Model" = 16)) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
  labs(
    title = "Parent size and building count: observed, historical benchmark and model",
    subtitle = sprintf("Jump %.3g, kink %.3g, mean splitting cost %.3g per added building (costs relative to building 99 units)",
      estimate$kappa, estimate$tau, estimate$sigma),
    x = "Parent units", y = "Share of parents", fill = NULL, shape = NULL,
    caption = paste(
      sprintf("%d historical parents (2019-2022), reweighted on zoning and borough; %d recent parents (2025 to July 8, 2026).",
        estimate$historical_parents, estimate$post_parents),
      "Shares are of all parents with 50+ units; each panel has its own scale.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, size = 8.5))

ggsave("../output/pdf/model_fit.pdf", figure, width = 9, height = 8)
ggsave("../output/model_fit.png", figure, width = 9, height = 8, dpi = 180, bg = "white")

parameter_labels <- c(kappa = "Jump at 100 units", tau = "Kink above 100 units",
  sigma = "Mean splitting cost per added building (log10)")
profile_figure <- profiles |>
  mutate(relative = objective / min(objective),
    value = if_else(parameter == "sigma", log10(value), value),
    parameter = factor(parameter_labels[parameter], levels = parameter_labels)) |>
  ggplot(aes(value, relative)) +
  geom_line(color = "#24689B") +
  geom_point(color = "#24689B", size = 1.5) +
  facet_wrap(~parameter, scales = "free_x", nrow = 1) +
  coord_cartesian(ylim = c(1, 3)) +
  labs(title = "How sharply the data pick out each parameter",
    subtitle = "Best objective at each value, relative to the overall best (other parameters re-optimized)",
    x = "Parameter value", y = "Objective relative to best") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")

ggsave("../output/pdf/parameter_profiles.pdf", profile_figure, width = 10, height = 3.8)
ggsave("../output/parameter_profiles.png", profile_figure, width = 10, height = 3.8, dpi = 180, bg = "white")

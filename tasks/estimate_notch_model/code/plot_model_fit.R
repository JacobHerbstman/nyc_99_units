# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

cell_fit <- read_csv("../output/cell_fit.csv", show_col_types = FALSE,
  col_types = cols(buildings = col_character())) |>
  filter(specification == "main", size_bin != "under 50")
estimate <- read_csv("../output/estimates.csv", show_col_types = FALSE) |>
  filter(specification == "main")

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
  scale_y_continuous(labels = scales::label_percent(accuracy = 0.5)) +
  labs(
    title = "Parent size and building count: observed, historical benchmark and model",
    subtitle = sprintf(paste("Jump %.3g, kink %.3g; k added buildings cost c * k^%.3g, mean c = %.3g",
      "(costs relative to building 99 units)"), estimate$kappa, estimate$tau, estimate$gamma, estimate$sigma),
    x = "Parent units", y = "Share of parents", fill = NULL, shape = NULL,
    caption = paste(
      sprintf("%d historical parents (2019-2022), reweighted on zoning and borough; %d recent parents (2025 to July 8, 2026) with 300 or fewer units.",
        estimate$historical_parents, estimate$post_parents),
      "Shares are of parents with 50-300 units in each distribution; each panel has its own scale.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, size = 8.5))

ggsave("../output/pdf/model_fit.pdf", figure, width = 9, height = 8)

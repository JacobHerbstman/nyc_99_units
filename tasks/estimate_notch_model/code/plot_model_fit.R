# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_notch_model/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

# The main model: the scaled burden of fit_heterogeneity.R, with its bootstrap
# interval for units lost.
cell_fit <- read_csv("../output/heterogeneity_cell_fit.csv", show_col_types = FALSE,
  col_types = cols(buildings = col_character())) |>
  filter(model == "scaled_burden", size_bin != "under 50")
estimate <- read_csv("../output/heterogeneity_estimates.csv", show_col_types = FALSE) |>
  filter(model == "scaled_burden")
units_lost <- read_csv("../output/scaled_burden_bootstrap_estimates_all_filings.csv", show_col_types = FALSE) |>
  filter(parameter == "units_lost")
historical_parents <- read_csv("../output/estimates.csv", show_col_types = FALSE) |>
  filter(specification == "least_squares") |>
  pull(historical_parents)

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
    subtitle = sprintf(paste("Median jump %.3g, kink %.3g, burden spread %.3g; k added buildings cost c * k^%.3g,",
      "mean c = %.3g (costs relative to building 99 units)"),
      estimate$kappa, estimate$tau, estimate$dispersion, estimate$gamma, estimate$sigma),
    x = "Parent units", y = "Share of parents", fill = NULL, shape = NULL,
    caption = paste(
      sprintf(paste("%d historical parents (2019-2022), reweighted on zoning and borough; %d recent parents",
        "(2025 to July 8, 2026) with 300 or fewer units."), historical_parents, sum(cell_fit$observed_parents)),
      sprintf(paste("Model shares include the unexplained share %.3g. Units lost %s (bootstrap 95%% interval %s-%s)."),
        estimate$epsilon, format(round(units_lost$estimate), big.mark = ","),
        format(round(units_lost$bootstrap_lower), big.mark = ","),
        format(round(units_lost$bootstrap_upper), big.mark = ",")),
      "Shares are of parents with 50-300 units in each distribution; each panel has its own scale.", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", legend.justification = "left",
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0, size = 8.5))

ggsave("../output/pdf/model_fit.pdf", figure, width = 9, height = 8)

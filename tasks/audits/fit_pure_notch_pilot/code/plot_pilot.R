# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_pure_notch_pilot/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
})

parents <- read_csv("../output/analysis_parents.csv", show_col_types = FALSE)
grid <- read_csv("../output/parameter_grid.csv", show_col_types = FALSE)
cells <- read_csv("../output/joint_cell_predictions.csv", show_col_types = FALSE)
best <- read_csv("../output/best_fits.csv", show_col_types = FALSE)
contributions <- read_parquet("../output/best_parent_contributions.parquet")
baseline <- filter(best, specification == "separate_baseline")
colors <- c("Weighted pre-period" = "#7A7A7A", "Post observed" = "#19638D", "Model prediction" = "#CF6538")
theme_set(theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom",
        plot.title = element_text(face = "bold")))

distribution <- bind_rows(
  parents |> transmute(series = if_else(sample == "historical", "Weighted pre-period", "Post observed"),
                       m = parent_total_units, J = n_components, mass = weight),
  contributions |> filter(specification == "separate_baseline") |>
    transmute(series = "Model prediction", m, J, mass))
size_shares <- distribution |> group_by(series, m) |>
  summarise(share = sum(mass), .groups = "drop")
organization_shares <- distribution |> group_by(series, J) |>
  summarise(share = sum(mass), .groups = "drop")
size_plot <- ggplot(filter(size_shares, m <= 300), aes(m, share, color = series)) +
  geom_linerange(aes(ymin = 0, ymax = share), position = position_dodge(width = .6)) +
  geom_point(size = 1.6, position = position_dodge(width = .6)) +
  scale_color_manual(values = colors) + scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = c(50, 99, 150, 198, 250, 300)) +
  labs(title = "Parent sizes", subtitle = "Shares of all eligible parents; 301+ retained in estimation",
       x = "Proposed parent units", y = "Share of parents", color = NULL)
organization_plot <- ggplot(filter(organization_shares, J >= 2), aes(factor(J), share, fill = series)) +
  geom_col(position = "dodge", width = .75) + scale_fill_manual(values = colors) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Parents with multiple constituents", subtitle = "Each bar uses all eligible parents as the denominator",
       x = "Number of constituents", y = "Share of parents", fill = NULL)
residuals <- filter(cells, fit_id == baseline$fit_id) |>
  mutate(size_bin = gsub("–", "-", size_bin, fixed = TRUE),
         size_bin = factor(size_bin, levels = unique(size_bin)),
         residual_pp = 100 * (predicted_share - observed_share))
residual_plot <- ggplot(residuals, aes(size_bin, organization, fill = residual_pp)) +
  geom_tile(color = "white") + geom_text(aes(label = sprintf("%.1f", residual_pp)), size = 3) +
  scale_fill_gradient2(low = "#24648D", mid = "white", high = "#CF6538", midpoint = 0) +
  labs(title = "Where the model misses", subtitle = "Predicted minus observed share, percentage points",
       x = "Parent units", y = "Constituents", fill = "pp") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right")

for (format in c("png", "pdf")) {
  if (format == "png") png("../output/fit_overview.png", width = 13, height = 10, units = "in", res = 160)
  if (format == "pdf") pdf("../output/pdf/fit_overview.pdf", width = 13, height = 10, family = "Helvetica")
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(3, 2, heights = c(.4, .32, .28))))
  print(size_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1:2))
  print(organization_plot, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1:2))
  print(residual_plot, vp = grid::viewport(layout.pos.row = 3, layout.pos.col = 1:2))
  dev.off()
}

profiles <- filter(grid, specification %in% c("separate_baseline", "joint_assessment")) |>
  select(specification, kappa, sigma_org, objective) |>
  pivot_longer(c(kappa, sigma_org), names_to = "parameter", values_to = "value") |>
  group_by(specification, parameter, value) |>
  summarise(objective = min(objective), .groups = "drop")
profile_plot <- ggplot(profiles, aes(value, objective, color = specification)) +
  geom_line() + geom_point() + facet_wrap(~parameter, scales = "free_x") +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 5)) +
  scale_color_manual(values = c(separate_baseline = "#CF6538", joint_assessment = "#19638D"),
                     labels = c(separate_baseline = "Separate assessment", joint_assessment = "Joint assessment")) +
  labs(title = "Pure-notch pilot: parameter profiles", subtitle = "Lowest squared-share error at each parameter value; tau = 0, lambda = 1",
       x = "Normalized cost", y = "Sum of squared errors across 45 cells", color = NULL,
       caption = "Joint assessment leaves organization unchanged, so its fit is constant across organization costs. Profiles are not confidence intervals.")
ggsave("../output/parameter_profiles.png", profile_plot, width = 12, height = 5, dpi = 160, bg = "white")
ggsave("../output/pdf/parameter_profiles.pdf", profile_plot, width = 12, height = 5, device = "pdf")

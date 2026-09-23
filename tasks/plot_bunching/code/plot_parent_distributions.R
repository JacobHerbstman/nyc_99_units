# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")
# exact_plot_minimum <- 50L
# exact_plot_maximum <- 300L
# preferred_minimum <- 50L
# pooled_tail_start <- 301L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(tibble)
  library(tidyr)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 4L)
  exact_plot_minimum <- as.integer(args[1])
  exact_plot_maximum <- as.integer(args[2])
  preferred_minimum <- as.integer(args[3])
  pooled_tail_start <- as.integer(args[4])
}

if (
  any(is.na(c(
    exact_plot_minimum,
    exact_plot_maximum,
    preferred_minimum,
    pooled_tail_start
  ))) ||
    exact_plot_minimum >= exact_plot_maximum ||
    preferred_minimum != exact_plot_minimum ||
    pooled_tail_start != exact_plot_maximum + 1L
) {
  stop("Descriptive scale-shape arguments are not internally consistent.")
}

parents <- read_parquet("../input/parent_opportunity_panel.parquet")

stopifnot(!anyDuplicated(parents$parent_id))

period_levels <- parents |>
  distinct(sample, period) |>
  arrange(match(sample, c("historical", "post_policy"))) |>
  pull(period)

if (length(period_levels) != 2L) {
  stop("Expected exactly one historical and one post-policy period.")
}

period_colors <- c("#4C78A8", "#E45756")
names(period_colors) <- period_levels

save_pdf <- function(figure, out_path, width = 11, height = 5.8) {
  ggsave(out_path, figure, width = width, height = height, bg = "white")
}

parents_ab <- parents |>
  filter(included_ab) |>
  mutate(period = factor(period, levels = period_levels))

parent_total_exact_distribution <- parents_ab |>
  filter(
    parent_total_units >= exact_plot_minimum,
    parent_total_units <= exact_plot_maximum
  ) |>
  count(period, exposure_years, parent_total_units, name = "parent_count") |>
  complete(
    period = factor(period, levels = period_levels),
    parent_total_units = seq.int(exact_plot_minimum, exact_plot_maximum),
    fill = list(parent_count = 0L)
  ) |>
  left_join(
    parents_ab |> distinct(period, exposure_years),
    by = "period",
    relationship = "many-to-one",
    suffix = c("", "_period")
  ) |>
  mutate(
    exposure_years = coalesce(exposure_years, exposure_years_period),
    annualized_count = parent_count / exposure_years
  ) |>
  select(-exposure_years_period) |>
  group_by(period) |>
  mutate(
    support_parent_count = sum(parent_count),
    normalized_share = parent_count / support_parent_count
  ) |>
  ungroup() |>
  arrange(period, parent_total_units)

preferred_parent_distribution <- parents_ab |>
  filter(parent_total_units >= preferred_minimum) |>
  mutate(
    unit_bin = if_else(
      parent_total_units < pooled_tail_start,
      as.character(parent_total_units),
      paste0(pooled_tail_start, "+")
    ),
    unit_bin_order = pmin(parent_total_units, pooled_tail_start)
  ) |>
  count(
    period,
    exposure_years,
    unit_bin,
    unit_bin_order,
    name = "parent_count"
  ) |>
  group_by(period) |>
  mutate(
    opportunity_count = sum(parent_count),
    normalized_share = parent_count / opportunity_count,
    annualized_count = parent_count / exposure_years
  ) |>
  ungroup() |>
  arrange(period, unit_bin_order)

annualized_figure <- ggplot(
  parent_total_exact_distribution,
  aes(
    x = parent_total_units,
    y = annualized_count,
    color = period,
    group = period
  )
) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.9) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(exact_plot_minimum, exact_plot_maximum)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Annualized A/B parent opportunities",
    subtitle = paste0(
      "Exact one-unit bins; each count is divided by its exact observation window."
    ),
    x = "Total proposed units in the linked parent",
    y = "Parent opportunities per year",
    color = NULL,
    caption = "Reference lines mark 99, 150, 198, and 297 units."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

normalized_reproduction_figure <- ggplot(
  parent_total_exact_distribution,
  aes(
    x = parent_total_units,
    y = normalized_share,
    color = period,
    group = period
  )
) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.9) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(exact_plot_minimum, exact_plot_maximum)
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Normalized A/B parent distribution: 50-300 reproduction",
    subtitle = "Each period sums to 100% within 50-300 units.",
    x = "Total proposed units in the linked parent",
    y = "Share of 50-300-unit parent opportunities",
    color = NULL,
    caption = "Reference lines mark 99, 150, 198, and 297 units."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

preferred_plot_rows <- preferred_parent_distribution |>
  filter(unit_bin_order <= exact_plot_maximum) |>
  transmute(period, unit_count = as.integer(unit_bin), normalized_share) |>
  complete(
    period,
    unit_count = seq.int(exact_plot_minimum, exact_plot_maximum),
    fill = list(normalized_share = 0)
  )

preferred_normalized_figure <- ggplot(
  preferred_plot_rows,
  aes(
    x = unit_count,
    y = normalized_share,
    color = period,
    group = period
  )
) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.9) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(exact_plot_minimum, exact_plot_maximum)
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Preferred normalized A/B parent distribution",
    subtitle = paste0(
      "Denominator includes every parent with at least 50 units; ",
      "pooled 301+ mass remains in the denominator."
    ),
    x = "Total proposed units in the linked parent",
    y = "Share of all 50+ parent opportunities",
    color = NULL,
    caption = "Exact bins through 300; reference lines mark 99, 150, 198, and 297."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

SaveData(
  parent_total_exact_distribution,
  c("period", "parent_total_units"),
  "../output/parent_total_exact_distribution_50_300.csv"
)
SaveData(
  preferred_parent_distribution,
  c("period", "unit_bin_order"),
  "../output/preferred_parent_distribution_50_plus.csv"
)
save_pdf(annualized_figure, "../output/pdf/annualized_parent_total_50_300.pdf")
save_pdf(normalized_reproduction_figure, "../output/pdf/normalized_parent_total_50_300_reproduction.pdf")
save_pdf(preferred_normalized_figure, "../output/pdf/normalized_parent_total_50_plus.pdf")

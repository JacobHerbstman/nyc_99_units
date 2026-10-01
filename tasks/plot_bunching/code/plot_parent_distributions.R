# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/plot_bunching/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(tidyr)
})

# Distribution of A/B parent totals over exact one-unit bins from 50 to 300,
# annualized and as shares.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |> filter(included_ab)
stopifnot(!anyDuplicated(parents$parent_id))
periods <- parents |> distinct(sample, period) |> arrange(sample) |> pull(period)
stopifnot(length(periods) == 2L)
parents <- parents |> mutate(period = factor(period, levels = periods))
years <- parents |> distinct(period, exposure_years)

exact <- parents |>
  filter(parent_total_units >= 50, parent_total_units <= 300) |>
  count(period, parent_total_units, name = "parents") |>
  complete(period, parent_total_units = 50:300, fill = list(parents = 0L)) |>
  left_join(years, by = "period", relationship = "many-to-one") |>
  group_by(period) |>
  mutate(annualized = parents / exposure_years, share_50_300 = parents / sum(parents)) |>
  ungroup()
# The preferred shares keep every parent of 50 or more units, including those
# above 300, in the denominator.
exact <- exact |>
  left_join(parents |> filter(parent_total_units >= 50) |> count(period, name = "parents_50_plus"),
    by = "period", relationship = "many-to-one") |>
  mutate(share_50_plus = parents / parents_50_plus)

parent_plot <- function(y, title, subtitle, y_label, caption, labels = waiver()) {
  ggplot(exact, aes(parent_total_units, .data[[y]], color = period, group = period)) +
    geom_vline(xintercept = c(99, 150, 198, 297), color = "grey72", linetype = "dashed", linewidth = 0.4) +
    geom_line(linewidth = 0.9) +
    scale_color_manual(values = setNames(c("#4C78A8", "#E45756"), periods)) +
    scale_x_continuous(breaks = c(50, 99, 150, 198, 250, 297), limits = c(50, 300)) +
    scale_y_continuous(labels = labels, expand = if (y == "annualized") expansion(mult = c(0, 0.08)) else waiver()) +
    labs(title = title, subtitle = subtitle, x = "Total proposed units in the linked parent", y = y_label,
      color = NULL, caption = caption) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top", panel.grid.minor = element_blank())
}

ggsave("../output/pdf/annualized_parent_total_50_300.pdf", parent_plot("annualized",
    "Annualized A/B parent opportunities",
    "Exact one-unit bins; each count is divided by its exact observation window.",
    "Parent opportunities per year", "Reference lines mark 99, 150, 198, and 297 units."),
  width = 11, height = 5.8, bg = "white")
ggsave("../output/pdf/normalized_parent_total_50_300_reproduction.pdf", parent_plot("share_50_300",
    "Normalized A/B parent distribution: 50-300 reproduction", "Each period sums to 100% within 50-300 units.",
    "Share of 50-300-unit parent opportunities", "Reference lines mark 99, 150, 198, and 297 units.",
    label_percent(accuracy = 0.1)),
  width = 11, height = 5.8, bg = "white")
ggsave("../output/pdf/normalized_parent_total_50_plus.pdf", parent_plot("share_50_plus",
    "Preferred normalized A/B parent distribution",
    "Denominator includes every parent with at least 50 units; pooled 301+ mass remains in the denominator.",
    "Share of all 50+ parent opportunities", "Exact bins through 300; reference lines mark 99, 150, 198, and 297."),
  width = 11, height = 5.8, bg = "white")

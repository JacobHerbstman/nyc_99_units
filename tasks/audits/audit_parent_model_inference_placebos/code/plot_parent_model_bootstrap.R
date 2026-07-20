# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_model_inference_placebos/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

bootstrap_summary <- read_csv(
  "../output/parent_model_bootstrap_summary.csv",
  show_col_types = FALSE
)

metric_order <- c(
  "frontier_from_missing_100_plus",
  "mean_n0_from_missing_100_plus",
  "frontier_from_exact_99",
  "mean_n0_from_exact_99",
  "conservation_gap",
  "missing_100_plus",
  "expected_no_notch_100_plus",
  "excess_exact_99",
  "expected_no_notch_exact_99"
)
metric_labels <- c(
  expected_no_notch_exact_99 = "Expected exact-99 mass",
  excess_exact_99 = "Excess exact-99 mass",
  expected_no_notch_100_plus = "Expected 100+ mass",
  missing_100_plus = "Missing 100+ mass",
  conservation_gap = "Conservation gap",
  mean_n0_from_exact_99 = "Affected mean N0: exact-99",
  frontier_from_exact_99 = "Frontier: exact-99",
  mean_n0_from_missing_100_plus = "Affected mean N0: missing 100+",
  frontier_from_missing_100_plus = "Frontier: missing 100+"
)

if (
  nrow(bootstrap_summary) == 0L ||
    anyDuplicated(bootstrap_summary[c("bootstrap_type", "metric")]) ||
    !all(metric_order %in% bootstrap_summary$metric)
) {
  stop("Parent-model bootstrap summary failed plotting QC.")
}

bootstrap_plot <- bootstrap_summary |>
  filter(metric %in% metric_order) |>
  mutate(
    metric_label = factor(
      metric_labels[metric],
      levels = unname(metric_labels[metric_order])
    ),
    bootstrap_label = recode(
      bootstrap_type,
      fixed_2025_parent_population = "Historical parents resampled; 2025 fixed",
      two_sample_historical_and_2025 = "Historical and 2025 parents resampled"
    )
  ) |>
  ggplot(aes(y = metric_label, color = bootstrap_label)) +
  geom_errorbarh(aes(
    xmin = interval_lower_value,
    xmax = interval_upper_value
  ), height = 0.14, position = position_dodge(width = 0.35)) +
  geom_point(
    aes(x = bootstrap_median),
    position = position_dodge(width = 0.35),
    size = 1.7
  ) +
  geom_point(
    aes(x = point_estimate),
    color = "black",
    shape = 4,
    size = 1.6,
    stroke = 0.7
  ) +
  facet_wrap(vars(metric_label), scales = "free", ncol = 3L) +
  scale_x_continuous(expand = expansion(mult = c(0.06, 0.08))) +
  scale_y_discrete(labels = NULL) +
  scale_color_manual(values = c("#1769AA", "#D95F02")) +
  labs(
    title = "Parent-level bootstrap uncertainty",
    subtitle = paste0(
      unique(bootstrap_summary$bootstrap_reps_requested),
      " parent resamples requested; ",
      unique(bootstrap_summary$successful_reps),
      " successful; bars show 2.5-97.5 percentile intervals"
    ),
    x = NULL,
    y = NULL,
    color = NULL,
    caption = "Black crosses are the preferred-sample point estimates."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.spacing.x = grid::unit(1.2, "lines"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title.position = "plot"
  )

ggsave(
  "../output/parent_model_bootstrap_intervals.pdf",
  bootstrap_plot,
  width = 11.5,
  height = 7,
  bg = "white"
)

cat("Wrote parent-model bootstrap interval figure to ../output\n")

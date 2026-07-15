# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_unit_distribution/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(readr)
  library(scales)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

reference_window <- "train_2013_2020_test_2021_2022h1"
reference_model <- "lognormal_linear_simple"

reference_predictions <- read_parquet("../output/no_notch_heldout_predictions.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(window == reference_window, model == reference_model)

window_specs <- read_csv("../output/no_notch_time_windows.csv", show_col_types = FALSE) |>
  mutate(
    window_short = recode(
      window,
      train_2010_2015_test_2016_2017 = "2010-15 -> 2016-17",
      train_2010_2017_test_2018_2020 = "2010-17 -> 2018-20",
      train_2013_2017_test_2018_2020 = "2013-17 -> 2018-20",
      train_2016_2018_test_2019_2020 = "2016-18 -> 2019-20",
      train_2010_2020_test_2021_2022h1 = "2010-20 -> 2021-22H1",
      train_2013_2020_test_2021_2022h1 = "2013-20 -> 2021-22H1",
      train_2016_2020_test_2021_2022h1 = "2016-20 -> 2021-22H1",
      train_2018_2020_test_2021_2022h1 = "2018-20 -> 2021-22H1",
      train_2016_2021_test_2022h1 = "2016-21 -> 2022H1",
      train_2018_2021_test_2022h1 = "2018-21 -> 2022H1",
      train_2013_2020_test_post_2022 = "2013-20 -> post-2022",
      train_2016_2020_test_post_2022 = "2016-20 -> post-2022",
      train_2018_2021_test_post_2022 = "2018-21 -> post-2022"
    ),
    window_short = factor(window_short, levels = rev(window_short))
  )

individual_bins <- reference_predictions |>
  mutate(prediction_bin = ntile(predicted_median_units, 10L)) |>
  group_by(prediction_bin) |>
  summarise(
    rows = n(),
    predicted_geometric_mean_units = exp(mean(log(predicted_median_units))),
    actual_geometric_mean_units = exp(mean(log(units))),
    .groups = "drop"
  )

probability_bins <- reference_predictions |>
  mutate(probability_bin = ntile(probability_at_least_100, 10L)) |>
  group_by(probability_bin) |>
  summarise(
    rows = n(),
    mean_predicted_probability = mean(probability_at_least_100),
    observed_share_at_least_100 = mean(units >= 100L),
    .groups = "drop"
  )

bootstrap_summary <- read_csv(
  "../output/no_notch_bootstrap_summary.csv",
  show_col_types = FALSE
)

window_threshold_comparison <- bootstrap_summary |>
  filter(
    model == reference_model,
    sample == "all",
    metric %in% c(
      "at_least_100_expected_rows",
      "at_least_100_observed_rows"
    )
  ) |>
  select(
    window, metric, bootstrap_mean, bootstrap_p025, bootstrap_p975
  ) |>
  pivot_wider(
    names_from = metric,
    values_from = c(bootstrap_mean, bootstrap_p025, bootstrap_p975)
  ) |>
  left_join(
    window_specs |>
      select(window, window_short, regime_note),
    by = "window",
    relationship = "many-to-one"
  ) |>
  transmute(
    window,
    window_short,
    regime_note,
    predicted_rows = bootstrap_mean_at_least_100_expected_rows,
    predicted_p025 = bootstrap_p025_at_least_100_expected_rows,
    predicted_p975 = bootstrap_p975_at_least_100_expected_rows,
    actual_rows = bootstrap_mean_at_least_100_observed_rows
  )

individual_plot <- ggplot(
  reference_predictions,
  aes(x = predicted_median_units, y = units)
) +
  geom_abline(slope = 1, intercept = 0, color = "#777777", linewidth = 0.5) +
  geom_point(alpha = 0.18, size = 1.2, color = "#555555") +
  geom_line(
    data = individual_bins,
    aes(
      x = predicted_geometric_mean_units,
      y = actual_geometric_mean_units
    ),
    color = "#0072B2",
    linewidth = 0.8
  ) +
  geom_point(
    data = individual_bins,
    aes(
      x = predicted_geometric_mean_units,
      y = actual_geometric_mean_units
    ),
    color = "#0072B2",
    size = 2
  ) +
  scale_x_log10(
    breaks = c(6, 10, 20, 50, 100, 250, 500, 1000),
    labels = label_number()
  ) +
  scale_y_log10(
    breaks = c(6, 10, 20, 50, 100, 250, 500, 1000),
    labels = label_number()
  ) +
  coord_equal() +
  labs(
    title = "Individual held-out predictions",
    subtitle = "Blue points average prediction deciles",
    x = "Predicted median units",
    y = "Actual units"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

probability_plot <- ggplot(
  probability_bins,
  aes(x = mean_predicted_probability, y = observed_share_at_least_100)
) +
  geom_abline(slope = 1, intercept = 0, color = "#777777", linewidth = 0.5) +
  geom_line(color = "#0072B2", linewidth = 0.8) +
  geom_point(color = "#0072B2", size = 2.2) +
  scale_x_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.25),
    labels = label_percent()
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.25),
    labels = label_percent()
  ) +
  coord_equal() +
  labs(
    title = "Calibration of Pr(units >= 100)",
    subtitle = "Ten equal-sized bins in the reference test",
    x = "Mean predicted probability",
    y = "Observed share"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

window_plot <- ggplot(
  window_threshold_comparison,
  aes(y = window_short)
) +
  geom_segment(
    aes(x = predicted_p025, xend = predicted_p975, yend = window_short),
    color = "#56B4E9",
    linewidth = 1.5
  ) +
  geom_segment(
    aes(x = actual_rows, xend = predicted_rows, yend = window_short),
    color = "#999999",
    linewidth = 0.5
  ) +
  geom_point(
    aes(x = actual_rows, shape = "Actual"),
    color = "#444444",
    size = 2.2
  ) +
  geom_point(
    aes(x = predicted_rows, shape = "Predicted"),
    color = "#0072B2",
    size = 2.4
  ) +
  scale_shape_manual(values = c("Actual" = 16, "Predicted" = 17)) +
  labs(
    title = "Aggregate 100-plus counts across all forward time splits",
    subtitle = "Blue ranges are 95% BBL-clustered bootstrap intervals",
    x = "Held-out filings with at least 100 units",
    y = NULL,
    shape = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position = "bottom"
  )

dashboard <- (individual_plot | probability_plot) / window_plot +
  plot_layout(heights = c(1, 1.15)) +
  plot_annotation(
    title = "How well does the simple no-notch model predict held-out units?",
    subtitle = "Simple linear model with i.i.d. normal shocks in log preferred units"
  )

write_csv_if_changed(
  individual_bins,
  "../output/no_notch_individual_prediction_bins.csv"
)
write_csv_if_changed(
  probability_bins,
  "../output/no_notch_probability_calibration_bins.csv"
)
write_csv_if_changed(
  window_threshold_comparison,
  "../output/no_notch_window_threshold_comparison.csv"
)

ggsave(
  "../output/no_notch_predicted_actual_dashboard.pdf",
  dashboard,
  width = 11,
  height = 10,
  bg = "white"
)
ggsave(
  "../output/no_notch_predicted_actual_dashboard.png",
  dashboard,
  width = 11,
  height = 10,
  dpi = 180,
  bg = "white"
)

cat("Wrote predicted-versus-actual validation plots.\n")

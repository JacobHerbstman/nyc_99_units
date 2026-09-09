# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_scale_shape_counterfactual/code")
# minimum_units <- 50L
# exact_plot_maximum <- 300L
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

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/scale_shape_helpers.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected minimum units, exact-plot maximum, and pooled-tail start.")
}

minimum_units <- as.integer(args[1])
exact_plot_maximum <- as.integer(args[2])
pooled_tail_start <- as.integer(args[3])

if (
  any(is.na(c(minimum_units, exact_plot_maximum, pooled_tail_start))) ||
    minimum_units >= exact_plot_maximum ||
    pooled_tail_start != exact_plot_maximum + 1L
) {
  stop("Counterfactual-audit support arguments are inconsistent.")
}

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as.data.frame() |>
  as_tibble()
counterfactual_distributions <- read_csv(
  "../input/reweighted_counterfactual_distributions.csv",
  show_col_types = FALSE
)
local_excess_deficit_moments <- read_csv(
  "../input/local_excess_deficit_moments.csv",
  show_col_types = FALSE
)

analysis_parents <- parents |>
  filter(
    included_ab,
    parent_total_units >= minimum_units,
    composition_eligible
  )
historical <- analysis_parents |> filter(sample == "historical")
post <- analysis_parents |>
  filter(sample == "post_policy") |>
  mutate(observation_weight = 1)

if (
  nrow(historical) == 0L ||
    nrow(post) == 0L ||
    anyDuplicated(historical$parent_id) ||
    anyDuplicated(post$parent_id)
) {
  stop("Counterfactual audit samples failed parent-level QC.")
}

parent_counterfactual <- counterfactual_distributions |>
  filter(
    outcome == "Parent total",
    series == "Historical reweighted to post sites"
  ) |>
  select(unit_bin_order, counterfactual_share = share)
parent_observed <- counterfactual_distributions |>
  filter(outcome == "Parent total", series == "Post observed") |>
  select(unit_bin_order, observed_share = share)

cumulative_99 <- full_join(
  parent_counterfactual,
  parent_observed,
  by = "unit_bin_order",
  relationship = "one-to-one"
) |>
  mutate(
    counterfactual_share = coalesce(counterfactual_share, 0),
    observed_share = coalesce(observed_share, 0)
  ) |>
  filter(unit_bin_order >= 100L, unit_bin_order <= 149L) |>
  arrange(unit_bin_order)

excess_at_99 <- local_excess_deficit_moments |>
  filter(outcome == "Parent total", moment == "excess_at_99") |>
  pull(estimate)
frontier_crossing <- cumulative_99 |>
  mutate(counterfactual_cumulative_mass = cumsum(counterfactual_share)) |>
  filter(counterfactual_cumulative_mass >= excess_at_99) |>
  slice_head(n = 1)

if (nrow(frontier_crossing) == 0L) {
  exploratory_q_theta <- tibble(
    outcome = "Parent total",
    q_crossing = NA_integer_,
    target_excess_at_99 = excess_at_99,
    counterfactual_mass_100_to_q_minus_1 = sum(
      cumulative_99$counterfactual_share
    ),
    q_found_below_150 = FALSE,
    theta_grid_upper = NA_integer_,
    theta = NA_real_,
    compression_target_post_mass = NA_real_,
    compression_counterfactual_mass = NA_real_,
    compression_absolute_gap = NA_real_,
    interpretation = "No discrete source frontier reached the 99 excess below 150."
  )
} else {
  q_crossing <- frontier_crossing$unit_bin_order + 1L
  q_source_mass <- sum(
    cumulative_99$counterfactual_share[
      cumulative_99$unit_bin_order < q_crossing
    ]
  )
  compression_target <- sum(
    cumulative_99$observed_share[
      cumulative_99$unit_bin_order >= 100L &
        cumulative_99$unit_bin_order <= q_crossing
    ]
  )
  theta_candidates <- tibble(theta_grid_upper = seq.int(q_crossing, 149L)) |>
    rowwise() |>
    mutate(
      compression_counterfactual_mass = sum(
        cumulative_99$counterfactual_share[
          cumulative_99$unit_bin_order >= q_crossing &
            cumulative_99$unit_bin_order <= theta_grid_upper
        ]
      ),
      compression_absolute_gap = abs(
        compression_counterfactual_mass - compression_target
      )
    ) |>
    ungroup() |>
    arrange(compression_absolute_gap, theta_grid_upper) |>
    slice_head(n = 1)

  exploratory_q_theta <- theta_candidates |>
    transmute(
      outcome = "Parent total",
      q_crossing,
      target_excess_at_99 = excess_at_99,
      counterfactual_mass_100_to_q_minus_1 = q_source_mass,
      q_found_below_150 = TRUE,
      theta_grid_upper,
      theta = theta_grid_upper / q_crossing,
      compression_target_post_mass = compression_target,
      compression_counterfactual_mass,
      compression_absolute_gap,
      interpretation = paste(
        "Discrete exploratory moment; not a structural cost estimate and",
        "conditional on the selected parent-total distribution."
      )
    )
}

placebo_definitions <- tribble(
  ~placebo, ~historical_years, ~target_year,
  "2019-2020 predicts 2021", list(2019:2020), 2021L,
  "2019-2021 predicts 2022", list(2019:2021), 2022L
)
placebo_distribution_rows <- list()
placebo_performance_rows <- list()

for (placebo_index in seq_len(nrow(placebo_definitions))) {
  definition <- placebo_definitions[placebo_index, ]
  placebo_historical <- historical |>
    filter(cohort_year %in% unlist(definition$historical_years))
  placebo_target <- historical |>
    filter(cohort_year == definition$target_year)
  placebo_calibration <- calibrate_historical_to_target(
    placebo_historical,
    placebo_target
  )
  placebo_target <- placebo_calibration$target |>
    mutate(observation_weight = 1)
  predicted <- weighted_exact_distribution(
    placebo_calibration$historical,
    "parent_total_units",
    "calibration_weight",
    minimum_units,
    pooled_tail_start
  )
  actual <- weighted_exact_distribution(
    placebo_target,
    "parent_total_units",
    "observation_weight",
    minimum_units,
    pooled_tail_start
  )
  placebo_distribution_rows[[placebo_index]] <- bind_rows(
    predicted |> mutate(series = "Predicted"),
    actual |> mutate(series = "Actual")
  ) |>
    mutate(placebo = definition$placebo)
  placebo_performance_rows[[placebo_index]] <- shape_distance(
    predicted,
    actual
  ) |>
    mutate(
      placebo = definition$placebo,
      historical_parents = nrow(placebo_historical),
      target_parents = nrow(placebo_target),
      effective_sample_size = sum(
        placebo_calibration$historical$calibration_weight
      )^2 / sum(placebo_calibration$historical$calibration_weight^2),
      predicted_share_99 = predicted$share[predicted$unit_bin_order == 99L],
      actual_share_99 = actual$share[actual$unit_bin_order == 99L],
      predicted_share_198 = predicted$share[predicted$unit_bin_order == 198L],
      actual_share_198 = actual$share[actual$unit_bin_order == 198L]
    )
}

placebo_distributions <- bind_rows(placebo_distribution_rows)
placebo_performance <- bind_rows(placebo_performance_rows)
observed_parent_distribution <- parent_observed |>
  rename(share = observed_share)

leave_one_year_out_rows <- list()
for (excluded_year in sort(unique(historical$cohort_year))) {
  loo_historical <- historical |> filter(cohort_year != excluded_year)
  loo_calibration <- calibrate_historical_to_target(loo_historical, post)
  loo_counterfactual <- weighted_exact_distribution(
    loo_calibration$historical,
    "parent_total_units",
    "calibration_weight",
    minimum_units,
    pooled_tail_start
  )
  leave_one_year_out_rows[[as.character(excluded_year)]] <-
    local_shape_moments(
      loo_counterfactual,
      observed_parent_distribution,
      "Parent total"
    ) |>
    filter(moment %in% c(
      "excess_at_99",
      "cumulative_deficit_100_149",
      "excess_at_198"
    )) |>
    select(moment, estimate) |>
    pivot_wider(names_from = moment, values_from = estimate) |>
    mutate(
      excluded_historical_year = excluded_year,
      historical_parents = nrow(loo_historical),
      effective_sample_size = sum(
        loo_calibration$historical$calibration_weight
      )^2 / sum(loo_calibration$historical$calibration_weight^2)
    )
}
leave_one_pre_year_out <- bind_rows(leave_one_year_out_rows) |>
  select(
    excluded_historical_year,
    historical_parents,
    effective_sample_size,
    everything()
  )

temporal_window_rows <- list()
for (window_start in c(2019L, 2021L)) {
  window_historical <- historical |>
    filter(cohort_year >= window_start, cohort_year <= 2022L)
  window_calibration <- calibrate_historical_to_target(window_historical, post)
  window_counterfactual <- weighted_exact_distribution(
    window_calibration$historical,
    "parent_total_units",
    "calibration_weight",
    minimum_units,
    pooled_tail_start
  )
  temporal_window_rows[[as.character(window_start)]] <- local_shape_moments(
    window_counterfactual,
    observed_parent_distribution,
    "Parent total"
  ) |>
    filter(moment %in% c(
      "excess_at_99",
      "cumulative_deficit_100_149",
      "excess_at_198"
    )) |>
    transmute(
      historical_window = paste0(window_start, "-2022"),
      historical_parents = nrow(window_historical),
      effective_sample_size = sum(
        window_calibration$historical$calibration_weight
      )^2 / sum(window_calibration$historical$calibration_weight^2),
      moment,
      estimate
    )
}
temporal_window_sensitivity <- bind_rows(temporal_window_rows)

placebo_figure <- placebo_distributions |>
  filter(unit_bin_order <= exact_plot_maximum) |>
  ggplot(aes(x = unit_bin_order, y = share, color = series, group = series)) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey75",
    linetype = "dashed",
    linewidth = 0.35
  ) +
  geom_line(linewidth = 0.75) +
  facet_wrap(~placebo, ncol = 1) +
  scale_color_manual(values = c("Predicted" = "#4C78A8", "Actual" = "#E45756")) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(minimum_units, exact_plot_maximum)
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Forward placebo predictions within 2019-2022",
    subtitle = "Earlier parents are reweighted to the site traits of a later pre-policy year.",
    x = "Total proposed units in the linked parent",
    y = "Normalized share",
    color = NULL
  ) +
  theme_minimal(base_size = 10.5) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

write_csv_if_changed(exploratory_q_theta, "../output/exploratory_q_theta.csv")
write_csv_if_changed(placebo_distributions, "../output/placebo_distributions.csv")
write_csv_if_changed(placebo_performance, "../output/placebo_performance.csv")
write_csv_if_changed(leave_one_pre_year_out, "../output/leave_one_pre_year_out.csv")
write_csv_if_changed(
  temporal_window_sensitivity,
  "../output/temporal_window_sensitivity.csv"
)

temporary_pdf <- tempfile(fileext = ".pdf")
ggsave(temporary_pdf, placebo_figure, width = 11, height = 8, bg = "white")
copy_if_changed(temporary_pdf, "../output/historical_forward_placebos.pdf")

cat("Wrote counterfactual robustness audits to ../output\n")

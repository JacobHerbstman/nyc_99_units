# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# minimum_units <- 50L
# exact_plot_maximum <- 300L
# pooled_tail_start <- 301L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../_lib/source_pipeline_utils.R")
source("scale_shape_helpers.R")

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
  stop("Counterfactual support arguments are not internally consistent.")
}

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

analysis_parents <- parents |>
  filter(
    included_ab,
    parent_total_units >= minimum_units,
    composition_eligible
  ) |>
  mutate(three_or_more_components = n_components >= 3L)

historical <- analysis_parents |> filter(sample == "historical")
post <- analysis_parents |> filter(sample == "post_policy")

if (
  nrow(historical) == 0L ||
    nrow(post) == 0L ||
    anyDuplicated(historical$parent_id) ||
    anyDuplicated(post$parent_id)
) {
  stop("The preferred calibration samples failed parent-level QC.")
}

calibration <- calibrate_historical_to_target(historical, post)
weighted_historical <- calibration$historical
post <- calibration$target |> mutate(observation_weight = 1)

calibration_weights <- weighted_historical |>
  transmute(
    sample,
    parent_id,
    cohort_year,
    parent_total_units,
    calibration_weight
  )

historical_matrix <- calibration$historical_matrix
post_matrix <- calibration$target_matrix
weight_vector <- weighted_historical$calibration_weight

balance_diagnostics <- tibble(
  balance_moment = colnames(historical_matrix),
  historical_unweighted_mean = colMeans(historical_matrix),
  historical_weighted_mean =
    colSums(historical_matrix * weight_vector) / sum(weight_vector),
  post_mean = colMeans(post_matrix),
  historical_standard_deviation = apply(historical_matrix, 2, sd)
) |>
  filter(balance_moment != "(Intercept)") |>
  mutate(
    standardized_difference_before = if_else(
      historical_standard_deviation > 0,
      (historical_unweighted_mean - post_mean) /
        historical_standard_deviation,
      NA_real_
    ),
    standardized_difference_after = if_else(
      historical_standard_deviation > 0,
      (historical_weighted_mean - post_mean) /
        historical_standard_deviation,
      NA_real_
    )
  )

calibration_summary <- tibble(
  historical_parents = nrow(historical),
  post_parents = nrow(post),
  sum_calibration_weights = sum(weight_vector),
  minimum_weight = min(weight_vector),
  median_weight = median(weight_vector),
  maximum_weight = max(weight_vector),
  effective_sample_size = sum(weight_vector)^2 / sum(weight_vector^2),
  maximum_absolute_moment_error = calibration$maximum_moment_error,
  excluded_historical_incomplete_features = sum(
    parents$sample == "historical" &
      parents$included_ab &
      parents$parent_total_units >= minimum_units &
      !parents$composition_eligible
  ),
  excluded_post_incomplete_features = sum(
    parents$sample == "post_policy" &
      parents$included_ab &
      parents$parent_total_units >= minimum_units &
      !parents$composition_eligible
  ),
  calibration_method = "Positive exponential calibration (survey raking)",
  calibration_moments = paste(
    "log lot area, residential FAR, built FAR, multi-lot status,",
    "and borough"
  ),
  omitted_candidate_moments = paste(
    "Capacity and slack levels/zero flags, number of lots, zoning family,",
    "and prior site use",
    "were retained in the panel but omitted from exact calibration because",
    "the richer moment vector failed positive-weight overlap/convergence."
  )
)

outcome_definitions <- tribble(
  ~outcome, ~outcome_variable, ~subset_variable,
  "Parent total", "parent_total_units", NA_character_,
  "Largest constituent", "max_component_units", NA_character_,
  "Single-component parent total", "parent_total_units", "single_component",
  "Second-ranked constituent", "second_component_units", "multi_component",
  "Third-ranked constituent", "third_component_units", "three_or_more_components"
)

counterfactual_distribution_rows <- list()
local_moment_rows <- list()

for (outcome_index in seq_len(nrow(outcome_definitions))) {
  definition <- outcome_definitions[outcome_index, ]
  pre_outcome <- weighted_historical
  post_outcome <- post

  if (!is.na(definition$subset_variable)) {
    pre_outcome <- pre_outcome |>
      filter(.data[[definition$subset_variable]])
    post_outcome <- post_outcome |>
      filter(.data[[definition$subset_variable]])
  }

  counterfactual <- weighted_exact_distribution(
    pre_outcome,
    definition$outcome_variable,
    "calibration_weight",
    minimum_units,
    pooled_tail_start
  )
  unweighted_historical <- pre_outcome |>
    mutate(observation_weight = 1) |>
    weighted_exact_distribution(
      definition$outcome_variable,
      "observation_weight",
      minimum_units,
      pooled_tail_start
    )
  observed <- weighted_exact_distribution(
    post_outcome,
    definition$outcome_variable,
    "observation_weight",
    minimum_units,
    pooled_tail_start
  )

  counterfactual_distribution_rows[[outcome_index]] <- bind_rows(
    unweighted_historical |>
      mutate(series = "Historical unweighted"),
    counterfactual |>
      mutate(series = "Historical reweighted to post sites"),
    observed |>
      mutate(series = "Post observed")
  ) |>
    mutate(outcome = definition$outcome)

  local_moment_rows[[outcome_index]] <- local_shape_moments(
    counterfactual,
    observed,
    definition$outcome
  )
}

counterfactual_distributions <- bind_rows(counterfactual_distribution_rows) |>
  mutate(
    unit_bin = if_else(
      unit_bin_order == pooled_tail_start,
      paste0(pooled_tail_start, "+"),
      as.character(unit_bin_order)
    )
  ) |>
  select(outcome, series, unit_bin, unit_bin_order, weighted_count, share)

local_excess_deficit_moments <- bind_rows(local_moment_rows)

reweighted_constituent_count_distribution <- bind_rows(
  weighted_historical |>
    group_by(n_components) |>
    summarise(weighted_count = sum(calibration_weight), .groups = "drop") |>
    mutate(series = "Historical reweighted to post sites"),
  post |>
    count(n_components, name = "weighted_count") |>
    mutate(series = "Post observed")
) |>
  group_by(series) |>
  mutate(share = weighted_count / sum(weighted_count)) |>
  ungroup()

parent_counterfactual <- counterfactual_distributions |>
  filter(
    outcome == "Parent total",
    series == "Historical reweighted to post sites"
  ) |>
  select(unit_bin_order, counterfactual_share = share)

parent_observed <- counterfactual_distributions |>
  filter(outcome == "Parent total", series == "Post observed") |>
  select(unit_bin_order, observed_share = share)

parent_share_difference <- full_join(
  parent_counterfactual,
  parent_observed,
  by = "unit_bin_order",
  relationship = "one-to-one"
) |>
  mutate(
    counterfactual_share = coalesce(counterfactual_share, 0),
    observed_share = coalesce(observed_share, 0),
    observed_minus_counterfactual_share =
      observed_share - counterfactual_share
  )

cumulative_99_diagnostics <- full_join(
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
  arrange(unit_bin_order) |>
  mutate(
    bin_deficit = counterfactual_share - observed_share,
    cumulative_deficit = cumsum(bin_deficit),
    excess_at_99 = local_excess_deficit_moments |>
      filter(outcome == "Parent total", moment == "excess_at_99") |>
      pull(estimate),
    excess_minus_cumulative_deficit = excess_at_99 - cumulative_deficit
  )

excess_at_99 <- unique(cumulative_99_diagnostics$excess_at_99)
frontier_crossing <- cumulative_99_diagnostics |>
  mutate(counterfactual_cumulative_mass = cumsum(counterfactual_share)) |>
  filter(counterfactual_cumulative_mass >= excess_at_99) |>
  slice_head(n = 1)

if (nrow(frontier_crossing) == 0L) {
  exploratory_q_theta <- tibble(
    outcome = "Parent total",
    q_crossing = NA_integer_,
    target_excess_at_99 = excess_at_99,
    counterfactual_mass_100_to_q_minus_1 = sum(
      cumulative_99_diagnostics$counterfactual_share
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
    cumulative_99_diagnostics$counterfactual_share[
      cumulative_99_diagnostics$unit_bin_order < q_crossing
    ]
  )
  compression_target <- sum(
    cumulative_99_diagnostics$observed_share[
      cumulative_99_diagnostics$unit_bin_order >= 100L &
        cumulative_99_diagnostics$unit_bin_order <= q_crossing
    ]
  )
  theta_candidates <- tibble(theta_grid_upper = seq.int(q_crossing, 149L)) |>
    rowwise() |>
    mutate(
      compression_counterfactual_mass = sum(
        cumulative_99_diagnostics$counterfactual_share[
          cumulative_99_diagnostics$unit_bin_order >= q_crossing &
            cumulative_99_diagnostics$unit_bin_order <= theta_grid_upper
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
      q_crossing = q_crossing,
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

post_exposure_years <- unique(post$exposure_years)

if (length(post_exposure_years) != 1L) {
  stop("Expected one exact post-policy exposure duration.")
}

scale_shape_count_decomposition <- counterfactual_distributions |>
  filter(outcome == "Parent total") |>
  select(unit_bin_order, series, share) |>
  pivot_wider(names_from = series, values_from = share) |>
  mutate(
    post_annualized_opportunity_rate = nrow(post) / post_exposure_years,
    scale_only_counterfactual_count =
      `Historical reweighted to post sites` * post_annualized_opportunity_rate,
    observed_post_annualized_count =
      `Post observed` * post_annualized_opportunity_rate,
    shape_effect_count =
      observed_post_annualized_count - scale_only_counterfactual_count
  )

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
      predicted_share_99 = predicted$share[
        predicted$unit_bin_order == 99L
      ],
      actual_share_99 = actual$share[actual$unit_bin_order == 99L],
      predicted_share_198 = predicted$share[
        predicted$unit_bin_order == 198L
      ],
      actual_share_198 = actual$share[actual$unit_bin_order == 198L]
    )
}

placebo_distributions <- bind_rows(placebo_distribution_rows)
placebo_performance <- bind_rows(placebo_performance_rows)

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
  loo_moments <- local_shape_moments(
    loo_counterfactual,
    counterfactual_distributions |>
      filter(outcome == "Parent total", series == "Post observed") |>
      select(unit_bin_order, share),
    "Parent total"
  )
  leave_one_year_out_rows[[as.character(excluded_year)]] <- loo_moments |>
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
    counterfactual_distributions |>
      filter(outcome == "Parent total", series == "Post observed") |>
      select(unit_bin_order, share),
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

save_pdf <- function(figure, out_path, width = 11, height = 5.8) {
  temporary_pdf <- tempfile(fileext = ".pdf")
  ggsave(temporary_pdf, figure, width = width, height = height, bg = "white")
  copy_if_changed(temporary_pdf, out_path)
}

plot_distribution <- counterfactual_distributions |>
  filter(
    outcome == "Parent total",
    unit_bin_order <= exact_plot_maximum,
    series != "Historical unweighted"
  )

counterfactual_figure <- ggplot(
  plot_distribution,
  aes(x = unit_bin_order, y = share, color = series, group = series)
) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.9) +
  scale_color_manual(values = c(
    "Historical reweighted to post sites" = "#4C78A8",
    "Post observed" = "#E45756"
  )) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297)
  ) +
  coord_cartesian(xlim = c(minimum_units, exact_plot_maximum)) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Composition-adjusted parent-size benchmark",
    subtitle = paste(
      "Historical 2019-2022 opportunities are exponentially reweighted using",
      "predetermined site characteristics."
    ),
    x = "Total proposed units in the linked parent",
    y = "Share of feature-complete 50+ A/B opportunities",
    color = NULL,
    caption = "Exact bins through 300; 301+ is retained in the denominator."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

scale_only_figure <- scale_shape_count_decomposition |>
  filter(unit_bin_order <= exact_plot_maximum) |>
  select(
    unit_bin_order,
    `Scale-only counterfactual` = scale_only_counterfactual_count,
    `Post observed` = observed_post_annualized_count
  ) |>
  pivot_longer(-unit_bin_order, names_to = "series", values_to = "count") |>
  ggplot(aes(x = unit_bin_order, y = count, color = series, group = series)) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_line(linewidth = 0.9) +
  scale_color_manual(values = c(
    "Scale-only counterfactual" = "#4C78A8",
    "Post observed" = "#E45756"
  )) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297),
    limits = c(minimum_units, exact_plot_maximum)
  ) +
  labs(
    title = "Annualized counts at post-period market scale",
    subtitle = "The benchmark holds the reweighted historical shape fixed and applies the post opportunity rate.",
    x = "Total proposed units in the linked parent",
    y = "Feature-complete parent opportunities per year",
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

shape_difference_figure <- scale_shape_count_decomposition |>
  filter(unit_bin_order <= exact_plot_maximum) |>
  ggplot(aes(x = unit_bin_order, y = shape_effect_count)) +
  geom_hline(yintercept = 0, color = "grey55", linewidth = 0.4) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_col(fill = "#7A5195", width = 0.9) +
  scale_x_continuous(
    breaks = c(50, 99, 150, 198, 250, 297)
  ) +
  coord_cartesian(xlim = c(minimum_units, exact_plot_maximum)) +
  labs(
    title = "Post count minus the scale-only counterfactual",
    subtitle = "Positive bars are excess annualized opportunities; negative bars are deficits.",
    x = "Total proposed units in the linked parent",
    y = "Annualized opportunity difference"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

share_difference_figure <- parent_share_difference |>
  filter(unit_bin_order <= exact_plot_maximum) |>
  ggplot(aes(x = unit_bin_order, y = observed_minus_counterfactual_share)) +
  geom_hline(yintercept = 0, color = "grey55", linewidth = 0.4) +
  geom_vline(
    xintercept = c(99, 150, 198, 297),
    color = "grey72",
    linetype = "dashed",
    linewidth = 0.4
  ) +
  geom_col(fill = "#7A5195", width = 0.9) +
  scale_x_continuous(breaks = c(50, 99, 150, 198, 250, 297)) +
  coord_cartesian(xlim = c(minimum_units, exact_plot_maximum)) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Observed minus composition-adjusted counterfactual shares",
    subtitle = "Positive bars are excess probability mass; negative bars are deficits.",
    x = "Total proposed units in the linked parent",
    y = "Share difference"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

cumulative_figure <- cumulative_99_diagnostics |>
  ggplot(aes(x = unit_bin_order)) +
  geom_hline(
    aes(yintercept = excess_at_99),
    color = "#E45756",
    linewidth = 0.9
  ) +
  geom_line(aes(y = cumulative_deficit), color = "#4C78A8", linewidth = 0.9) +
  scale_y_continuous(labels = label_percent(accuracy = 0.1)) +
  labs(
    title = "Cumulative missing share above 99",
    subtitle = "Blue accumulates reweighted counterfactual share minus post share; red is the excess exactly at 99.",
    x = "Upper endpoint of cumulative range beginning at 100",
    y = "Share of feature-complete 50+ A/B opportunities"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

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
    subtitle = "Earlier parents are reweighted to the predetermined characteristics of a later pre-policy year.",
    x = "Total proposed units in the linked parent",
    y = "Normalized share",
    color = NULL
  ) +
  theme_minimal(base_size = 10.5) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

reweighted_constituent_count_figure <- ggplot(
  reweighted_constituent_count_distribution,
  aes(x = n_components, y = share, fill = series)
) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c(
    "Historical reweighted to post sites" = "#4C78A8",
    "Post observed" = "#E45756"
  )) +
  scale_x_continuous(
    breaks = sort(unique(reweighted_constituent_count_distribution$n_components))
  ) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Composition-adjusted number of constituents per parent",
    x = "Constituent filings/buildings in the linked parent",
    y = "Share of feature-complete 50+ A/B opportunities",
    fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

write_csv_if_changed(calibration_weights, "../output/calibration_weights.csv")
write_csv_if_changed(balance_diagnostics, "../output/calibration_balance.csv")
write_csv_if_changed(calibration_summary, "../output/calibration_summary.csv")
write_csv_if_changed(
  counterfactual_distributions,
  "../output/reweighted_counterfactual_distributions.csv"
)
write_csv_if_changed(
  scale_shape_count_decomposition,
  "../output/scale_shape_count_decomposition.csv"
)
write_csv_if_changed(
  parent_share_difference,
  "../output/parent_share_difference.csv"
)
write_csv_if_changed(
  local_excess_deficit_moments,
  "../output/local_excess_deficit_moments.csv"
)
write_csv_if_changed(
  reweighted_constituent_count_distribution,
  "../output/reweighted_constituent_count_distribution.csv"
)
write_csv_if_changed(
  cumulative_99_diagnostics,
  "../output/cumulative_99_diagnostics.csv"
)
write_csv_if_changed(
  exploratory_q_theta,
  "../output/exploratory_q_theta.csv"
)
write_csv_if_changed(
  placebo_distributions,
  "../output/placebo_distributions.csv"
)
write_csv_if_changed(
  placebo_performance,
  "../output/placebo_performance.csv"
)
write_csv_if_changed(
  leave_one_pre_year_out,
  "../output/leave_one_pre_year_out.csv"
)
write_csv_if_changed(
  temporal_window_sensitivity,
  "../output/temporal_window_sensitivity.csv"
)

save_pdf(
  counterfactual_figure,
  "../output/pdf/reweighted_parent_counterfactual_50_300.pdf"
)
save_pdf(
  scale_only_figure,
  "../output/pdf/scale_only_parent_counts_50_300.pdf"
)
save_pdf(
  shape_difference_figure,
  "../output/pdf/shape_effect_parent_counts_50_300.pdf"
)
save_pdf(
  share_difference_figure,
  "../output/pdf/observed_minus_counterfactual_shares_50_300.pdf"
)
save_pdf(
  cumulative_figure,
  "../output/pdf/cumulative_99_deficit.pdf",
  width = 9,
  height = 5.4
)
save_pdf(
  placebo_figure,
  "../output/pdf/historical_forward_placebos.pdf",
  width = 11,
  height = 8
)
save_pdf(
  reweighted_constituent_count_figure,
  "../output/pdf/reweighted_constituent_count_distribution.pdf",
  width = 9,
  height = 5.4
)

cat("Wrote composition-adjusted counterfactual and placebo outputs.\n")

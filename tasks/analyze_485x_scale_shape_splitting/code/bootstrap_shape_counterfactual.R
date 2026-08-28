# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_485x_scale_shape_splitting/code")
# minimum_units <- 50L
# exact_plot_maximum <- 300L
# pooled_tail_start <- 301L
# bootstrap_replications <- 499L
# random_seed <- 48599L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})

source("../../_lib/source_pipeline_utils.R")
source("scale_shape_helpers.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop(
    "Expected minimum units, exact-plot maximum, pooled-tail start, ",
    "bootstrap replications, and random seed."
  )
}

minimum_units <- as.integer(args[1])
exact_plot_maximum <- as.integer(args[2])
pooled_tail_start <- as.integer(args[3])
bootstrap_replications <- as.integer(args[4])
random_seed <- as.integer(args[5])

if (
  any(is.na(c(
    minimum_units,
    exact_plot_maximum,
    pooled_tail_start,
    bootstrap_replications,
    random_seed
  ))) ||
    minimum_units >= exact_plot_maximum ||
    pooled_tail_start != exact_plot_maximum + 1L ||
    bootstrap_replications < 99L
) {
  stop("Bootstrap arguments are not internally consistent.")
}

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    included_ab,
    parent_total_units >= minimum_units,
    model_eligible
  )

historical <- parents |> filter(sample == "historical")
post <- parents |> filter(sample == "post_policy")
post_exposure_years <- unique(post$exposure_years)

if (length(post_exposure_years) != 1L) {
  stop("Expected one exact post-policy exposure duration.")
}

calculate_statistics <- function(historical_sample, post_sample) {
  calibration <- calibrate_historical_to_target(
    historical_sample,
    post_sample
  )
  historical_sample <- calibration$historical
  post_sample <- calibration$target |> mutate(observation_weight = 1)

  outcome_definitions <- tribble(
    ~outcome, ~outcome_variable, ~subset_variable,
    "parent_total", "parent_total_units", NA_character_,
    "largest_constituent", "max_component_units", NA_character_,
    "single_component", "parent_total_units", "single_component"
  )

  statistic_rows <- list()
  parent_counterfactual <- NULL
  parent_observed <- NULL

  for (outcome_index in seq_len(nrow(outcome_definitions))) {
    definition <- outcome_definitions[outcome_index, ]
    historical_outcome <- historical_sample
    post_outcome <- post_sample

    if (!is.na(definition$subset_variable)) {
      historical_outcome <- historical_outcome |>
        filter(.data[[definition$subset_variable]])
      post_outcome <- post_outcome |>
        filter(.data[[definition$subset_variable]])
    }

    counterfactual <- weighted_exact_distribution(
      historical_outcome,
      definition$outcome_variable,
      "calibration_weight",
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
    local_moments <- local_shape_moments(
      counterfactual,
      observed,
      definition$outcome
    ) |>
      transmute(
        statistic = paste0(outcome, "__", moment),
        estimate
      )
    statistic_rows[[outcome_index]] <- local_moments

    if (definition$outcome == "parent_total") {
      parent_counterfactual <- counterfactual
      parent_observed <- observed
    }
  }

  bin_rows <- full_join(
    parent_counterfactual |>
      select(unit_bin_order, counterfactual_share = share),
    parent_observed |>
      select(unit_bin_order, observed_share = share),
    by = "unit_bin_order",
    relationship = "one-to-one"
  ) |>
    mutate(
      counterfactual_share = coalesce(counterfactual_share, 0),
      observed_share = coalesce(observed_share, 0),
      difference = observed_share - counterfactual_share
    ) |>
    select(unit_bin_order, counterfactual_share, observed_share, difference) |>
    pivot_longer(
      -unit_bin_order,
      names_to = "series",
      values_to = "estimate"
    ) |>
    transmute(
      statistic = paste0(
        "parent_total_bin_",
        unit_bin_order,
        "__",
        series
      ),
      estimate
    )

  parent_joined <- full_join(
    parent_counterfactual |>
      select(unit_bin_order, counterfactual_share = share),
    parent_observed |>
      select(unit_bin_order, observed_share = share),
    by = "unit_bin_order",
    relationship = "one-to-one"
  ) |>
    mutate(
      counterfactual_share = coalesce(counterfactual_share, 0),
      observed_share = coalesce(observed_share, 0)
    )

  excess_99 <- parent_joined$observed_share[
    parent_joined$unit_bin_order == 99L
  ] - parent_joined$counterfactual_share[
    parent_joined$unit_bin_order == 99L
  ]
  source_rows <- parent_joined |>
    filter(unit_bin_order >= 100L, unit_bin_order <= 149L) |>
    arrange(unit_bin_order) |>
    mutate(counterfactual_cumulative = cumsum(counterfactual_share))
  q_row <- source_rows |>
    filter(counterfactual_cumulative >= excess_99) |>
    slice_head(n = 1)

  if (nrow(q_row) == 0L || excess_99 <= 0) {
    q_theta_rows <- tibble(
      statistic = c("parent_total__q_crossing", "parent_total__theta"),
      estimate = c(NA_real_, NA_real_)
    )
  } else {
    q_crossing <- q_row$unit_bin_order + 1L
    compression_target <- sum(
      source_rows$observed_share[
        source_rows$unit_bin_order >= 100L &
          source_rows$unit_bin_order <= q_crossing
      ]
    )
    theta_candidates <- tibble(theta_grid_upper = seq.int(q_crossing, 149L)) |>
      rowwise() |>
      mutate(
        counterfactual_mass = sum(
          source_rows$counterfactual_share[
            source_rows$unit_bin_order >= q_crossing &
              source_rows$unit_bin_order <= theta_grid_upper
          ]
        ),
        gap = abs(counterfactual_mass - compression_target)
      ) |>
      ungroup() |>
      arrange(gap, theta_grid_upper) |>
      slice_head(n = 1)
    q_theta_rows <- tibble(
      statistic = c("parent_total__q_crossing", "parent_total__theta"),
      estimate = c(q_crossing, theta_candidates$theta_grid_upper / q_crossing)
    )
  }

  exact_198_parents <- post_sample |>
    filter(parent_total_units == 198L)
  vector_rows <- tibble(
    statistic = c(
      "post_share_exact_198",
      "post_share_exact_198_as_99x2",
      "exact_198_conditional_verified",
      "exact_198_conditional_suggestive",
      "exact_198_conditional_unable"
    ),
    estimate = c(
      mean(post_sample$parent_total_units == 198L),
      mean(post_sample$exact_99x2),
      if_else(
        nrow(exact_198_parents) > 0L,
        mean(
          exact_198_parents$splitting_verification_status ==
            "verified_separate_485x_units"
        ),
        NA_real_
      ),
      if_else(
        nrow(exact_198_parents) > 0L,
        mean(
          exact_198_parents$splitting_verification_status ==
            "suggestive_separate_components"
        ),
        NA_real_
      ),
      if_else(
        nrow(exact_198_parents) > 0L,
        mean(
          exact_198_parents$splitting_verification_status ==
            "unable_to_verify"
        ),
        NA_real_
      )
    )
  )

  scale_rows <- parent_joined |>
    filter(unit_bin_order %in% c(99L, 198L)) |>
    transmute(
      statistic = paste0(
        "annualized_shape_effect_at_",
        unit_bin_order
      ),
      estimate = (
        observed_share - counterfactual_share
      ) * nrow(post_sample) / post_exposure_years
    )

  bind_rows(
    bind_rows(statistic_rows),
    bin_rows,
    q_theta_rows,
    vector_rows,
    scale_rows
  )
}

point_statistics <- calculate_statistics(historical, post) |>
  mutate(replication = 0L, status = "point_estimate")

set.seed(random_seed)
bootstrap_rows <- vector("list", bootstrap_replications)
bootstrap_status_rows <- vector("list", bootstrap_replications)

for (replication in seq_len(bootstrap_replications)) {
  historical_sample <- historical[
    sample.int(nrow(historical), nrow(historical), replace = TRUE),
  ]
  post_sample <- post[
    sample.int(nrow(post), nrow(post), replace = TRUE),
  ]

  replication_result <- tryCatch(
    calculate_statistics(historical_sample, post_sample),
    error = function(condition) condition
  )

  if (inherits(replication_result, "error")) {
    bootstrap_status_rows[[replication]] <- tibble(
      replication,
      status = "calibration_failed",
      detail = conditionMessage(replication_result)
    )
  } else {
    bootstrap_rows[[replication]] <- replication_result |>
      mutate(replication, status = "successful")
    bootstrap_status_rows[[replication]] <- tibble(
      replication,
      status = "successful",
      detail = NA_character_
    )
  }
}

bootstrap_draws <- bind_rows(bootstrap_rows)
bootstrap_status <- bind_rows(bootstrap_status_rows)

if (mean(bootstrap_status$status == "successful") < 0.9) {
  stop("Fewer than 90 percent of bootstrap calibrations succeeded.")
}

bootstrap_intervals <- bootstrap_draws |>
  filter(!is.na(estimate)) |>
  group_by(statistic) |>
  summarise(
    successful_replications = n(),
    bootstrap_mean = mean(estimate),
    percentile_lower = quantile(estimate, 0.025, names = FALSE),
    percentile_upper = quantile(estimate, 0.975, names = FALSE),
    .groups = "drop"
  ) |>
  left_join(
    point_statistics |> select(statistic, point_estimate = estimate),
    by = "statistic",
    relationship = "one-to-one"
  ) |>
  mutate(
    basic_lower = 2 * point_estimate - percentile_upper,
    basic_upper = 2 * point_estimate - percentile_lower
  ) |>
  select(
    statistic,
    point_estimate,
    successful_replications,
    bootstrap_mean,
    percentile_lower,
    percentile_upper,
    basic_lower,
    basic_upper
  )

bootstrap_run_summary <- bootstrap_status |>
  count(status, detail, name = "replications") |>
  mutate(
    requested_replications = bootstrap_replications,
    random_seed = random_seed
  )

write_csv_if_changed(
  bind_rows(point_statistics, bootstrap_draws),
  "../output/bootstrap_draws.csv"
)
write_csv_if_changed(
  bootstrap_intervals,
  "../output/bootstrap_intervals.csv"
)
write_csv_if_changed(
  bootstrap_run_summary,
  "../output/bootstrap_run_summary.csv"
)

cat(
  "Wrote parent-level bootstrap inference with ",
  sum(bootstrap_status$status == "successful"),
  " successful replications.\n",
  sep = ""
)

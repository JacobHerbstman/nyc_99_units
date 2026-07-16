# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_model_inference_placebos/code")
# training_start_year <- 2019L
# training_end_year <- 2023L
# post_year <- 2025L
# min_units <- 6L
# minimum_category_rows <- 30L
# threshold_units <- 100L
# counterfactual_max_units <- 400L
# bootstrap_reps <- 499L
# bootstrap_seed <- 9901L
# interval_lower <- 0.025
# interval_upper <- 0.975

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/parent_no_notch_model.R")
source("parent_model_audit_functions.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 11L) {
  stop(
    "Expected training years, post year, unit and category floors, threshold, ",
    "distribution maximum, bootstrap repetitions and seed, and interval bounds."
  )
}

training_start_year <- as.integer(args[1])
training_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
minimum_category_rows <- as.integer(args[5])
threshold_units <- as.integer(args[6])
counterfactual_max_units <- as.integer(args[7])
bootstrap_reps <- as.integer(args[8])
bootstrap_seed <- as.integer(args[9])
interval_lower <- as.numeric(args[10])
interval_upper <- as.numeric(args[11])

if (
  any(is.na(c(
    training_start_year, training_end_year, post_year, min_units,
    minimum_category_rows, threshold_units, counterfactual_max_units,
    bootstrap_reps, bootstrap_seed, interval_lower, interval_upper
  ))) ||
    training_start_year >= training_end_year ||
    post_year <= training_end_year ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    threshold_units <= min_units ||
    counterfactual_max_units <= threshold_units ||
    bootstrap_reps < 20L ||
    interval_lower <= 0 ||
    interval_upper >= 1 ||
    interval_lower >= interval_upper
) {
  stop("Parent-model bootstrap arguments are not internally consistent.")
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

standardize_moments <- function(moment_row) {
  moment_row |>
    transmute(
      observed_exact_99 = observed_exact_bunch_units,
      expected_no_notch_exact_99 = expected_no_notch_exact_bunch_units,
      excess_exact_99 = excess_exact_bunch_units,
      observed_100_plus = observed_at_or_above_threshold,
      expected_no_notch_100_plus =
        expected_no_notch_at_or_above_threshold,
      missing_100_plus = missing_at_or_above_threshold,
      conservation_gap,
      mean_n0_from_exact_99 = mean_n0_from_exact_bunch_units,
      frontier_from_exact_99 = frontier_from_exact_bunch_units,
      mean_n0_from_missing_100_plus = mean_n0_from_missing_above,
      frontier_from_missing_100_plus = frontier_from_missing_above,
      shock_sigma
    )
}

historical_panel <- read_parquet(
  "../input/historical_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

training_rows <- historical_panel |>
  filter(
    model_eligible,
    filing_year >= training_start_year,
    date_last_filed <= as.Date(paste0(training_end_year, "-12-31"))
  )

post_rows <- post_panel |>
  filter(model_eligible) |>
  mutate(
    units = units_hdb_priority,
    log_units = log(units)
  )

if (
  nrow(training_rows) == 0L ||
    nrow(post_rows) == 0L ||
    anyDuplicated(training_rows$observation_id) ||
    anyDuplicated(post_rows$observation_id)
) {
  stop("Parent-model bootstrap samples failed key QC.")
}

point_fit <- fit_rounded_mle(
  training_rows,
  post_rows,
  min_units,
  minimum_category_rows,
  model_formula
)
point_distribution <- expected_unit_distribution(
  point_fit$test_mu,
  point_fit$sigma,
  min_units,
  counterfactual_max_units
)
point_estimates <- no_notch_moments(
  post_rows$units,
  point_fit$test_mu,
  point_fit$sigma,
  point_distribution,
  min_units,
  threshold_units
) |>
  standardize_moments()

set.seed(bootstrap_seed)
bootstrap_draw_rows <- vector("list", bootstrap_reps * 2L)
bootstrap_status_rows <- vector("list", bootstrap_reps)

for (bootstrap_rep in seq_len(bootstrap_reps)) {
  historical_index <- sample.int(
    nrow(training_rows),
    nrow(training_rows),
    replace = TRUE
  )
  post_index <- sample.int(
    nrow(post_rows),
    nrow(post_rows),
    replace = TRUE
  )
  bootstrap_attempt <- tryCatch(
    list(
      fit = fit_rounded_mle(
        training_rows[historical_index, ],
        post_rows,
        min_units,
        minimum_category_rows,
        model_formula
      ),
      error = NA_character_
    ),
    error = function(error_condition) {
      list(
        fit = NULL,
        error = conditionMessage(error_condition)
      )
    }
  )
  bootstrap_fit <- bootstrap_attempt$fit

  bootstrap_status_rows[[bootstrap_rep]] <- tibble(
    bootstrap_rep,
    fit_success = !is.null(bootstrap_fit),
    fit_error = bootstrap_attempt$error,
    distinct_historical_parents = n_distinct(historical_index),
    distinct_post_parents = n_distinct(post_index)
  )

  if (!is.null(bootstrap_fit)) {
    fixed_distribution <- expected_unit_distribution(
      bootstrap_fit$test_mu,
      bootstrap_fit$sigma,
      min_units,
      counterfactual_max_units
    )
    fixed_moments <- no_notch_moments(
      post_rows$units,
      bootstrap_fit$test_mu,
      bootstrap_fit$sigma,
      fixed_distribution,
      min_units,
      threshold_units
    ) |>
      standardize_moments() |>
      mutate(
        bootstrap_rep,
        bootstrap_type = "fixed_2025_parent_population",
        .before = 1L
      )

    resampled_post_mu <- bootstrap_fit$test_mu[post_index]
    resampled_post_distribution <- expected_unit_distribution(
      resampled_post_mu,
      bootstrap_fit$sigma,
      min_units,
      counterfactual_max_units
    )
    two_sample_moments <- no_notch_moments(
      post_rows$units[post_index],
      resampled_post_mu,
      bootstrap_fit$sigma,
      resampled_post_distribution,
      min_units,
      threshold_units
    ) |>
      standardize_moments() |>
      mutate(
        bootstrap_rep,
        bootstrap_type = "two_sample_historical_and_2025",
        .before = 1L
      )

    bootstrap_draw_rows[[2L * bootstrap_rep - 1L]] <- fixed_moments
    bootstrap_draw_rows[[2L * bootstrap_rep]] <- two_sample_moments
  }

  if (bootstrap_rep %% 25L == 0L || bootstrap_rep == bootstrap_reps) {
    cat("Completed bootstrap repetition", bootstrap_rep, "of", bootstrap_reps, "\n")
  }
}

bootstrap_draws <- bind_rows(bootstrap_draw_rows) |>
  arrange(bootstrap_type, bootstrap_rep)
bootstrap_status <- bind_rows(bootstrap_status_rows) |>
  arrange(bootstrap_rep)
successful_reps <- sum(bootstrap_status$fit_success)

metric_order <- c(
  "expected_no_notch_exact_99",
  "excess_exact_99",
  "expected_no_notch_100_plus",
  "missing_100_plus",
  "conservation_gap",
  "mean_n0_from_exact_99",
  "frontier_from_exact_99",
  "mean_n0_from_missing_100_plus",
  "frontier_from_missing_100_plus",
  "shock_sigma"
)

point_estimates_long <- point_estimates |>
  select(all_of(metric_order)) |>
  pivot_longer(
    everything(),
    names_to = "metric",
    values_to = "point_estimate"
  )

bootstrap_summary <- bootstrap_draws |>
  select(bootstrap_type, bootstrap_rep, all_of(metric_order)) |>
  pivot_longer(
    all_of(metric_order),
    names_to = "metric",
    values_to = "value"
  ) |>
  group_by(bootstrap_type, metric) |>
  summarise(
    bootstrap_reps_requested = bootstrap_reps,
    successful_reps = n_distinct(bootstrap_rep),
    finite_draws = sum(is.finite(value)),
    bootstrap_mean = mean(value, na.rm = TRUE),
    bootstrap_sd = sd(value, na.rm = TRUE),
    interval_lower_probability = interval_lower,
    interval_upper_probability = interval_upper,
    interval_lower_value = quantile(
      value,
      interval_lower,
      na.rm = TRUE,
      names = FALSE
    ),
    bootstrap_median = median(value, na.rm = TRUE),
    interval_upper_value = quantile(
      value,
      interval_upper,
      na.rm = TRUE,
      names = FALSE
    ),
    .groups = "drop"
  ) |>
  left_join(
    point_estimates_long,
    by = "metric",
    relationship = "many-to-one"
  ) |>
  mutate(metric = factor(metric, levels = metric_order)) |>
  arrange(bootstrap_type, metric) |>
  mutate(metric = as.character(metric))

bootstrap_qc <- tibble(
  check = c(
    "bootstrap_reps_requested",
    "bootstrap_seed",
    "historical_parent_rows",
    "fixed_post_parent_rows",
    "successful_historical_refits",
    "failed_historical_refits",
    "minimum_required_successful_refits",
    "bootstrap_types",
    "draw_rows",
    "imputed_parents"
  ),
  value = as.character(c(
    bootstrap_reps,
    bootstrap_seed,
    nrow(training_rows),
    nrow(post_rows),
    successful_reps,
    bootstrap_reps - successful_reps,
    ceiling(0.95 * bootstrap_reps),
    n_distinct(bootstrap_draws$bootstrap_type),
    nrow(bootstrap_draws),
    0L
  ))
)

if (
  successful_reps < ceiling(0.95 * bootstrap_reps) ||
    anyDuplicated(bootstrap_status$bootstrap_rep) ||
    anyDuplicated(bootstrap_draws[c("bootstrap_type", "bootstrap_rep")]) ||
    nrow(bootstrap_draws) != successful_reps * 2L ||
    n_distinct(bootstrap_draws$bootstrap_type) != 2L ||
    any(bootstrap_summary$finite_draws < ceiling(0.90 * successful_reps))
) {
  stop("Parent-model bootstrap outputs failed final QC.")
}

write_parquet_if_changed(
  bootstrap_draws,
  "../output/parent_model_bootstrap_draws.parquet"
)
write_csv_if_changed(
  bootstrap_summary,
  "../output/parent_model_bootstrap_summary.csv"
)
write_csv_if_changed(
  bootstrap_status,
  "../output/parent_model_bootstrap_refit_status.csv"
)
write_csv_if_changed(
  bootstrap_qc,
  "../output/parent_model_bootstrap_qc.csv"
)

cat("Wrote preferred parent-model bootstrap inference to ../output\n")

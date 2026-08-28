# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_tail_counterfactual/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(survey)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

historical_tail <- readRDS("../output/tail_pre_c99.rds")
post_tail <- readRDS("../output/tail_post_c99.rds")

continuous_variables <- c(
  "log_lot_area",
  "residential_capacity_sqft",
  "redevelopment_slack_sqft",
  "residential_far",
  "built_far"
)

categorical_variables <- c(
  "borough",
  "zoning_category",
  "prior_site_use"
)

required_variables <- c(
  "observation_id", "parent_id", "cohort_year", "total_units",
  continuous_variables, "multi_lot_indicator",
  "zero_residential_capacity", "zero_redevelopment_slack",
  categorical_variables
)

if (
  nrow(historical_tail) == 0L || nrow(post_tail) == 0L ||
    anyDuplicated(historical_tail$observation_id) ||
    anyDuplicated(post_tail$observation_id) ||
    any(!required_variables %in% names(historical_tail)) ||
    any(!required_variables %in% names(post_tail)) ||
    any(!complete.cases(historical_tail[required_variables])) ||
    any(!complete.cases(post_tail[required_variables]))
) {
  stop("A c=99 tail sample failed calibration input QC.")
}

standardization <- tibble(
  variable = continuous_variables,
  historical_mean = vapply(
    historical_tail[continuous_variables],
    mean,
    numeric(1)
  ),
  historical_standard_deviation = vapply(
    historical_tail[continuous_variables],
    sd,
    numeric(1)
  )
)

if (
  any(!is.finite(standardization$historical_mean)) ||
    any(!is.finite(standardization$historical_standard_deviation)) ||
    any(standardization$historical_standard_deviation <= 0)
) {
  stop("A continuous balance variable cannot be standardized.")
}

for (variable_name in continuous_variables) {
  standardized_name <- paste0(variable_name, "_z")
  historical_mean <- standardization$historical_mean[
    standardization$variable == variable_name
  ]
  historical_sd <- standardization$historical_standard_deviation[
    standardization$variable == variable_name
  ]

  historical_tail[[standardized_name]] <-
    (historical_tail[[variable_name]] - historical_mean) / historical_sd
  post_tail[[standardized_name]] <-
    (post_tail[[variable_name]] - historical_mean) / historical_sd
}

for (variable_name in categorical_variables) {
  historical_levels <- sort(unique(historical_tail[[variable_name]]))
  post_levels <- sort(unique(post_tail[[variable_name]]))
  post_only_levels <- setdiff(post_levels, historical_levels)

  if (length(post_only_levels) > 0L) {
    stop(
      "Post-policy ", variable_name,
      " levels lack historical support: ",
      paste(post_only_levels, collapse = ", ")
    )
  }

  shared_levels <- sort(unique(c(historical_levels, post_levels)))
  historical_tail[[variable_name]] <- factor(
    historical_tail[[variable_name]],
    levels = shared_levels
  )
  post_tail[[variable_name]] <- factor(
    post_tail[[variable_name]],
    levels = shared_levels
  )
}

balance_formula <- ~
  log_lot_area_z +
  residential_capacity_sqft_z +
  redevelopment_slack_sqft_z +
  residential_far_z +
  built_far_z +
  multi_lot_indicator +
  zero_residential_capacity +
  zero_redevelopment_slack +
  borough +
  zoning_category +
  prior_site_use

historical_matrix <- model.matrix(balance_formula, historical_tail)
post_matrix <- model.matrix(balance_formula, post_tail)

if (
  !identical(colnames(historical_matrix), colnames(post_matrix)) ||
    qr(historical_matrix)$rank != ncol(historical_matrix)
) {
  stop("The c=99 calibration matrix is incompatible or rank deficient.")
}

target_totals <- colSums(post_matrix)
historical_design <- svydesign(
  ids = ~1,
  weights = ~1,
  data = historical_tail
)

calibrated_design <- calibrate(
  historical_design,
  formula = balance_formula,
  population = target_totals,
  calfun = "raking",
  epsilon = 1e-10,
  maxit = 1000
)

calibration_weights <- as.numeric(weights(calibrated_design))

if (
  any(!is.finite(calibration_weights)) ||
    any(calibration_weights <= 0) ||
    abs(sum(calibration_weights) - nrow(post_tail)) > 1e-7
) {
  stop("Positive c=99 calibration weights failed final QC.")
}

weighted_totals <- colSums(historical_matrix * calibration_weights)
balance_error <- weighted_totals - target_totals

if (max(abs(balance_error)) > 1e-7) {
  stop("The c=99 calibration constraints were not satisfied.")
}

historical_means <- colMeans(historical_matrix)
post_means <- colMeans(post_matrix)
weighted_historical_means <- weighted_totals / sum(calibration_weights)
historical_sds <- apply(historical_matrix, 2, sd)

balance_diagnostics <- tibble(
  balance_term = colnames(historical_matrix),
  historical_mean_unweighted = historical_means,
  post_policy_mean = post_means,
  historical_mean_weighted = weighted_historical_means,
  historical_standard_deviation = historical_sds,
  standardized_mean_difference_unweighted = if_else(
    historical_sds > 0,
    (historical_means - post_means) / historical_sds,
    0
  ),
  standardized_mean_difference_weighted = if_else(
    historical_sds > 0,
    (weighted_historical_means - post_means) / historical_sds,
    0
  ),
  calibration_total_error = balance_error
) |>
  filter(balance_term != "(Intercept)")

sorted_weights <- sort(calibration_weights, decreasing = TRUE)
weight_count <- length(sorted_weights)

weight_diagnostics <- tibble(
  method = "survey::calibrate",
  calibration_function = "raking",
  tail_cutoff = 99L,
  historical_parents = nrow(historical_tail),
  post_policy_parents = nrow(post_tail),
  balance_columns_including_intercept = ncol(historical_matrix),
  balance_matrix_rank = qr(historical_matrix)$rank,
  weight_sum = sum(calibration_weights),
  effective_sample_size =
    sum(calibration_weights)^2 / sum(calibration_weights^2),
  minimum_weight = min(calibration_weights),
  median_weight = median(calibration_weights),
  p90_weight = unname(quantile(calibration_weights, 0.90)),
  p95_weight = unname(quantile(calibration_weights, 0.95)),
  p99_weight = unname(quantile(calibration_weights, 0.99)),
  maximum_weight = max(calibration_weights),
  largest_1_percent_weight_share = sum(
    head(sorted_weights, ceiling(0.01 * weight_count))
  ) / sum(calibration_weights),
  largest_5_percent_weight_share = sum(
    head(sorted_weights, ceiling(0.05 * weight_count))
  ) / sum(calibration_weights),
  largest_10_percent_weight_share = sum(
    head(sorted_weights, ceiling(0.10 * weight_count))
  ) / sum(calibration_weights),
  maximum_absolute_smd_unweighted = max(abs(
    balance_diagnostics$standardized_mean_difference_unweighted
  )),
  maximum_absolute_smd_weighted = max(abs(
    balance_diagnostics$standardized_mean_difference_weighted
  )),
  maximum_absolute_calibration_error = max(abs(balance_error))
)

weighted_historical_rows <- historical_tail |>
  transmute(
    observation_id,
    parent_id,
    cohort_year,
    base_weight = 1,
    calibration_weight = calibration_weights
  )

cohort_composition <- historical_tail |>
  mutate(calibration_weight = calibration_weights) |>
  group_by(cohort_year) |>
  summarise(
    historical_parents = n(),
    unweighted_share = n() / nrow(historical_tail),
    calibrated_parent_mass = sum(calibration_weight),
    calibrated_share = sum(calibration_weight) / sum(calibration_weights),
    .groups = "drop"
  )

write_csv_if_changed(
  weighted_historical_rows,
  "../output/tail_pre_c99_calibration_weights.csv"
)
write_csv_if_changed(
  standardization,
  "../output/calibration_standardization_c99.csv"
)
write_csv_if_changed(
  balance_diagnostics,
  "../output/calibration_balance_c99.csv"
)
write_csv_if_changed(
  weight_diagnostics,
  "../output/calibration_weight_diagnostics_c99.csv"
)
write_csv_if_changed(
  cohort_composition,
  "../output/calibration_cohort_composition_c99.csv"
)

cat("Wrote positive c=99 calibration weights and diagnostics to ../output\n")

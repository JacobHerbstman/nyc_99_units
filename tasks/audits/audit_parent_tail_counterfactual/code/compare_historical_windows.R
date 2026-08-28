# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_tail_counterfactual/code")
# historical_start_years_text <- "2011,2014,2017,2019"
# historical_end_year <- 2022L
# post_year <- 2025L
# tail_cutoff <- 99L
# minimum_followup_days <- 180L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(survey)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop(
    "Expected historical start years, historical end year, post year, ",
    "tail cutoff, and minimum follow-up days."
  )
}

historical_start_years_text <- args[1]
historical_start_years <- as.integer(str_split_1(
  historical_start_years_text,
  ","
))
historical_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
tail_cutoff <- as.integer(args[4])
minimum_followup_days <- as.integer(args[5])

if (
  length(historical_start_years) == 0L ||
    any(is.na(c(
      historical_start_years, historical_end_year, post_year,
      tail_cutoff, minimum_followup_days
    ))) ||
    anyDuplicated(historical_start_years) ||
    any(historical_start_years > historical_end_year) ||
    historical_end_year >= post_year ||
    tail_cutoff != 99L ||
    minimum_followup_days < 1L || minimum_followup_days >= 365L
) {
  stop("Historical-window comparison arguments are not internally consistent.")
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

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_followup <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(parent_id, cohort_date, source_end_date, left_window_observed) |>
  mutate(observed_followup_days = as.integer(source_end_date - cohort_date))

post_tail <- post_panel |>
  left_join(
    post_followup |>
      select(parent_id, observed_followup_days, left_window_observed),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(
    cohort_year == post_year,
    left_window_observed,
    observed_followup_days >= minimum_followup_days,
    model_eligible,
    units_hdb_priority >= tail_cutoff
  ) |>
  transmute(
    observation_id,
    parent_id,
    cohort_year,
    total_units = units_hdb_priority,
    log_lot_area = log(lotarea),
    broad_zoning_capacity_sqft = lotarea * broad_zoning_far,
    broad_redevelopment_slack_sqft = pmax(
      lotarea * broad_zoning_far - lotarea * builtfar,
      0
    ),
    broad_zoning_far,
    built_far = builtfar,
    multi_lot_indicator = as.integer(feature_lots > 1L),
    zero_broad_zoning_capacity = as.integer(
      lotarea * broad_zoning_far == 0
    ),
    zero_broad_redevelopment_slack = as.integer(
      pmax(lotarea * broad_zoning_far - lotarea * builtfar, 0) == 0
    ),
    borough = str_squish(as.character(borough)),
    zoning_category = str_squish(as.character(zone_detail)),
    prior_site_use = str_squish(as.character(prior_site_use))
  )

continuous_variables <- c(
  "log_lot_area",
  "broad_zoning_capacity_sqft",
  "broad_redevelopment_slack_sqft",
  "broad_zoning_far",
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
  "zero_broad_zoning_capacity", "zero_broad_redevelopment_slack",
  categorical_variables
)

if (
  nrow(historical_panel) == 0L || nrow(post_tail) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_tail$observation_id) ||
    any(!complete.cases(post_tail[required_variables]))
) {
  stop("Historical-window comparison inputs failed row QC.")
}

balance_formula <- ~
  log_lot_area_z +
  broad_zoning_capacity_sqft_z +
  broad_redevelopment_slack_sqft_z +
  broad_zoning_far_z +
  built_far_z +
  multi_lot_indicator +
  zero_broad_zoning_capacity +
  zero_broad_redevelopment_slack +
  borough +
  zoning_category +
  prior_site_use

comparison_rows <- list()
cohort_rows <- list()
parent_weight_rows <- list()

for (historical_start_year in historical_start_years) {
  historical_tail <- historical_panel |>
    filter(
      analysis_status == "historical_fully_observed",
      cohort_year >= historical_start_year,
      cohort_year <= historical_end_year,
      model_eligible,
      units_hdb_priority >= tail_cutoff
    ) |>
    transmute(
      observation_id,
      parent_id,
      cohort_year,
      total_units = units_hdb_priority,
      log_lot_area = log(lotarea),
      broad_zoning_capacity_sqft = lotarea * broad_zoning_far,
      broad_redevelopment_slack_sqft = pmax(
        lotarea * broad_zoning_far - lotarea * builtfar,
        0
      ),
      broad_zoning_far,
      built_far = builtfar,
      multi_lot_indicator = as.integer(feature_lots > 1L),
      zero_broad_zoning_capacity = as.integer(
        lotarea * broad_zoning_far == 0
      ),
      zero_broad_redevelopment_slack = as.integer(
        pmax(lotarea * broad_zoning_far - lotarea * builtfar, 0) == 0
      ),
      borough = str_squish(as.character(borough)),
      zoning_category = str_squish(as.character(zone_detail)),
      prior_site_use = str_squish(as.character(prior_site_use))
    )

  if (
    nrow(historical_tail) == 0L ||
      anyDuplicated(historical_tail$observation_id) ||
      any(!complete.cases(historical_tail[required_variables])) ||
      any(historical_tail$total_units < tail_cutoff)
  ) {
    stop("A historical-window tail sample failed row QC.")
  }

  window_post_tail <- post_tail
  historical_means <- vapply(
    historical_tail[continuous_variables],
    mean,
    numeric(1)
  )
  historical_sds <- vapply(
    historical_tail[continuous_variables],
    sd,
    numeric(1)
  )

  if (
    any(!is.finite(historical_means)) ||
      any(!is.finite(historical_sds)) ||
      any(historical_sds <= 0)
  ) {
    stop("A historical-window balance variable cannot be standardized.")
  }

  for (variable_name in continuous_variables) {
    standardized_name <- paste0(variable_name, "_z")
    historical_tail[[standardized_name]] <-
      (historical_tail[[variable_name]] - historical_means[variable_name]) /
      historical_sds[variable_name]
    window_post_tail[[standardized_name]] <-
      (window_post_tail[[variable_name]] - historical_means[variable_name]) /
      historical_sds[variable_name]
  }

  for (variable_name in categorical_variables) {
    historical_levels <- sort(unique(historical_tail[[variable_name]]))
    post_levels <- sort(unique(window_post_tail[[variable_name]]))
    post_only_levels <- setdiff(post_levels, historical_levels)

    if (length(post_only_levels) > 0L) {
      stop(
        "Window beginning ", historical_start_year, " lacks ",
        variable_name, " support for: ",
        paste(post_only_levels, collapse = ", ")
      )
    }

    shared_levels <- sort(unique(c(historical_levels, post_levels)))
    historical_tail[[variable_name]] <- factor(
      historical_tail[[variable_name]],
      levels = shared_levels
    )
    window_post_tail[[variable_name]] <- factor(
      window_post_tail[[variable_name]],
      levels = shared_levels
    )
  }

  historical_matrix <- model.matrix(balance_formula, historical_tail)
  post_matrix <- model.matrix(balance_formula, window_post_tail)

  if (
    !identical(colnames(historical_matrix), colnames(post_matrix)) ||
      qr(historical_matrix)$rank != ncol(historical_matrix)
  ) {
    stop("A historical-window calibration matrix is incompatible.")
  }

  target_totals <- colSums(post_matrix)
  calibrated_design <- calibrate(
    svydesign(ids = ~1, weights = ~1, data = historical_tail),
    formula = balance_formula,
    population = target_totals,
    calfun = "raking",
    epsilon = 1e-10,
    maxit = 1000
  )
  calibration_weights <- as.numeric(weights(calibrated_design))
  weighted_totals <- colSums(historical_matrix * calibration_weights)

  if (
    any(!is.finite(calibration_weights)) ||
      any(calibration_weights <= 0) ||
      abs(sum(calibration_weights) - nrow(window_post_tail)) > 1e-7 ||
      max(abs(weighted_totals - target_totals)) > 1e-7
  ) {
    stop("A historical-window calibration failed final QC.")
  }

  observed_at_99 <- sum(window_post_tail$total_units == tail_cutoff)
  counterfactual_at_99 <- sum(
    calibration_weights[historical_tail$total_units == tail_cutoff]
  )
  excess_at_99 <- observed_at_99 - counterfactual_at_99

  exact_counts <- tibble(count_value = seq.int(100L, 149L)) |>
    left_join(
      historical_tail |>
        mutate(calibration_weight = calibration_weights) |>
        filter(total_units >= 100L, total_units <= 149L) |>
        group_by(count_value = total_units) |>
        summarise(
          counterfactual_mass = sum(calibration_weight),
          .groups = "drop"
        ),
      by = "count_value",
      relationship = "one-to-one"
    ) |>
    left_join(
      window_post_tail |>
        filter(total_units >= 100L, total_units <= 149L) |>
        count(count_value = total_units, name = "observed_mass"),
      by = "count_value",
      relationship = "one-to-one"
    ) |>
    mutate(
      counterfactual_mass = coalesce(counterfactual_mass, 0),
      observed_mass = coalesce(observed_mass, 0L),
      structural_cumulative_mass = cumsum(counterfactual_mass),
      observed_cumulative_missing_mass = cumsum(
        counterfactual_mass - observed_mass
      )
    )

  reaching_rows <- exact_counts |>
    filter(structural_cumulative_mass >= excess_at_99)

  if (excess_at_99 <= 0 || nrow(reaching_rows) == 0L) {
    frontier_final_count <- NA_integer_
    continuous_frontier <- NA_real_
    affected_project_mean <- NA_real_
  } else {
    frontier_final_count <- reaching_rows$count_value[1]
    mass_before_frontier <- sum(
      exact_counts$counterfactual_mass[
        exact_counts$count_value < frontier_final_count
      ]
    )
    mass_at_frontier <- exact_counts$counterfactual_mass[
      exact_counts$count_value == frontier_final_count
    ]
    frontier_fraction <-
      (excess_at_99 - mass_before_frontier) / mass_at_frontier
    continuous_frontier <- frontier_final_count + frontier_fraction
    affected_project_mean <- (
      sum(
        exact_counts$count_value[
          exact_counts$count_value < frontier_final_count
        ] *
          exact_counts$counterfactual_mass[
            exact_counts$count_value < frontier_final_count
          ]
      ) +
        frontier_final_count * frontier_fraction * mass_at_frontier
    ) / excess_at_99
  }

  historical_column_sds <- apply(historical_matrix, 2, sd)
  unweighted_smd <- ifelse(
    historical_column_sds > 0,
    (colMeans(historical_matrix) - colMeans(post_matrix)) /
      historical_column_sds,
    0
  )
  sorted_weights <- sort(calibration_weights, decreasing = TRUE)

  comparison_rows[[length(comparison_rows) + 1L]] <- tibble(
    calibration_spec = "common_broad_zoning_capacity",
    historical_start_year,
    historical_end_year,
    historical_parents = nrow(historical_tail),
    post_policy_parents = nrow(window_post_tail),
    historical_exact_99_parents = sum(
      historical_tail$total_units == tail_cutoff
    ),
    observed_at_99,
    counterfactual_at_99,
    excess_at_99,
    frontier_final_count,
    continuous_frontier,
    affected_project_mean_no_notch_units = affected_project_mean,
    counterfactual_mass_150_plus = sum(
      calibration_weights[historical_tail$total_units >= 150L]
    ),
    observed_missing_mass_peak_through_149 = max(
      exact_counts$observed_cumulative_missing_mass
    ),
    observed_missing_mass_at_149 = exact_counts |>
      filter(count_value == 149L) |>
      pull(observed_cumulative_missing_mass),
    effective_sample_size =
      sum(calibration_weights)^2 / sum(calibration_weights^2),
    minimum_weight = min(calibration_weights),
    median_weight = median(calibration_weights),
    maximum_weight = max(calibration_weights),
    largest_1_percent_weight_share = sum(
      head(sorted_weights, ceiling(0.01 * length(sorted_weights)))
    ) / sum(calibration_weights),
    largest_5_percent_weight_share = sum(
      head(sorted_weights, ceiling(0.05 * length(sorted_weights)))
    ) / sum(calibration_weights),
    largest_10_percent_weight_share = sum(
      head(sorted_weights, ceiling(0.10 * length(sorted_weights)))
    ) / sum(calibration_weights),
    balance_columns_including_intercept = ncol(historical_matrix),
    maximum_absolute_smd_unweighted = max(abs(unweighted_smd)),
    maximum_absolute_calibration_error = max(abs(
      weighted_totals - target_totals
    ))
  )

  cohort_rows[[length(cohort_rows) + 1L]] <- historical_tail |>
    mutate(calibration_weight = calibration_weights) |>
    group_by(cohort_year) |>
    summarise(
      historical_parents = n(),
      unweighted_share = n() / nrow(historical_tail),
      calibrated_parent_mass = sum(calibration_weight),
      calibrated_share = sum(calibration_weight) /
        sum(calibration_weights),
      .groups = "drop"
    ) |>
    mutate(
      historical_start_year = historical_start_year,
      historical_end_year = historical_end_year,
      .before = 1
    )

  parent_weight_rows[[length(parent_weight_rows) + 1L]] <- historical_tail |>
    transmute(
      calibration_spec = "common_broad_zoning_capacity",
      historical_start_year,
      historical_end_year,
      observation_id,
      parent_id,
      cohort_year,
      total_units,
      calibration_weight = calibration_weights
    )
}

window_comparison <- bind_rows(comparison_rows) |>
  arrange(historical_start_year)
window_cohort_composition <- bind_rows(cohort_rows) |>
  arrange(historical_start_year, cohort_year)
window_parent_weights <- bind_rows(parent_weight_rows) |>
  arrange(historical_start_year, cohort_year, parent_id)

if (
  nrow(window_comparison) != length(historical_start_years) ||
    anyDuplicated(window_comparison$historical_start_year) ||
    anyDuplicated(
      window_cohort_composition[c("historical_start_year", "cohort_year")]
    ) ||
    anyDuplicated(
      window_parent_weights[c("historical_start_year", "parent_id")]
    )
) {
  stop("Historical-window comparison outputs failed final QC.")
}

write_csv_if_changed(
  window_comparison,
  "../output/historical_window_comparison_c99.csv"
)
write_csv_if_changed(
  window_cohort_composition,
  "../output/historical_window_cohort_composition_c99.csv"
)
write_csv_if_changed(
  window_parent_weights,
  "../output/historical_window_parent_weights_c99.csv"
)

cat("Wrote c=99 historical-window comparisons to ../output\n")

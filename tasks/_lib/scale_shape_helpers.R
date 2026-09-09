suppressPackageStartupMessages({
  library(dplyr)
  library(survey)
  library(tidyr)
})

calibration_formula <- ~ log_lot_area_z + residential_far_z +
  built_far_z + multi_lot_indicator + borough

prepare_calibration_data <- function(historical, target) {
  continuous_variables <- c(
    "log_lot_area",
    "residential_far",
    "built_far"
  )

  for (variable in continuous_variables) {
    historical_mean <- mean(historical[[variable]])
    historical_sd <- sd(historical[[variable]])

    if (!is.finite(historical_sd) || historical_sd == 0) {
      stop("A calibration variable has no historical variation: ", variable)
    }

    standardized_name <- paste0(variable, "_z")
    historical[[standardized_name]] <-
      (historical[[variable]] - historical_mean) / historical_sd
    target[[standardized_name]] <-
      (target[[variable]] - historical_mean) / historical_sd
  }

  for (variable in "borough") {
    common_levels <- sort(unique(c(
      historical[[variable]],
      target[[variable]]
    )))
    historical[[variable]] <- factor(
      historical[[variable]],
      levels = common_levels
    )
    target[[variable]] <- factor(target[[variable]], levels = common_levels)
  }

  list(historical = historical, target = target)
}

calibrate_historical_to_target <- function(historical, target) {
  prepared <- prepare_calibration_data(historical, target)
  historical <- prepared$historical
  target <- prepared$target

  historical_matrix <- model.matrix(calibration_formula, historical)
  target_matrix <- model.matrix(calibration_formula, target)

  if (!identical(colnames(historical_matrix), colnames(target_matrix))) {
    stop("Historical and target calibration matrices do not align.")
  }

  target_totals <- colSums(target_matrix)
  design <- svydesign(ids = ~1, weights = ~1, data = historical)
  calibrated_design <- calibrate(
    design,
    calibration_formula,
    population = target_totals,
    calfun = "raking",
    maxit = 2000,
    epsilon = 1e-7
  )
  calibration_weights <- as.numeric(weights(calibrated_design))

  maximum_moment_error <- max(abs(
    colSums(historical_matrix * calibration_weights) - target_totals
  ))

  if (
    any(!is.finite(calibration_weights)) ||
      any(calibration_weights <= 0) ||
      maximum_moment_error > 1e-4
  ) {
    stop("Positive exponential calibration failed its moment checks.")
  }

  list(
    historical = historical |>
      mutate(calibration_weight = calibration_weights),
    target = target,
    historical_matrix = historical_matrix,
    target_matrix = target_matrix,
    target_totals = target_totals,
    maximum_moment_error = maximum_moment_error
  )
}

weighted_exact_distribution <- function(
  data,
  outcome_variable,
  weight_variable,
  minimum_units,
  pooled_tail_start
) {
  data |>
    filter(!is.na(.data[[outcome_variable]])) |>
    mutate(
      unit_bin_order = pmin(.data[[outcome_variable]], pooled_tail_start),
      distribution_weight = .data[[weight_variable]]
    ) |>
    filter(unit_bin_order >= minimum_units) |>
    group_by(unit_bin_order) |>
    summarise(weighted_count = sum(distribution_weight), .groups = "drop") |>
    complete(
      unit_bin_order = seq.int(minimum_units, pooled_tail_start),
      fill = list(weighted_count = 0)
    ) |>
    mutate(share = weighted_count / sum(weighted_count))
}

local_shape_moments <- function(
  counterfactual,
  observed,
  outcome,
  cumulative_limits = c(110L, 120L, 122L, 130L, 140L, 149L)
) {
  joined <- full_join(
    counterfactual |>
      select(unit_bin_order, counterfactual_share = share),
    observed |>
      select(unit_bin_order, observed_share = share),
    by = "unit_bin_order",
    relationship = "one-to-one"
  ) |>
    mutate(
      counterfactual_share = coalesce(counterfactual_share, 0),
      observed_share = coalesce(observed_share, 0)
    )

  threshold_rows <- tibble(
    outcome = outcome,
    moment = c("excess_at_99", "excess_at_198"),
    lower_bound = c(99L, 198L),
    upper_bound = c(99L, 198L),
    estimate = c(
      joined$observed_share[joined$unit_bin_order == 99L] -
        joined$counterfactual_share[joined$unit_bin_order == 99L],
      joined$observed_share[joined$unit_bin_order == 198L] -
        joined$counterfactual_share[joined$unit_bin_order == 198L]
    )
  )

  deficit_rows <- lapply(cumulative_limits, function(upper_bound) {
    tibble(
      outcome = outcome,
      moment = paste0("cumulative_deficit_100_", upper_bound),
      lower_bound = 100L,
      upper_bound = upper_bound,
      estimate = sum(
        joined$counterfactual_share[
          joined$unit_bin_order >= 100L &
            joined$unit_bin_order <= upper_bound
        ] -
          joined$observed_share[
            joined$unit_bin_order >= 100L &
              joined$unit_bin_order <= upper_bound
          ]
      )
    )
  })

  bind_rows(threshold_rows, bind_rows(deficit_rows))
}

shape_distance <- function(predicted, observed) {
  joined <- full_join(
    predicted |> select(unit_bin_order, predicted_share = share),
    observed |> select(unit_bin_order, observed_share = share),
    by = "unit_bin_order",
    relationship = "one-to-one"
  ) |>
    arrange(unit_bin_order) |>
    mutate(
      predicted_share = coalesce(predicted_share, 0),
      observed_share = coalesce(observed_share, 0)
    )

  tibble(
    total_variation_distance =
      0.5 * sum(abs(joined$predicted_share - joined$observed_share)),
    maximum_absolute_cdf_difference = max(abs(
      cumsum(joined$predicted_share) - cumsum(joined$observed_share)
    ))
  )
}

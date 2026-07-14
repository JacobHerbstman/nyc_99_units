# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_x_targeted_training/code")
# universe_min_units <- 6L
# alternative_floor <- 11L
# risk_min_units <- 50L
# risk_max_units <- 150L
# kernel_center_units <- 100L
# kernel_bandwidth_log <- log(2)
# minimum_category_rows <- 30L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7L) {
  stop(
    "Expected seven arguments: universe minimum units, alternative floor, ",
    "risk-set minimum and maximum, kernel center, kernel log bandwidth, ",
    "and minimum category rows."
  )
}

universe_min_units <- as.integer(args[1])
alternative_floor <- as.integer(args[2])
risk_min_units <- as.integer(args[3])
risk_max_units <- as.integer(args[4])
kernel_center_units <- as.integer(args[5])
kernel_bandwidth_log <- as.numeric(args[6])
minimum_category_rows <- as.integer(args[7])

if (
  any(is.na(c(
    universe_min_units, alternative_floor, risk_min_units, risk_max_units,
    kernel_center_units, kernel_bandwidth_log, minimum_category_rows
  ))) ||
    universe_min_units < 1L ||
    alternative_floor <= universe_min_units ||
    risk_min_units <= alternative_floor ||
    risk_max_units <= risk_min_units ||
    kernel_center_units < risk_min_units ||
    kernel_center_units > risk_max_units ||
    kernel_bandwidth_log <= 0 ||
    minimum_category_rows < 2L
) {
  stop("X-targeted training arguments are not internally consistent.")
}

reference_window <- "train_2013_2020_test_2021_2022h1"
all_sample_name <- paste0("all_units_at_least_", universe_min_units)
risk_sample_name <- paste0(
  "floor_", universe_min_units, "_x_predicted_units_",
  risk_min_units, "_", risk_max_units, "_fixed_risk_set"
)

floor_unweighted_name <- paste0("floor", universe_min_units, "_unweighted")
alternative_unweighted_name <- paste0(
  "floor", alternative_floor, "_unweighted"
)
hard_band_name <- paste0(
  "floor", universe_min_units, "_x_hard_",
  risk_min_units, "_", risk_max_units
)
kernel_name <- paste0(
  "floor", universe_min_units, "_x_kernel_", kernel_center_units
)

model_order <- c(
  floor_unweighted_name,
  alternative_unweighted_name,
  hard_band_name,
  kernel_name
)

model_description <- tibble(
  model = model_order,
  training_rule = c(
    paste0("all observed units >= ", universe_min_units),
    paste0("observed units >= ", alternative_floor),
    paste0(
      "leave-one-out X-predicted median units in ",
      risk_min_units, "-", risk_max_units
    ),
    paste0(
      "Gaussian weight around leave-one-out X-predicted median ",
      kernel_center_units
    )
  ),
  selects_on_own_units = c(FALSE, TRUE, FALSE, FALSE),
  targeting_type = c("none", "outcome_floor", "hard_X_band", "smooth_X_kernel")
)

prepare_train_test <- function(train_data, test_data) {
  train_prepared <- train_data
  test_prepared <- test_data

  training_year_mean <- mean(train_prepared$filing_year)
  train_prepared$filing_year_centered <-
    train_prepared$filing_year - training_year_mean
  test_prepared$filing_year_centered <-
    test_prepared$filing_year - training_year_mean

  for (feature_name in c("log_lotarea", "residfar", "builtfar")) {
    missing_name <- paste0(feature_name, "_missing")
    train_values <- train_prepared[[feature_name]]
    test_values <- test_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    test_prepared[[missing_name]] <- is.na(test_values)

    imputation_value <- median(train_values, na.rm = TRUE)
    if (!is.finite(imputation_value)) {
      stop("Training data have no finite values for ", feature_name, ".")
    }

    train_values[is.na(train_values)] <- imputation_value
    test_values[is.na(test_values)] <- imputation_value
    train_prepared[[feature_name]] <- train_values
    test_prepared[[feature_name]] <- test_values
  }

  for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
    train_values <- str_squish(as.character(train_prepared[[feature_name]]))
    test_values <- str_squish(as.character(test_prepared[[feature_name]]))
    train_values[is.na(train_values) | train_values == ""] <- "missing"
    test_values[is.na(test_values) | test_values == ""] <- "missing"
    training_counts <- table(train_values)
    keep_levels <- names(training_counts)[
      training_counts >= minimum_category_rows
    ]

    if (length(keep_levels) == 0L) {
      keep_levels <- names(sort(training_counts, decreasing = TRUE))[1]
    }

    train_values[!(train_values %in% keep_levels)] <- "other_rare"
    factor_levels <- sort(unique(train_values))
    fallback_level <- if ("other_rare" %in% factor_levels) {
      "other_rare"
    } else {
      names(sort(training_counts, decreasing = TRUE))[1]
    }
    test_values[!(test_values %in% keep_levels)] <- fallback_level
    train_prepared[[feature_name]] <- factor(
      train_values,
      levels = factor_levels
    )
    test_prepared[[feature_name]] <- factor(
      test_values,
      levels = factor_levels
    )
  }

  list(train = train_prepared, test = test_prepared)
}

make_predictions <- function(mu, sigma, observed_units) {
  lower_boundary <- universe_min_units - 0.5
  lower_probability <- pnorm((log(lower_boundary) - mu) / sigma)
  denominator <- pmax(1 - lower_probability, 1e-12)
  observed_low <- pmax(observed_units - 0.5, lower_boundary)
  observed_high <- observed_units + 0.5
  observed_probability <- (
    pnorm((log(observed_high) - mu) / sigma) -
      pnorm((log(observed_low) - mu) / sigma)
  ) / denominator
  probability_at_least_100 <- (
    1 - pnorm((log(99.5) - mu) / sigma)
  ) / denominator

  tibble(
    predicted_log_units = mu,
    predicted_median_units = exp(mu),
    predicted_mean_units = exp(mu + sigma^2 / 2),
    probability_observed_units = pmax(observed_probability, 1e-15),
    probability_at_least_100 = pmin(
      pmax(probability_at_least_100, 0),
      1
    )
  )
}

calculate_metrics <- function(evaluation_data) {
  observed_at_least_100 <- evaluation_data$units >= 100L
  positive_rows <- sum(observed_at_least_100)
  negative_rows <- nrow(evaluation_data) - positive_rows

  if (nrow(evaluation_data) == 0L) {
    stop("A declared evaluation sample is empty.")
  }

  if (positive_rows == 0L || negative_rows == 0L) {
    auc_at_least_100 <- NA_real_
  } else {
    probability_ranks <- rank(
      evaluation_data$probability_at_least_100,
      ties.method = "average"
    )
    auc_at_least_100 <- (
      sum(probability_ranks[observed_at_least_100]) -
        positive_rows * (positive_rows + 1) / 2
    ) / (positive_rows * negative_rows)
  }

  total_units_ratio <-
    sum(evaluation_data$predicted_mean_units) / sum(evaluation_data$units)

  tibble(
    metric = c(
      "rmse_log_units",
      "mae_log_units",
      "mae_units_using_predicted_median",
      "predicted_to_actual_total_units_ratio",
      "absolute_log_total_units_ratio",
      "share_within_factor_two",
      "mean_negative_log_probability",
      "brier_at_least_100",
      "absolute_at_least_100_rate_error",
      "auc_at_least_100"
    ),
    preferred_direction = c(
      rep("lower", 3L),
      "target_one",
      "lower",
      "higher",
      rep("lower", 3L),
      "higher"
    ),
    value = c(
      sqrt(mean(
        (evaluation_data$log_units -
          evaluation_data$predicted_log_units)^2
      )),
      mean(abs(
        evaluation_data$log_units - evaluation_data$predicted_log_units
      )),
      mean(abs(
        evaluation_data$units - evaluation_data$predicted_median_units
      )),
      total_units_ratio,
      abs(log(total_units_ratio)),
      mean(abs(
        evaluation_data$log_units - evaluation_data$predicted_log_units
      ) <= log(2)),
      mean(-log(evaluation_data$probability_observed_units)),
      mean(
        (observed_at_least_100 -
          evaluation_data$probability_at_least_100)^2
      ),
      abs(
        mean(observed_at_least_100) -
          mean(evaluation_data$probability_at_least_100)
      ),
      auc_at_least_100
    )
  )
}

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

window_specs <- read_csv(
  "../input/no_notch_time_windows.csv",
  show_col_types = FALSE,
  na = c("", "NA")
) |>
  filter(regime_note != "post_deadline_transport") |>
  mutate(
    train_start = as.Date(train_start),
    train_end = as.Date(train_end),
    test_start = as.Date(test_start),
    test_end = as.Date(test_end)
  )

if (
  nrow(window_specs) != 10L ||
    sum(window_specs$window == reference_window) != 1L
) {
  stop("Expected ten pre-policy validation windows and one reference window.")
}

model_rows <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= universe_min_units,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  mutate(
    units = as.integer(round(classa_prop)),
    log_units = log(units),
    log_lotarea = log(lotarea),
    zonedist1_clean = str_to_upper(str_squish(zonedist1)),
    zone_base = str_extract(zonedist1_clean, "^[RCM][0-9]+"),
    zone_detail = case_when(
      str_detect(zonedist1_clean, "/") ~ "MX_slash",
      zone_base %in% c("R1", "R2", "R3", "R4", "R5") ~ "R1_R5",
      zone_base == "R6" ~ "R6",
      zone_base == "R7" ~ "R7",
      zone_base %in% c("R8", "R9", "R10") ~ "R8_R10",
      str_detect(zonedist1_clean, "^C") ~ "C",
      str_detect(zonedist1_clean, "^M") ~ "M_non_slash",
      TRUE ~ "Other"
    ),
    has_existing_units = !is.na(unitsres) & unitsres > 0,
    landuse_code = str_pad(as.character(landuse), 2L, pad = "0"),
    prior_site_use = case_when(
      has_existing_units ~ "existing_residential_units",
      landuse_code == "11" ~ "vacant_land",
      landuse_code == "10" ~ "parking",
      landuse_code %in% c("05", "06") ~ "commercial_industrial",
      landuse_code == "04" ~ "mixed_res_commercial",
      landuse_code %in% c("07", "08") ~ "public_transport_utility",
      is.na(landuse_code) ~ "missing_landuse",
      TRUE ~ "other_no_res_units"
    ),
    borough = hdb_borough_name
  ) |>
  arrange(date_filed, job_number) |>
  mutate(observation_id = row_number()) |>
  select(
    observation_id, job_number, date_filed, filing_year, units, log_units,
    log_lotarea, residfar, builtfar, borough, zone_detail, prior_site_use
  )

if (
  nrow(model_rows) == 0L ||
    any(model_rows$units < universe_min_units) ||
    anyDuplicated(model_rows$observation_id)
) {
  stop("X-targeted model universe failed construction QC.")
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

metric_rows <- list()
diagnostic_rows <- list()
reference_predictions <- NULL
reference_summary_lines <- c(
  "No-notch outcome-free X-targeted training audit",
  "",
  paste0("Universe minimum units: ", universe_min_units),
  paste0("Outcome-selected comparison floor: ", alternative_floor),
  paste0(
    "Fixed held-out X-risk band: predicted median units ",
    risk_min_units, " through ", risk_max_units
  ),
  paste0("Kernel center units: ", kernel_center_units),
  paste0("Kernel bandwidth on log scale: ", kernel_bandwidth_log),
  paste0("Minimum category rows: ", minimum_category_rows),
  "",
  paste(
    "Training targeting uses exact leave-one-out fitted values from the",
    "floor-universe OLS. A row's weight therefore uses its pre-filing X and",
    "other training outcomes, but not its own realized units or residual."
  ),
  paste(
    "The held-out risk set is defined once per window by the ordinary floor-",
    universe_min_units,
    "fit and held-out X. Held-out units never define that set."
  ),
  ""
)

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  train_floor_raw <- model_rows |>
    filter(
      date_filed >= window_spec$train_start,
      date_filed <= window_spec$train_end
    )
  train_alternative_raw <- train_floor_raw |>
    filter(units >= alternative_floor)
  test_raw <- model_rows |>
    filter(
      date_filed >= window_spec$test_start,
      date_filed <= window_spec$test_end
    )

  if (
    nrow(train_floor_raw) < 500L ||
    nrow(train_alternative_raw) < 300L ||
    nrow(test_raw) < 50L
  ) {
    stop("A declared forward-validation window has too few rows: ", window_spec$window)
  }

  prepared_floor <- prepare_train_test(train_floor_raw, test_raw)
  fit_floor <- lm(model_formula, data = prepared_floor$train)
  leverage <- hatvalues(fit_floor)

  if (any(!is.finite(leverage)) || max(leverage) >= 0.99) {
    stop("Leave-one-out leverage failed QC in ", window_spec$window, ".")
  }

  loo_predicted_log_units <-
    prepared_floor$train$log_units - residuals(fit_floor) / (1 - leverage)
  hard_training_rows <-
    loo_predicted_log_units >= log(risk_min_units) &
    loo_predicted_log_units <= log(risk_max_units)
  kernel_weights <- exp(
    -0.5 * (
      (loo_predicted_log_units - log(kernel_center_units)) /
        kernel_bandwidth_log
    )^2
  )
  kernel_weights <- kernel_weights / mean(kernel_weights)

  if (
    sum(hard_training_rows) < 100L ||
    any(!is.finite(loo_predicted_log_units)) ||
    any(!is.finite(kernel_weights)) ||
    any(kernel_weights <= 0)
  ) {
    stop(
      "X-based training weights failed QC in ", window_spec$window,
      ": hard-band rows = ", sum(hard_training_rows),
      ", minimum kernel weight = ", min(kernel_weights), "."
    )
  }

  prepared_alternative <- prepare_train_test(train_alternative_raw, test_raw)
  prepared_hard <- prepare_train_test(
    train_floor_raw[hard_training_rows, ],
    test_raw
  )

  fit_alternative <- lm(model_formula, data = prepared_alternative$train)
  fit_hard <- lm(model_formula, data = prepared_hard$train)
  fit_kernel <- lm(
    model_formula,
    data = prepared_floor$train,
    weights = kernel_weights
  )

  fit_list <- list(fit_floor, fit_alternative, fit_hard, fit_kernel)
  names(fit_list) <- model_order
  test_data_list <- list(
    prepared_floor$test,
    prepared_alternative$test,
    prepared_hard$test,
    prepared_floor$test
  )
  names(test_data_list) <- model_order
  train_data_list <- list(
    prepared_floor$train,
    prepared_alternative$train,
    prepared_hard$train,
    prepared_floor$train
  )
  names(train_data_list) <- model_order
  training_weights_list <- list(
    rep(1, nrow(prepared_floor$train)),
    rep(1, nrow(prepared_alternative$train)),
    rep(1, nrow(prepared_hard$train)),
    kernel_weights
  )
  names(training_weights_list) <- model_order
  training_score_list <- list(
    loo_predicted_log_units,
    loo_predicted_log_units[train_floor_raw$units >= alternative_floor],
    loo_predicted_log_units[hard_training_rows],
    loo_predicted_log_units
  )
  names(training_score_list) <- model_order

  residual_rms_list <- lapply(model_order, function(model_name) {
    sqrt(weighted.mean(
      residuals(fit_list[[model_name]])^2,
      training_weights_list[[model_name]]
    ))
  })
  names(residual_rms_list) <- model_order

  predictions_by_model <- lapply(model_order, function(model_name) {
    fit <- fit_list[[model_name]]
    test_data <- test_data_list[[model_name]]
    mu <- as.numeric(predict(fit, newdata = test_data))
    sigma <- residual_rms_list[[model_name]]

    if (any(!is.finite(mu)) || !is.finite(sigma) || sigma <= 0) {
      stop("A model produced invalid predictions in ", window_spec$window, ".")
    }

    bind_cols(
      test_data |>
        transmute(
          observation_id,
          job_number,
          date_filed,
          units,
          log_units
        ),
      make_predictions(mu, sigma, test_data$units)
    ) |>
      mutate(training_residual_rms = sigma)
  })
  names(predictions_by_model) <- model_order

  baseline_predictions <- predictions_by_model[[floor_unweighted_name]]
  expected_ids <- baseline_predictions$observation_id

  for (model_name in model_order) {
    if (!identical(predictions_by_model[[model_name]]$observation_id, expected_ids)) {
      stop("Prediction rows differ across models in ", window_spec$window, ".")
    }
  }

  fixed_risk_rows <-
    baseline_predictions$predicted_median_units >= risk_min_units &
    baseline_predictions$predicted_median_units <= risk_max_units

  if (sum(fixed_risk_rows) < 30L) {
    stop("The fixed held-out X-risk set is too small in ", window_spec$window, ".")
  }

  evaluation_samples <- list(
    all_universe = rep(TRUE, nrow(baseline_predictions)),
    fixed_x_risk_set = fixed_risk_rows
  )
  names(evaluation_samples) <- c(all_sample_name, risk_sample_name)

  for (model_name in model_order) {
    model_predictions <- predictions_by_model[[model_name]]

    for (sample_name in names(evaluation_samples)) {
      evaluation_rows <- evaluation_samples[[sample_name]]
      metric_rows[[length(metric_rows) + 1L]] <- calculate_metrics(
        model_predictions[evaluation_rows, ]
      ) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = model_name,
          sample = sample_name,
          evaluation_rows = sum(evaluation_rows),
          .before = metric
        )
    }

    fit <- fit_list[[model_name]]
    train_data <- train_data_list[[model_name]]
    training_weights <- training_weights_list[[model_name]]
    training_score <- training_score_list[[model_name]]
    diagnostic_rows[[length(diagnostic_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      model = model_name,
      train_rows = nrow(train_data),
      effective_train_rows =
        sum(training_weights)^2 / sum(training_weights^2),
      training_residual_rms = residual_rms_list[[model_name]],
      training_adjusted_r_squared = summary(fit)$adj.r.squared,
      training_mean_units_unweighted = mean(train_data$units),
      training_mean_units_weighted = weighted.mean(
        train_data$units,
        training_weights
      ),
      training_share_units_at_least_100_unweighted = mean(
        train_data$units >= 100L
      ),
      training_share_units_at_least_100_weighted = weighted.mean(
        train_data$units >= 100L,
        training_weights
      ),
      median_leave_one_out_X_predicted_units = median(exp(training_score)),
      minimum_training_weight = min(training_weights),
      maximum_training_weight = max(training_weights),
      floor6_hard_band_rows = sum(hard_training_rows),
      floor6_maximum_leverage = max(leverage),
      heldout_rows_all_universe = nrow(test_raw),
      heldout_rows_fixed_X_risk_set = sum(fixed_risk_rows)
    )

    if (window_spec$window == reference_window) {
      printed_fit <- fit
      printed_fit$call$formula <- model_formula
      reference_summary_lines <- c(
        reference_summary_lines,
        paste0("Model: ", model_name),
        paste0("Training rule: ", model_description$training_rule[
          model_description$model == model_name
        ]),
        paste0("Training observations: ", nrow(train_data)),
        paste0(
          "Effective training observations: ",
          format(
            sum(training_weights)^2 / sum(training_weights^2),
            digits = 12
          )
        ),
        paste0(
          "Training residual RMS: ",
          format(residual_rms_list[[model_name]], digits = 12)
        ),
        "",
        "Exact R output",
        "",
        capture.output(print(summary(printed_fit))),
        "",
        str_dup("=", 80L),
        ""
      )
    }
  }

  if (window_spec$window == reference_window) {
    reference_predictions <- bind_rows(lapply(model_order, function(model_name) {
      predictions_by_model[[model_name]] |>
        mutate(model = model_name, .after = date_filed)
    })) |>
      mutate(
        fixed_X_risk_set = observation_id %in%
          baseline_predictions$observation_id[fixed_risk_rows]
      ) |>
      select(
        observation_id, job_number, date_filed, model, units, log_units,
        fixed_X_risk_set, predicted_log_units, predicted_median_units,
        predicted_mean_units, probability_observed_units,
        probability_at_least_100, training_residual_rms
      ) |>
      arrange(model, observation_id)
  }
}

window_metrics <- bind_rows(metric_rows) |>
  left_join(model_description, by = "model", relationship = "many-to-one") |>
  arrange(sample, metric, window, match(model, model_order))

training_diagnostics <- bind_rows(diagnostic_rows) |>
  left_join(model_description, by = "model", relationship = "many-to-one") |>
  arrange(window, match(model, model_order))

winning_rows <- window_metrics |>
  mutate(
    selection_score = case_when(
      preferred_direction == "lower" ~ value,
      preferred_direction == "higher" ~ -value,
      preferred_direction == "target_one" ~ abs(log(value)),
      TRUE ~ NA_real_
    ),
    selection_score = if_else(is.finite(selection_score), selection_score, Inf),
    model_order_value = match(model, model_order)
  ) |>
  arrange(window, sample, metric, selection_score, model_order_value) |>
  group_by(window, sample, metric) |>
  slice_head(n = 1L) |>
  ungroup() |>
  count(model, sample, metric, name = "validation_window_wins")

validation_summary <- window_metrics |>
  group_by(
    model, training_rule, selects_on_own_units, targeting_type,
    sample, metric, preferred_direction
  ) |>
  summarise(
    validation_windows = n_distinct(window),
    mean_evaluation_rows = mean(evaluation_rows),
    mean_value = mean(value, na.rm = TRUE),
    median_value = median(value, na.rm = TRUE),
    minimum_value = min(value, na.rm = TRUE),
    maximum_value = max(value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(
    winning_rows,
    by = c("model", "sample", "metric"),
    relationship = "one-to-one"
  ) |>
  mutate(
    validation_window_wins = coalesce(validation_window_wins, 0L),
    model_order_value = match(model, model_order)
  ) |>
  arrange(sample, metric, model_order_value) |>
  select(-model_order_value)

core_metric_rows <- window_metrics$metric != "auc_at_least_100"
expected_reference_rows <- training_diagnostics |>
  filter(window == reference_window) |>
  summarise(
    rows = first(heldout_rows_all_universe) * n_distinct(model)
  ) |>
  pull(rows)

if (
  nrow(window_metrics) != nrow(window_specs) * length(model_order) * 2L * 10L ||
    nrow(training_diagnostics) != nrow(window_specs) * length(model_order) ||
    any(!is.finite(window_metrics$value[core_metric_rows])) ||
    any(training_diagnostics$effective_train_rows < 100) ||
    any(training_diagnostics$heldout_rows_fixed_X_risk_set < 30L) ||
    nrow(reference_predictions) != expected_reference_rows ||
    anyDuplicated(reference_predictions[c("observation_id", "model")]) ||
    any(validation_summary$validation_windows != nrow(window_specs))
) {
  stop("X-targeted training outputs failed QC.")
}

write_csv_if_changed(
  window_metrics,
  "../output/no_notch_x_targeted_window_metrics.csv"
)
write_csv_if_changed(
  validation_summary,
  "../output/no_notch_x_targeted_validation_summary.csv"
)
write_csv_if_changed(
  training_diagnostics,
  "../output/no_notch_x_targeted_training_diagnostics.csv"
)
write_parquet_if_changed(
  reference_predictions,
  "../output/no_notch_x_targeted_reference_predictions.parquet"
)
writeLines(
  reference_summary_lines,
  "../output/no_notch_x_targeted_reference_fit_summary.txt"
)

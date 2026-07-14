# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_truncated_likelihood/code")
# training_floors_text <- "6,11,30"
# universe_min_units <- 6L
# local_min_units <- 50L
# local_max_units <- 150L
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

if (length(args) != 5L) {
  stop(
    "Expected five arguments: training floors, universe minimum units, ",
    "local minimum units, local maximum units, and minimum category rows."
  )
}

training_floors_text <- args[1]
universe_min_units <- as.integer(args[2])
local_min_units <- as.integer(args[3])
local_max_units <- as.integer(args[4])
minimum_category_rows <- as.integer(args[5])
training_floors <- as.integer(str_split(training_floors_text, ",", simplify = TRUE))

if (
  any(is.na(c(
    training_floors, universe_min_units, local_min_units,
    local_max_units, minimum_category_rows
  ))) ||
    length(training_floors) < 2L ||
    any(training_floors < universe_min_units) ||
    !universe_min_units %in% training_floors ||
    anyDuplicated(training_floors) ||
    !identical(training_floors, sort(training_floors)) ||
    local_min_units < universe_min_units ||
    local_max_units <= local_min_units ||
    minimum_category_rows < 2L ||
    any(training_floors >= 100L)
) {
  stop("Truncated-likelihood audit arguments are not internally consistent.")
}

reference_window <- "train_2013_2020_test_2021_2022h1"
model_names <- c("ols_plugin", "truncated_rounded_mle")
all_sample_name <- paste0("all_units_at_least_", universe_min_units)
actual_local_sample_name <- paste0(
  "actual_units_", local_min_units, "_", local_max_units,
  "_outcome_selected"
)
x_selected_sample_name <- paste0(
  "floor_", universe_min_units, "_x_predicted_units_",
  local_min_units, "_", local_max_units, "_fixed_risk_set"
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

log_one_minus_exp <- function(log_value) {
  if (any(log_value > 0, na.rm = TRUE)) {
    stop("log_one_minus_exp received a positive log value.")
  }

  result <- numeric(length(log_value))
  use_log1p <- log_value < log(0.5)
  result[use_log1p] <- log1p(-exp(log_value[use_log1p]))
  result[!use_log1p] <- log(-expm1(log_value[!use_log1p]))
  result
}

log_normal_interval_probability <- function(lower_z, upper_z) {
  if (length(lower_z) != length(upper_z) || any(lower_z >= upper_z)) {
    stop("Normal interval bounds are not strictly ordered.")
  }

  result <- numeric(length(lower_z))
  use_upper_tail <- lower_z > 0

  if (any(!use_upper_tail)) {
    upper_log_cdf <- pnorm(
      upper_z[!use_upper_tail],
      log.p = TRUE
    )
    lower_log_cdf <- pnorm(
      lower_z[!use_upper_tail],
      log.p = TRUE
    )
    result[!use_upper_tail] <- upper_log_cdf + log_one_minus_exp(
      lower_log_cdf - upper_log_cdf
    )
  }

  if (any(use_upper_tail)) {
    lower_log_survival <- pnorm(
      lower_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    upper_log_survival <- pnorm(
      upper_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    result[use_upper_tail] <- lower_log_survival + log_one_minus_exp(
      upper_log_survival - lower_log_survival
    )
  }

  result
}

rounded_conditional_log_probability <- function(
    units, predicted_log_units, sigma, training_floor) {
  if (!is.finite(sigma) || sigma <= 0) {
    return(rep(NA_real_, length(units)))
  }

  lower_z <- (log(units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(training_floor - 0.5) - predicted_log_units
  ) / sigma

  log_probability <- log_normal_interval_probability(lower_z, upper_z) -
    pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  log_probability[units < training_floor] <- NA_real_
  log_probability
}

negative_log_likelihood <- function(
    parameters, model_matrix, units, training_floor) {
  coefficient_count <- ncol(model_matrix)
  sigma <- exp(parameters[coefficient_count + 1L])

  if (!is.finite(sigma) || sigma <= 0) {
    return(1e100)
  }

  predicted_log_units <- as.numeric(
    model_matrix %*% parameters[seq_len(coefficient_count)]
  )
  log_probability <- rounded_conditional_log_probability(
    units,
    predicted_log_units,
    sigma,
    training_floor
  )

  if (any(!is.finite(log_probability))) {
    return(1e100)
  }

  -sum(log_probability)
}

probability_at_least_100 <- function(
    predicted_log_units, sigma, training_floor) {
  floor_log_survival <- pnorm(
    (log(training_floor - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  threshold_log_survival <- pnorm(
    (log(99.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  probability <- exp(threshold_log_survival - floor_log_survival)

  if (
    any(!is.finite(probability)) ||
      any(probability < -1e-12) ||
      any(probability > 1 + 1e-10)
  ) {
    stop("A fitted conditional threshold probability failed bounds QC.")
  }

  pmin(pmax(probability, 0), 1)
}

calculate_probability_metrics <- function(
    evaluation_data, probability_name, log_probability_name,
    metric_suffix, evaluation_basis, declared_sample_rows,
    support_excluded_rows) {
  observed_at_least_100 <- evaluation_data$units >= 100L
  probability <- evaluation_data[[probability_name]]
  log_probability_observed <- evaluation_data[[log_probability_name]]
  positive_rows <- sum(observed_at_least_100)
  negative_rows <- nrow(evaluation_data) - positive_rows
  auc_at_least_100 <- if (positive_rows == 0L || negative_rows == 0L) {
    NA_real_
  } else {
    probability_ranks <- rank(probability, ties.method = "average")
    (
      sum(probability_ranks[observed_at_least_100]) -
        positive_rows * (positive_rows + 1) / 2
    ) / (positive_rows * negative_rows)
  }
  probability_for_log_score <- pmin(pmax(probability, 1e-12), 1 - 1e-12)
  observed_share <- mean(observed_at_least_100)
  expected_share <- mean(probability)
  expected_count <- sum(probability)
  observed_count <- sum(observed_at_least_100)

  tibble(
    metric = paste0(
      c(
        "rounded_conditional_negative_log_score",
        "brier_at_least_100",
        "binary_negative_log_score_at_least_100",
        "auc_at_least_100",
        "mean_probability_at_least_100",
        "observed_share_at_least_100",
        "absolute_probability_calibration_gap_at_least_100",
        "expected_at_least_100_rows",
        "observed_at_least_100_rows",
        "absolute_at_least_100_count_error"
      ),
      metric_suffix
    ),
    preferred_direction = c(
      rep("lower", 3L),
      "higher",
      rep("descriptive", 2L),
      "lower",
      rep("descriptive", 2L),
      "lower"
    ),
    evaluation_basis = evaluation_basis,
    declared_sample_rows = declared_sample_rows,
    evaluation_rows = nrow(evaluation_data),
    support_excluded_rows = support_excluded_rows,
    value = c(
      -mean(log_probability_observed),
      mean((observed_at_least_100 - probability)^2),
      -mean(
        observed_at_least_100 * log(probability_for_log_score) +
          (1 - observed_at_least_100) * log(1 - probability_for_log_score)
      ),
      auc_at_least_100,
      expected_share,
      observed_share,
      abs(expected_share - observed_share),
      expected_count,
      observed_count,
      abs(expected_count - observed_count)
    )
  )
}

calculate_metrics <- function(prediction_data, declared_rows, training_floor) {
  declared_data <- prediction_data[declared_rows, ]
  support_data <- declared_data |>
    filter(units >= training_floor)

  if (nrow(declared_data) == 0L || nrow(support_data) == 0L) {
    stop("A declared evaluation sample is empty after required support QC.")
  }

  total_units_ratio <- sum(declared_data$predicted_latent_mean_units) /
    sum(declared_data$units)
  point_metrics <- tibble(
    metric = c(
      "rmse_log_units_latent_location",
      "mae_log_units_latent_location",
      "rmse_units_using_latent_lognormal_mean",
      "mae_units_using_latent_median",
      "predicted_to_actual_total_units_ratio_latent_mean",
      "share_within_factor_two_latent_location"
    ),
    preferred_direction = c(
      rep("lower", 4L),
      "target_one",
      "higher"
    ),
    evaluation_basis = "complete_declared_sample_latent_location",
    declared_sample_rows = nrow(declared_data),
    evaluation_rows = nrow(declared_data),
    support_excluded_rows = 0L,
    value = c(
      sqrt(mean(
        (declared_data$log_units - declared_data$predicted_log_units)^2
      )),
      mean(abs(
        declared_data$log_units - declared_data$predicted_log_units
      )),
      sqrt(mean(
        (declared_data$units - declared_data$predicted_latent_mean_units)^2
      )),
      mean(abs(
        declared_data$units - declared_data$predicted_latent_median_units
      )),
      total_units_ratio,
      mean(abs(
        declared_data$log_units - declared_data$predicted_log_units
      ) <= log(2))
    )
  )

  training_floor_metrics <- calculate_probability_metrics(
    support_data,
    "probability_at_least_100_conditioned_at_training_floor",
    "conditional_log_probability_observed_at_training_floor",
    "_conditioned_at_training_floor",
    "declared_sample_with_observed_units_at_or_above_training_floor",
    nrow(declared_data),
    nrow(declared_data) - nrow(support_data)
  )
  universe_floor_metrics <- calculate_probability_metrics(
    declared_data,
    "probability_at_least_100_transported_to_universe_floor",
    "conditional_log_probability_observed_transported_to_universe_floor",
    "_transported_to_universe_floor",
    "complete_declared_sample_transported_to_universe_floor",
    nrow(declared_data),
    0L
  )

  bind_rows(point_metrics, training_floor_metrics, universe_floor_metrics)
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
  stop("Truncated-likelihood model universe failed construction QC.")
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

metric_rows <- list()
fit_qc_rows <- list()
reference_prediction_rows <- list()
reference_coefficient_rows <- list()
reference_summary_lines <- c(
  "No-notch rounded lower-truncated likelihood audit",
  "",
  paste0("Training floors: ", paste(training_floors, collapse = ", ")),
  paste0("Universe minimum units: ", universe_min_units),
  paste0("Formula: ", paste(deparse(model_formula), collapse = " ")),
  "",
  paste(
    "OLS plug-in uses lm coefficients and sqrt(mean(residual^2)), then",
    "evaluates the same rounded conditional distribution as the MLE."
  ),
  paste(
    "MLE maximizes the integer-bin probability divided by the probability",
    "of lying at or above the declared training floor."
  ),
  ""
)

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  test_raw <- model_rows |>
    filter(
      date_filed >= window_spec$test_start,
      date_filed <= window_spec$test_end
    )

  predictions_by_floor_model <- list()

  for (training_floor in training_floors) {
    train_raw <- model_rows |>
      filter(
        date_filed >= window_spec$train_start,
        date_filed <= window_spec$train_end,
        units >= training_floor
      )

    if (nrow(train_raw) < 200L || nrow(test_raw) < 50L) {
      stop(
        "A declared window-floor combination has too few observations: ",
        window_spec$window, ", floor ", training_floor, "."
      )
    }

    prepared <- prepare_train_test(train_raw, test_raw)
    train_data <- prepared$train
    test_data <- prepared$test
    ols_fit <- lm(model_formula, data = train_data)
    train_matrix_full <- model.matrix(model_formula, data = train_data)
    test_matrix_full <- model.matrix(model_formula, data = test_data)
    ols_coefficients_full <- coef(ols_fit)
    estimable_terms <- names(ols_coefficients_full)[
      !is.na(ols_coefficients_full)
    ]
    train_matrix <- train_matrix_full[, estimable_terms, drop = FALSE]
    test_matrix <- test_matrix_full[, estimable_terms, drop = FALSE]
    ols_coefficients <- ols_coefficients_full[estimable_terms]
    ols_sigma <- sqrt(mean(residuals(ols_fit)^2))

    if (
      qr(train_matrix)$rank != ncol(train_matrix) ||
        any(!is.finite(ols_coefficients)) ||
        !identical(colnames(train_matrix), names(ols_coefficients)) ||
        !identical(colnames(test_matrix_full), colnames(train_matrix_full)) ||
        !identical(colnames(test_matrix), colnames(train_matrix)) ||
        ncol(train_matrix) != ols_fit$rank ||
        !is.finite(ols_sigma) || ols_sigma <= 0
    ) {
      stop(
        "A model matrix or OLS start failed full-rank QC: ",
        window_spec$window, ", floor ", training_floor, "."
      )
    }

    ols_parameters <- c(ols_coefficients, log(ols_sigma))
    ols_negative_log_likelihood <- negative_log_likelihood(
      ols_parameters,
      train_matrix,
      train_data$units,
      training_floor
    )

    mle_warnings <- character()
    mle_fit <- withCallingHandlers(
      nlminb(
        start = ols_parameters,
        objective = negative_log_likelihood,
        lower = c(rep(-Inf, ncol(train_matrix)), log(0.02)),
        upper = c(rep(Inf, ncol(train_matrix)), log(10)),
        model_matrix = train_matrix,
        units = train_data$units,
        training_floor = training_floor,
        control = list(
          eval.max = 5000L,
          iter.max = 1000L,
          rel.tol = 1e-10,
          x.tol = 1e-8
        )
      ),
      warning = function(warning_condition) {
        mle_warnings <<- c(mle_warnings, conditionMessage(warning_condition))
        invokeRestart("muffleWarning")
      }
    )

    mle_coefficients <- mle_fit$par[seq_len(ncol(train_matrix))]
    mle_sigma <- exp(mle_fit$par[ncol(train_matrix) + 1L])
    mle_negative_log_likelihood <- negative_log_likelihood(
      mle_fit$par,
      train_matrix,
      train_data$units,
      training_floor
    )

    if (
      mle_fit$convergence != 0L ||
        any(!is.finite(mle_fit$par)) ||
        !is.finite(mle_negative_log_likelihood) ||
        mle_negative_log_likelihood > ols_negative_log_likelihood + 1e-5 ||
        mle_sigma <= 0.020001 || mle_sigma >= 9.999
    ) {
      stop(
        "Rounded truncated MLE failed convergence or objective QC: ",
        window_spec$window, ", floor ", training_floor,
        ". Optimizer message: ", mle_fit$message
      )
    }

    model_coefficients <- list(
      ols_plugin = ols_coefficients,
      truncated_rounded_mle = mle_coefficients
    )
    model_sigmas <- c(
      ols_plugin = ols_sigma,
      truncated_rounded_mle = mle_sigma
    )
    model_negative_log_likelihoods <- c(
      ols_plugin = ols_negative_log_likelihood,
      truncated_rounded_mle = mle_negative_log_likelihood
    )

    normalization_errors <- numeric()

    for (model_name in model_names) {
      predicted_log_units <- as.numeric(
        test_matrix %*% model_coefficients[[model_name]]
      )
      sigma <- model_sigmas[[model_name]]
      conditional_log_probability_observed_at_training_floor <-
        rounded_conditional_log_probability(
          test_data$units,
          predicted_log_units,
          sigma,
          training_floor
        )
      probability_at_least_100_conditioned_at_training_floor <-
        probability_at_least_100(
          predicted_log_units,
          sigma,
          training_floor
        )
      conditional_log_probability_observed_transported_to_universe_floor <-
        rounded_conditional_log_probability(
          test_data$units,
          predicted_log_units,
          sigma,
          universe_min_units
        )
      probability_at_least_100_transported_to_universe_floor <-
        probability_at_least_100(
          predicted_log_units,
          sigma,
          universe_min_units
        )

      prediction_data <- test_data |>
        transmute(
          observation_id,
          job_number,
          date_filed,
          units,
          log_units,
          predicted_log_units = .env$predicted_log_units,
          predicted_latent_median_units = exp(.env$predicted_log_units),
          predicted_latent_mean_units = exp(
            .env$predicted_log_units + .env$sigma^2 / 2
          ),
          probability_at_least_100_conditioned_at_training_floor =
            .env$probability_at_least_100_conditioned_at_training_floor,
          conditional_log_probability_observed_at_training_floor =
            .env$conditional_log_probability_observed_at_training_floor,
          probability_at_least_100_transported_to_universe_floor =
            .env$probability_at_least_100_transported_to_universe_floor,
          conditional_log_probability_observed_transported_to_universe_floor =
            .env$conditional_log_probability_observed_transported_to_universe_floor,
          fitted_sigma = .env$sigma
        )

      if (
        any(!is.finite(prediction_data$predicted_log_units)) ||
          any(!is.finite(prediction_data$predicted_latent_mean_units)) ||
          any(!is.finite(
            prediction_data$conditional_log_probability_observed_at_training_floor[
              prediction_data$units >= training_floor
            ]
          )) ||
          any(!is.finite(
            prediction_data$conditional_log_probability_observed_transported_to_universe_floor
          ))
      ) {
        stop("A prediction vector failed finite-value QC.")
      }

      predictions_by_floor_model[[paste(training_floor, model_name)]] <-
        prediction_data

      qc_rows <- seq_len(min(10L, nrow(train_matrix)))
      qc_mu <- as.numeric(
        train_matrix[qc_rows, , drop = FALSE] %*%
          model_coefficients[[model_name]]
      )
      qc_upper_units <- max(10000L, 10L * max(train_data$units))
      qc_floor_z <- (log(training_floor - 0.5) - qc_mu) / sigma
      qc_upper_z <- (log(qc_upper_units + 0.5) - qc_mu) / sigma
      qc_log_denominator <- pnorm(
        qc_floor_z,
        lower.tail = FALSE,
        log.p = TRUE
      )
      qc_mass_through_upper <- exp(
        log_normal_interval_probability(qc_floor_z, qc_upper_z) -
          qc_log_denominator
      )
      qc_tail_above_upper <- exp(
        pnorm(qc_upper_z, lower.tail = FALSE, log.p = TRUE) -
          qc_log_denominator
      )
      normalization_errors[model_name] <- max(abs(
        qc_mass_through_upper + qc_tail_above_upper - 1
      ))

      if (normalization_errors[model_name] > 1e-10) {
        stop("A rounded conditional distribution failed normalization QC.")
      }

      if (window_spec$window == reference_window) {
        reference_prediction_rows[[length(reference_prediction_rows) + 1L]] <-
          prediction_data |>
          mutate(
            training_floor = training_floor,
            model = model_name,
            .after = date_filed
          )
        full_model_estimates <- rep(NA_real_, ncol(train_matrix_full))
        names(full_model_estimates) <- colnames(train_matrix_full)
        full_model_estimates[estimable_terms] <-
          model_coefficients[[model_name]]
        reference_coefficient_rows[[
          length(reference_coefficient_rows) + 1L
        ]] <- tibble(
          training_floor = training_floor,
          model = model_name,
          term = colnames(train_matrix_full),
          estimable = term %in% estimable_terms,
          estimate = as.numeric(full_model_estimates)
        )
      }
    }

    fit_qc_rows[[length(fit_qc_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      training_floor = training_floor,
      train_rows = nrow(train_data),
      test_rows_all_universe = nrow(test_data),
      candidate_coefficient_count = ncol(train_matrix_full),
      estimable_coefficient_count = ncol(train_matrix),
      model_matrix_rank = qr(train_matrix_full)$rank,
      ols_sigma = ols_sigma,
      mle_sigma = mle_sigma,
      ols_rounded_conditional_negative_log_likelihood =
        ols_negative_log_likelihood,
      mle_rounded_conditional_negative_log_likelihood =
        mle_negative_log_likelihood,
      mle_training_log_likelihood_gain_per_row =
        (ols_negative_log_likelihood - mle_negative_log_likelihood) /
          nrow(train_data),
      maximum_absolute_coefficient_change = max(abs(
        mle_coefficients - ols_coefficients
      )),
      mle_convergence_code = mle_fit$convergence,
      mle_optimizer_message = mle_fit$message,
      mle_iterations = mle_fit$iterations,
      mle_function_evaluations = unname(mle_fit$evaluations["function"]),
      mle_gradient_evaluations = unname(mle_fit$evaluations["gradient"]),
      mle_warning_messages = if_else(
        length(mle_warnings) == 0L,
        NA_character_,
        paste(unique(mle_warnings), collapse = " | ")
      ),
      ols_maximum_normalization_error =
        normalization_errors["ols_plugin"],
      mle_maximum_normalization_error =
        normalization_errors["truncated_rounded_mle"]
    )

    if (window_spec$window == reference_window) {
      reference_summary_lines <- c(
        reference_summary_lines,
        paste0("Training floor: ", training_floor),
        paste0(
          "Training dates: ", window_spec$train_start,
          " through ", window_spec$train_end
        ),
        paste0(
          "Held-out dates: ", window_spec$test_start,
          " through ", window_spec$test_end
        ),
        paste0("Training observations: ", nrow(train_data)),
        paste0("Held-out universe observations: ", nrow(test_data)),
        paste0(
          "Candidate / estimable coefficients: ",
          ncol(train_matrix_full), " / ", ncol(train_matrix)
        ),
        paste0("OLS sigma: ", format(ols_sigma, digits = 12)),
        paste0("MLE sigma: ", format(mle_sigma, digits = 12)),
        paste0(
          "OLS rounded conditional negative log likelihood: ",
          format(ols_negative_log_likelihood, digits = 14)
        ),
        paste0(
          "MLE rounded conditional negative log likelihood: ",
          format(mle_negative_log_likelihood, digits = 14)
        ),
        paste0(
          "MLE training log-likelihood gain per row: ",
          format(
            (ols_negative_log_likelihood - mle_negative_log_likelihood) /
              nrow(train_data),
            digits = 12
          )
        ),
        paste0("MLE convergence code: ", mle_fit$convergence),
        paste0("MLE optimizer message: ", mle_fit$message),
        "",
        str_dup("=", 80L),
        ""
      )
    }
  }

  baseline_predictions <- predictions_by_floor_model[[paste(
    universe_min_units,
    "ols_plugin"
  )]]
  expected_ids <- baseline_predictions$observation_id

  for (training_floor in training_floors) {
    for (model_name in model_names) {
      if (!identical(
        predictions_by_floor_model[[
          paste(training_floor, model_name)
        ]]$observation_id,
        expected_ids
      )) {
        stop("Prediction rows differ across floors or models within a window.")
      }
    }
  }

  actual_local_rows <-
    baseline_predictions$units >= local_min_units &
    baseline_predictions$units <= local_max_units
  x_selected_rows <-
    baseline_predictions$predicted_latent_median_units >= local_min_units &
    baseline_predictions$predicted_latent_median_units <= local_max_units
  sample_rows <- list(
    all_sample = rep(TRUE, nrow(baseline_predictions)),
    actual_local = actual_local_rows,
    x_selected = x_selected_rows
  )
  names(sample_rows) <- c(
    all_sample_name,
    actual_local_sample_name,
    x_selected_sample_name
  )

  if (!any(actual_local_rows) || !any(x_selected_rows)) {
    stop("A declared local evaluation sample is empty: ", window_spec$window)
  }

  for (training_floor in training_floors) {
    for (model_name in model_names) {
      prediction_data <- predictions_by_floor_model[[paste(
        training_floor,
        model_name
      )]]

      for (sample_name in names(sample_rows)) {
        metric_rows[[length(metric_rows) + 1L]] <- calculate_metrics(
          prediction_data,
          sample_rows[[sample_name]],
          training_floor
        ) |>
          mutate(
            window = window_spec$window,
            regime_note = window_spec$regime_note,
            training_floor = training_floor,
            model = model_name,
            sample = sample_name,
            .before = metric
          )
      }
    }
  }

  if (window_spec$window == reference_window) {
    reference_ids_actual_local <-
      baseline_predictions$observation_id[actual_local_rows]
    reference_ids_x_selected <-
      baseline_predictions$observation_id[x_selected_rows]
    reference_prediction_rows <- lapply(
      reference_prediction_rows,
      function(reference_data) {
        reference_data |>
          mutate(
            actual_local_outcome_selected = observation_id %in%
              reference_ids_actual_local,
            x_selected_fixed_risk_set = observation_id %in%
              reference_ids_x_selected
          )
      }
    )
  }
}

window_metrics <- bind_rows(metric_rows) |>
  arrange(sample, metric, window, training_floor, match(model, model_names))

fit_qc <- bind_rows(fit_qc_rows) |>
  arrange(window, training_floor)

ols_metrics <- window_metrics |>
  filter(model == "ols_plugin") |>
  select(
    window, training_floor, sample, metric,
    ols_value = value
  )

validation_summary <- window_metrics |>
  left_join(
    ols_metrics,
    by = c("window", "training_floor", "sample", "metric"),
    relationship = "many-to-one"
  ) |>
  mutate(
    comparison_score = case_when(
      preferred_direction == "lower" ~ value,
      preferred_direction == "higher" ~ -value,
      preferred_direction == "target_one" ~ abs(log(value)),
      TRUE ~ NA_real_
    ),
    ols_comparison_score = case_when(
      preferred_direction == "lower" ~ ols_value,
      preferred_direction == "higher" ~ -ols_value,
      preferred_direction == "target_one" ~ abs(log(ols_value)),
      TRUE ~ NA_real_
    ),
    better_than_ols = model == "truncated_rounded_mle" &
      comparison_score < ols_comparison_score
  ) |>
  group_by(
    training_floor, model, sample, metric,
    preferred_direction, evaluation_basis
  ) |>
  summarise(
    validation_windows = n_distinct(window),
    finite_windows = sum(is.finite(value)),
    mean_declared_sample_rows = mean(declared_sample_rows),
    mean_evaluation_rows = mean(evaluation_rows),
    mean_support_excluded_rows = mean(support_excluded_rows),
    mean_value = mean(value[is.finite(value)]),
    median_value = median(value[is.finite(value)]),
    minimum_value = min(value[is.finite(value)]),
    maximum_value = max(value[is.finite(value)]),
    windows_better_than_ols = sum(better_than_ols, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(sample, metric, training_floor, match(model, model_names))

reference_predictions <- bind_rows(reference_prediction_rows) |>
  select(
    observation_id, job_number, date_filed, training_floor, model,
    units, log_units, predicted_log_units,
    predicted_latent_median_units, predicted_latent_mean_units,
    fitted_sigma,
    probability_at_least_100_conditioned_at_training_floor,
    conditional_log_probability_observed_at_training_floor,
    probability_at_least_100_transported_to_universe_floor,
    conditional_log_probability_observed_transported_to_universe_floor,
    actual_local_outcome_selected, x_selected_fixed_risk_set
  ) |>
  arrange(training_floor, match(model, model_names), observation_id)

reference_coefficients <- bind_rows(reference_coefficient_rows) |>
  arrange(training_floor, match(model, model_names), term)

expected_metric_rows <-
  nrow(window_specs) * length(training_floors) * length(model_names) *
  3L * 26L
expected_fit_rows <- nrow(window_specs) * length(training_floors)
expected_reference_rows <-
  sum(reference_predictions$training_floor == universe_min_units &
    reference_predictions$model == "ols_plugin") *
  length(training_floors) * length(model_names)

if (
  nrow(window_metrics) != expected_metric_rows ||
    nrow(fit_qc) != expected_fit_rows ||
    any(fit_qc$mle_convergence_code != 0L) ||
    any(fit_qc$estimable_coefficient_count != fit_qc$model_matrix_rank) ||
    any(fit_qc$candidate_coefficient_count < fit_qc$model_matrix_rank) ||
    any(fit_qc$mle_training_log_likelihood_gain_per_row < -1e-8) ||
    any(fit_qc$ols_maximum_normalization_error > 1e-10) ||
    any(fit_qc$mle_maximum_normalization_error > 1e-10) ||
    nrow(reference_predictions) != expected_reference_rows ||
    nrow(reference_coefficients) !=
      sum(fit_qc$candidate_coefficient_count[
        fit_qc$window == reference_window
      ]) *
        length(model_names) ||
    any(!is.finite(window_metrics$value[
      !str_starts(window_metrics$metric, "auc_at_least_100")
    ])) ||
    any(
      reference_predictions$probability_at_least_100_conditioned_at_training_floor <
        0
    ) ||
    any(
      reference_predictions$probability_at_least_100_conditioned_at_training_floor >
        1
    ) ||
    any(
      reference_predictions$probability_at_least_100_transported_to_universe_floor <
        0
    ) ||
    any(
      reference_predictions$probability_at_least_100_transported_to_universe_floor >
        1
    )
) {
  stop("Truncated-likelihood outputs failed completeness or numerical QC.")
}

write_csv_if_changed(
  window_metrics,
  "../output/no_notch_truncated_likelihood_window_metrics.csv"
)
write_csv_if_changed(
  validation_summary,
  "../output/no_notch_truncated_likelihood_validation_summary.csv"
)
write_csv_if_changed(
  fit_qc,
  "../output/no_notch_truncated_likelihood_fit_qc.csv"
)
write_csv_if_changed(
  reference_coefficients,
  "../output/no_notch_truncated_likelihood_reference_coefficients.csv"
)
write_parquet_if_changed(
  reference_predictions,
  "../output/no_notch_truncated_likelihood_reference_predictions.parquet"
)
reference_summary_temp <- tempfile(fileext = ".txt")
writeLines(reference_summary_lines, reference_summary_temp)
copy_if_changed(
  reference_summary_temp,
  "../output/no_notch_truncated_likelihood_reference_fit_summary.txt"
)

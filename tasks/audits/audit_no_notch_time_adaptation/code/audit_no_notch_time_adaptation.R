# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_time_adaptation/code")
# training_floors_text <- "6,11"
# universe_min_units <- 6L
# expanding_start_year <- 2010L
# first_train_end_year <- 2015L
# last_train_end_year <- 2021L
# final_train_end_year <- 2023L
# rolling_years <- 5L
# recent_intercept_years <- 2L
# risk_min_units <- 50L
# risk_max_units <- 150L
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

if (length(args) != 11L) {
  stop(
    "Expected eleven arguments: training floors, universe floor, expanding ",
    "start year, first, last validation, and final training end years, ",
    "rolling years, recent intercept years, risk-set bounds, and minimum ",
    "category rows."
  )
}

training_floors_text <- args[1]
universe_min_units <- as.integer(args[2])
expanding_start_year <- as.integer(args[3])
first_train_end_year <- as.integer(args[4])
last_train_end_year <- as.integer(args[5])
final_train_end_year <- as.integer(args[6])
rolling_years <- as.integer(args[7])
recent_intercept_years <- as.integer(args[8])
risk_min_units <- as.integer(args[9])
risk_max_units <- as.integer(args[10])
minimum_category_rows <- as.integer(args[11])
training_floors <- as.integer(str_split(training_floors_text, ",", simplify = TRUE))

if (
  any(is.na(c(
    training_floors, universe_min_units, expanding_start_year,
    first_train_end_year, last_train_end_year, rolling_years,
    final_train_end_year, recent_intercept_years, risk_min_units, risk_max_units,
    minimum_category_rows
  ))) ||
    !identical(training_floors, c(6L, 11L)) ||
    universe_min_units != 6L ||
    first_train_end_year <= expanding_start_year ||
    last_train_end_year < first_train_end_year ||
    last_train_end_year >= 2022L ||
    final_train_end_year <= last_train_end_year ||
    final_train_end_year > 2023L ||
    rolling_years < 3L ||
    recent_intercept_years < 1L ||
    recent_intercept_years >= rolling_years ||
    risk_min_units < universe_min_units ||
    risk_max_units <= risk_min_units ||
    minimum_category_rows < 2L
) {
  stop("Time-adaptation audit arguments are not internally consistent.")
}

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
    keep_levels <- names(training_counts)[training_counts >= minimum_category_rows]

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
    train_prepared[[feature_name]] <- factor(train_values, levels = factor_levels)
    test_prepared[[feature_name]] <- factor(test_values, levels = factor_levels)
  }

  list(
    train = train_prepared,
    test = test_prepared,
    training_year_mean = training_year_mean
  )
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
    upper_log_cdf <- pnorm(upper_z[!use_upper_tail], log.p = TRUE)
    lower_log_cdf <- pnorm(lower_z[!use_upper_tail], log.p = TRUE)
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
    units, predicted_log_units, sigma, conditioning_floor) {
  lower_z <- (log(units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(conditioning_floor - 0.5) - predicted_log_units
  ) / sigma

  log_probability <- log_normal_interval_probability(lower_z, upper_z) -
    pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  log_probability[units < conditioning_floor] <- NA_real_
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

fit_rounded_mle <- function(train_raw, test_raw, training_floor, model_formula) {
  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test
  ols_fit <- lm(model_formula, data = train_data)
  train_matrix_full <- model.matrix(model_formula, data = train_data)
  test_matrix_full <- model.matrix(model_formula, data = test_data)
  ols_coefficients_full <- coef(ols_fit)
  estimable_terms <- names(ols_coefficients_full)[!is.na(ols_coefficients_full)]
  train_matrix <- train_matrix_full[, estimable_terms, drop = FALSE]
  test_matrix <- test_matrix_full[, estimable_terms, drop = FALSE]
  ols_coefficients <- ols_coefficients_full[estimable_terms]
  ols_sigma <- sqrt(mean(residuals(ols_fit)^2))

  if (
    qr(train_matrix)$rank != ncol(train_matrix) ||
      !identical(colnames(train_matrix), names(ols_coefficients)) ||
      !identical(colnames(test_matrix_full), colnames(train_matrix_full)) ||
      !identical(colnames(test_matrix), colnames(train_matrix)) ||
      any(!is.finite(ols_coefficients)) ||
      !is.finite(ols_sigma) || ols_sigma <= 0
  ) {
    stop("A model matrix or OLS starting value failed QC.")
  }

  ols_parameters <- c(ols_coefficients, log(ols_sigma))
  ols_objective <- negative_log_likelihood(
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
  coefficient_count <- ncol(train_matrix)
  coefficients <- mle_fit$par[seq_len(coefficient_count)]
  names(coefficients) <- colnames(train_matrix)
  sigma <- exp(mle_fit$par[coefficient_count + 1L])
  mle_objective <- negative_log_likelihood(
    mle_fit$par,
    train_matrix,
    train_data$units,
    training_floor
  )

  if (
    mle_fit$convergence != 0L ||
      length(mle_warnings) > 0L ||
      any(!is.finite(mle_fit$par)) ||
      !is.finite(mle_objective) ||
      mle_objective > ols_objective + 1e-5 ||
      sigma <= 0.020001 || sigma >= 9.999
  ) {
    stop("A rounded truncated MLE failed convergence or objective QC.")
  }

  list(
    train_data = train_data,
    test_data = test_data,
    train_matrix = train_matrix,
    test_matrix = test_matrix,
    coefficients = coefficients,
    sigma = sigma,
    train_mu = as.numeric(train_matrix %*% coefficients),
    test_mu = as.numeric(test_matrix %*% coefficients),
    ols_test_mu = as.numeric(test_matrix %*% ols_coefficients),
    objective = mle_objective,
    ols_objective = ols_objective,
    convergence = mle_fit$convergence,
    optimizer_message = mle_fit$message,
    aliased_terms = paste(
      names(ols_coefficients_full)[is.na(ols_coefficients_full)],
      collapse = ";"
    ),
    training_year_mean = prepared$training_year_mean
  )
}

probability_at_least_100 <- function(predicted_log_units, sigma) {
  floor_log_survival <- pnorm(
    (log(universe_min_units - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  threshold_log_survival <- pnorm(
    (log(99.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  pmin(pmax(exp(threshold_log_survival - floor_log_survival), 0), 1)
}

conditional_cdf <- function(predicted_log_units, sigma, threshold) {
  lower_cdf <- pnorm(
    (log(universe_min_units - 0.5) - predicted_log_units) / sigma
  )
  upper_cdf <- pnorm((log(threshold + 0.5) - predicted_log_units) / sigma)
  pmin(pmax((upper_cdf - lower_cdf) / pmax(1 - lower_cdf, 1e-12), 0), 1)
}

calculate_metrics <- function(prediction_data) {
  observed_at_least_100 <- prediction_data$units >= 100L
  probability <- prediction_data$probability_at_least_100
  probability_for_log <- pmin(pmax(probability, 1e-12), 1 - 1e-12)
  positive_rows <- sum(observed_at_least_100)
  negative_rows <- nrow(prediction_data) - positive_rows
  auc <- if (positive_rows == 0L || negative_rows == 0L) {
    NA_real_
  } else {
    probability_ranks <- rank(probability, ties.method = "average")
    (
      sum(probability_ranks[observed_at_least_100]) -
        positive_rows * (positive_rows + 1) / 2
    ) / (positive_rows * negative_rows)
  }
  cdf_errors <- vapply(80L:120L, function(threshold) {
    predicted_share <- mean(conditional_cdf(
      prediction_data$predicted_log_units,
      prediction_data$sigma[1],
      threshold
    ))
    observed_share <- mean(prediction_data$units <= threshold)
    predicted_share - observed_share
  }, numeric(1))
  expected_count <- sum(probability)
  observed_count <- sum(observed_at_least_100)

  tibble(
    metric = c(
      "rounded_negative_log_score",
      "brier_at_least_100",
      "binary_negative_log_score_at_least_100",
      "cdf_rmse_80_120",
      "absolute_at_least_100_count_error",
      "expected_at_least_100_rows",
      "observed_at_least_100_rows",
      "rmse_log_units",
      "share_within_factor_two",
      "auc_at_least_100"
    ),
    preferred_direction = c(
      rep("lower", 5L),
      rep("descriptive", 2L),
      "lower",
      "higher",
      "higher"
    ),
    value = c(
      -mean(prediction_data$log_probability_observed),
      mean((observed_at_least_100 - probability)^2),
      -mean(
        observed_at_least_100 * log(probability_for_log) +
          (1 - observed_at_least_100) * log(1 - probability_for_log)
      ),
      sqrt(mean(cdf_errors^2)),
      abs(expected_count - observed_count),
      expected_count,
      observed_count,
      sqrt(mean(
        (prediction_data$log_units - prediction_data$predicted_log_units)^2
      )),
      mean(abs(
        prediction_data$log_units - prediction_data$predicted_log_units
      ) <= log(2)),
      auc
    )
  )
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

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
  stop("Time-adaptation model universe failed construction QC.")
}

time_windows <- tibble(train_end_year = first_train_end_year:last_train_end_year) |>
  mutate(
    window = paste0("train_through_", train_end_year, "_test_", train_end_year + 1L),
    expanding_train_start = as.Date(paste0(expanding_start_year, "-01-01")),
    rolling_train_start = as.Date(paste0(train_end_year - rolling_years + 1L, "-01-01")),
    train_end = as.Date(paste0(train_end_year, "-12-31")),
    recent_intercept_start = as.Date(paste0(
      train_end_year - recent_intercept_years + 1L,
      "-01-01"
    )),
    test_start = as.Date(paste0(train_end_year + 1L, "-01-01")),
    test_end = if_else(
      train_end_year == last_train_end_year,
      as.Date("2022-06-15"),
      as.Date(paste0(train_end_year + 1L, "-12-31"))
    )
  )

metric_rows <- list()
fit_qc_rows <- list()
sample_qc_rows <- list()
out_of_time_prediction_rows <- list()

for (window_index in seq_len(nrow(time_windows))) {
  window_spec <- time_windows[window_index, ]
  test_raw <- model_rows |>
    filter(
      date_filed >= window_spec$test_start,
      date_filed <= window_spec$test_end
    )
  predictions <- list()
  fixed_risk_rows <- NULL

  for (training_floor in training_floors) {
    expanding_train_raw <- model_rows |>
      filter(
        date_filed >= window_spec$expanding_train_start,
        date_filed <= window_spec$train_end,
        units >= training_floor
      )
    rolling_train_raw <- model_rows |>
      filter(
        date_filed >= window_spec$rolling_train_start,
        date_filed <= window_spec$train_end,
        units >= training_floor
      )

    if (
      nrow(expanding_train_raw) < 200L ||
        nrow(rolling_train_raw) < 200L ||
        nrow(test_raw) < 50L
    ) {
      stop("A time-adaptation window has too few observations.")
    }

    expanding_fit <- fit_rounded_mle(
      expanding_train_raw,
      test_raw,
      training_floor,
      model_formula
    )
    rolling_fit <- fit_rounded_mle(
      rolling_train_raw,
      test_raw,
      training_floor,
      model_formula
    )
    recent_rows <- expanding_fit$train_data$date_filed >=
      window_spec$recent_intercept_start
    recent_objective <- function(intercept_delta) {
      -sum(rounded_conditional_log_probability(
        expanding_fit$train_data$units[recent_rows],
        expanding_fit$train_mu[recent_rows] + intercept_delta,
        expanding_fit$sigma,
        training_floor
      ))
    }
    recent_fit <- optimize(recent_objective, interval = c(-2, 2))
    intercept_delta <- recent_fit$minimum

    if (
      sum(recent_rows) < 100L ||
        !is.finite(intercept_delta) ||
        abs(intercept_delta) > 1.999
    ) {
      stop("A recent-intercept calibration failed QC.")
    }

    if (training_floor == universe_min_units) {
      fixed_risk_rows <-
        exp(expanding_fit$ols_test_mu) >= risk_min_units &
        exp(expanding_fit$ols_test_mu) <= risk_max_units
    }

    candidate_specs <- list(
      expanding = list(
        predicted_log_units = expanding_fit$test_mu,
        sigma = expanding_fit$sigma,
        train_start = window_spec$expanding_train_start,
        train_rows = nrow(expanding_fit$train_data),
        objective = expanding_fit$objective,
        intercept_delta = 0,
        fit = expanding_fit
      ),
      rolling_5_year = list(
        predicted_log_units = rolling_fit$test_mu,
        sigma = rolling_fit$sigma,
        train_start = window_spec$rolling_train_start,
        train_rows = nrow(rolling_fit$train_data),
        objective = rolling_fit$objective,
        intercept_delta = 0,
        fit = rolling_fit
      ),
      recent_2_year_intercept = list(
        predicted_log_units = expanding_fit$test_mu + intercept_delta,
        sigma = expanding_fit$sigma,
        train_start = window_spec$expanding_train_start,
        train_rows = nrow(expanding_fit$train_data),
        objective = recent_fit$objective,
        intercept_delta = intercept_delta,
        fit = expanding_fit
      )
    )

    for (timing_name in names(candidate_specs)) {
      candidate <- candidate_specs[[timing_name]]
      candidate_name <- paste0("floor_", training_floor, "_", timing_name)
      predicted_log_units <- candidate$predicted_log_units
      sigma <- candidate$sigma
      predictions[[candidate_name]] <- test_raw |>
        transmute(
          observation_id, job_number, date_filed, filing_year,
          units,
          log_units,
          predicted_log_units = .env$predicted_log_units,
          sigma = .env$sigma,
          probability_at_least_100 = probability_at_least_100(
            .env$predicted_log_units,
            .env$sigma
          ),
          log_probability_observed = rounded_conditional_log_probability(
            units,
            .env$predicted_log_units,
            .env$sigma,
            universe_min_units
          )
        )
      out_of_time_prediction_rows[[
        length(out_of_time_prediction_rows) + 1L
      ]] <- predictions[[candidate_name]] |>
        mutate(
          window = window_spec$window,
          training_floor = training_floor,
          timing = timing_name,
          model = candidate_name,
          .before = observation_id
        )
      fit_qc_rows[[length(fit_qc_rows) + 1L]] <- tibble(
        window = window_spec$window,
        training_floor = training_floor,
        timing = timing_name,
        model = candidate_name,
        train_start = candidate$train_start,
        train_end = window_spec$train_end,
        train_rows = candidate$train_rows,
        recent_calibration_rows = if_else(
          timing_name == "recent_2_year_intercept",
          sum(recent_rows),
          NA_integer_
        ),
        sigma = sigma,
        intercept_delta = candidate$intercept_delta,
        objective = candidate$objective,
        convergence = candidate$fit$convergence,
        optimizer_message = candidate$fit$optimizer_message,
        aliased_terms = candidate$fit$aliased_terms,
        training_year_mean = candidate$fit$training_year_mean
      )
    }
  }

  if (is.null(fixed_risk_rows) || !any(fixed_risk_rows)) {
    stop("A fixed X-selected risk set is empty.")
  }

  sample_qc_rows[[length(sample_qc_rows) + 1L]] <- tibble(
    window = window_spec$window,
    test_start = window_spec$test_start,
    test_end = window_spec$test_end,
    all_test_rows = nrow(test_raw),
    risk_set_rows = sum(fixed_risk_rows),
    risk_set_rows_units_6_10 = sum(
      fixed_risk_rows & test_raw$units >= 6L & test_raw$units <= 10L
    ),
    risk_set_rows_units_11_99 = sum(
      fixed_risk_rows & test_raw$units >= 11L & test_raw$units <= 99L
    ),
    risk_set_rows_units_100_plus = sum(
      fixed_risk_rows & test_raw$units >= 100L
    )
  )

  for (candidate_name in names(predictions)) {
    candidate_parts <- str_match(
      candidate_name,
      "^floor_([0-9]+)_(expanding|rolling_5_year|recent_2_year_intercept)$"
    )
    training_floor <- as.integer(candidate_parts[2])
    timing_name <- candidate_parts[3]
    sample_rows <- list(
      all_units_at_least_6 = rep(TRUE, nrow(test_raw)),
      floor_6_x_predicted_units_50_150_fixed_risk_set = fixed_risk_rows
    )

    for (sample_name in names(sample_rows)) {
      evaluation_rows <- sample_rows[[sample_name]]
      metric_rows[[length(metric_rows) + 1L]] <- calculate_metrics(
        predictions[[candidate_name]][evaluation_rows, ]
      ) |>
        mutate(
          window = window_spec$window,
          training_floor = training_floor,
          timing = timing_name,
          model = candidate_name,
          sample = sample_name,
          evaluation_rows = sum(evaluation_rows),
          .before = metric
        )
    }
  }
}

window_metrics <- bind_rows(metric_rows) |>
  arrange(sample, metric, window, training_floor, timing)

out_of_time_predictions <- bind_rows(out_of_time_prediction_rows) |>
  arrange(window, training_floor, timing, date_filed, job_number)

fit_qc <- bind_rows(fit_qc_rows) |>
  arrange(window, training_floor, timing)

sample_qc <- bind_rows(sample_qc_rows) |>
  arrange(window)

validation_summary <- window_metrics |>
  group_by(training_floor, timing, model, sample, metric, preferred_direction) |>
  summarise(
    validation_windows = n_distinct(window),
    mean_evaluation_rows = mean(evaluation_rows),
    mean_value = mean(value, na.rm = TRUE),
    median_value = median(value, na.rm = TRUE),
    minimum_value = min(value, na.rm = TRUE),
    maximum_value = max(value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(sample, metric, training_floor, timing)

selection_metrics <- c(
  "rounded_negative_log_score",
  "brier_at_least_100",
  "cdf_rmse_80_120",
  "absolute_at_least_100_count_error"
)

ranking_cells <- window_metrics |>
  filter(metric %in% selection_metrics) |>
  group_by(window, sample, metric) |>
  mutate(metric_rank = rank(value, ties.method = "average")) |>
  ungroup()

model_ranking <- ranking_cells |>
  group_by(training_floor, timing, model) |>
  summarise(
    selection_cells = n(),
    average_rank = mean(metric_rank),
    row_weighted_average_rank = weighted.mean(metric_rank, evaluation_rows),
    median_rank = median(metric_rank),
    first_place_cells = sum(metric_rank == 1),
    .groups = "drop"
  ) |>
  arrange(average_rank, median_rank, desc(first_place_cells), training_floor, timing) |>
  mutate(overall_rank = row_number(), .before = training_floor)

model_choice <- model_ranking |>
  slice_head(n = 1L) |>
  mutate(
    choice_status = "interim preferred full-distribution model",
    selection_rule = paste(
      "lowest average within-window rank across exact unit log score,",
      "Brier score at 100, CDF RMSE from 80 to 120, and absolute 100-plus",
      "count error in the full sample and fixed X-selected risk set"
    )
  ) |>
  select(choice_status, selection_rule, everything())

final_fit_specs <- tribble(
  ~model_role, ~training_floor, ~timing,
  "preferred_full_distribution", 6L, "expanding",
  "required_sample_robustness", 11L, "rolling_5_year"
)
final_fit_parameter_rows <- list()
final_train_end <- as.Date(paste0(final_train_end_year, "-12-31"))

for (final_spec_index in seq_len(nrow(final_fit_specs))) {
  final_spec <- final_fit_specs[final_spec_index, ]
  final_train_start <- if (final_spec$timing == "expanding") {
    as.Date(paste0(expanding_start_year, "-01-01"))
  } else {
    as.Date(paste0(final_train_end_year - rolling_years + 1L, "-01-01"))
  }
  final_train_raw <- model_rows |>
    filter(
      date_filed >= final_train_start,
      date_filed <= final_train_end,
      units >= final_spec$training_floor
    )
  final_fit <- fit_rounded_mle(
    final_train_raw,
    final_train_raw,
    final_spec$training_floor,
    model_formula
  )
  final_model_name <- paste0(
    "floor_", final_spec$training_floor, "_", final_spec$timing
  )
  final_fit_parameter_rows[[length(final_fit_parameter_rows) + 1L]] <- tibble(
    model_role = final_spec$model_role,
    model = final_model_name,
    training_floor = final_spec$training_floor,
    timing = final_spec$timing,
    train_start = final_train_start,
    train_end = final_train_end,
    train_rows = nrow(final_fit$train_data),
    training_year_mean = final_fit$training_year_mean,
    term = names(final_fit$coefficients),
    estimate = as.numeric(final_fit$coefficients)
  )
  final_fit_parameter_rows[[length(final_fit_parameter_rows) + 1L]] <- tibble(
    model_role = final_spec$model_role,
    model = final_model_name,
    training_floor = final_spec$training_floor,
    timing = final_spec$timing,
    train_start = final_train_start,
    train_end = final_train_end,
    train_rows = nrow(final_fit$train_data),
    training_year_mean = final_fit$training_year_mean,
    term = "shock_sigma",
    estimate = final_fit$sigma
  )
}

interim_fit_parameters <- bind_rows(final_fit_parameter_rows) |>
  arrange(match(model_role, final_fit_specs$model_role), term)

expected_metric_rows <- nrow(time_windows) * length(training_floors) * 3L * 2L * 10L
expected_fit_rows <- nrow(time_windows) * length(training_floors) * 3L
expected_selection_cells <- nrow(time_windows) * 2L * length(selection_metrics)
expected_prediction_rows <- sum(sample_qc$all_test_rows) *
  length(training_floors) * 3L

if (
  nrow(window_metrics) != expected_metric_rows ||
    nrow(out_of_time_predictions) != expected_prediction_rows ||
    anyDuplicated(out_of_time_predictions[c("observation_id", "model")]) ||
    nrow(fit_qc) != expected_fit_rows ||
    nrow(sample_qc) != nrow(time_windows) ||
    any(
      sample_qc$risk_set_rows !=
        sample_qc$risk_set_rows_units_6_10 +
        sample_qc$risk_set_rows_units_11_99 +
        sample_qc$risk_set_rows_units_100_plus
    ) ||
    any(fit_qc$convergence != 0L) ||
    any(!is.finite(window_metrics$value[
      window_metrics$preferred_direction != "descriptive"
    ])) ||
    any(model_ranking$selection_cells != expected_selection_cells) ||
    nrow(model_choice) != 1L ||
    n_distinct(interim_fit_parameters$model_role) != 2L ||
    any(
      interim_fit_parameters |>
        filter(term == "shock_sigma") |>
        count(model_role) |>
        pull(n) != 1L
    ) ||
    any(validation_summary$validation_windows != nrow(time_windows))
) {
  stop("Time-adaptation audit outputs failed QC.")
}

write_csv_if_changed(
  window_metrics,
  "../output/no_notch_time_adaptation_window_metrics.csv"
)
write_parquet_if_changed(
  out_of_time_predictions,
  "../output/no_notch_time_adaptation_out_of_time_predictions.parquet"
)
write_csv_if_changed(
  validation_summary,
  "../output/no_notch_time_adaptation_validation_summary.csv"
)
write_csv_if_changed(
  model_ranking,
  "../output/no_notch_time_adaptation_model_ranking.csv"
)
write_csv_if_changed(
  model_choice,
  "../output/no_notch_time_adaptation_model_choice.csv"
)
write_csv_if_changed(
  interim_fit_parameters,
  "../output/no_notch_time_adaptation_interim_fit_parameters.csv"
)
write_csv_if_changed(
  fit_qc,
  "../output/no_notch_time_adaptation_fit_qc.csv"
)
write_csv_if_changed(
  sample_qc,
  "../output/no_notch_time_adaptation_sample_qc.csv"
)
write_csv_if_changed(
  time_windows,
  "../output/no_notch_time_adaptation_windows.csv"
)

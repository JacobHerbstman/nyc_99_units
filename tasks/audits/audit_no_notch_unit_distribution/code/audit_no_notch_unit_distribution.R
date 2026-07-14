# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_unit_distribution/code")
# min_units <- 6L
# local_min_units <- 50L
# local_max_units <- 150L
# minimum_category_rows <- 30L
# bootstrap_reps <- 200L
# seed <- 20260710L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(mgcv)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop("Expected six arguments: minimum units, local minimum units, local maximum units, minimum category rows, bootstrap replications, and seed.")
}

min_units <- as.integer(args[1])
local_min_units <- as.integer(args[2])
local_max_units <- as.integer(args[3])
minimum_category_rows <- as.integer(args[4])
bootstrap_reps <- as.integer(args[5])
seed <- as.integer(args[6])

if (
  any(is.na(c(
    min_units, local_min_units, local_max_units, minimum_category_rows,
    bootstrap_reps, seed
  ))) ||
    min_units < 1L || local_min_units < min_units || local_max_units <= local_min_units ||
    minimum_category_rows < 2L || bootstrap_reps < 1L
) {
  stop("Audit arguments are not internally consistent.")
}

set.seed(seed)

thresholds <- c(80L, 90L, 99L, 100L, 110L, 125L, 150L)
histogram_units <- seq(local_min_units, local_max_units)
reference_window_name <- "train_2013_2020_test_2021_2022h1"

window_specs <- tribble(
  ~window, ~train_start, ~train_end, ~test_start, ~test_end, ~regime_note,
  "train_2010_2015_test_2016_2017", "2010-01-01", "2015-12-31", "2016-01-01", "2017-12-31", "early_pre_policy_validation",
  "train_2010_2017_test_2018_2020", "2010-01-01", "2017-12-31", "2018-01-01", "2020-12-31", "pre_deadline_validation",
  "train_2013_2017_test_2018_2020", "2013-01-01", "2017-12-31", "2018-01-01", "2020-12-31", "pre_deadline_validation",
  "train_2016_2018_test_2019_2020", "2016-01-01", "2018-12-31", "2019-01-01", "2020-12-31", "recent_pre_deadline_validation",
  "train_2010_2020_test_2021_2022h1", "2010-01-01", "2020-12-31", "2021-01-01", "2022-06-15", "pre_deadline_validation",
  "train_2013_2020_test_2021_2022h1", "2013-01-01", "2020-12-31", "2021-01-01", "2022-06-15", "pre_deadline_validation",
  "train_2016_2020_test_2021_2022h1", "2016-01-01", "2020-12-31", "2021-01-01", "2022-06-15", "pre_deadline_validation",
  "train_2018_2020_test_2021_2022h1", "2018-01-01", "2020-12-31", "2021-01-01", "2022-06-15", "recent_pre_deadline_validation",
  "train_2016_2021_test_2022h1", "2016-01-01", "2021-12-31", "2022-01-01", "2022-06-15", "short_pre_deadline_validation",
  "train_2018_2021_test_2022h1", "2018-01-01", "2021-12-31", "2022-01-01", "2022-06-15", "short_recent_pre_deadline_validation",
  "train_2013_2020_test_post_2022", "2013-01-01", "2020-12-31", "2022-06-16", "2023-12-31", "post_deadline_transport",
  "train_2016_2020_test_post_2022", "2016-01-01", "2020-12-31", "2022-06-16", "2023-12-31", "post_deadline_transport",
  "train_2018_2021_test_post_2022", "2018-01-01", "2021-12-31", "2022-06-16", "2023-12-31", "post_deadline_transport"
) |>
  mutate(
    train_start = as.Date(train_start),
    train_end = as.Date(train_end),
    test_start = as.Date(test_start),
    test_end = as.Date(test_end),
    reference_window = window == reference_window_name
  )

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

model_rows <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= min_units,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  mutate(
    units = as.integer(round(classa_prop)),
    log_units = log(units),
    log_lotarea = log(lotarea),
    log_allowed_res_area = if_else(allowed_res_area > 0, log(allowed_res_area), NA_real_),
    residual_res_share = if_else(
      allowed_res_area > 0 & !is.na(residual_res_area),
      pmin(pmax(residual_res_area / allowed_res_area, 0), 1),
      NA_real_
    ),
    log_assessland_per_allowed_res_area = if_else(
      assessland > 0 & allowed_res_area > 0,
      log(assessland / allowed_res_area),
      NA_real_
    ),
    has_existing_units = !is.na(unitsres) & unitsres > 0,
    log_existing_units = if_else(has_existing_units, log(unitsres), NA_real_),
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
    borough = hdb_borough_name,
    community_district = hdb_community_district,
    bootstrap_cluster = if_else(
      is.na(bbl),
      paste0("job_", job_number),
      paste0("bbl_", as.character(bbl))
    )
  ) |>
  select(
    job_number, date_filed, filing_year, bbl, bootstrap_cluster, address,
    units, log_units,
    log_lotarea, residfar, builtfar, log_allowed_res_area, residual_res_share,
    log_assessland_per_allowed_res_area, has_existing_units, log_existing_units,
    numbldgs, numfloors, borough, community_district, zone_detail, prior_site_use
  )

if (nrow(model_rows) == 0L || any(model_rows$units < min_units)) {
  stop("No-notch model sample is empty or violates the minimum-unit rule.")
}

numeric_features <- c(
  "log_lotarea", "residfar", "builtfar", "log_allowed_res_area",
  "residual_res_share", "log_assessland_per_allowed_res_area",
  "log_existing_units", "numbldgs", "numfloors"
)

categorical_features <- c("borough", "community_district", "zone_detail", "prior_site_use")

prepare_train_test <- function(train_data, test_data) {
  train_prepared <- train_data
  test_prepared <- test_data

  train_year_mean <- mean(train_prepared$filing_year)
  train_prepared$filing_year_centered <- train_prepared$filing_year - train_year_mean
  test_prepared$filing_year_centered <- test_prepared$filing_year - train_year_mean

  for (feature_name in numeric_features) {
    missing_name <- paste0(feature_name, "_missing")
    train_values <- train_prepared[[feature_name]]
    test_values <- test_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    test_prepared[[missing_name]] <- is.na(test_values)

    impute_value <- median(train_values, na.rm = TRUE)
    if (!is.finite(impute_value)) {
      impute_value <- 0
    }

    train_values[is.na(train_values)] <- impute_value
    test_values[is.na(test_values)] <- impute_value
    train_prepared[[feature_name]] <- train_values
    test_prepared[[feature_name]] <- test_values
  }

  for (feature_name in categorical_features) {
    train_values <- str_squish(as.character(train_prepared[[feature_name]]))
    test_values <- str_squish(as.character(test_prepared[[feature_name]]))
    train_values[is.na(train_values) | train_values == ""] <- "missing"
    test_values[is.na(test_values) | test_values == ""] <- "missing"
    train_counts <- table(train_values)
    keep_levels <- names(train_counts)[train_counts >= minimum_category_rows]

    if (length(keep_levels) == 0L) {
      keep_levels <- names(sort(train_counts, decreasing = TRUE))[1]
    }

    train_values[!(train_values %in% keep_levels)] <- "other_rare"
    factor_levels <- sort(unique(train_values))
    fallback_level <- if ("other_rare" %in% factor_levels) {
      "other_rare"
    } else {
      names(sort(train_counts, decreasing = TRUE))[1]
    }
    test_values[!(test_values %in% keep_levels)] <- fallback_level
    train_prepared[[feature_name]] <- factor(train_values, levels = factor_levels)
    test_prepared[[feature_name]] <- factor(test_values, levels = factor_levels)
  }

  list(train = train_prepared, test = test_prepared)
}

unconditional_formula <- log_units ~ 1

simple_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

enriched_formula <- log_units ~ log_allowed_res_area + residual_res_share +
  log_assessland_per_allowed_res_area + log_existing_units +
  has_existing_units + numbldgs + numfloors + filing_year_centered +
  log_allowed_res_area_missing + residual_res_share_missing +
  log_assessland_per_allowed_res_area_missing + log_existing_units_missing +
  numbldgs_missing + numfloors_missing + community_district + zone_detail +
  prior_site_use

gam_formula <- log_units ~
  s(log_allowed_res_area, k = 5) +
  s(residual_res_share, k = 5) +
  s(log_assessland_per_allowed_res_area, k = 5) +
  s(log_existing_units, k = 5) +
  s(numbldgs, k = 5) +
  s(numfloors, k = 5) +
  filing_year_centered +
  has_existing_units + log_allowed_res_area_missing +
  residual_res_share_missing + log_assessland_per_allowed_res_area_missing +
  log_existing_units_missing + numbldgs_missing + numfloors_missing +
  community_district + zone_detail + prior_site_use

negative_binomial_formula <- update(simple_formula, units ~ .)

lognormal_predictions <- function(mu, sigma, observed_units) {
  lower_boundary <- min_units - 0.5
  lower_probability <- pnorm((log(lower_boundary) - mu) / sigma)
  denominator <- pmax(1 - lower_probability, 1e-12)
  observed_low <- pmax(observed_units - 0.5, lower_boundary)
  observed_high <- observed_units + 0.5
  probability_mass <- (
    pnorm((log(observed_high) - mu) / sigma) -
      pnorm((log(observed_low) - mu) / sigma)
  ) / denominator
  probability_exactly_99 <- (
    pnorm((log(99.5) - mu) / sigma) -
      pnorm((log(98.5) - mu) / sigma)
  ) / denominator

  threshold_cdf <- sapply(thresholds, function(threshold) {
    (
      pnorm((log(threshold + 0.5) - mu) / sigma) - lower_probability
    ) / denominator
  })

  quantile_units <- sapply(c(0.025, 0.10, 0.25, 0.50, 0.75, 0.90, 0.975), function(probability) {
    untruncated_probability <- lower_probability + probability * denominator
    pmax(min_units, round(exp(mu + sigma * qnorm(untruncated_probability))))
  })

  list(
    pmf = pmax(probability_mass, 1e-12),
    pmf_99 = pmax(probability_exactly_99, 0),
    cdf = threshold_cdf,
    quantiles = quantile_units,
    predicted_log_units = log(pmax(quantile_units[, 4L], min_units))
  )
}

fit_student_t_shocks <- function(model_residuals) {
  residual_scale <- sd(model_residuals)

  objective <- function(parameters) {
    scale_parameter <- exp(parameters[1])
    degrees_freedom <- 2 + exp(parameters[2])
    -sum(
      dt(model_residuals / scale_parameter, df = degrees_freedom, log = TRUE) -
        log(scale_parameter)
    )
  }

  optimizer <- optim(
    par = c(log(residual_scale), log(6)),
    fn = objective,
    method = "L-BFGS-B",
    lower = c(log(residual_scale / 10), log(0.05)),
    upper = c(log(residual_scale * 10), log(198))
  )

  if (optimizer$convergence != 0L) {
    stop("Student-t shock optimization did not converge.")
  }

  list(
    scale = exp(optimizer$par[1]),
    degrees_freedom = 2 + exp(optimizer$par[2])
  )
}

log_student_t_predictions <- function(mu, scale, degrees_freedom, observed_units) {
  lower_boundary <- min_units - 0.5
  lower_probability <- pt(
    (log(lower_boundary) - mu) / scale,
    df = degrees_freedom
  )
  denominator <- pmax(1 - lower_probability, 1e-12)
  observed_low <- pmax(observed_units - 0.5, lower_boundary)
  observed_high <- observed_units + 0.5
  probability_mass <- (
    pt((log(observed_high) - mu) / scale, df = degrees_freedom) -
      pt((log(observed_low) - mu) / scale, df = degrees_freedom)
  ) / denominator
  probability_exactly_99 <- (
    pt((log(99.5) - mu) / scale, df = degrees_freedom) -
      pt((log(98.5) - mu) / scale, df = degrees_freedom)
  ) / denominator

  threshold_cdf <- sapply(thresholds, function(threshold) {
    (
      pt((log(threshold + 0.5) - mu) / scale, df = degrees_freedom) -
        lower_probability
    ) / denominator
  })

  quantile_units <- sapply(c(0.025, 0.10, 0.25, 0.50, 0.75, 0.90, 0.975), function(probability) {
    untruncated_probability <- lower_probability + probability * denominator
    pmax(
      min_units,
      round(exp(mu + scale * qt(untruncated_probability, df = degrees_freedom)))
    )
  })

  list(
    pmf = pmax(probability_mass, 1e-12),
    pmf_99 = pmax(probability_exactly_99, 0),
    cdf = threshold_cdf,
    quantiles = quantile_units,
    predicted_log_units = log(pmax(quantile_units[, 4L], min_units))
  )
}

negative_binomial_predictions <- function(mu, size, observed_units) {
  lower_probability <- pnbinom(min_units - 1L, size = size, mu = mu)
  denominator <- pmax(1 - lower_probability, 1e-12)
  probability_mass <- dnbinom(observed_units, size = size, mu = mu) / denominator
  probability_exactly_99 <- dnbinom(99L, size = size, mu = mu) / denominator

  threshold_cdf <- sapply(thresholds, function(threshold) {
    (
      pnbinom(threshold, size = size, mu = mu) - lower_probability
    ) / denominator
  })

  quantile_units <- sapply(c(0.025, 0.10, 0.25, 0.50, 0.75, 0.90, 0.975), function(probability) {
    untruncated_probability <- lower_probability + probability * denominator
    pmax(min_units, qnbinom(untruncated_probability, size = size, mu = mu))
  })

  list(
    pmf = pmax(probability_mass, 1e-12),
    pmf_99 = pmax(probability_exactly_99, 0),
    cdf = threshold_cdf,
    quantiles = quantile_units,
    predicted_log_units = log(pmax(quantile_units[, 4L], min_units))
  )
}

distribution_metrics <- function(evaluation_data, prediction, sample_name) {
  sample_rows <- if (sample_name == "all") {
    rep(TRUE, nrow(evaluation_data))
  } else {
    evaluation_data$units >= local_min_units & evaluation_data$units <= local_max_units
  }

  observed <- evaluation_data$units[sample_rows]
  pmf <- prediction$pmf[sample_rows]
  cdf <- prediction$cdf[sample_rows, , drop = FALSE]
  quantiles <- prediction$quantiles[sample_rows, , drop = FALSE]
  predicted_log_units <- prediction$predicted_log_units[sample_rows]
  probability_exactly_99 <- prediction$pmf_99[sample_rows]

  if (length(observed) == 0L) {
    return(tibble())
  }

  cdf_errors <- colMeans(cdf) - sapply(thresholds, function(threshold) mean(observed <= threshold))
  p_at_least_100 <- 1 - cdf[, which(thresholds == 99L)]

  tibble(
    sample = sample_name,
    rows = length(observed),
    metric = c(
      "mean_negative_log_score", "rmse_log_units", "mae_log_units",
      "brier_at_least_100", "cdf_rmse", "exact_99_expected_rows",
      "exact_99_observed_rows", "at_least_100_expected_rows",
      "at_least_100_observed_rows"
    ),
    value = c(
      -mean(log(pmf)),
      sqrt(mean((log(observed) - predicted_log_units)^2)),
      mean(abs(log(observed) - predicted_log_units)),
      mean((as.integer(observed >= 100L) - p_at_least_100)^2),
      sqrt(mean(cdf_errors^2)),
      sum(probability_exactly_99),
      sum(observed == 99L),
      sum(p_at_least_100),
      sum(observed >= 100L)
    )
  )
}

status_rows <- list()
summary_rows <- list()
cdf_rows <- list()
interval_rows <- list()
prediction_rows <- list()
histogram_rows <- list()
coefficient_rows <- list()
shock_rows <- list()

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  train_raw <- model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  test_raw <- model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

  if (nrow(train_raw) < 200L || nrow(test_raw) < 50L) {
    status_rows[[length(status_rows) + 1L]] <- window_spec |>
      transmute(
        window, model = NA_character_, train_rows = nrow(train_raw), test_rows = nrow(test_raw),
        status = "skipped_insufficient_rows", warning_messages = NA_character_
      )
    next
  }

  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test

  model_names <- c(
    "lognormal_unconditional", "lognormal_linear_simple",
    "lognormal_linear_enriched", "lognormal_gam_enriched",
    "log_student_t_linear_simple", "negative_binomial_simple"
  )

  for (model_name in model_names) {
    warning_messages <- character()
    model_fit <- NULL
    prediction <- NULL
    shock_distribution <- NA_character_
    shock_scale <- NA_real_
    shock_degrees_freedom <- NA_real_
    negative_binomial_size <- NA_real_

    model_fit <- tryCatch(
      withCallingHandlers(
        {
          if (model_name == "lognormal_unconditional") {
            lm(unconditional_formula, data = train_data)
          } else if (model_name %in% c(
            "lognormal_linear_simple", "log_student_t_linear_simple"
          )) {
            lm(simple_formula, data = train_data)
          } else if (model_name == "lognormal_linear_enriched") {
            lm(enriched_formula, data = train_data)
          } else if (model_name == "lognormal_gam_enriched") {
            gam(gam_formula, data = train_data, method = "REML")
          } else {
            MASS::glm.nb(
              negative_binomial_formula,
              data = train_data,
              control = glm.control(maxit = 100)
            )
          }
        },
        warning = function(warning_condition) {
          warning_messages <<- c(warning_messages, conditionMessage(warning_condition))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(error_condition) {
        warning_messages <<- c(warning_messages, conditionMessage(error_condition))
        NULL
      }
    )

    if (!is.null(model_fit)) {
      prediction <- tryCatch(
        {
          if (model_name == "negative_binomial_simple") {
            predicted_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
            shock_distribution <- "negative_binomial"
            negative_binomial_size <- model_fit$theta
            negative_binomial_predictions(predicted_mean, model_fit$theta, test_data$units)
          } else if (model_name == "log_student_t_linear_simple") {
            predicted_log_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
            shock_fit <- fit_student_t_shocks(residuals(model_fit))
            shock_distribution <- "student_t_log_units"
            shock_scale <- shock_fit$scale
            shock_degrees_freedom <- shock_fit$degrees_freedom
            log_student_t_predictions(
              predicted_log_mean,
              shock_fit$scale,
              shock_fit$degrees_freedom,
              test_data$units
            )
          } else {
            predicted_log_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
            residual_sigma <- sqrt(mean(residuals(model_fit)^2))
            shock_distribution <- "normal_log_units"
            shock_scale <- residual_sigma
            lognormal_predictions(predicted_log_mean, residual_sigma, test_data$units)
          }
        },
        error = function(error_condition) {
          warning_messages <<- c(warning_messages, conditionMessage(error_condition))
          NULL
        }
      )
    }

    status_rows[[length(status_rows) + 1L]] <- tibble(
      window = window_spec$window,
      model = model_name,
      train_rows = nrow(train_data),
      test_rows = nrow(test_data),
      status = if_else(is.null(prediction), "failed", "fit"),
      warning_messages = if_else(
        length(warning_messages) == 0L,
        NA_character_,
        paste(unique(warning_messages), collapse = " | ")
      )
    )

    if (is.null(prediction)) {
      next
    }

    shock_rows[[length(shock_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      model = model_name,
      train_rows = nrow(train_data),
      shock_distribution,
      unit_distribution_shock_scale = shock_scale,
      unit_distribution_shock_degrees_freedom = shock_degrees_freedom,
      negative_binomial_size
    )

    for (sample_name in c("all", "local")) {
      summary_rows[[length(summary_rows) + 1L]] <- distribution_metrics(
        test_data,
        prediction,
        sample_name
      ) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = model_name,
          .before = sample
        )
    }

    for (threshold_index in seq_along(thresholds)) {
      for (sample_name in c("all", "local")) {
        sample_rows <- if (sample_name == "all") {
          rep(TRUE, nrow(test_data))
        } else {
          test_data$units >= local_min_units & test_data$units <= local_max_units
        }

        cdf_rows[[length(cdf_rows) + 1L]] <- tibble(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = model_name,
          sample = sample_name,
          threshold = thresholds[threshold_index],
          rows = sum(sample_rows),
          predicted_share_at_or_below = mean(prediction$cdf[sample_rows, threshold_index]),
          observed_share_at_or_below = mean(test_data$units[sample_rows] <= thresholds[threshold_index]),
          calibration_error = predicted_share_at_or_below - observed_share_at_or_below
        )
      }
    }

    for (interval_index in seq_along(c(0.50, 0.80, 0.95))) {
      interval_level <- c(0.50, 0.80, 0.95)[interval_index]
      quantile_columns <- list(c(3L, 5L), c(2L, 6L), c(1L, 7L))[[interval_index]]

      interval_rows[[length(interval_rows) + 1L]] <- tibble(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        model = model_name,
        interval_level,
        rows = nrow(test_data),
        coverage = mean(
          test_data$units >= prediction$quantiles[, quantile_columns[1]] &
            test_data$units <= prediction$quantiles[, quantile_columns[2]]
        ),
        mean_width = mean(
          prediction$quantiles[, quantile_columns[2]] -
            prediction$quantiles[, quantile_columns[1]]
        )
      )
    }

    prediction_rows[[length(prediction_rows) + 1L]] <- test_data |>
      transmute(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        model = model_name,
        job_number,
        date_filed,
        units,
        predicted_median_units = prediction$quantiles[, 4L],
        predicted_p10_units = prediction$quantiles[, 2L],
        predicted_p90_units = prediction$quantiles[, 6L],
        probability_at_least_100 = 1 - prediction$cdf[, which(thresholds == 99L)],
        probability_exactly_99 = prediction$pmf_99,
        probability_observed_units = prediction$pmf
      )

    if (isTRUE(window_spec$reference_window)) {
      histogram_rows[[length(histogram_rows) + 1L]] <- bind_rows(lapply(histogram_units, function(unit_value) {
        if (model_name == "negative_binomial_simple") {
          predicted_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
          lower_probability <- pnbinom(min_units - 1L, size = model_fit$theta, mu = predicted_mean)
          expected_rows <- sum(
            dnbinom(unit_value, size = model_fit$theta, mu = predicted_mean) /
              pmax(1 - lower_probability, 1e-12)
          )
        } else if (model_name == "log_student_t_linear_simple") {
          predicted_log_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
          shock_fit <- fit_student_t_shocks(residuals(model_fit))
          lower_probability <- pt(
            (log(min_units - 0.5) - predicted_log_mean) / shock_fit$scale,
            df = shock_fit$degrees_freedom
          )
          expected_rows <- sum((
            pt(
              (log(unit_value + 0.5) - predicted_log_mean) / shock_fit$scale,
              df = shock_fit$degrees_freedom
            ) -
              pt(
                (log(unit_value - 0.5) - predicted_log_mean) / shock_fit$scale,
                df = shock_fit$degrees_freedom
              )
          ) / pmax(1 - lower_probability, 1e-12))
        } else {
          predicted_log_mean <- as.numeric(predict(model_fit, newdata = test_data, type = "response"))
          residual_sigma <- sqrt(mean(residuals(model_fit)^2))
          lower_probability <- pnorm((log(min_units - 0.5) - predicted_log_mean) / residual_sigma)
          expected_rows <- sum((
            pnorm((log(unit_value + 0.5) - predicted_log_mean) / residual_sigma) -
              pnorm((log(unit_value - 0.5) - predicted_log_mean) / residual_sigma)
          ) / pmax(1 - lower_probability, 1e-12))
        }

        tibble(
          window = window_spec$window,
          model = model_name,
          units = unit_value,
          expected_rows,
          observed_rows = sum(test_data$units == unit_value)
        )
      }))

      if (model_name != "lognormal_gam_enriched") {
        coefficient_table <- as.data.frame(coef(summary(model_fit)))
        coefficient_table$term <- rownames(coefficient_table)
        rownames(coefficient_table) <- NULL
        names(coefficient_table) <- normalize_names(names(coefficient_table))
        statistic_column <- if ("t_value" %in% names(coefficient_table)) "t_value" else "z_value"
        p_value_column <- if ("pr_t" %in% names(coefficient_table)) "pr_t" else "pr_z"

        coefficient_rows[[length(coefficient_rows) + 1L]] <- coefficient_table |>
          transmute(
            window = window_spec$window,
            model = model_name,
            term,
            estimate,
            std_error,
            statistic = .data[[statistic_column]],
            p_value = .data[[p_value_column]]
          )
      }
    }
  }
}

model_status <- bind_rows(status_rows)
model_window_summary <- bind_rows(summary_rows)
cdf_calibration <- bind_rows(cdf_rows)
interval_calibration <- bind_rows(interval_rows)
heldout_predictions <- bind_rows(prediction_rows)
histogram_validation <- bind_rows(histogram_rows)
reference_coefficients <- bind_rows(coefficient_rows)
shock_parameters <- bind_rows(shock_rows)

if (nrow(model_window_summary) == 0L || nrow(heldout_predictions) == 0L) {
  stop("No no-notch distribution model completed successfully.")
}

validation_windows <- window_specs |>
  filter(regime_note != "post_deadline_transport") |>
  pull(window)

complete_validation_models <- model_status |>
  filter(window %in% validation_windows, status == "fit", !is.na(model)) |>
  count(model, name = "successful_validation_windows") |>
  filter(successful_validation_windows == length(validation_windows)) |>
  pull(model)

model_ranking <- model_window_summary |>
  filter(
    model %in% complete_validation_models,
    sample == "local",
    regime_note != "post_deadline_transport",
    metric %in% c("mean_negative_log_score", "brier_at_least_100", "cdf_rmse")
  ) |>
  group_by(model, metric) |>
  summarise(
    windows = n_distinct(window),
    mean_value = mean(value),
    worst_value = max(value),
    .groups = "drop"
  ) |>
  group_by(metric) |>
  mutate(metric_rank = rank(mean_value, ties.method = "average")) |>
  ungroup() |>
  group_by(model) |>
  summarise(
    metrics = n(),
    validated_windows = min(windows),
    mean_metric_rank = mean(metric_rank),
    worst_metric_rank = max(metric_rank),
    .groups = "drop"
  ) |>
  arrange(mean_metric_rank, worst_metric_rank, model)

model_comparison <- model_window_summary |>
  filter(
    model %in% complete_validation_models,
    regime_note != "post_deadline_transport",
    metric %in% c(
      "mean_negative_log_score", "brier_at_least_100", "cdf_rmse",
      "rmse_log_units", "mae_log_units"
    )
  ) |>
  group_by(sample, model, metric) |>
  summarise(
    validated_windows = n_distinct(window),
    mean_value = mean(value),
    median_value = median(value),
    best_value = min(value),
    worst_value = max(value),
    .groups = "drop"
  ) |>
  arrange(sample, metric, mean_value, model)

bootstrap_model <- "lognormal_linear_simple"
bootstrap_metric_rows <- list()
bootstrap_status_rows <- list()

set.seed(seed)

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  train_raw <- model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  test_raw <- model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)
  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test
  cluster_rows <- split(seq_len(nrow(train_data)), train_data$bootstrap_cluster)

  for (bootstrap_rep in seq_len(bootstrap_reps)) {
    sampled_clusters <- sample(
      names(cluster_rows),
      size = length(cluster_rows),
      replace = TRUE
    )
    bootstrap_indices <- unlist(cluster_rows[sampled_clusters], use.names = FALSE)
    warning_messages <- character()

    bootstrap_result <- tryCatch(
      withCallingHandlers(
        {
          model_fit <- lm(simple_formula, data = train_data[bootstrap_indices, ])
          predicted_log_mean <- as.numeric(
            predict(model_fit, newdata = test_data, type = "response")
          )
          residual_sigma <- sqrt(mean(residuals(model_fit)^2))

          if (any(!is.finite(predicted_log_mean)) || !is.finite(residual_sigma)) {
            stop("Bootstrap fit produced non-finite predictions or residual scale.")
          }

          list(
            prediction = lognormal_predictions(
              predicted_log_mean,
              residual_sigma,
              test_data$units
            ),
            shock_scale = residual_sigma
          )
        },
        warning = function(warning_condition) {
          warning_messages <<- c(warning_messages, conditionMessage(warning_condition))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(error_condition) {
        warning_messages <<- c(warning_messages, conditionMessage(error_condition))
        NULL
      }
    )

    bootstrap_status_rows[[length(bootstrap_status_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      model = bootstrap_model,
      bootstrap_rep,
      sampled_clusters = length(sampled_clusters),
      sampled_rows = length(bootstrap_indices),
      status = if_else(is.null(bootstrap_result), "failed", "fit"),
      warning_messages = if_else(
        length(warning_messages) == 0L,
        NA_character_,
        paste(unique(warning_messages), collapse = " | ")
      )
    )

    if (is.null(bootstrap_result)) {
      next
    }

    bootstrap_metric_rows[[length(bootstrap_metric_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      model = bootstrap_model,
      bootstrap_rep,
      sample = "training",
      rows = nrow(train_data),
      metric = "unit_distribution_shock_scale",
      value = bootstrap_result$shock_scale
    )

    for (sample_name in c("all", "local")) {
      bootstrap_metric_rows[[length(bootstrap_metric_rows) + 1L]] <-
        distribution_metrics(test_data, bootstrap_result$prediction, sample_name) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = bootstrap_model,
          bootstrap_rep,
          .before = sample
        )
    }
  }
}

bootstrap_metrics <- bind_rows(bootstrap_metric_rows)
bootstrap_status <- bind_rows(bootstrap_status_rows)
bootstrap_summary <- bootstrap_metrics |>
  group_by(window, regime_note, model, sample, rows, metric) |>
  summarise(
    successful_reps = n(),
    bootstrap_mean = mean(value),
    bootstrap_sd = sd(value),
    bootstrap_p025 = quantile(value, 0.025),
    bootstrap_p975 = quantile(value, 0.975),
    .groups = "drop"
  )

sample_qc <- tibble(
  metric = c(
    "source_rows", "eligible_model_rows", "unique_jobs", "unique_bbls",
    "first_filing_date", "last_filing_date", "minimum_units",
    "median_units", "mean_units", "maximum_units", "local_rows",
    "exact_99_rows", "missing_allowed_res_area", "missing_assessed_land"
  ),
  value = c(
    nrow(panel), nrow(model_rows), n_distinct(model_rows$job_number),
    n_distinct(model_rows$bbl), as.character(min(model_rows$date_filed)),
    as.character(max(model_rows$date_filed)), min(model_rows$units),
    median(model_rows$units), mean(model_rows$units), max(model_rows$units),
    sum(model_rows$units >= local_min_units & model_rows$units <= local_max_units),
    sum(model_rows$units == 99L), sum(is.na(model_rows$log_allowed_res_area)),
    sum(is.na(model_rows$log_assessland_per_allowed_res_area))
  )
)

histogram_plot <- histogram_validation |>
  mutate(
    model_label = recode(
      model,
      lognormal_unconditional = "Unconditional lognormal",
      lognormal_linear_simple = "Simple linear + normal shocks",
      lognormal_linear_enriched = "Enriched linear + normal shocks",
      lognormal_gam_enriched = "Enriched GAM + normal shocks",
      log_student_t_linear_simple = "Simple linear + Student-t shocks",
      negative_binomial_simple = "Simple negative binomial"
    )
  ) |>
  select(window, model_label, units, expected_rows, observed_rows) |>
  tidyr::pivot_longer(
    cols = c(expected_rows, observed_rows),
    names_to = "series",
    values_to = "rows"
  ) |>
  mutate(
    series = recode(
      series,
      expected_rows = "Model expected",
      observed_rows = "Observed"
    )
  ) |>
  ggplot(aes(x = units, y = rows, color = series)) +
  geom_line(linewidth = 0.55) +
  geom_vline(xintercept = 99.5, linetype = "dashed", color = "#0072B2") +
  facet_wrap(~ model_label, ncol = 2, scales = "free_y") +
  scale_color_manual(values = c("Model expected" = "#D55E00", "Observed" = "#555555")) +
  labs(
    title = "Held-out unit distributions near the 100-unit threshold",
    subtitle = "Training: 2013-2020; test: 2021 through June 15, 2022",
    x = "Proposed permanent Class A units",
    y = "Held-out buildings",
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

write_csv_if_changed(model_window_summary, "../output/no_notch_model_window_summary.csv")
write_csv_if_changed(sample_qc, "../output/no_notch_sample_qc.csv")
write_csv_if_changed(window_specs, "../output/no_notch_time_windows.csv")
write_csv_if_changed(model_status, "../output/no_notch_model_status.csv")
write_csv_if_changed(cdf_calibration, "../output/no_notch_cdf_calibration.csv")
write_csv_if_changed(interval_calibration, "../output/no_notch_interval_calibration.csv")
write_csv_if_changed(model_ranking, "../output/no_notch_model_ranking.csv")
write_csv_if_changed(model_comparison, "../output/no_notch_model_comparison.csv")
write_csv_if_changed(shock_parameters, "../output/no_notch_shock_parameters.csv")
write_csv_if_changed(reference_coefficients, "../output/no_notch_reference_coefficients.csv")
write_parquet_if_changed(heldout_predictions, "../output/no_notch_heldout_predictions.parquet")
write_csv_if_changed(bootstrap_metrics, "../output/no_notch_bootstrap_metrics.csv")
write_csv_if_changed(bootstrap_summary, "../output/no_notch_bootstrap_summary.csv")
write_csv_if_changed(bootstrap_status, "../output/no_notch_bootstrap_status.csv")
ggsave(
  "../output/no_notch_histogram_validation.pdf",
  histogram_plot,
  width = 10,
  height = 7
)

cat("Wrote no-notch unit-distribution audit outputs.\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_outcome_scale/code")
# min_units <- 6L
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

if (length(args) != 4L) {
  stop("Expected four arguments: minimum units, local minimum units, local maximum units, and minimum category rows.")
}

min_units <- as.integer(args[1])
local_min_units <- as.integer(args[2])
local_max_units <- as.integer(args[3])
minimum_category_rows <- as.integer(args[4])

if (
  any(is.na(c(min_units, local_min_units, local_max_units, minimum_category_rows))) ||
    min_units < 1L || local_min_units < min_units ||
    local_max_units <= local_min_units || minimum_category_rows < 2L
) {
  stop("Audit arguments are not internally consistent.")
}

reference_window <- "train_2013_2020_test_2021_2022h1"

prepare_train_test <- function(train_data, test_data) {
  train_prepared <- train_data
  test_prepared <- test_data

  train_year_mean <- mean(train_prepared$filing_year)
  train_prepared$filing_year_centered <- train_prepared$filing_year - train_year_mean
  test_prepared$filing_year_centered <- test_prepared$filing_year - train_year_mean

  for (feature_name in c("log_lotarea", "residfar", "builtfar")) {
    missing_name <- paste0(feature_name, "_missing")
    train_values <- train_prepared[[feature_name]]
    test_values <- test_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    test_prepared[[missing_name]] <- is.na(test_values)

    impute_value <- median(train_values, na.rm = TRUE)
    if (!is.finite(impute_value)) {
      stop("Training data have no finite values for ", feature_name, ".")
    }

    train_values[is.na(train_values)] <- impute_value
    test_values[is.na(test_values)] <- impute_value
    train_prepared[[feature_name]] <- train_values
    test_prepared[[feature_name]] <- test_values
  }

  for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
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

  list(
    train = train_prepared,
    test = test_prepared,
    training_year_mean = train_year_mean
  )
}

point_prediction_metrics <- function(
  evaluation_data,
  predicted_mean_units,
  predicted_median_units,
  sample_name
) {
  sample_rows <- if (sample_name == "all") {
    rep(TRUE, nrow(evaluation_data))
  } else {
    evaluation_data$units >= local_min_units & evaluation_data$units <= local_max_units
  }

  observed <- evaluation_data$units[sample_rows]
  predicted_mean <- predicted_mean_units[sample_rows]
  predicted_median <- predicted_median_units[sample_rows]

  if (length(observed) == 0L) {
    return(tibble())
  }

  observed_at_least_100 <- observed >= 100L
  predicted_at_least_100 <- predicted_median >= 100L
  prediction_ranks <- rank(predicted_median, ties.method = "average")
  positive_rows <- sum(observed_at_least_100)
  negative_rows <- length(observed_at_least_100) - positive_rows
  auc_at_least_100 <- (
    sum(prediction_ranks[observed_at_least_100]) -
      positive_rows * (positive_rows + 1) / 2
  ) / (positive_rows * negative_rows)

  tibble(
    sample = sample_name,
    rows = length(observed),
    metric = c(
      "rmse_units_using_predicted_mean",
      "mae_units_using_predicted_median",
      "mean_unit_error_using_predicted_mean",
      "predicted_to_actual_total_units_ratio",
      "rmse_log_units_using_predicted_median",
      "mae_log_units_using_predicted_median",
      "share_within_factor_two_using_predicted_median",
      "auc_at_least_100_using_predicted_median",
      "classification_accuracy_at_100_using_predicted_median",
      "sensitivity_at_100_using_predicted_median",
      "specificity_at_100_using_predicted_median"
    ),
    value = c(
      sqrt(mean((observed - predicted_mean)^2)),
      mean(abs(observed - predicted_median)),
      mean(predicted_mean - observed),
      sum(predicted_mean) / sum(observed),
      sqrt(mean((log(observed) - log(predicted_median))^2)),
      mean(abs(log(observed) - log(predicted_median))),
      mean(abs(log(observed) - log(predicted_median)) <= log(2)),
      auc_at_least_100,
      mean(predicted_at_least_100 == observed_at_least_100),
      mean(predicted_at_least_100[observed_at_least_100]),
      mean(!predicted_at_least_100[!observed_at_least_100])
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
  mutate(
    train_start = as.Date(train_start),
    train_end = as.Date(train_end),
    test_start = as.Date(test_start),
    test_end = as.Date(test_end)
  )

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
  select(
    job_number, date_filed, filing_year, units, log_units,
    log_lotarea, residfar, builtfar, borough, zone_detail, prior_site_use
  )

if (nrow(model_rows) == 0L || any(model_rows$units < min_units)) {
  stop("Outcome-scale audit sample is empty or violates the minimum-unit rule.")
}

log_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
level_formula <- update(log_formula, units ~ .)

metric_rows <- list()
qc_rows <- list()
reference_predictions <- NULL
reference_summary_lines <- NULL

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  train_raw <- model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  test_raw <- model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

  if (nrow(train_raw) < 200L || nrow(test_raw) < 50L) {
    stop("A declared window has too few observations: ", window_spec$window)
  }

  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test

  log_fit <- lm(log_formula, data = train_data)
  level_fit <- lm(level_formula, data = train_data)

  predicted_log_units <- as.numeric(predict(log_fit, newdata = test_data))
  predicted_raw_units <- as.numeric(predict(level_fit, newdata = test_data))
  log_sigma <- sqrt(mean(residuals(log_fit)^2))
  level_sigma <- sqrt(mean(residuals(level_fit)^2))
  normal_smearing_factor <- exp(log_sigma^2 / 2)
  empirical_smearing_factor <- mean(exp(residuals(log_fit)))

  log_predicted_median_units <- pmax(
    min_units,
    floor(exp(predicted_log_units) + 0.5)
  )
  log_predicted_mean_units_normal <- pmax(
    min_units,
    exp(predicted_log_units) * normal_smearing_factor
  )
  log_predicted_mean_units_empirical <- pmax(
    min_units,
    exp(predicted_log_units) * empirical_smearing_factor
  )
  level_predicted_mean_units <- pmax(min_units, predicted_raw_units)
  level_predicted_median_units <- pmax(
    min_units,
    floor(predicted_raw_units + 0.5)
  )

  predictions <- list(
    log_units_ols_normal_retransformation = list(
      mean = log_predicted_mean_units_normal,
      median = log_predicted_median_units
    ),
    log_units_ols_empirical_smearing = list(
      mean = log_predicted_mean_units_empirical,
      median = log_predicted_median_units
    ),
    raw_units_ols_clipped = list(
      mean = level_predicted_mean_units,
      median = level_predicted_median_units
    )
  )

  for (model_name in names(predictions)) {
    for (sample_name in c("all", "local")) {
      metric_rows[[length(metric_rows) + 1L]] <- point_prediction_metrics(
        test_data,
        predictions[[model_name]]$mean,
        predictions[[model_name]]$median,
        sample_name
      ) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = model_name,
          .before = sample
        )
    }
  }

  qc_rows[[length(qc_rows) + 1L]] <- tibble(
    window = window_spec$window,
    regime_note = window_spec$regime_note,
    train_rows = nrow(train_data),
    test_rows = nrow(test_data),
    log_residual_rms = log_sigma,
    raw_unit_residual_rms = level_sigma,
    normal_smearing_factor = normal_smearing_factor,
    empirical_smearing_factor = empirical_smearing_factor,
    nonpositive_raw_ols_predictions = sum(predicted_raw_units <= 0),
    raw_ols_predictions_below_six = sum(predicted_raw_units < min_units),
    raw_ols_unclipped_rmse_units = sqrt(
      mean((test_data$units - predicted_raw_units)^2)
    ),
    raw_ols_unclipped_mean_unit_error = mean(
      predicted_raw_units - test_data$units
    ),
    raw_ols_unclipped_total_units_ratio = sum(predicted_raw_units) /
      sum(test_data$units)
  )

  if (window_spec$window == reference_window) {
    reference_predictions <- test_data |>
      transmute(
        job_number,
        date_filed,
        units,
        log_ols_predicted_median_units = log_predicted_median_units,
        log_ols_predicted_mean_units_normal = log_predicted_mean_units_normal,
        log_ols_predicted_mean_units_empirical = log_predicted_mean_units_empirical,
        raw_ols_unclipped_predicted_units = predicted_raw_units,
        raw_ols_clipped_predicted_mean_units = level_predicted_mean_units,
        raw_ols_clipped_predicted_median_units = level_predicted_median_units
      )

    reference_log_fit <- log_fit
    reference_level_fit <- level_fit
    reference_log_fit$call$formula <- log_formula
    reference_level_fit$call$formula <- level_formula
    reference_summary_lines <- c(
      "No-notch outcome-scale audit: reference-window fits",
      "",
      paste0("Training dates: ", window_spec$train_start, " through ", window_spec$train_end),
      paste0("Held-out dates: ", window_spec$test_start, " through ", window_spec$test_end),
      paste0("Training observations: ", nrow(train_data)),
      paste0("Held-out observations: ", nrow(test_data)),
      paste0("Training mean filing year: ", format(prepared$training_year_mean, digits = 12)),
      paste0("Log-unit residual RMS: ", format(log_sigma, digits = 12)),
      paste0("Raw-unit residual RMS: ", format(level_sigma, digits = 12)),
      paste0("Normal log retransformation factor: ", format(normal_smearing_factor, digits = 12)),
      paste0("Empirical log smearing factor: ", format(empirical_smearing_factor, digits = 12)),
      paste0(
        "Raw-unit unconditioned predictions below six in holdout: ",
        sum(predicted_raw_units < min_units)
      ),
      "",
      "Exact R output: log-units OLS",
      "",
      capture.output(print(summary(reference_log_fit))),
      "",
      "Exact R output: raw-units OLS",
      "",
      capture.output(print(summary(reference_level_fit)))
    )
  }
}

window_metrics <- bind_rows(metric_rows) |>
  arrange(window, sample, metric, model)

validation_summary <- window_metrics |>
  filter(regime_note != "post_deadline_transport") |>
  group_by(model, sample, metric) |>
  summarise(
    validation_windows = n_distinct(window),
    mean_value = mean(value),
    median_value = median(value),
    minimum_value = min(value),
    maximum_value = max(value),
    .groups = "drop"
  ) |>
  arrange(sample, metric, mean_value)

prediction_qc <- bind_rows(qc_rows) |>
  arrange(window)

reference_test_rows <- window_specs |>
  filter(window == .env$reference_window) |>
  transmute(
    rows = sum(
      model_rows$date_filed >= test_start & model_rows$date_filed <= test_end
    )
  ) |>
  pull(rows)

if (
  length(reference_test_rows) != 1L ||
    nrow(reference_predictions) != reference_test_rows ||
    any(!is.finite(window_metrics$value)) ||
    any(reference_predictions$log_ols_predicted_median_units < min_units) ||
    any(reference_predictions$raw_ols_clipped_predicted_mean_units < min_units)
) {
  stop(
    "Outcome-scale output failed QC: reference rows expected=",
    paste(reference_test_rows, collapse = ","),
    ", observed=", nrow(reference_predictions),
    ", nonfinite metrics=", sum(!is.finite(window_metrics$value)),
    ", log predictions below support=",
    sum(reference_predictions$log_ols_predicted_median_units < min_units),
    ", raw predictions below support=",
    sum(reference_predictions$raw_ols_clipped_predicted_mean_units < min_units),
    "."
  )
}

write_csv_if_changed(
  window_metrics,
  "../output/no_notch_outcome_scale_window_metrics.csv"
)
write_csv_if_changed(
  validation_summary,
  "../output/no_notch_outcome_scale_validation_summary.csv"
)
write_csv_if_changed(
  prediction_qc,
  "../output/no_notch_outcome_scale_prediction_qc.csv"
)
write_parquet_if_changed(
  reference_predictions,
  "../output/no_notch_outcome_scale_reference_predictions.parquet"
)
writeLines(
  reference_summary_lines,
  "../output/no_notch_outcome_scale_reference_summary.txt"
)

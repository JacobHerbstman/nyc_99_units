# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_threshold_hurdle/code")
# min_units <- 6L
# minimum_category_rows <- 30L
# cutoffs_text <- "11,20,30,40"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected three arguments: minimum units, minimum category rows, and comma-separated hurdle cutoffs.")
}

min_units <- as.integer(args[1])
minimum_category_rows <- as.integer(args[2])
cutoffs_text <- args[3]
cutoffs <- as.integer(str_split(cutoffs_text, ",", simplify = TRUE))

if (
  any(is.na(c(min_units, minimum_category_rows, cutoffs))) ||
    min_units < 1L || minimum_category_rows < 2L ||
    any(cutoffs <= min_units) || any(cutoffs >= 100L) ||
    anyDuplicated(cutoffs) > 0L
) {
  stop("Audit arguments are not internally consistent.")
}

reference_window <- "train_2013_2020_test_2021_2022h1"
model_names <- c(
  "simple_lognormal",
  "direct_logit_100",
  paste0("sequential_logit_cutoff_", cutoffs)
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

fit_logit <- function(model_formula, training_data, prediction_data) {
  warning_messages <- character()
  model_fit <- tryCatch(
    withCallingHandlers(
      glm(model_formula, data = training_data, family = binomial()),
      warning = function(warning_condition) {
        warning_messages <<- c(
          warning_messages,
          conditionMessage(warning_condition)
        )
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error_condition) {
      warning_messages <<- c(
        warning_messages,
        conditionMessage(error_condition)
      )
      NULL
    }
  )

  probability <- if (is.null(model_fit)) {
    rep(NA_real_, nrow(prediction_data))
  } else {
    tryCatch(
      as.numeric(predict(model_fit, newdata = prediction_data, type = "response")),
      error = function(error_condition) {
        warning_messages <<- c(
          warning_messages,
          conditionMessage(error_condition)
        )
        rep(NA_real_, nrow(prediction_data))
      }
    )
  }

  successful_fit <- !is.null(model_fit) && isTRUE(model_fit$converged) &&
    length(probability) == nrow(prediction_data) &&
    all(is.finite(probability)) &&
    all(probability >= 0 & probability <= 1)

  list(
    fit = model_fit,
    probability = probability,
    successful_fit = successful_fit,
    warning_messages = unique(warning_messages)
  )
}

summarize_binary_predictions <- function(observed, probability) {
  probability_for_log_score <- pmin(pmax(probability, 1e-12), 1 - 1e-12)
  positive_rows <- sum(observed == 1L)
  negative_rows <- sum(observed == 0L)
  prediction_ranks <- rank(probability, ties.method = "average")
  auc <- if (positive_rows > 0L && negative_rows > 0L) {
    (
      sum(prediction_ranks[observed == 1L]) -
        positive_rows * (positive_rows + 1) / 2
    ) / (positive_rows * negative_rows)
  } else {
    NA_real_
  }

  expected_rows <- sum(probability)
  observed_rows <- sum(observed)

  tibble(
    brier_score = mean((observed - probability)^2),
    binary_negative_log_score = -mean(
      observed * log(probability_for_log_score) +
        (1 - observed) * log(1 - probability_for_log_score)
    ),
    auc_at_least_100 = auc,
    expected_at_least_100_rows = expected_rows,
    observed_at_least_100_rows = observed_rows,
    absolute_at_least_100_count_error = abs(expected_rows - observed_rows)
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
    at_least_100 = as.integer(units >= 100L),
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
    job_number, date_filed, filing_year, units, log_units, at_least_100,
    log_lotarea, residfar, builtfar, borough, zone_detail, prior_site_use
  )

if (nrow(model_rows) == 0L || any(model_rows$units < min_units)) {
  stop("Threshold-hurdle sample is empty or violates the minimum-unit rule.")
}

lognormal_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
logit_formula <- update(lognormal_formula, at_least_100 ~ .)
gate_formula <- update(lognormal_formula, above_cutoff ~ .)

metric_rows <- list()
status_rows <- list()
prediction_rows <- list()

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  train_raw <- model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  test_raw <- model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

  if (
    nrow(train_raw) < 200L || nrow(test_raw) < 50L ||
      anyDuplicated(train_raw$job_number) > 0L ||
      anyDuplicated(test_raw$job_number) > 0L
  ) {
    stop("A declared window has too few or duplicate observations: ", window_spec$window)
  }

  prepared <- prepare_train_test(train_raw, test_raw)
  train_data <- prepared$train
  test_data <- prepared$test
  observed <- test_data$at_least_100

  baseline_warnings <- character()
  baseline_fit <- tryCatch(
    withCallingHandlers(
      lm(lognormal_formula, data = train_data),
      warning = function(warning_condition) {
        baseline_warnings <<- c(
          baseline_warnings,
          conditionMessage(warning_condition)
        )
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error_condition) {
      baseline_warnings <<- c(
        baseline_warnings,
        conditionMessage(error_condition)
      )
      NULL
    }
  )

  baseline_probability <- rep(NA_real_, nrow(test_data))
  if (!is.null(baseline_fit)) {
    predicted_log_units <- as.numeric(predict(baseline_fit, newdata = test_data))
    residual_sigma <- sqrt(mean(residuals(baseline_fit)^2))
    probability_above_sample_floor <- pnorm(
      (log(min_units - 0.5) - predicted_log_units) / residual_sigma,
      lower.tail = FALSE
    )
    probability_above_99 <- pnorm(
      (log(99.5) - predicted_log_units) / residual_sigma,
      lower.tail = FALSE
    )
    baseline_probability <-
      probability_above_99 / probability_above_sample_floor
  }

  baseline_success <- !is.null(baseline_fit) &&
    all(is.finite(baseline_probability)) &&
    all(baseline_probability >= 0 & baseline_probability <= 1)
  status_rows[[length(status_rows) + 1L]] <- tibble(
    window = window_spec$window,
    regime_note = window_spec$regime_note,
    model = "simple_lognormal",
    cutoff = NA_integer_,
    train_rows = nrow(train_data),
    conditional_train_rows = nrow(train_data),
    train_at_least_100_rows = sum(train_data$at_least_100),
    status = if_else(baseline_success, "fit", "failed"),
    warning_messages = if_else(
      length(baseline_warnings) == 0L,
      NA_character_,
      paste(unique(baseline_warnings), collapse = " | ")
    )
  )

  if (baseline_success) {
    metric_rows[[length(metric_rows) + 1L]] <-
      summarize_binary_predictions(observed, baseline_probability) |>
      mutate(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        model = "simple_lognormal",
        cutoff = NA_integer_,
        train_rows = nrow(train_data),
        test_rows = nrow(test_data),
        .before = brier_score
      )
    prediction_rows[[length(prediction_rows) + 1L]] <- test_data |>
      transmute(
        window = window_spec$window,
        job_number,
        date_filed,
        units,
        observed_at_least_100 = at_least_100,
        model = "simple_lognormal",
        probability_at_least_100 = baseline_probability
      )
  }

  direct_logit <- fit_logit(logit_formula, train_data, test_data)
  status_rows[[length(status_rows) + 1L]] <- tibble(
    window = window_spec$window,
    regime_note = window_spec$regime_note,
    model = "direct_logit_100",
    cutoff = NA_integer_,
    train_rows = nrow(train_data),
    conditional_train_rows = nrow(train_data),
    train_at_least_100_rows = sum(train_data$at_least_100),
    status = if_else(direct_logit$successful_fit, "fit", "failed"),
    warning_messages = if_else(
      length(direct_logit$warning_messages) == 0L,
      NA_character_,
      paste(direct_logit$warning_messages, collapse = " | ")
    )
  )

  if (direct_logit$successful_fit) {
    metric_rows[[length(metric_rows) + 1L]] <-
      summarize_binary_predictions(observed, direct_logit$probability) |>
      mutate(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        model = "direct_logit_100",
        cutoff = NA_integer_,
        train_rows = nrow(train_data),
        test_rows = nrow(test_data),
        .before = brier_score
      )
    prediction_rows[[length(prediction_rows) + 1L]] <- test_data |>
      transmute(
        window = window_spec$window,
        job_number,
        date_filed,
        units,
        observed_at_least_100 = at_least_100,
        model = "direct_logit_100",
        probability_at_least_100 = direct_logit$probability
      )
  }

  for (cutoff in cutoffs) {
    train_data$above_cutoff <- as.integer(train_data$units >= cutoff)
    gate_logit <- fit_logit(gate_formula, train_data, test_data)
    conditional_train <- train_data |>
      filter(units >= cutoff)
    conditional_logit <- fit_logit(
      logit_formula,
      conditional_train,
      test_data
    )
    sequential_probability <-
      gate_logit$probability * conditional_logit$probability
    sequential_success <- gate_logit$successful_fit &&
      conditional_logit$successful_fit &&
      all(is.finite(sequential_probability)) &&
      all(sequential_probability >= 0 & sequential_probability <= 1)
    sequential_model <- paste0("sequential_logit_cutoff_", cutoff)
    sequential_warnings <- unique(c(
      gate_logit$warning_messages,
      conditional_logit$warning_messages
    ))

    status_rows[[length(status_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      model = sequential_model,
      cutoff,
      train_rows = nrow(train_data),
      conditional_train_rows = nrow(conditional_train),
      train_at_least_100_rows = sum(conditional_train$at_least_100),
      status = if_else(sequential_success, "fit", "failed"),
      warning_messages = if_else(
        length(sequential_warnings) == 0L,
        NA_character_,
        paste(sequential_warnings, collapse = " | ")
      )
    )

    if (sequential_success) {
      metric_rows[[length(metric_rows) + 1L]] <-
        summarize_binary_predictions(observed, sequential_probability) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          model = sequential_model,
          cutoff,
          train_rows = nrow(train_data),
          test_rows = nrow(test_data),
          .before = brier_score
        )
      prediction_rows[[length(prediction_rows) + 1L]] <- test_data |>
        transmute(
          window = window_spec$window,
          job_number,
          date_filed,
          units,
          observed_at_least_100 = at_least_100,
          model = sequential_model,
          probability_at_least_100 = sequential_probability
        )
    }
  }
}

window_metrics <- bind_rows(metric_rows) |>
  arrange(window, match(model, model_names))

model_status <- bind_rows(status_rows) |>
  arrange(window, match(model, model_names))

all_predictions <- bind_rows(prediction_rows)

validation_metrics <- window_metrics |>
  filter(regime_note != "post_deadline_transport")

baseline_validation_metrics <- validation_metrics |>
  filter(model == "simple_lognormal") |>
  select(
    window,
    baseline_brier_score = brier_score,
    baseline_binary_negative_log_score = binary_negative_log_score,
    baseline_absolute_count_error = absolute_at_least_100_count_error
  )

validation_summary <- validation_metrics |>
  left_join(
    baseline_validation_metrics,
    by = "window",
    relationship = "many-to-one"
  ) |>
  group_by(model, cutoff) |>
  summarise(
    validation_windows = n_distinct(window),
    complete_validation = validation_windows == 10L,
    mean_brier_score = mean(brier_score),
    mean_binary_negative_log_score = mean(binary_negative_log_score),
    mean_auc_at_least_100 = mean(auc_at_least_100),
    mean_expected_at_least_100_rows = mean(expected_at_least_100_rows),
    mean_observed_at_least_100_rows = mean(observed_at_least_100_rows),
    mean_absolute_at_least_100_count_error = mean(
      absolute_at_least_100_count_error
    ),
    windows_lower_brier_than_lognormal = sum(
      brier_score < baseline_brier_score
    ),
    windows_lower_log_score_than_lognormal = sum(
      binary_negative_log_score < baseline_binary_negative_log_score
    ),
    windows_lower_absolute_count_error_than_lognormal = sum(
      absolute_at_least_100_count_error < baseline_absolute_count_error
    ),
    .groups = "drop"
  ) |>
  arrange(match(model, model_names))

reference_predictions <- all_predictions |>
  filter(window == reference_window) |>
  select(
    job_number, date_filed, units, observed_at_least_100,
    model, probability_at_least_100
  ) |>
  pivot_wider(
    names_from = model,
    values_from = probability_at_least_100,
    names_prefix = "probability_"
  ) |>
  arrange(date_filed, job_number)

probability_columns <- names(reference_predictions)[
  str_starts(names(reference_predictions), "probability_")
]
observed_counts_per_window <- window_metrics |>
  group_by(window) |>
  summarise(
    distinct_observed_counts = n_distinct(observed_at_least_100_rows),
    .groups = "drop"
  )

if (
  nrow(window_specs) != 13L ||
    nrow(window_metrics) != nrow(window_specs) * length(model_names) ||
    nrow(model_status) != nrow(window_specs) * length(model_names) ||
    any(model_status$status != "fit") ||
    nrow(validation_summary) != length(model_names) ||
    any(!validation_summary$complete_validation) ||
    any(observed_counts_per_window$distinct_observed_counts != 1L) ||
    nrow(reference_predictions) != 800L ||
    length(probability_columns) != length(model_names) ||
    any(!is.finite(as.matrix(reference_predictions[probability_columns]))) ||
    any(as.matrix(reference_predictions[probability_columns]) < 0) ||
    any(as.matrix(reference_predictions[probability_columns]) > 1)
) {
  stop("Threshold-hurdle outputs failed completeness or probability QC.")
}

write_csv_if_changed(
  validation_summary,
  "../output/no_notch_threshold_hurdle_validation_summary.csv"
)
write_csv_if_changed(
  window_metrics,
  "../output/no_notch_threshold_hurdle_window_metrics.csv"
)
write_csv_if_changed(
  model_status,
  "../output/no_notch_threshold_hurdle_status.csv"
)
write_parquet_if_changed(
  reference_predictions,
  "../output/no_notch_threshold_hurdle_reference_predictions.parquet"
)

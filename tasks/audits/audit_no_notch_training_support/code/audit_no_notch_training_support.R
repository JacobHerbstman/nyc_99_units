# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_training_support/code")
# training_floors_text <- "6,10,11,20,30,40,50"
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
    universe_min_units < 1L ||
    local_min_units < universe_min_units ||
    local_max_units <= local_min_units ||
    minimum_category_rows < 2L
) {
  stop("Training-support audit arguments are not internally consistent.")
}

reference_window <- "train_2013_2020_test_2021_2022h1"
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

  imputation_values <- numeric()

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
    imputation_values[feature_name] <- imputation_value
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

  list(
    train = train_prepared,
    test = test_prepared,
    training_year_mean = training_year_mean,
    imputation_values = imputation_values
  )
}

calculate_metrics <- function(evaluation_data) {
  observed_units <- evaluation_data$units
  observed_log_units <- evaluation_data$log_units
  predicted_log_units <- evaluation_data$predicted_log_units
  predicted_median_units <- evaluation_data$predicted_median_units
  predicted_mean_units <- evaluation_data$predicted_mean_units

  if (length(observed_units) == 0L) {
    stop("A declared evaluation sample is empty.")
  }

  observed_at_least_100 <- observed_units >= 100L
  predicted_at_least_100 <- predicted_median_units >= 100
  positive_rows <- sum(observed_at_least_100)
  negative_rows <- length(observed_at_least_100) - positive_rows

  if (positive_rows == 0L || negative_rows == 0L) {
    auc_at_least_100 <- NA_real_
  } else {
    prediction_ranks <- rank(predicted_log_units, ties.method = "average")
    auc_at_least_100 <- (
      sum(prediction_ranks[observed_at_least_100]) -
        positive_rows * (positive_rows + 1) / 2
    ) / (positive_rows * negative_rows)
  }

  sensitivity_at_100 <- if (positive_rows == 0L) {
    NA_real_
  } else {
    mean(predicted_at_least_100[observed_at_least_100])
  }
  specificity_at_100 <- if (negative_rows == 0L) {
    NA_real_
  } else {
    mean(!predicted_at_least_100[!observed_at_least_100])
  }
  total_units_ratio <- sum(predicted_mean_units) / sum(observed_units)

  tibble(
    metric = c(
      "rmse_log_units",
      "mae_log_units",
      "rmse_units_using_normal_predicted_mean",
      "mae_units_using_predicted_median",
      "predicted_to_actual_total_units_ratio",
      "absolute_log_total_units_ratio",
      "share_within_factor_two",
      "auc_at_least_100",
      "classification_accuracy_at_100",
      "sensitivity_at_100",
      "specificity_at_100"
    ),
    preferred_direction = c(
      rep("lower", 4L),
      "target_one",
      "lower",
      rep("higher", 5L)
    ),
    value = c(
      sqrt(mean((observed_log_units - predicted_log_units)^2)),
      mean(abs(observed_log_units - predicted_log_units)),
      sqrt(mean((observed_units - predicted_mean_units)^2)),
      mean(abs(observed_units - predicted_median_units)),
      total_units_ratio,
      abs(log(total_units_ratio)),
      mean(abs(observed_log_units - predicted_log_units) <= log(2)),
      auc_at_least_100,
      mean(predicted_at_least_100 == observed_at_least_100),
      sensitivity_at_100,
      specificity_at_100
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
    lotarea, log_lotarea, residfar, builtfar, borough, zone_detail,
    prior_site_use
  )

if (
  nrow(model_rows) == 0L ||
    any(model_rows$units < universe_min_units) ||
    anyDuplicated(model_rows$observation_id)
) {
  stop("Training-support model universe failed construction QC.")
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

metric_rows <- list()
count_rows <- list()
reference_predictions <- NULL
reference_summary_lines <- c(
  "No-notch training-support audit: reference-window fits",
  "",
  paste0("Training floors: ", paste(training_floors, collapse = ", ")),
  paste0("Universe minimum units: ", universe_min_units),
  paste0(
    "Outcome-selected local diagnostic: actual units ",
    local_min_units, " through ", local_max_units
  ),
  paste0(
    "Fixed X-selected risk set: floor-", universe_min_units,
    " predicted median units ", local_min_units, " through ", local_max_units
  ),
  paste0("Minimum training rows per retained category: ", minimum_category_rows),
  "",
  paste(
    "Higher training floors select on the no-policy outcome. Their residual",
    "RMS values describe selected samples and are not directly comparable",
    "structural shock estimates."
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

  predictions_by_floor <- list()
  metadata_by_floor <- list()

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
    fit <- lm(model_formula, data = train_data)
    predicted_log_units <- as.numeric(predict(fit, newdata = test_data))
    residual_rms <- sqrt(mean(residuals(fit)^2))

    predictions_by_floor[[as.character(training_floor)]] <- test_data |>
      transmute(
        observation_id,
        job_number,
        date_filed,
        units,
        log_units,
        predicted_log_units = .env$predicted_log_units,
        predicted_median_units = exp(.env$predicted_log_units),
        predicted_mean_units = exp(
          .env$predicted_log_units + .env$residual_rms^2 / 2
        ),
        training_residual_rms = .env$residual_rms
      )

    metadata_by_floor[[as.character(training_floor)]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      training_floor = training_floor,
      train_rows = nrow(train_data),
      test_rows_all_universe = nrow(test_data),
      training_mean_units = mean(train_data$units),
      training_median_units = median(train_data$units),
      training_residual_rms = residual_rms,
      training_adjusted_r_squared = summary(fit)$adj.r.squared,
      training_mean_filing_year = prepared$training_year_mean
    )

    if (window_spec$window == reference_window) {
      printed_fit <- fit
      printed_fit$call$formula <- model_formula
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
          "Training mean filing year: ",
          format(prepared$training_year_mean, digits = 12)
        ),
        paste0(
          "Training median ResidFAR imputation value: ",
          format(prepared$imputation_values["residfar"], digits = 12)
        ),
        paste0(
          "Training median BuiltFAR imputation value: ",
          format(prepared$imputation_values["builtfar"], digits = 12)
        ),
        paste0(
          "Training residual RMS: ", format(residual_rms, digits = 12)
        ),
        paste0(
          "Normal retransformation factor: ",
          format(exp(residual_rms^2 / 2), digits = 12)
        ),
        paste0(
          "Borough factor levels: ",
          paste(levels(train_data$borough), collapse = ", ")
        ),
        paste0(
          "Zone factor levels: ",
          paste(levels(train_data$zone_detail), collapse = ", ")
        ),
        paste0(
          "Prior-use factor levels: ",
          paste(levels(train_data$prior_site_use), collapse = ", ")
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

  baseline_predictions <- predictions_by_floor[[
    as.character(universe_min_units)
  ]]
  expected_ids <- baseline_predictions$observation_id

  for (training_floor in training_floors) {
    if (!identical(
      predictions_by_floor[[as.character(training_floor)]]$observation_id,
      expected_ids
    )) {
      stop("Prediction rows differ across training floors within a window.")
    }
  }

  actual_local_rows <-
    baseline_predictions$units >= local_min_units &
    baseline_predictions$units <= local_max_units
  x_selected_rows <-
    baseline_predictions$predicted_median_units >= local_min_units &
    baseline_predictions$predicted_median_units <= local_max_units

  if (!any(actual_local_rows) || !any(x_selected_rows)) {
    stop("A declared local evaluation sample is empty: ", window_spec$window)
  }

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

  for (training_floor in training_floors) {
    floor_predictions <- predictions_by_floor[[as.character(training_floor)]]

    for (sample_name in names(sample_rows)) {
      evaluation_rows <- sample_rows[[sample_name]]
      metric_rows[[length(metric_rows) + 1L]] <- calculate_metrics(
        floor_predictions[evaluation_rows, ]
      ) |>
        mutate(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          training_floor = training_floor,
          sample = sample_name,
          evaluation_rows = sum(evaluation_rows),
          .before = metric
        )
    }

    count_rows[[length(count_rows) + 1L]] <- metadata_by_floor[[
      as.character(training_floor)
    ]] |>
      mutate(
        test_rows_actual_local_outcome_selected = sum(actual_local_rows),
        test_rows_x_selected_fixed_risk_set = sum(x_selected_rows)
      )
  }

  if (window_spec$window == reference_window) {
    reference_predictions <- bind_rows(
      lapply(training_floors, function(training_floor) {
        predictions_by_floor[[as.character(training_floor)]] |>
          mutate(training_floor = training_floor, .after = date_filed)
      })
    ) |>
      mutate(
        actual_local_outcome_selected =
          units >= local_min_units & units <= local_max_units,
        x_selected_fixed_risk_set = observation_id %in%
          baseline_predictions$observation_id[x_selected_rows]
      ) |>
      select(
        observation_id, job_number, date_filed, training_floor,
        units, log_units, predicted_log_units, predicted_median_units,
        predicted_mean_units, training_residual_rms,
        actual_local_outcome_selected,
        x_selected_fixed_risk_set
      ) |>
      arrange(training_floor, observation_id)
  }
}

window_metrics <- bind_rows(metric_rows) |>
  arrange(sample, metric, window, training_floor)

window_counts <- bind_rows(count_rows) |>
  arrange(window, training_floor)

winning_rows <- window_metrics |>
  mutate(
    selection_score = case_when(
      preferred_direction == "lower" ~ value,
      preferred_direction == "higher" ~ -value,
      preferred_direction == "target_one" ~ abs(log(value)),
      TRUE ~ NA_real_
    ),
    selection_score = if_else(
      is.finite(selection_score),
      selection_score,
      Inf
    )
  ) |>
  arrange(window, sample, metric, selection_score, training_floor) |>
  group_by(window, sample, metric) |>
  slice_head(n = 1L) |>
  ungroup() |>
  count(training_floor, sample, metric, name = "validation_window_wins")

validation_summary <- window_metrics |>
  group_by(training_floor, sample, metric, preferred_direction) |>
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
    by = c("training_floor", "sample", "metric"),
    relationship = "one-to-one"
  ) |>
  mutate(validation_window_wins = coalesce(validation_window_wins, 0L)) |>
  arrange(sample, metric, training_floor)

reference_dates <- window_specs |>
  filter(window == .env$reference_window)

reference_training_data <- model_rows |>
  filter(
    date_filed >= reference_dates$train_start,
    date_filed <= reference_dates$train_end
  )

reference_sample_composition <- reference_training_data |>
  mutate(
    unit_group = case_when(
      units <= 9L ~ "6-9",
      units == 10L ~ "10",
      units <= 19L ~ "11-19",
      units <= 29L ~ "20-29",
      units <= 39L ~ "30-39",
      units <= 49L ~ "40-49",
      TRUE ~ "50+"
    ),
    unit_group_order = match(
      unit_group,
      c("6-9", "10", "11-19", "20-29", "30-39", "40-49", "50+")
    )
  ) |>
  group_by(unit_group, unit_group_order) |>
  summarise(
    rows = n(),
    minimum_units = min(units),
    maximum_units = max(units),
    mean_units = mean(units),
    median_units = median(units),
    median_lotarea = median(lotarea),
    median_residfar = median(residfar, na.rm = TRUE),
    median_builtfar = median(builtfar, na.rm = TRUE),
    share_brooklyn = mean(coalesce(borough == "Brooklyn", FALSE)),
    share_queens = mean(coalesce(borough == "Queens", FALSE)),
    share_r1_through_r6 = mean(zone_detail %in% c("R1_R5", "R6")),
    share_r8_through_r10 = mean(zone_detail == "R8_R10"),
    .groups = "drop"
  ) |>
  mutate(share_of_reference_training_rows = rows / sum(rows)) |>
  arrange(unit_group_order) |>
  select(
    unit_group,
    rows,
    share_of_reference_training_rows,
    everything(),
    -unit_group_order
  )

reference_training_rows <- window_counts |>
  filter(
    window == reference_window,
    training_floor == universe_min_units
  ) |>
  pull(train_rows)

core_metric_rows <- window_metrics$metric %in% c(
  "rmse_log_units",
  "mae_log_units",
  "rmse_units_using_normal_predicted_mean",
  "mae_units_using_predicted_median",
  "predicted_to_actual_total_units_ratio",
  "absolute_log_total_units_ratio",
  "share_within_factor_two"
)

expected_reference_prediction_rows <- window_counts |>
  filter(window == reference_window) |>
  summarise(rows = first(test_rows_all_universe) * n()) |>
  pull(rows)

if (
  nrow(window_metrics) !=
    nrow(window_specs) * length(training_floors) * 3L * 11L ||
    nrow(window_counts) != nrow(window_specs) * length(training_floors) ||
    any(!is.finite(window_metrics$value[core_metric_rows])) ||
    any(window_counts$train_rows < 200L) ||
    nrow(reference_predictions) != expected_reference_prediction_rows ||
    anyDuplicated(reference_predictions[c("observation_id", "training_floor")]) ||
    sum(reference_sample_composition$rows) != reference_training_rows ||
    any(validation_summary$validation_windows != nrow(window_specs))
) {
  stop("Training-support audit outputs failed QC.")
}

write_csv_if_changed(
  window_metrics,
  "../output/no_notch_training_support_window_metrics.csv"
)
write_csv_if_changed(
  validation_summary,
  "../output/no_notch_training_support_validation_summary.csv"
)
write_csv_if_changed(
  window_counts,
  "../output/no_notch_training_support_window_counts.csv"
)
write_csv_if_changed(
  reference_sample_composition,
  "../output/no_notch_training_support_reference_sample_composition.csv"
)
write_parquet_if_changed(
  reference_predictions,
  "../output/no_notch_training_support_reference_predictions.parquet"
)
writeLines(
  reference_summary_lines,
  "../output/no_notch_training_support_reference_fit_summary.txt"
)

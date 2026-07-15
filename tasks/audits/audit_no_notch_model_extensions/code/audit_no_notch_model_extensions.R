# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_model_extensions/code")
# min_units <- 6L
# local_min_units <- 50L
# local_max_units <- 150L
# minimum_category_rows <- 30L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
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

thresholds <- c(80L, 90L, 99L, 100L, 110L, 125L, 150L)
reference_window <- "train_2013_2020_test_2021_2022h1"

normalize_address <- function(x) {
  x_clean <- str_to_upper(str_squish(as.character(x)))
  x_clean[x_clean %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  x_clean <- str_replace_all(
    x_clean,
    c(
      "\\bAVENUE\\b" = "AVE", "\\bSTREET\\b" = "ST",
      "\\bROAD\\b" = "RD", "\\bBOULEVARD\\b" = "BLVD",
      "\\bPLACE\\b" = "PL", "\\bDRIVE\\b" = "DR",
      "\\bLANE\\b" = "LN", "\\bPARKWAY\\b" = "PKWY",
      "\\bHIGHWAY\\b" = "HWY", "\\bTERRACE\\b" = "TER",
      "\\bCOURT\\b" = "CT"
    )
  )
  str_squish(str_replace_all(x_clean, "[^A-Z0-9]", " "))
}

aggregate_provisional_site_year <- function(data) {
  data |>
    arrange(date_filed, job_number) |>
    mutate(
      provisional_site_key = if_else(
        is.na(pluto_feature_bbl),
        paste0("job_", job_number),
        paste0("bbl_", pluto_feature_bbl)
      )
    ) |>
    group_by(provisional_site_key, filing_year) |>
    summarise(
      observation_id = paste0(first(provisional_site_key), "_", first(filing_year)),
      job_number = first(job_number),
      date_filed = min(date_filed),
      pluto_feature_bbl = first(pluto_feature_bbl),
      units = sum(units),
      log_units = log(units),
      component_rows = n(),
      future_appbbl_recovery_components = sum(future_appbbl_recovery_used),
      component_pluto_versions = n_distinct(
        paste(pluto_source_id_used, pluto_version_used, sep = "::")
      ),
      component_lotarea_values = n_distinct(lotarea),
      component_nonmissing_bins = sum(!is.na(bin) & bin != ""),
      component_distinct_bins = n_distinct(bin[!is.na(bin) & bin != ""]),
      component_duplicate_bin_rows = pmax(
        component_nonmissing_bins - component_distinct_bins,
        0L
      ),
      component_job_status_values = n_distinct(job_status),
      across(
        c(
          log_lotarea, residfar, builtfar, log_broad_zoning_capacity,
          log_lotfront, log_lotdepth, broad_zoning_far, lotarea, borough,
          zone_detail, prior_site_use, address_alignment, ownership_group
        ),
        first
      ),
      .groups = "drop"
    )
}

numeric_features <- c(
  "log_lotarea", "residfar", "builtfar", "log_broad_zoning_capacity",
  "log_lotfront", "log_lotdepth"
)

categorical_features <- c(
  "borough", "zone_detail", "prior_site_use", "address_alignment",
  "ownership_group"
)

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

  conditional_median_probability <- lower_probability + 0.5 * denominator
  predicted_median_units <- pmax(
    min_units,
    round(exp(mu + sigma * qnorm(conditional_median_probability)))
  )

  list(
    pmf = pmax(probability_mass, 1e-12),
    pmf_99 = pmax(probability_exactly_99, 0),
    cdf = threshold_cdf,
    predicted_median_units = predicted_median_units
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
  predicted_log_units <- log(prediction$predicted_median_units[sample_rows])
  probability_exactly_99 <- prediction$pmf_99[sample_rows]

  if (length(observed) == 0L) {
    return(tibble())
  }

  cdf_errors <- colMeans(cdf) - sapply(
    thresholds,
    function(threshold) mean(observed <= threshold)
  )
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

required_panel_columns <- c(
  "job_number", "job_status", "date_filed", "filing_year", "classa_prop",
  "classa_prop_integer", "primary_leakage_safe_sample", "pluto_feature_bbl",
  "pluto_source_id_used", "pluto_version_used", "appbbl_recovery_used",
  "appbbl_future_appdate_used_for_linkage",
  "bin", "address", "street_name", "ownership", "pluto_address", "hdb_borough_name", "zonedist1", "landuse",
  "unitsres", "lotarea", "residfar", "commfar", "facilfar", "maxallwfar",
  "builtfar", "lotfront", "lotdepth"
)
missing_panel_columns <- setdiff(required_panel_columns, names(panel))

if (length(missing_panel_columns) > 0L) {
  stop("Training panel is missing required columns: ", paste(missing_panel_columns, collapse = ", "))
}

project_rows <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop > 0,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  mutate(
    units = as.integer(round(classa_prop)),
    log_units = log(units),
    log_lotarea = log(lotarea),
    log_lotfront = if_else(lotfront > 0, log(lotfront), NA_real_),
    log_lotdepth = if_else(lotdepth > 0, log(lotdepth), NA_real_),
    hdb_address_clean = normalize_address(address),
    pluto_address_clean = normalize_address(pluto_address),
    hdb_street_clean = normalize_address(street_name),
    pluto_street_clean = normalize_address(
      str_remove(str_squish(as.character(pluto_address)), "^[^ ]+\\s+")
    ),
    address_alignment = case_when(
      hdb_address_clean == pluto_address_clean ~ "exact_address",
      is.na(hdb_address_clean) | is.na(pluto_address_clean) |
        is.na(hdb_street_clean) | is.na(pluto_street_clean) ~ "missing_address",
      hdb_street_clean == pluto_street_clean ~ "same_street_other_address",
      TRUE ~ "different_street"
    ),
    available_far_fields = rowSums(!is.na(pick(residfar, commfar, facilfar, maxallwfar))),
    broad_zoning_far = pmax(
      coalesce(residfar, 0),
      coalesce(commfar, 0),
      coalesce(facilfar, 0),
      coalesce(maxallwfar, 0)
    ),
    broad_zoning_far = if_else(
      available_far_fields > 0 & broad_zoning_far > 0,
      broad_zoning_far,
      NA_real_
    ),
    broad_zoning_capacity = lotarea * broad_zoning_far,
    log_broad_zoning_capacity = if_else(
      broad_zoning_capacity > 0,
      log(broad_zoning_capacity),
      NA_real_
    ),
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
    ownership_clean = str_to_upper(str_squish(as.character(ownership))),
    ownership_group = case_when(
      str_detect(ownership_clean, "PRIVATE FOR-PROFIT: CORPORATION") ~ "private_for_profit_corporation",
      str_detect(ownership_clean, "PRIVATE FOR-PROFIT: PARTNERSHIP") ~ "private_for_profit_partnership",
      str_detect(ownership_clean, "PRIVATE FOR-PROFIT: INDIVIDUAL") ~ "private_for_profit_individual",
      str_detect(ownership_clean, "PRIVATE NON-PROFIT") ~ "private_nonprofit",
      str_detect(ownership_clean, "GOVERNMENT") ~ "government",
      is.na(ownership_clean) | ownership_clean == "" ~ "missing_ownership",
      TRUE ~ "other_ownership"
    ),
    private_for_profit = str_detect(ownership_group, "^private_for_profit"),
    borough = hdb_borough_name,
    observation_id = paste0("job_", job_number),
    component_rows = 1L,
    bin = na_if(str_squish(as.character(bin)), ""),
    job_status = na_if(str_squish(as.character(job_status)), ""),
    future_appbbl_recovery_used = appbbl_recovery_used &
      appbbl_future_appdate_used_for_linkage,
    component_pluto_versions = 1L,
    component_lotarea_values = 1L,
    component_nonmissing_bins = as.integer(!is.na(bin)),
    component_distinct_bins = as.integer(!is.na(bin)),
    component_duplicate_bin_rows = 0L,
    component_job_status_values = as.integer(!is.na(job_status)),
    future_appbbl_recovery_components = as.integer(future_appbbl_recovery_used)
  )

feature_bbl_counts <- project_rows |>
  filter(!is.na(pluto_feature_bbl)) |>
  count(pluto_feature_bbl, name = "all_period_feature_bbl_rows")

project_rows <- project_rows |>
  left_join(feature_bbl_counts, by = "pluto_feature_bbl", relationship = "many-to-one") |>
  mutate(
    all_period_feature_bbl_rows = coalesce(all_period_feature_bbl_rows, 1L),
    all_period_singleton = all_period_feature_bbl_rows == 1L
  ) |>
  select(
    observation_id, job_number, job_status, bin, date_filed, filing_year, pluto_feature_bbl,
    pluto_source_id_used, pluto_version_used,
    units, log_units, component_rows, all_period_singleton,
    future_appbbl_recovery_used, future_appbbl_recovery_components,
    component_pluto_versions, component_lotarea_values,
    component_nonmissing_bins, component_distinct_bins,
    component_duplicate_bin_rows, component_job_status_values,
    log_lotarea, residfar, builtfar, log_broad_zoning_capacity,
    log_lotfront, log_lotdepth, broad_zoning_far, lotarea, borough,
    zone_detail, prior_site_use, address_alignment, ownership_group,
    private_for_profit
  )

baseline_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

broad_capacity_formula <- update(
  baseline_formula,
  . ~ . + log_broad_zoning_capacity
)

ownership_formula <- update(
  broad_capacity_formula,
  . ~ . + ownership_group
)

lot_geometry_formula <- update(
  ownership_formula,
  . ~ . + log_lotfront + log_lotdepth
)

capacity_site_use_interaction_formula <- update(
  broad_capacity_formula,
  . ~ . + prior_site_use:log_broad_zoning_capacity
)

address_capacity_interaction_formula <- update(
  broad_capacity_formula,
  . ~ . + address_alignment + address_alignment:log_lotarea +
    address_alignment:residfar
)

lot_spline_formula <- update(
  baseline_formula,
  . ~ . - log_lotarea + splines::ns(log_lotarea, df = 3)
)

address_formula <- update(
  baseline_formula,
  . ~ . + address_alignment
)

model_formulas <- list(
  baseline_simple = baseline_formula,
  broad_capacity = broad_capacity_formula,
  capacity_ownership = ownership_formula,
  capacity_ownership_geometry = lot_geometry_formula,
  capacity_site_use_interactions = capacity_site_use_interaction_formula,
  lot_spline = lot_spline_formula,
  address_alignment_diagnostic = address_formula,
  address_capacity_interactions_diagnostic = address_capacity_interaction_formula
)

model_roles <- c(
  baseline_simple = "structural_candidate",
  broad_capacity = "structural_candidate",
  capacity_ownership = "structural_candidate",
  capacity_ownership_geometry = "structural_candidate",
  capacity_site_use_interactions = "structural_candidate",
  lot_spline = "structural_candidate",
  address_alignment_diagnostic = "diagnostic_only",
  address_capacity_interactions_diagnostic = "diagnostic_only"
)

sample_definitions <- c(
  "building_job_retrospective_crosswalk",
  "building_job_no_future_appbbl_recovery",
  "building_job_private_for_profit",
  "all_period_singleton_job_diagnostic",
  "provisional_feature_bbl_year_retrospective_crosswalk",
  "provisional_feature_bbl_year_no_future_appbbl_recovery"
)

building_model_rows <- project_rows |>
  filter(units >= min_units)

status_rows <- list()
metric_rows <- list()
prediction_rows <- list()
design_qc_rows <- list()
reference_model_summary_lines <- NULL
reference_model_coefficients <- tibble()

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]
  building_train <- building_model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  building_test <- building_model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)
  project_train <- project_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)
  project_test <- project_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

  for (sample_definition in sample_definitions) {
    train_duplicate_bin_site_years_excluded <- 0L
    test_duplicate_bin_site_years_excluded <- 0L

    if (sample_definition == "building_job_retrospective_crosswalk") {
      train_raw <- building_train
      test_raw <- building_test
    } else if (sample_definition == "building_job_no_future_appbbl_recovery") {
      train_raw <- building_train |>
        filter(!future_appbbl_recovery_used)
      test_raw <- building_test |>
        filter(!future_appbbl_recovery_used)
    } else if (sample_definition == "building_job_private_for_profit") {
      train_raw <- building_train |>
        filter(private_for_profit)
      test_raw <- building_test |>
        filter(private_for_profit)
    } else if (sample_definition == "all_period_singleton_job_diagnostic") {
      train_raw <- building_train |>
        filter(all_period_singleton)
      test_raw <- building_test |>
        filter(all_period_singleton)
    } else if (sample_definition == "provisional_feature_bbl_year_retrospective_crosswalk") {
      train_sites <- aggregate_provisional_site_year(project_train)
      test_sites <- aggregate_provisional_site_year(project_test)
      train_duplicate_bin_site_years_excluded <- sum(train_sites$component_duplicate_bin_rows > 0L)
      test_duplicate_bin_site_years_excluded <- sum(test_sites$component_duplicate_bin_rows > 0L)
      train_raw <- train_sites |>
        filter(units >= min_units, component_duplicate_bin_rows == 0L)
      test_raw <- test_sites |>
        filter(units >= min_units, component_duplicate_bin_rows == 0L)
    } else {
      train_sites <- project_train |>
        filter(!future_appbbl_recovery_used) |>
        aggregate_provisional_site_year()
      test_sites <- project_test |>
        filter(!future_appbbl_recovery_used) |>
        aggregate_provisional_site_year()
      train_duplicate_bin_site_years_excluded <- sum(train_sites$component_duplicate_bin_rows > 0L)
      test_duplicate_bin_site_years_excluded <- sum(test_sites$component_duplicate_bin_rows > 0L)
      train_raw <- train_sites |>
        filter(units >= min_units, component_duplicate_bin_rows == 0L)
      test_raw <- test_sites |>
        filter(units >= min_units, component_duplicate_bin_rows == 0L)
    }

    design_qc_rows[[length(design_qc_rows) + 1L]] <- tibble(
      window = window_spec$window,
      regime_note = window_spec$regime_note,
      sample_definition,
      train_observations = nrow(train_raw),
      test_observations = nrow(test_raw),
      train_component_filings = sum(train_raw$component_rows),
      test_component_filings = sum(test_raw$component_rows),
      train_multi_component_observations = sum(train_raw$component_rows > 1L),
      test_multi_component_observations = sum(test_raw$component_rows > 1L),
      train_observations_multiple_pluto_versions = sum(train_raw$component_pluto_versions > 1L),
      test_observations_multiple_pluto_versions = sum(test_raw$component_pluto_versions > 1L),
      train_observations_multiple_lotarea_values = sum(train_raw$component_lotarea_values > 1L),
      test_observations_multiple_lotarea_values = sum(test_raw$component_lotarea_values > 1L),
      train_future_appbbl_recovery_components = sum(train_raw$future_appbbl_recovery_components),
      test_future_appbbl_recovery_components = sum(test_raw$future_appbbl_recovery_components),
      train_duplicate_bin_site_years_excluded = train_duplicate_bin_site_years_excluded,
      test_duplicate_bin_site_years_excluded = test_duplicate_bin_site_years_excluded
    )

    if (nrow(train_raw) < 200L || nrow(test_raw) < 50L) {
      status_rows[[length(status_rows) + 1L]] <- tibble(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        sample_definition,
        model = NA_character_,
        model_role = NA_character_,
        train_rows = nrow(train_raw),
        test_rows = nrow(test_raw),
        status = "skipped_insufficient_rows",
        warning_messages = NA_character_
      )
      next
    }

    prepared <- prepare_train_test(train_raw, test_raw)
    train_data <- prepared$train
    test_data <- prepared$test

    for (model_name in names(model_formulas)) {
      warning_messages <- character()
      model_fit <- tryCatch(
        withCallingHandlers(
          lm(model_formulas[[model_name]], data = train_data),
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

      prediction <- NULL
      shock_scale <- NA_real_

      if (!is.null(model_fit)) {
        prediction <- tryCatch(
          withCallingHandlers(
            {
              predicted_log_mean <- as.numeric(predict(model_fit, newdata = test_data))
              shock_scale <- sqrt(mean(residuals(model_fit)^2))
              if (any(!is.finite(predicted_log_mean)) || !is.finite(shock_scale) || shock_scale <= 0) {
                stop("Model produced non-finite predictions or shock scale.")
              }
              lognormal_predictions(predicted_log_mean, shock_scale, test_data$units)
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
      }

      if (
        window_spec$window == reference_window &&
          sample_definition == "building_job_retrospective_crosswalk" &&
          model_name == "baseline_simple" &&
          !is.null(model_fit) && !is.null(prediction)
      ) {
        reference_model_for_print <- model_fit
        reference_model_for_print$call$formula <- baseline_formula
        reference_model_summary <- summary(reference_model_for_print)
        reference_model_summary_lines <- c(
          "Preferred simple no-notch model: exact reference-window specification",
          "",
          paste0("Training dates: ", window_spec$train_start, " through ", window_spec$train_end),
          paste0("Held-out dates: ", window_spec$test_start, " through ", window_spec$test_end),
          paste0("Training observations: ", nrow(train_data)),
          paste0("Held-out observations: ", nrow(test_data)),
          paste0("Minimum proposed Class A units: ", min_units),
          paste0("Training mean filing year used for centering: ", format(mean(train_raw$filing_year), digits = 12)),
          paste0("Training median ResidFAR used for missing-value imputation: ", format(median(train_raw$residfar, na.rm = TRUE), digits = 12)),
          paste0("Training observations with missing ResidFAR: ", sum(is.na(train_raw$residfar))),
          paste0("Training observations with missing BuiltFAR: ", sum(is.na(train_raw$builtfar)), " (no BuiltFAR imputation used)"),
          paste0("Minimum category count before other_rare pooling: ", minimum_category_rows),
          paste0("Borough factor levels: ", paste(levels(train_data$borough), collapse = ", ")),
          paste0("Zone factor levels: ", paste(levels(train_data$zone_detail), collapse = ", ")),
          paste0("Prior-site-use factor levels: ", paste(levels(train_data$prior_site_use), collapse = ", ")),
          paste0("Training residual shock scale sqrt(mean(residual^2)): ", format(shock_scale, digits = 12)),
          "Unit distribution: rounded lognormal, conditional on proposed units >= 6.",
          "",
          "Exact R output from print(summary(reference_model_for_print)):",
          "",
          capture.output(print(reference_model_summary))
        )

        reference_model_coefficients <- as.data.frame(reference_model_summary$coefficients) |>
          rownames_to_column("term") |>
          as_tibble()
        names(reference_model_coefficients) <- c(
          "term", "estimate", "std_error", "t_value", "p_value"
        )
      }

      status_rows[[length(status_rows) + 1L]] <- tibble(
        window = window_spec$window,
        regime_note = window_spec$regime_note,
        sample_definition,
        model = model_name,
        model_role = model_roles[[model_name]],
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

      for (sample_name in c("all", "local")) {
        metric_rows[[length(metric_rows) + 1L]] <- distribution_metrics(
          test_data,
          prediction,
          sample_name
        ) |>
          mutate(
            window = window_spec$window,
            regime_note = window_spec$regime_note,
            sample_definition,
            model = model_name,
            model_role = model_roles[[model_name]],
            shock_scale = shock_scale,
            .before = sample
          )
      }

      prediction_rows[[length(prediction_rows) + 1L]] <- test_data |>
        transmute(
          window = window_spec$window,
          regime_note = window_spec$regime_note,
          sample_definition,
          model = model_name,
          model_role = model_roles[[model_name]],
          observation_id,
          job_number,
          date_filed,
          filing_year,
          pluto_feature_bbl,
          component_rows,
          address_alignment,
          lotarea,
          broad_zoning_far,
          units,
          predicted_units = prediction$predicted_median_units,
          log_residual = log(units) - log(predicted_units),
          absolute_log_residual = abs(log_residual),
          probability_at_least_100 = 1 - prediction$cdf[, which(thresholds == 99L)],
          probability_exactly_99 = prediction$pmf_99,
          probability_observed_units = prediction$pmf
        )
    }
  }
}

model_status <- bind_rows(status_rows)
window_metrics <- bind_rows(metric_rows)
heldout_predictions <- bind_rows(prediction_rows)
design_qc <- bind_rows(design_qc_rows)

if (nrow(window_metrics) == 0L || nrow(heldout_predictions) == 0L) {
  stop("No model extension completed successfully.")
}

if (is.null(reference_model_summary_lines) || nrow(reference_model_coefficients) == 0L) {
  stop("Reference model output was not captured.")
}

validation_windows <- window_specs |>
  filter(regime_note != "post_deadline_transport") |>
  pull(window)

baseline_metrics <- window_metrics |>
  filter(model == "baseline_simple") |>
  select(
    window, sample_definition, sample, metric,
    baseline_value = value
  )

window_comparison <- window_metrics |>
  filter(metric %in% c(
    "mean_negative_log_score", "rmse_log_units", "mae_log_units",
    "brier_at_least_100", "cdf_rmse"
  )) |>
  left_join(
    baseline_metrics,
    by = c("window", "sample_definition", "sample", "metric"),
    relationship = "many-to-one"
  ) |>
  mutate(
    improvement_over_baseline = baseline_value - value,
    percent_improvement_over_baseline = 100 * improvement_over_baseline / baseline_value
  )

model_comparison <- window_comparison |>
  filter(window %in% validation_windows) |>
  group_by(sample_definition, sample, model, model_role, metric) |>
  summarise(
    validated_windows = n_distinct(window),
    complete_validation = validated_windows == length(validation_windows),
    mean_value = mean(value),
    worst_value = max(value),
    mean_baseline_value = mean(baseline_value),
    mean_percent_improvement = mean(percent_improvement_over_baseline),
    windows_better_than_baseline = sum(improvement_over_baseline > 0),
    windows_worse_than_baseline = sum(improvement_over_baseline < 0),
    .groups = "drop"
  ) |>
  mutate(
    percent_improvement_in_mean_metric = 100 *
      (mean_baseline_value - mean_value) / mean_baseline_value
  ) |>
  arrange(sample_definition, sample, metric, mean_value, model)

address_summary <- heldout_predictions |>
  filter(
    window == reference_window,
    sample_definition == "building_job_retrospective_crosswalk",
    model == "baseline_simple"
  ) |>
  group_by(address_alignment) |>
  summarise(
    rows = n(),
    mean_actual_units = mean(units),
    mean_predicted_units = mean(predicted_units),
    mean_log_residual = mean(log_residual),
    rmse_log_units = sqrt(mean(log_residual^2)),
    share_underpredicted_by_factor_two = mean(log_residual > log(2)),
    share_overpredicted_by_factor_two = mean(log_residual < -log(2)),
    .groups = "drop"
  ) |>
  arrange(desc(rows))

reference_baseline_tail <- heldout_predictions |>
  filter(
    window == reference_window,
    sample_definition == "building_job_retrospective_crosswalk",
    model == "baseline_simple"
  ) |>
  arrange(desc(absolute_log_residual)) |>
  slice_head(n = 50L) |>
  select(
    observation_id, job_number, date_filed, pluto_feature_bbl,
    address_alignment, lotarea, broad_zoning_far, units,
    baseline_predicted_units = predicted_units,
    baseline_log_residual = log_residual,
    baseline_absolute_log_residual = absolute_log_residual
  )

tail_cases <- heldout_predictions |>
  filter(
    window == reference_window,
    sample_definition == "building_job_retrospective_crosswalk",
    observation_id %in% reference_baseline_tail$observation_id
  ) |>
  select(observation_id, model, predicted_units, absolute_log_residual) |>
  tidyr::pivot_wider(
    names_from = model,
    values_from = c(predicted_units, absolute_log_residual),
    names_glue = "{model}_{.value}"
  ) |>
  right_join(reference_baseline_tail, by = "observation_id", relationship = "one-to-one") |>
  arrange(desc(baseline_absolute_log_residual))

reference_residuals <- heldout_predictions |>
  filter(
    window == reference_window,
    sample_definition == "building_job_retrospective_crosswalk",
    model == "baseline_simple"
  ) |>
  arrange(desc(absolute_log_residual)) |>
  mutate(reference_residual_rank = row_number())

reference_residual_summary <- tibble(
  metric = c(
    "heldout_rows", "rmse_log_units", "mae_log_units",
    "median_absolute_log_residual", "p90_absolute_log_residual",
    "p95_absolute_log_residual", "rows_within_factor_two",
    "share_within_factor_two", "rows_underpredicted_by_factor_two",
    "rows_overpredicted_by_factor_two", "top_tail_rows",
    "top_50_share_of_squared_log_error", "rmse_excluding_top_50"
  ),
  value = c(
    nrow(reference_residuals),
    sqrt(mean(reference_residuals$log_residual^2)),
    mean(reference_residuals$absolute_log_residual),
    median(reference_residuals$absolute_log_residual),
    quantile(reference_residuals$absolute_log_residual, 0.90),
    quantile(reference_residuals$absolute_log_residual, 0.95),
    sum(reference_residuals$absolute_log_residual <= log(2)),
    mean(reference_residuals$absolute_log_residual <= log(2)),
    sum(reference_residuals$log_residual > log(2)),
    sum(reference_residuals$log_residual < -log(2)),
    50L,
    sum(reference_residuals$log_residual[reference_residuals$reference_residual_rank <= 50L]^2) /
      sum(reference_residuals$log_residual^2),
    sqrt(mean(reference_residuals$log_residual[reference_residuals$reference_residual_rank > 50L]^2))
  )
)

plot_data <- model_comparison |>
  filter(
    sample_definition == "building_job_retrospective_crosswalk",
    sample %in% c("all", "local"),
    metric == "rmse_log_units",
    complete_validation
  ) |>
  mutate(
    model_label = recode(
      model,
      baseline_simple = "Baseline",
      broad_capacity = "Broad capacity",
      capacity_ownership = "Capacity + ownership",
      capacity_ownership_geometry = "Capacity + ownership + lot geometry",
      capacity_site_use_interactions = "Capacity-site use interactions",
      lot_spline = "Lot-size spline",
      address_alignment_diagnostic = "Address alignment (diagnostic)",
      address_capacity_interactions_diagnostic = "Address interactions (diagnostic)"
    ),
    sample_label = recode(
      sample,
      all = "All held-out filings",
      local = "Actual units: 50-150"
    )
  )

window_plot_data <- window_comparison |>
  filter(
    window %in% validation_windows,
    sample_definition == "building_job_retrospective_crosswalk",
    sample == "local",
    metric == "rmse_log_units",
    model != "baseline_simple"
  ) |>
  semi_join(
    model_comparison |>
      filter(
        sample_definition == "building_job_retrospective_crosswalk",
        sample == "local",
        metric == "rmse_log_units",
        complete_validation
      ) |>
      select(model),
    by = "model"
  ) |>
  mutate(
    model_label = recode(
      model,
      broad_capacity = "Broad capacity",
      capacity_ownership = "Capacity + ownership",
      capacity_ownership_geometry = "Capacity + ownership + lot geometry",
      capacity_site_use_interactions = "Capacity-site use interactions",
      lot_spline = "Lot-size spline",
      address_alignment_diagnostic = "Address alignment (diagnostic)",
      address_capacity_interactions_diagnostic = "Address interactions (diagnostic)"
    ),
    window_order = match(window, validation_windows)
  )

outcome_plot_data <- model_comparison |>
  filter(
    sample == "all",
    metric == "rmse_log_units",
    model == "baseline_simple",
    complete_validation
  ) |>
  mutate(
    outcome_label = recode(
      sample_definition,
      building_job_retrospective_crosswalk = "Individual filing (current crosswalk)",
      building_job_no_future_appbbl_recovery = "Individual filing (prospective link)",
      building_job_private_for_profit = "Individual filing (private for-profit)",
      all_period_singleton_job_diagnostic = "Singleton filing (diagnostic)",
      provisional_feature_bbl_year_retrospective_crosswalk = "Provisional site-year (current crosswalk)",
      provisional_feature_bbl_year_no_future_appbbl_recovery = "Provisional site-year (prospective link)"
    )
  )

extension_plot <- ggplot(plot_data, aes(x = percent_improvement_in_mean_metric, y = reorder(model_label, percent_improvement_in_mean_metric), color = sample_label)) +
  geom_vline(xintercept = 0, color = "grey65", linewidth = 0.4) +
  geom_point(size = 2.4, position = position_dodge(width = 0.45)) +
  scale_color_manual(values = c("All held-out filings" = "#0072B2", "Actual units: 50-150" = "#D55E00")) +
  labs(
    title = "Covariates help globally, but little near 100",
    subtitle = "Mean RMSE gain across ten forward-validation windows",
    x = "Mean improvement in log-unit RMSE (%)",
    y = NULL,
    color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 12),
    plot.subtitle = element_text(size = 9)
  )

window_plot <- ggplot(window_plot_data, aes(x = window_order, y = percent_improvement_over_baseline, color = model_label)) +
  geom_hline(yintercept = 0, color = "grey65", linewidth = 0.4) +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1.5) +
  scale_color_manual(values = c(
    "Broad capacity" = "#0072B2",
    "Capacity + ownership" = "#56B4E9",
    "Capacity + ownership + lot geometry" = "#E69F00",
    "Capacity-site use interactions" = "#999999",
    "Lot-size spline" = "#CC79A7",
    "Address alignment (diagnostic)" = "#009E73",
    "Address interactions (diagnostic)" = "#D55E00"
  )) +
  labs(
    title = "Local gains are unstable across time",
    subtitle = "Actual units: 50-150; positive values improve on baseline",
    x = "Forward-validation window (earliest to latest)",
    y = "RMSE improvement (%)",
    color = NULL
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 7),
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 12),
    plot.subtitle = element_text(size = 9)
  )

outcome_plot <- ggplot(outcome_plot_data, aes(x = mean_value, y = reorder(outcome_label, mean_value))) +
  geom_point(size = 2.6, color = "#0072B2") +
  labs(
    title = "Error falls when filings are regrouped",
    subtitle = "Mean held-out RMSE; site and singleton definitions are diagnostic",
    x = "Log-unit RMSE",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 12),
    plot.subtitle = element_text(size = 9)
  )

address_plot <- address_summary |>
  mutate(
    address_label = recode(
      address_alignment,
      exact_address = "Exact address",
      same_street_other_address = "Same street, other address",
      different_street = "Different street",
      missing_address = "Missing address"
    )
  ) |>
  ggplot(aes(x = rmse_log_units, y = reorder(address_label, rmse_log_units))) +
  geom_point(size = 2.6, color = "#D55E00") +
  labs(
    title = "Address disagreement flags harder matches",
    subtitle = "Reference holdout: 2021 through June 15, 2022",
    x = "Baseline log-unit RMSE",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 12),
    plot.subtitle = element_text(size = 9)
  )

write_csv_if_changed(model_comparison, "../output/no_notch_extension_comparison.csv")
write_csv_if_changed(window_metrics, "../output/no_notch_extension_window_metrics.csv")
write_csv_if_changed(window_comparison, "../output/no_notch_extension_window_comparison.csv")
write_csv_if_changed(model_status, "../output/no_notch_extension_status.csv")
write_csv_if_changed(design_qc, "../output/no_notch_extension_design_qc.csv")
write_csv_if_changed(address_summary, "../output/no_notch_extension_address_summary.csv")
write_csv_if_changed(tail_cases, "../output/no_notch_extension_tail_cases.csv")
writeLines(reference_model_summary_lines, "../output/no_notch_reference_model_summary.txt")
write_csv_if_changed(reference_model_coefficients, "../output/no_notch_reference_model_coefficients.csv")
write_csv_if_changed(reference_residual_summary, "../output/no_notch_reference_residual_summary.csv")
write_parquet_if_changed(heldout_predictions, "../output/no_notch_extension_predictions.parquet")

grDevices::pdf("../output/no_notch_extension_diagnostics.pdf", width = 15, height = 10)
grid::grid.newpage()
dashboard_layout <- grid::grid.layout(nrow = 2, ncol = 2)
grid::pushViewport(grid::viewport(layout = dashboard_layout))
print(extension_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
print(window_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
print(outcome_plot, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
print(address_plot, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 2))
grDevices::dev.off()

grDevices::png(
  "../output/no_notch_extension_diagnostics.png",
  width = 15,
  height = 10,
  units = "in",
  res = 180
)
grid::grid.newpage()
dashboard_layout <- grid::grid.layout(nrow = 2, ncol = 2)
grid::pushViewport(grid::viewport(layout = dashboard_layout))
print(extension_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
print(window_plot, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
print(outcome_plot, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
print(address_plot, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 2))
grDevices::dev.off()

cat("Wrote no-notch model-extension audit outputs.\n")

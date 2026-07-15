# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_post_policy_exposure/code")
# post_year <- 2025L
# universe_min_units <- 6L
# threshold_units <- 100L
# plot_min_units <- 50L
# plot_max_units <- 150L
# minimum_category_rows <- 30L
# exposure_threshold_low <- 0.50
# exposure_threshold_high <- 0.75

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 8L) {
  stop(
    "Expected eight arguments: post year, universe floor, policy threshold, ",
    "plot bounds, minimum category rows, and two exposure thresholds."
  )
}

post_year <- as.integer(args[1])
universe_min_units <- as.integer(args[2])
threshold_units <- as.integer(args[3])
plot_min_units <- as.integer(args[4])
plot_max_units <- as.integer(args[5])
minimum_category_rows <- as.integer(args[6])
exposure_threshold_low <- as.numeric(args[7])
exposure_threshold_high <- as.numeric(args[8])
bunch_units <- threshold_units - 1L

if (
  any(is.na(c(
    post_year, universe_min_units, threshold_units, plot_min_units,
    plot_max_units, minimum_category_rows, exposure_threshold_low,
    exposure_threshold_high
  ))) ||
    post_year < 2010L ||
    universe_min_units < 1L ||
    threshold_units <= universe_min_units ||
    plot_min_units < universe_min_units ||
    plot_max_units <= plot_min_units ||
    bunch_units < plot_min_units || bunch_units > plot_max_units ||
    minimum_category_rows < 2L ||
    exposure_threshold_low <= 0 ||
    exposure_threshold_high <= exposure_threshold_low ||
    exposure_threshold_high >= 1
) {
  stop("Post-policy exposure arguments are not internally consistent.")
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

rounded_conditional_probability <- function(
    units, predicted_log_units, sigma) {
  lower_z <- (log(units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(universe_min_units - 0.5) - predicted_log_units
  ) / sigma
  exp(
    log_normal_interval_probability(lower_z, upper_z) -
      pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  )
}

probability_at_least_threshold <- function(predicted_log_units, sigma) {
  floor_log_survival <- pnorm(
    (log(universe_min_units - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  threshold_log_survival <- pnorm(
    (log(threshold_units - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  pmin(pmax(exp(threshold_log_survival - floor_log_survival), 0), 1)
}

conditional_probability_between <- function(
    lower_units, upper_units, predicted_log_units, sigma) {
  lower_z <- (log(lower_units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(upper_units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(universe_min_units - 0.5) - predicted_log_units
  ) / sigma
  pmin(pmax(exp(
    log_normal_interval_probability(lower_z, upper_z) -
      pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  ), 0), 1)
}

conditional_unit_quantile <- function(probability, predicted_log_units, sigma) {
  floor_cdf <- pnorm(
    (log(universe_min_units - 0.5) - predicted_log_units) / sigma
  )
  target_cdf <- floor_cdf + probability * (1 - floor_cdf)
  pmax(
    universe_min_units,
    ceiling(exp(predicted_log_units + sigma * qnorm(target_cdf)) - 0.5)
  )
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

fit_parameters <- read_csv(
  "../input/no_notch_time_adaptation_interim_fit_parameters.csv",
  show_col_types = FALSE
) |>
  mutate(
    train_start = as.Date(train_start),
    train_end = as.Date(train_end)
  )

developer_panel <- read_parquet(
  "../input/developer_response_application_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

model_rows <- panel |>
  filter(
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
    observation_id, job_number, job_status, date_filed, filing_year, bbl, bin,
    address, borough, units, log_units, log_lotarea, residfar, builtfar,
    zone_detail, prior_site_use, primary_leakage_safe_sample,
    pluto_version_used, pluto_timing_status, pluto_days_relative_to_filing,
    exclusion_reason
  )

post_all <- panel |>
  filter(
    filing_year == post_year,
    classa_prop_integer,
    classa_prop >= universe_min_units
  ) |>
  mutate(units = as.integer(round(classa_prop))) |>
  arrange(date_filed, job_number)

post_scoreable <- model_rows |>
  filter(filing_year == post_year, primary_leakage_safe_sample)

if (
  nrow(post_all) == 0L ||
    nrow(post_scoreable) == 0L ||
    anyDuplicated(post_all$job_number) ||
    anyDuplicated(post_scoreable$job_number) ||
    anyDuplicated(developer_panel$job_number) ||
    n_distinct(fit_parameters$model_role) != 2L
) {
  stop("Post-policy source data failed row or identifier QC.")
}

score_rows <- list()
model_roles <- unique(fit_parameters$model_role)

for (model_role_value in model_roles) {
  model_parameters <- fit_parameters |>
    filter(model_role == model_role_value)
  model_metadata <- model_parameters |>
    distinct(
      model_role, model, training_floor, timing, train_start, train_end,
      train_rows, training_year_mean
    )

  if (nrow(model_metadata) != 1L) {
    stop("A frozen model has inconsistent metadata.")
  }

  train_raw <- model_rows |>
    filter(
      primary_leakage_safe_sample,
      date_filed >= model_metadata$train_start,
      date_filed <= model_metadata$train_end,
      units >= model_metadata$training_floor
    )
  prepared <- prepare_train_test(train_raw, post_scoreable)
  post_data <- prepared$test
  coefficient_rows <- model_parameters |>
    filter(term != "shock_sigma")
  sigma <- model_parameters$estimate[model_parameters$term == "shock_sigma"]
  post_matrix_full <- model.matrix(model_formula, data = post_data)
  missing_terms <- setdiff(coefficient_rows$term, colnames(post_matrix_full))

  if (
    nrow(train_raw) != model_metadata$train_rows ||
      abs(prepared$training_year_mean - model_metadata$training_year_mean) > 1e-8 ||
      length(sigma) != 1L || !is.finite(sigma) || sigma <= 0 ||
      length(missing_terms) > 0L ||
      anyDuplicated(coefficient_rows$term)
  ) {
    stop("Frozen model reconstruction failed preprocessing or parameter QC.")
  }

  post_matrix <- post_matrix_full[, coefficient_rows$term, drop = FALSE]
  coefficients <- coefficient_rows$estimate
  names(coefficients) <- coefficient_rows$term
  predicted_log_units <- as.numeric(post_matrix %*% coefficients)
  score_rows[[length(score_rows) + 1L]] <- post_data |>
    transmute(
      observation_id,
      job_number,
      job_status,
      date_filed,
      filing_year,
      bbl,
      bin,
      address,
      borough,
      observed_units = units,
      pre_filing_lot_area = exp(log_lotarea),
      pre_filing_residential_far = residfar,
      pre_filing_residential_far_missing = residfar_missing,
      pre_filing_built_far = builtfar,
      pre_filing_built_far_missing = builtfar_missing,
      zone_detail,
      prior_site_use,
      model_role = model_role_value,
      model = model_metadata$model,
      training_floor = model_metadata$training_floor,
      timing = model_metadata$timing,
      predicted_log_units = .env$predicted_log_units,
      shock_sigma = .env$sigma,
      predicted_q10_units = conditional_unit_quantile(
        0.10, .env$predicted_log_units, .env$sigma
      ),
      predicted_median_units = conditional_unit_quantile(
        0.50, .env$predicted_log_units, .env$sigma
      ),
      predicted_q90_units = conditional_unit_quantile(
        0.90, .env$predicted_log_units, .env$sigma
      ),
      probability_observed_units = rounded_conditional_probability(
        observed_units, .env$predicted_log_units, .env$sigma
      ),
      probability_exact_99 = rounded_conditional_probability(
        bunch_units, .env$predicted_log_units, .env$sigma
      ),
      probability_at_least_100 = probability_at_least_threshold(
        .env$predicted_log_units, .env$sigma
      ),
      probability_90_through_110 = conditional_probability_between(
        90L, 110L, .env$predicted_log_units, .env$sigma
      ),
      pluto_version_used,
      pluto_timing_status,
      pluto_days_relative_to_filing
    )
}

scores <- bind_rows(score_rows) |>
  arrange(model_role, date_filed, job_number)

if (
  nrow(scores) != nrow(post_scoreable) * length(model_roles) ||
    anyDuplicated(scores[c("job_number", "model_role")]) ||
    any(!is.finite(scores$probability_observed_units)) ||
    any(scores$probability_at_least_100 < 0 | scores$probability_at_least_100 > 1)
) {
  stop("Post-policy model scores failed probability or row-count QC.")
}

distribution_rows <- list()

for (model_role_value in model_roles) {
  model_scores <- scores |>
    filter(model_role == model_role_value)

  for (unit_value in plot_min_units:plot_max_units) {
    distribution_rows[[length(distribution_rows) + 1L]] <- tibble(
      model_role = model_role_value,
      model = unique(model_scores$model),
      proposed_units = unit_value,
      observed_count = sum(model_scores$observed_units == unit_value),
      expected_no_notch_count = sum(rounded_conditional_probability(
        unit_value,
        model_scores$predicted_log_units,
        model_scores$shock_sigma
      ))
    )
  }
}

distribution_counts <- bind_rows(distribution_rows) |>
  mutate(observed_minus_expected = observed_count - expected_no_notch_count) |>
  arrange(model_role, proposed_units)

aggregate_summary <- scores |>
  group_by(model_role, model, training_floor, timing) |>
  summarise(
    scoreable_2025_filings = n(),
    observed_exact_99_filings = sum(observed_units == bunch_units),
    expected_no_notch_exact_99_filings = sum(probability_exact_99),
    observed_minus_expected_exact_99 =
      observed_exact_99_filings - expected_no_notch_exact_99_filings,
    observed_100_plus_filings = sum(observed_units >= threshold_units),
    expected_no_notch_100_plus_filings = sum(probability_at_least_100),
    observed_minus_expected_100_plus =
      observed_100_plus_filings - expected_no_notch_100_plus_filings,
    exact_99_mean_probability_at_least_100 = mean(
      probability_at_least_100[observed_units == bunch_units]
    ),
    exact_99_median_probability_at_least_100 = median(
      probability_at_least_100[observed_units == bunch_units]
    ),
    exact_99_exposure_probability_sum = sum(
      probability_at_least_100[observed_units == bunch_units]
    ),
    exact_99_rows_probability_at_least_low = sum(
      observed_units == bunch_units &
        probability_at_least_100 >= exposure_threshold_low
    ),
    exact_99_rows_probability_at_least_high = sum(
      observed_units == bunch_units &
        probability_at_least_100 >= exposure_threshold_high
    ),
    .groups = "drop"
  ) |>
  mutate(
    missing_no_notch_100_plus_filings =
      expected_no_notch_100_plus_filings - observed_100_plus_filings,
    excess_exact_99_share_of_missing_100_plus = if_else(
      missing_no_notch_100_plus_filings > 0,
      observed_minus_expected_exact_99 / missing_no_notch_100_plus_filings,
      NA_real_
    )
  ) |>
  arrange(model_role)

wide_scores <- scores |>
  filter(observed_units == bunch_units) |>
  mutate(
    model_suffix = if_else(
      model_role == "preferred_full_distribution",
      "preferred",
      "floor11_robustness"
    )
  ) |>
  select(
    job_number, model_suffix, predicted_q10_units, predicted_median_units,
    predicted_q90_units, probability_observed_units, probability_exact_99,
    probability_at_least_100, probability_90_through_110
  ) |>
  pivot_wider(
    names_from = model_suffix,
    values_from = c(
      predicted_q10_units, predicted_median_units, predicted_q90_units,
      probability_observed_units, probability_exact_99,
      probability_at_least_100, probability_90_through_110
    ),
    names_glue = "{model_suffix}_{.value}"
  )

same_bbl_counts <- developer_panel |>
  filter(
    filing_year == post_year,
    !is.na(hdb_bbl),
    hdb_bbl != "",
    !is.na(hdb_units),
    hdb_units >= universe_min_units
  ) |>
  group_by(hdb_bbl) |>
  summarise(
    same_bbl_2025_application_count = n(),
    same_bbl_2025_exact_99_count = sum(hdb_units == bunch_units),
    same_bbl_2025_total_application_units = sum(hdb_units),
    .groups = "drop"
  )

exact_99_ledger <- post_all |>
  filter(units == bunch_units) |>
  select(
    job_number, date_filed, job_status, bbl, bin, address,
    hdb_borough_name, units, primary_leakage_safe_sample, exclusion_reason,
    pluto_version_used, pluto_timing_status, pluto_days_relative_to_filing
  ) |>
  left_join(
    developer_panel |>
      select(
        job_number, total_construction_floor_area,
        gross_construction_square_feet_per_unit, proposed_stories,
        proposed_height, owner_business_name, applicant_business_name,
        dob_initial_match, units_agree, bbl_agree, bin_agree
      ),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  left_join(
    same_bbl_counts,
    by = c("bbl" = "hdb_bbl"),
    relationship = "many-to-one"
  ) |>
  left_join(wide_scores, by = "job_number", relationship = "one-to-one") |>
  mutate(
    score_status = if_else(
      primary_leakage_safe_sample,
      "scored",
      paste0("not_scored_", exclusion_reason)
    )
  ) |>
  arrange(
    is.na(preferred_probability_at_least_100),
    desc(preferred_probability_at_least_100),
    job_number
  )

sample_qc <- bind_rows(
  post_all |>
    count(exclusion_reason, name = "rows") |>
    mutate(
      qc_type = "all_2025_integer_six_plus_by_exclusion_reason",
      qc_value = exclusion_reason,
      exact_99_rows = vapply(exclusion_reason, function(reason_value) {
        sum(post_all$exclusion_reason == reason_value & post_all$units == bunch_units)
      }, integer(1))
    ) |>
    select(qc_type, qc_value, rows, exact_99_rows),
  post_scoreable |>
    count(pluto_version_used, name = "rows") |>
    mutate(
      qc_type = "scoreable_2025_by_lagged_pluto_version",
      qc_value = pluto_version_used,
      exact_99_rows = vapply(pluto_version_used, function(version_value) {
        sum(
          post_scoreable$pluto_version_used == version_value &
            post_scoreable$units == bunch_units
        )
      }, integer(1))
    ) |>
    select(qc_type, qc_value, rows, exact_99_rows),
  tibble(
    qc_type = "scoreable_2025_mappluto_staleness",
    qc_value = c("median_days", "minimum_days", "maximum_days"),
    rows = as.integer(c(
      median(post_scoreable$pluto_days_relative_to_filing),
      min(post_scoreable$pluto_days_relative_to_filing),
      max(post_scoreable$pluto_days_relative_to_filing)
    )),
    exact_99_rows = NA_integer_
  )
) |>
  arrange(qc_type, qc_value)

model_labels <- c(
  preferred_full_distribution = "Preferred: floor 6, expanding history",
  required_sample_robustness = "Robustness: floor 11, rolling five years"
)

distribution_plot <- distribution_counts |>
  mutate(model_label = factor(
    model_labels[model_role],
    levels = unname(model_labels)
  )) |>
  ggplot(aes(x = proposed_units)) +
  geom_col(
    aes(y = observed_count),
    fill = "#1769AA",
    alpha = 0.72,
    width = 0.82
  ) +
  geom_line(
    aes(y = expected_no_notch_count),
    color = "#D95F02",
    linewidth = 0.85
  ) +
  geom_vline(
    xintercept = bunch_units,
    color = "#333333",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  facet_wrap(vars(model_label), ncol = 1L) +
  scale_x_continuous(
    breaks = c(plot_min_units, 75L, bunch_units, 125L, plot_max_units)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Observed 2025 filings place far more mass at 99 than the no-notch models",
    subtitle = paste0(
      "Bars are observed scoreable HDB filings; orange lines sum model probabilities over the same ",
      nrow(post_scoreable), " filing opportunities."
    ),
    x = "Proposed Class A units",
    y = "Observed or expected filings"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "#F2F2F2", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(exact_99_ledger) != sum(post_all$units == bunch_units) ||
    anyDuplicated(exact_99_ledger$job_number) ||
    sum(exact_99_ledger$score_status == "scored") !=
      sum(post_scoreable$units == bunch_units) ||
    nrow(distribution_counts) !=
      length(model_roles) * (plot_max_units - plot_min_units + 1L) ||
    nrow(aggregate_summary) != length(model_roles) ||
    any(!is.finite(distribution_counts$expected_no_notch_count))
) {
  stop("Post-policy exposure outputs failed final QC.")
}

write_parquet_if_changed(
  scores,
  "../output/no_notch_post_policy_exposure_scores.parquet"
)
write_csv_if_changed(
  exact_99_ledger,
  "../output/no_notch_post_policy_exact_99_ledger.csv"
)
write_csv_if_changed(
  distribution_counts,
  "../output/no_notch_post_policy_distribution_counts.csv"
)
write_csv_if_changed(
  aggregate_summary,
  "../output/no_notch_post_policy_aggregate_summary.csv"
)
write_csv_if_changed(
  sample_qc,
  "../output/no_notch_post_policy_sample_qc.csv"
)
ggsave(
  "../output/no_notch_post_policy_distribution.pdf",
  distribution_plot,
  width = 10,
  height = 8.5,
  device = "pdf"
)
ggsave(
  "../output/no_notch_post_policy_distribution.png",
  distribution_plot,
  width = 10,
  height = 8.5,
  dpi = 180
)

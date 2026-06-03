# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_basic_hdb_mappluto_regression/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

deadline_421a <- as.Date("2022-06-15")

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

model_data <- panel |>
  filter(
    primary_leakage_safe_sample,
    date_filed <= deadline_421a,
    classa_prop_integer,
    !is.na(y100),
    !is.na(lotarea),
    lotarea > 0,
    !is.na(residfar),
    !is.na(builtfar),
    !is.na(hdb_borough_name),
    !is.na(zonedist1)
  ) |>
  mutate(
    y100_num = as.integer(y100),
    log_units = log(classa_prop),
    log_lotarea = log(lotarea),
    zone_family_raw = str_sub(zonedist1, 1L, 1L),
    zone_family = if_else(zone_family_raw %in% c("R", "C", "M"), zone_family_raw, "Other"),
    zone_family = relevel(factor(zone_family), ref = "R"),
    borough = relevel(factor(hdb_borough_name), ref = "Brooklyn"),
    vacant_lot = as.integer(is_vacant_lot %in% TRUE),
    has_existing_res_units = as.integer(!is.na(unitsres) & unitsres > 0)
  )

if (nrow(model_data) == 0) {
  stop("Basic regression sample is empty.")
}

if (sum(model_data$y100_num) == 0 || sum(model_data$y100_num == 0) == 0) {
  stop("Basic regression sample must contain both y100 and non-y100 rows.")
}

numeric_features <- c("log_lotarea", "residfar", "builtfar")

feature_summary_numeric <- bind_rows(lapply(numeric_features, function(feature_name) {
  values <- model_data[[feature_name]]

  tibble(
    feature = feature_name,
    level = NA_character_,
    rows = length(values),
    y100_rows = sum(model_data$y100_num),
    y100_share = mean(model_data$y100_num),
    mean_value = mean(values),
    sd_value = sd(values),
    min_value = min(values),
    median_value = median(values),
    max_value = max(values)
  )
}))

for (feature_name in numeric_features) {
  feature_mean <- mean(model_data[[feature_name]])
  feature_sd <- sd(model_data[[feature_name]])

  if (is.na(feature_sd) || feature_sd == 0) {
    stop("Feature has zero or missing standard deviation: ", feature_name)
  }

  model_data[[paste0("z_", feature_name)]] <- (model_data[[feature_name]] - feature_mean) / feature_sd
}

feature_summary_binary <- bind_rows(
  model_data |>
    count(vacant_lot, name = "rows") |>
    left_join(
      model_data |>
        group_by(vacant_lot) |>
        summarise(y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop"),
      by = "vacant_lot",
      relationship = "one-to-one"
    ) |>
    transmute(
      feature = "vacant_lot",
      level = as.character(vacant_lot),
      rows,
      y100_rows,
      y100_share,
      mean_value = NA_real_,
      sd_value = NA_real_,
      min_value = NA_real_,
      median_value = NA_real_,
      max_value = NA_real_
    ),
  model_data |>
    count(has_existing_res_units, name = "rows") |>
    left_join(
      model_data |>
        group_by(has_existing_res_units) |>
        summarise(y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop"),
      by = "has_existing_res_units",
      relationship = "one-to-one"
    ) |>
    transmute(
      feature = "has_existing_res_units",
      level = as.character(has_existing_res_units),
      rows,
      y100_rows,
      y100_share,
      mean_value = NA_real_,
      sd_value = NA_real_,
      min_value = NA_real_,
      median_value = NA_real_,
      max_value = NA_real_
    )
)

feature_summary_categorical <- bind_rows(
  model_data |>
    group_by(borough) |>
    summarise(rows = n(), y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop") |>
    transmute(
      feature = "borough",
      level = as.character(borough),
      rows,
      y100_rows,
      y100_share,
      mean_value = NA_real_,
      sd_value = NA_real_,
      min_value = NA_real_,
      median_value = NA_real_,
      max_value = NA_real_
    ),
  model_data |>
    group_by(zone_family) |>
    summarise(rows = n(), y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop") |>
    transmute(
      feature = "zone_family",
      level = as.character(zone_family),
      rows,
      y100_rows,
      y100_share,
      mean_value = NA_real_,
      sd_value = NA_real_,
      min_value = NA_real_,
      median_value = NA_real_,
      max_value = NA_real_
    )
)

feature_summary <- bind_rows(feature_summary_numeric, feature_summary_binary, feature_summary_categorical) |>
  arrange(feature, level)

model_formula <- y100_num ~ z_log_lotarea + z_residfar + z_builtfar +
  vacant_lot + has_existing_res_units + borough + zone_family

logit_model <- glm(model_formula, data = model_data, family = binomial())
log_units_model <- lm(update(model_formula, log_units ~ .), data = model_data)
units_model <- lm(update(model_formula, classa_prop ~ .), data = model_data)

format_coefficients <- function(model_object, model_name) {
  coef_table <- as.data.frame(coef(summary(model_object)))
  coef_table$term <- rownames(coef_table)
  rownames(coef_table) <- NULL
  names(coef_table) <- normalize_names(names(coef_table))

  statistic_column <- if ("z_value" %in% names(coef_table)) "z_value" else "t_value"
  p_value_column <- if ("pr_z" %in% names(coef_table)) "pr_z" else "pr_t"

  coef_table |>
    transmute(
      model = model_name,
      term,
      estimate,
      std_error,
      statistic = .data[[statistic_column]],
      p_value = .data[[p_value_column]]
    )
}

logit_coefficients <- format_coefficients(logit_model, "logit_y100") |>
  mutate(
    odds_ratio = exp(estimate),
    odds_ratio_low = exp(estimate - 1.96 * std_error),
    odds_ratio_high = exp(estimate + 1.96 * std_error)
  )

log_units_coefficients <- format_coefficients(log_units_model, "ols_log_units") |>
  mutate(
    approximate_percent_change = 100 * (exp(estimate) - 1),
    approximate_percent_change_low = 100 * (exp(estimate - 1.96 * std_error) - 1),
    approximate_percent_change_high = 100 * (exp(estimate + 1.96 * std_error) - 1)
  )

units_coefficients <- format_coefficients(units_model, "ols_units") |>
  mutate(
    units_change = estimate,
    units_change_low = estimate - 1.96 * std_error,
    units_change_high = estimate + 1.96 * std_error
  )

rank_auc <- function(y_values, score_values) {
  positive_count <- sum(y_values == 1)
  negative_count <- sum(y_values == 0)

  if (positive_count == 0 || negative_count == 0) {
    return(NA_real_)
  }

  score_ranks <- rank(score_values, ties.method = "average")
  (sum(score_ranks[y_values == 1]) - positive_count * (positive_count + 1) / 2) / (positive_count * negative_count)
}

logit_predictions <- predict(logit_model, type = "response")
ols_predictions <- predict(log_units_model)
units_predictions <- predict(units_model)
null_logit_model <- glm(y100_num ~ 1, data = model_data, family = binomial())
top_decile_cutoff <- quantile(logit_predictions, 0.90, names = FALSE)
top_decile_rows <- logit_predictions >= top_decile_cutoff

fit_summary <- bind_rows(
  tibble(
    model = "logit_y100",
    rows = nrow(model_data),
    outcome = "y100",
    outcome_mean = mean(model_data$y100_num),
    metric = "auc",
    value = rank_auc(model_data$y100_num, logit_predictions)
  ),
  tibble(
    model = "logit_y100",
    rows = nrow(model_data),
    outcome = "y100",
    outcome_mean = mean(model_data$y100_num),
    metric = "brier_score",
    value = mean((model_data$y100_num - logit_predictions)^2)
  ),
  tibble(
    model = "logit_y100",
    rows = nrow(model_data),
    outcome = "y100",
    outcome_mean = mean(model_data$y100_num),
    metric = "mcfadden_pseudo_r2",
    value = 1 - as.numeric(logLik(logit_model)) / as.numeric(logLik(null_logit_model))
  ),
  tibble(
    model = "logit_y100",
    rows = nrow(model_data),
    outcome = "y100",
    outcome_mean = mean(model_data$y100_num),
    metric = "top_decile_y100_share",
    value = mean(model_data$y100_num[top_decile_rows])
  ),
  tibble(
    model = "logit_y100",
    rows = nrow(model_data),
    outcome = "y100",
    outcome_mean = mean(model_data$y100_num),
    metric = "top_decile_capture_share",
    value = sum(model_data$y100_num[top_decile_rows]) / sum(model_data$y100_num)
  ),
  tibble(
    model = "ols_log_units",
    rows = nrow(model_data),
    outcome = "log_classa_prop",
    outcome_mean = mean(model_data$log_units),
    metric = "r_squared",
    value = summary(log_units_model)$r.squared
  ),
  tibble(
    model = "ols_log_units",
    rows = nrow(model_data),
    outcome = "log_classa_prop",
    outcome_mean = mean(model_data$log_units),
    metric = "adjusted_r_squared",
    value = summary(log_units_model)$adj.r.squared
  ),
  tibble(
    model = "ols_log_units",
    rows = nrow(model_data),
    outcome = "log_classa_prop",
    outcome_mean = mean(model_data$log_units),
    metric = "rmse",
    value = sqrt(mean((model_data$log_units - ols_predictions)^2))
  ),
  tibble(
    model = "ols_units",
    rows = nrow(model_data),
    outcome = "classa_prop",
    outcome_mean = mean(model_data$classa_prop),
    metric = "r_squared",
    value = summary(units_model)$r.squared
  ),
  tibble(
    model = "ols_units",
    rows = nrow(model_data),
    outcome = "classa_prop",
    outcome_mean = mean(model_data$classa_prop),
    metric = "adjusted_r_squared",
    value = summary(units_model)$adj.r.squared
  ),
  tibble(
    model = "ols_units",
    rows = nrow(model_data),
    outcome = "classa_prop",
    outcome_mean = mean(model_data$classa_prop),
    metric = "rmse",
    value = sqrt(mean((model_data$classa_prop - units_predictions)^2))
  ),
  tibble(
    model = "ols_units",
    rows = nrow(model_data),
    outcome = "classa_prop",
    outcome_mean = mean(model_data$classa_prop),
    metric = "mean_absolute_error",
    value = mean(abs(model_data$classa_prop - units_predictions))
  )
)

sample_by_year <- model_data |>
  group_by(filing_year) |>
  summarise(
    rows = n(),
    y100_rows = sum(y100_num),
    y100_share = mean(y100_num),
    mean_classa_prop = mean(classa_prop),
    median_classa_prop = median(classa_prop),
    .groups = "drop"
  ) |>
  arrange(filing_year)

write_csv_if_changed(logit_coefficients, "../output/basic_logit_coefficients.csv")
write_csv_if_changed(log_units_coefficients, "../output/basic_log_units_coefficients.csv")
write_csv_if_changed(units_coefficients, "../output/basic_units_coefficients.csv")
write_csv_if_changed(fit_summary, "../output/basic_regression_fit_summary.csv")
write_csv_if_changed(sample_by_year, "../output/basic_regression_sample_by_year.csv")
write_csv_if_changed(feature_summary, "../output/basic_regression_feature_summary.csv")
cat("Wrote basic HDB-MapPLUTO regression audit outputs to ../output\n")

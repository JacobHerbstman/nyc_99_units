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
candidate_min_classa_prop <- 70L
conditioned_candidate_min_classa_props <- c(50L, 60L, 70L)

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
    zonedist1_clean = toupper(zonedist1),
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
    zone_detail = relevel(factor(zone_detail), ref = "R6"),
    landuse_code = str_pad(as.character(landuse), 2L, pad = "0"),
    prior_site_use = case_when(
      !is.na(unitsres) & unitsres > 0 ~ "existing_residential_units",
      landuse_code == "11" ~ "vacant_land",
      landuse_code == "10" ~ "parking",
      landuse_code %in% c("05", "06") ~ "commercial_industrial",
      landuse_code == "04" ~ "mixed_res_commercial",
      landuse_code %in% c("07", "08") ~ "public_transport_utility",
      is.na(landuse_code) ~ "missing_landuse",
      TRUE ~ "other_no_res_units"
    ),
    prior_site_use = relevel(factor(prior_site_use), ref = "existing_residential_units"),
    borough = relevel(factor(hdb_borough_name), ref = "Brooklyn")
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
    group_by(zone_detail) |>
    summarise(rows = n(), y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop") |>
    transmute(
      feature = "zone_detail",
      level = as.character(zone_detail),
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
    group_by(prior_site_use) |>
    summarise(rows = n(), y100_rows = sum(y100_num), y100_share = mean(y100_num), .groups = "drop") |>
    transmute(
      feature = "prior_site_use",
      level = as.character(prior_site_use),
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

feature_summary <- bind_rows(feature_summary_numeric, feature_summary_categorical) |>
  arrange(feature, level)

model_formula <- y100_num ~ z_log_lotarea + z_residfar + z_builtfar +
  borough + zone_detail + prior_site_use

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

binary_holdout_metrics <- function(split_name, split_data) {
  split_top_decile_cutoff <- quantile(split_data$pred_p100, 0.90, names = FALSE)
  split_top_decile_rows <- split_data$pred_p100 >= split_top_decile_cutoff

  bind_rows(
    tibble(
      split = split_name,
      model = "logit_y100",
      rows = nrow(split_data),
      outcome = "y100",
      outcome_mean = mean(split_data$y100_num),
      metric = "auc",
      value = rank_auc(split_data$y100_num, split_data$pred_p100)
    ),
    tibble(
      split = split_name,
      model = "logit_y100",
      rows = nrow(split_data),
      outcome = "y100",
      outcome_mean = mean(split_data$y100_num),
      metric = "brier_score",
      value = mean((split_data$y100_num - split_data$pred_p100)^2)
    ),
    tibble(
      split = split_name,
      model = "logit_y100",
      rows = nrow(split_data),
      outcome = "y100",
      outcome_mean = mean(split_data$y100_num),
      metric = "top_decile_y100_share",
      value = mean(split_data$y100_num[split_top_decile_rows])
    ),
    tibble(
      split = split_name,
      model = "logit_y100",
      rows = nrow(split_data),
      outcome = "y100",
      outcome_mean = mean(split_data$y100_num),
      metric = "top_decile_capture_share",
      value = sum(split_data$y100_num[split_top_decile_rows]) / sum(split_data$y100_num)
    )
  )
}

continuous_holdout_metrics <- function(split_name, split_data, model_name, outcome_name, outcome_values, prediction_values, baseline_mean) {
  bind_rows(
    tibble(
      split = split_name,
      model = model_name,
      rows = nrow(split_data),
      outcome = outcome_name,
      outcome_mean = mean(outcome_values),
      metric = "rmse",
      value = sqrt(mean((outcome_values - prediction_values)^2))
    ),
    tibble(
      split = split_name,
      model = model_name,
      rows = nrow(split_data),
      outcome = outcome_name,
      outcome_mean = mean(outcome_values),
      metric = "mean_absolute_error",
      value = mean(abs(outcome_values - prediction_values))
    ),
    tibble(
      split = split_name,
      model = model_name,
      rows = nrow(split_data),
      outcome = outcome_name,
      outcome_mean = mean(outcome_values),
      metric = "r_squared_against_train_mean",
      value = 1 - sum((outcome_values - prediction_values)^2) / sum((outcome_values - baseline_mean)^2)
    )
  )
}

fit_holdout_window <- function(holdout_model_data, train_split, test_split) {
  holdout_train <- holdout_model_data |>
    filter(holdout_split == train_split)

  holdout_test <- holdout_model_data |>
    filter(holdout_split == test_split)

  if (nrow(holdout_train) == 0 || nrow(holdout_test) == 0) {
    stop("Holdout training and test samples must both be non-empty for ", train_split, " / ", test_split, ".")
  }

  if (sum(holdout_train$y100_num) == 0 || sum(holdout_train$y100_num == 0) == 0) {
    stop("Holdout training sample must contain both y100 and non-y100 rows for ", train_split, ".")
  }

  if (sum(holdout_test$y100_num) == 0 || sum(holdout_test$y100_num == 0) == 0) {
    stop("Holdout test sample must contain both y100 and non-y100 rows for ", test_split, ".")
  }

  for (feature_name in numeric_features) {
    train_values <- holdout_train[[feature_name]]
    feature_mean <- mean(train_values)
    feature_sd <- sd(train_values)

    if (is.na(feature_sd) || feature_sd == 0) {
      stop("Training feature has zero or missing standard deviation: ", feature_name)
    }

    holdout_train[[paste0("z_", feature_name)]] <- (holdout_train[[feature_name]] - feature_mean) / feature_sd
    holdout_test[[paste0("z_", feature_name)]] <- (holdout_test[[feature_name]] - feature_mean) / feature_sd
  }

  holdout_logit_model <- glm(model_formula, data = holdout_train, family = binomial())
  holdout_log_units_model <- lm(update(model_formula, log_units ~ .), data = holdout_train)
  holdout_units_model <- lm(update(model_formula, classa_prop ~ .), data = holdout_train)

  holdout_train_eval <- holdout_train |>
    mutate(
      pred_p100 = predict(holdout_logit_model, newdata = holdout_train, type = "response"),
      pred_log_units = predict(holdout_log_units_model, newdata = holdout_train),
      pred_units = predict(holdout_units_model, newdata = holdout_train)
    )

  holdout_test_eval <- holdout_test |>
    mutate(
      pred_p100 = predict(holdout_logit_model, newdata = holdout_test, type = "response"),
      pred_log_units = predict(holdout_log_units_model, newdata = holdout_test),
      pred_units = predict(holdout_units_model, newdata = holdout_test)
    )

  holdout_fit_summary <- bind_rows(
    binary_holdout_metrics(train_split, holdout_train_eval),
    binary_holdout_metrics(test_split, holdout_test_eval),
    continuous_holdout_metrics(
      train_split,
      holdout_train_eval,
      "ols_log_units",
      "log_classa_prop",
      holdout_train_eval$log_units,
      holdout_train_eval$pred_log_units,
      mean(holdout_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      test_split,
      holdout_test_eval,
      "ols_log_units",
      "log_classa_prop",
      holdout_test_eval$log_units,
      holdout_test_eval$pred_log_units,
      mean(holdout_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      train_split,
      holdout_train_eval,
      "ols_units",
      "classa_prop",
      holdout_train_eval$classa_prop,
      holdout_train_eval$pred_units,
      mean(holdout_train_eval$classa_prop)
    ),
    continuous_holdout_metrics(
      test_split,
      holdout_test_eval,
      "ols_units",
      "classa_prop",
      holdout_test_eval$classa_prop,
      holdout_test_eval$pred_units,
      mean(holdout_train_eval$classa_prop)
    )
  )

  holdout_deciles <- holdout_test_eval |>
    mutate(pred_p100_decile = ntile(pred_p100, 10L)) |>
    group_by(pred_p100_decile) |>
    summarise(
      split = test_split,
      rows = n(),
      y100_rows = sum(y100_num),
      y100_share = mean(y100_num),
      mean_pred_p100 = mean(pred_p100),
      min_pred_p100 = min(pred_p100),
      max_pred_p100 = max(pred_p100),
      capture_share = sum(y100_num) / sum(holdout_test_eval$y100_num),
      mean_classa_prop = mean(classa_prop),
      .groups = "drop"
    ) |>
    arrange(pred_p100_decile)

  candidate70_train_eval <- holdout_train_eval |>
    filter(classa_prop >= candidate_min_classa_prop)

  candidate70_test_eval <- holdout_test_eval |>
    filter(classa_prop >= candidate_min_classa_prop)

  if (nrow(candidate70_train_eval) == 0 || nrow(candidate70_test_eval) == 0) {
    stop("Candidate-size holdout training and test samples must both be non-empty for ", train_split, " / ", test_split, ".")
  }

  if (sum(candidate70_train_eval$y100_num) == 0 || sum(candidate70_train_eval$y100_num == 0) == 0) {
    stop("Candidate-size training sample must contain both y100 and non-y100 rows for ", train_split, ".")
  }

  if (sum(candidate70_test_eval$y100_num) == 0 || sum(candidate70_test_eval$y100_num == 0) == 0) {
    stop("Candidate-size test sample must contain both y100 and non-y100 rows for ", test_split, ".")
  }

  candidate70_fit_summary <- bind_rows(
    binary_holdout_metrics(train_split, candidate70_train_eval),
    binary_holdout_metrics(test_split, candidate70_test_eval),
    continuous_holdout_metrics(
      train_split,
      candidate70_train_eval,
      "ols_log_units",
      "log_classa_prop",
      candidate70_train_eval$log_units,
      candidate70_train_eval$pred_log_units,
      mean(candidate70_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      test_split,
      candidate70_test_eval,
      "ols_log_units",
      "log_classa_prop",
      candidate70_test_eval$log_units,
      candidate70_test_eval$pred_log_units,
      mean(candidate70_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      train_split,
      candidate70_train_eval,
      "ols_units",
      "classa_prop",
      candidate70_train_eval$classa_prop,
      candidate70_train_eval$pred_units,
      mean(candidate70_train_eval$classa_prop)
    ),
    continuous_holdout_metrics(
      test_split,
      candidate70_test_eval,
      "ols_units",
      "classa_prop",
      candidate70_test_eval$classa_prop,
      candidate70_test_eval$pred_units,
      mean(candidate70_train_eval$classa_prop)
    )
  ) |>
    mutate(candidate_min_classa_prop = candidate_min_classa_prop, .before = split)

  candidate70_deciles <- candidate70_test_eval |>
    mutate(pred_p100_decile = ntile(pred_p100, 10L)) |>
    group_by(pred_p100_decile) |>
    summarise(
      candidate_min_classa_prop = candidate_min_classa_prop,
      split = test_split,
      rows = n(),
      y100_rows = sum(y100_num),
      y100_share = mean(y100_num),
      mean_pred_p100 = mean(pred_p100),
      min_pred_p100 = min(pred_p100),
      max_pred_p100 = max(pred_p100),
      capture_share = sum(y100_num) / sum(candidate70_test_eval$y100_num),
      mean_classa_prop = mean(classa_prop),
      .groups = "drop"
    ) |>
    arrange(pred_p100_decile)

  list(
    fit_summary = holdout_fit_summary,
    deciles = holdout_deciles,
    candidate70_fit_summary = candidate70_fit_summary,
    candidate70_deciles = candidate70_deciles
  )
}

narrow_holdout_model_data <- model_data |>
  mutate(
    holdout_split = case_when(
      filing_year %in% c(2019L, 2020L) ~ "train_2019_2020",
      date_filed > as.Date("2020-12-31") & date_filed <= deadline_421a ~ "test_2021_2022h1",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(holdout_split))

expanded_holdout_model_data <- model_data |>
  mutate(
    holdout_split = case_when(
      date_filed >= as.Date("2010-01-01") & date_filed <= as.Date("2020-12-31") ~ "train_2010_2020",
      date_filed > as.Date("2020-12-31") & date_filed <= deadline_421a ~ "test_2021_2022h1",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(holdout_split))

narrow_holdout_outputs <- fit_holdout_window(
  narrow_holdout_model_data,
  "train_2019_2020",
  "test_2021_2022h1"
)

expanded_holdout_outputs <- fit_holdout_window(
  expanded_holdout_model_data,
  "train_2010_2020",
  "test_2021_2022h1"
)

fit_conditioned_holdout_window <- function(holdout_model_data, train_split, test_split, training_window, candidate_min_classa) {
  conditioned_data <- holdout_model_data |>
    filter(classa_prop >= candidate_min_classa)

  holdout_train <- conditioned_data |>
    filter(holdout_split == train_split)

  holdout_test <- conditioned_data |>
    filter(holdout_split == test_split)

  raw_train_rows <- nrow(holdout_train)
  raw_test_rows <- nrow(holdout_test)

  if (nrow(holdout_train) == 0 || nrow(holdout_test) == 0) {
    stop("Conditioned holdout samples must both be non-empty for ", training_window, " at ", candidate_min_classa, "+.")
  }

  categorical_features <- c("borough", "zone_detail", "prior_site_use")
  supported_test_rows <- rep(TRUE, nrow(holdout_test))

  for (feature_name in categorical_features) {
    train_levels <- sort(unique(as.character(holdout_train[[feature_name]])))
    supported_test_rows <- supported_test_rows & as.character(holdout_test[[feature_name]]) %in% train_levels
  }

  unsupported_test_category_rows <- sum(!supported_test_rows)
  holdout_test <- holdout_test[supported_test_rows, ]

  if (nrow(holdout_test) == 0) {
    stop("Conditioned test sample has no rows with supported training categories for ", training_window, " at ", candidate_min_classa, "+.")
  }

  for (feature_name in categorical_features) {
    train_levels <- sort(unique(as.character(holdout_train[[feature_name]])))

    holdout_train[[feature_name]] <- factor(as.character(holdout_train[[feature_name]]), levels = train_levels)
    holdout_test[[feature_name]] <- factor(as.character(holdout_test[[feature_name]]), levels = train_levels)

    if (feature_name == "borough" && "Brooklyn" %in% train_levels) {
      holdout_train[[feature_name]] <- relevel(holdout_train[[feature_name]], ref = "Brooklyn")
      holdout_test[[feature_name]] <- relevel(holdout_test[[feature_name]], ref = "Brooklyn")
    }

    if (feature_name == "zone_detail" && "R6" %in% train_levels) {
      holdout_train[[feature_name]] <- relevel(holdout_train[[feature_name]], ref = "R6")
      holdout_test[[feature_name]] <- relevel(holdout_test[[feature_name]], ref = "R6")
    }

    if (feature_name == "prior_site_use" && "existing_residential_units" %in% train_levels) {
      holdout_train[[feature_name]] <- relevel(holdout_train[[feature_name]], ref = "existing_residential_units")
      holdout_test[[feature_name]] <- relevel(holdout_test[[feature_name]], ref = "existing_residential_units")
    }

    if (length(unique(as.character(holdout_train[[feature_name]]))) < 2L) {
      stop("Conditioned training sample has fewer than two observed levels for ", feature_name, " at ", candidate_min_classa, "+.")
    }
  }

  if (sum(holdout_train$y100_num) == 0 || sum(holdout_train$y100_num == 0) == 0) {
    stop("Conditioned training sample must contain both y100 and non-y100 rows for ", training_window, " at ", candidate_min_classa, "+.")
  }

  if (sum(holdout_test$y100_num) == 0 || sum(holdout_test$y100_num == 0) == 0) {
    stop("Conditioned test sample must contain both y100 and non-y100 rows for ", training_window, " at ", candidate_min_classa, "+.")
  }

  for (feature_name in numeric_features) {
    train_values <- holdout_train[[feature_name]]
    feature_mean <- mean(train_values)
    feature_sd <- sd(train_values)

    if (is.na(feature_sd) || feature_sd == 0) {
      stop("Conditioned training feature has zero or missing standard deviation: ", feature_name)
    }

    holdout_train[[paste0("z_", feature_name)]] <- (holdout_train[[feature_name]] - feature_mean) / feature_sd
    holdout_test[[paste0("z_", feature_name)]] <- (holdout_test[[feature_name]] - feature_mean) / feature_sd
  }

  conditioned_logit_model <- glm(model_formula, data = holdout_train, family = binomial())
  conditioned_log_units_model <- lm(update(model_formula, log_units ~ .), data = holdout_train)
  conditioned_units_model <- lm(update(model_formula, classa_prop ~ .), data = holdout_train)

  holdout_train_eval <- holdout_train |>
    mutate(
      pred_p100 = predict(conditioned_logit_model, newdata = holdout_train, type = "response"),
      pred_log_units = predict(conditioned_log_units_model, newdata = holdout_train),
      pred_units = predict(conditioned_units_model, newdata = holdout_train)
    )

  holdout_test_eval <- holdout_test |>
    mutate(
      pred_p100 = predict(conditioned_logit_model, newdata = holdout_test, type = "response"),
      pred_log_units = predict(conditioned_log_units_model, newdata = holdout_test),
      pred_units = predict(conditioned_units_model, newdata = holdout_test)
    )

  fit_summary <- bind_rows(
    tibble(
      split = train_split,
      model = "sample_support",
      rows = nrow(holdout_train),
      outcome = "classa_prop",
      outcome_mean = mean(holdout_train$classa_prop),
      metric = "raw_rows",
      value = raw_train_rows
    ),
    tibble(
      split = test_split,
      model = "sample_support",
      rows = nrow(holdout_test),
      outcome = "classa_prop",
      outcome_mean = mean(holdout_test$classa_prop),
      metric = "raw_rows",
      value = raw_test_rows
    ),
    tibble(
      split = test_split,
      model = "sample_support",
      rows = nrow(holdout_test),
      outcome = "classa_prop",
      outcome_mean = mean(holdout_test$classa_prop),
      metric = "unsupported_test_category_rows",
      value = unsupported_test_category_rows
    ),
    binary_holdout_metrics(train_split, holdout_train_eval),
    binary_holdout_metrics(test_split, holdout_test_eval),
    continuous_holdout_metrics(
      train_split,
      holdout_train_eval,
      "ols_log_units",
      "log_classa_prop",
      holdout_train_eval$log_units,
      holdout_train_eval$pred_log_units,
      mean(holdout_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      test_split,
      holdout_test_eval,
      "ols_log_units",
      "log_classa_prop",
      holdout_test_eval$log_units,
      holdout_test_eval$pred_log_units,
      mean(holdout_train_eval$log_units)
    ),
    continuous_holdout_metrics(
      train_split,
      holdout_train_eval,
      "ols_units",
      "classa_prop",
      holdout_train_eval$classa_prop,
      holdout_train_eval$pred_units,
      mean(holdout_train_eval$classa_prop)
    ),
    continuous_holdout_metrics(
      test_split,
      holdout_test_eval,
      "ols_units",
      "classa_prop",
      holdout_test_eval$classa_prop,
      holdout_test_eval$pred_units,
      mean(holdout_train_eval$classa_prop)
    )
  ) |>
    mutate(
      training_window = training_window,
      candidate_min_classa_prop = candidate_min_classa,
      .before = split
    )

  deciles <- holdout_test_eval |>
    mutate(pred_p100_decile = ntile(pred_p100, 10L)) |>
    group_by(pred_p100_decile) |>
    summarise(
      training_window = training_window,
      candidate_min_classa_prop = candidate_min_classa,
      split = test_split,
      rows = n(),
      y100_rows = sum(y100_num),
      y100_share = mean(y100_num),
      mean_pred_p100 = mean(pred_p100),
      min_pred_p100 = min(pred_p100),
      max_pred_p100 = max(pred_p100),
      capture_share = sum(y100_num) / sum(holdout_test_eval$y100_num),
      mean_classa_prop = mean(classa_prop),
      .groups = "drop"
    ) |>
    arrange(training_window, candidate_min_classa_prop, pred_p100_decile)

  list(fit_summary = fit_summary, deciles = deciles)
}

conditioned_holdout_rows <- list()

for (candidate_min_classa in conditioned_candidate_min_classa_props) {
  conditioned_holdout_rows[[length(conditioned_holdout_rows) + 1L]] <- fit_conditioned_holdout_window(
    narrow_holdout_model_data,
    "train_2019_2020",
    "test_2021_2022h1",
    "narrow_train_2019_2020",
    candidate_min_classa
  )

  conditioned_holdout_rows[[length(conditioned_holdout_rows) + 1L]] <- fit_conditioned_holdout_window(
    expanded_holdout_model_data,
    "train_2010_2020",
    "test_2021_2022h1",
    "expanded_train_2010_2020",
    candidate_min_classa
  )
}

conditioned_holdout_fit_summary <- bind_rows(lapply(conditioned_holdout_rows, function(output) output$fit_summary)) |>
  arrange(candidate_min_classa_prop, training_window, split, model, metric)

conditioned_holdout_deciles <- bind_rows(lapply(conditioned_holdout_rows, function(output) output$deciles)) |>
  arrange(candidate_min_classa_prop, training_window, pred_p100_decile)

write_csv_if_changed(logit_coefficients, "../output/basic_logit_coefficients.csv")
write_csv_if_changed(log_units_coefficients, "../output/basic_log_units_coefficients.csv")
write_csv_if_changed(units_coefficients, "../output/basic_units_coefficients.csv")
write_csv_if_changed(fit_summary, "../output/basic_regression_fit_summary.csv")
write_csv_if_changed(sample_by_year, "../output/basic_regression_sample_by_year.csv")
write_csv_if_changed(feature_summary, "../output/basic_regression_feature_summary.csv")
write_csv_if_changed(narrow_holdout_outputs$fit_summary, "../output/basic_holdout_fit_summary.csv")
write_csv_if_changed(narrow_holdout_outputs$deciles, "../output/basic_holdout_deciles.csv")
write_csv_if_changed(narrow_holdout_outputs$candidate70_fit_summary, "../output/basic_holdout_candidate70_fit_summary.csv")
write_csv_if_changed(narrow_holdout_outputs$candidate70_deciles, "../output/basic_holdout_candidate70_deciles.csv")
write_csv_if_changed(expanded_holdout_outputs$fit_summary, "../output/basic_expanded_holdout_fit_summary.csv")
write_csv_if_changed(expanded_holdout_outputs$deciles, "../output/basic_expanded_holdout_deciles.csv")
write_csv_if_changed(expanded_holdout_outputs$candidate70_fit_summary, "../output/basic_expanded_holdout_candidate70_fit_summary.csv")
write_csv_if_changed(expanded_holdout_outputs$candidate70_deciles, "../output/basic_expanded_holdout_candidate70_deciles.csv")
write_csv_if_changed(conditioned_holdout_fit_summary, "../output/basic_conditioned_holdout_fit_summary.csv")
write_csv_if_changed(conditioned_holdout_deciles, "../output/basic_conditioned_holdout_deciles.csv")
cat("Wrote basic HDB-MapPLUTO regression audit outputs to ../output\n")

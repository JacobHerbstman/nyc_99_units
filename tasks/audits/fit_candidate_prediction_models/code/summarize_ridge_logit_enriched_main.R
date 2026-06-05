# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_candidate_prediction_models/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(glmnet)
  library(Matrix)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

set.seed(20260604)

candidate_min_classa_prop <- 50L
train_start <- as.Date("2013-01-01")
train_end <- as.Date("2020-12-31")
test_start <- as.Date("2021-01-01")
test_end <- as.Date("2022-06-15")
min_category_rows <- 10L

log_positive <- function(x) {
  if_else(!is.na(x) & x > 0, log(x), NA_real_)
}

positive_ratio <- function(numerator, denominator) {
  if_else(!is.na(numerator) & !is.na(denominator) & denominator > 0, numerator / denominator, NA_real_)
}

rank_auc <- function(y_values, score_values) {
  positive_count <- sum(y_values == 1)
  negative_count <- sum(y_values == 0)

  if (positive_count == 0 || negative_count == 0) {
    return(NA_real_)
  }

  score_ranks <- rank(score_values, ties.method = "average")
  (sum(score_ranks[y_values == 1]) - positive_count * (positive_count + 1) / 2) / (positive_count * negative_count)
}

average_precision <- function(y_values, score_values) {
  positive_count <- sum(y_values == 1)

  if (positive_count == 0 || positive_count == length(y_values)) {
    return(NA_real_)
  }

  order_index <- order(score_values, decreasing = TRUE)
  y_sorted <- y_values[order_index]
  true_positive_count <- cumsum(y_sorted == 1)
  prediction_count <- seq_along(y_sorted)
  precision_at_positive <- true_positive_count[y_sorted == 1] / prediction_count[y_sorted == 1]
  mean(precision_at_positive)
}

safe_logit <- function(x) {
  x <- pmin(pmax(x, 1e-6), 1 - 1e-6)
  log(x / (1 - x))
}

safe_log_loss <- function(y_values, score_values) {
  score_values <- pmin(pmax(score_values, 1e-6), 1 - 1e-6)
  -mean(y_values * log(score_values) + (1 - y_values) * log(1 - score_values))
}

safe_capture_share <- function(y_values, selected_rows) {
  if (sum(y_values) == 0) {
    return(NA_real_)
  }

  sum(y_values[selected_rows]) / sum(y_values)
}

make_year_foldid <- function(filing_year) {
  year_fold <- match(filing_year, sort(unique(filing_year)))

  if (length(unique(year_fold)) >= 3L) {
    return(year_fold)
  }

  rep(seq_len(min(5L, length(filing_year))), length.out = length(filing_year))
}

prepare_design <- function(train_data, test_data, numeric_features, categorical_features, min_category_rows) {
  train_prepared <- train_data
  test_prepared <- test_data
  design_terms <- character()
  reference_rows <- list()

  for (feature_name in numeric_features) {
    missing_name <- paste0(feature_name, "_missing")
    scaled_name <- paste0("z_", feature_name)
    train_values <- train_prepared[[feature_name]]
    test_values <- test_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    test_prepared[[missing_name]] <- is.na(test_values)

    impute_value <- median(train_values, na.rm = TRUE)
    if (is.na(impute_value)) {
      impute_value <- 0
    }

    train_values[is.na(train_values)] <- impute_value
    test_values[is.na(test_values)] <- impute_value
    train_mean <- mean(train_values)
    train_sd <- sd(train_values)

    if (is.na(train_sd) || train_sd == 0) {
      train_sd <- 1
    }

    train_prepared[[scaled_name]] <- (train_values - train_mean) / train_sd
    test_prepared[[scaled_name]] <- (test_values - train_mean) / train_sd
    design_terms <- c(design_terms, scaled_name, missing_name)
  }

  for (feature_name in categorical_features) {
    train_values <- str_squish(as.character(train_prepared[[feature_name]]))
    test_values <- str_squish(as.character(test_prepared[[feature_name]]))
    train_values[is.na(train_values) | train_values == ""] <- "missing"
    test_values[is.na(test_values) | test_values == ""] <- "missing"
    train_counts <- sort(table(train_values), decreasing = TRUE)
    keep_levels <- names(train_counts)[train_counts >= min_category_rows]

    if (length(keep_levels) == 0) {
      keep_levels <- names(train_counts)[1]
    }

    train_values[!(train_values %in% keep_levels)] <- "other_rare"
    test_values[!(test_values %in% keep_levels)] <- "other_rare"
    factor_levels <- unique(c(sort(keep_levels), "other_rare"))
    train_prepared[[feature_name]] <- factor(train_values, levels = factor_levels)
    test_prepared[[feature_name]] <- factor(test_values, levels = factor_levels)
    design_terms <- c(design_terms, feature_name)

    reference_rows[[length(reference_rows) + 1L]] <- tibble(
      feature = feature_name,
      reference_level = factor_levels[1],
      levels_used = paste(factor_levels, collapse = "|"),
      train_distinct_levels_before_pooling = length(train_counts),
      train_levels_kept_before_other = length(keep_levels),
      min_category_rows = min_category_rows
    )
  }

  design_formula <- as.formula(paste("~", paste(design_terms, collapse = " + ")))
  train_matrix <- model.matrix(design_formula, train_prepared)
  test_matrix <- model.matrix(design_formula, test_prepared)
  colnames(train_matrix) <- make.names(colnames(train_matrix), unique = TRUE)
  colnames(test_matrix) <- make.names(colnames(test_matrix), unique = TRUE)

  list(
    train_data = train_prepared,
    test_data = test_prepared,
    train_matrix = Matrix(train_matrix[, colnames(train_matrix) != "(Intercept)", drop = FALSE], sparse = TRUE),
    test_matrix = Matrix(test_matrix[, colnames(test_matrix) != "(Intercept)", drop = FALSE], sparse = TRUE),
    reference_levels = bind_rows(reference_rows)
  )
}

summarize_split_metrics <- function(split_label, split_role, eval_data) {
  top_decile_cutoff <- quantile(eval_data$score_value, 0.90, names = FALSE, na.rm = TRUE)
  top_quartile_cutoff <- quantile(eval_data$score_value, 0.75, names = FALSE, na.rm = TRUE)
  top_decile_rows <- eval_data$score_value >= top_decile_cutoff
  top_quartile_rows <- eval_data$score_value >= top_quartile_cutoff

  calibration_intercept <- NA_real_
  calibration_slope <- NA_real_
  if (length(unique(eval_data$y100_num)) == 2L) {
    calibration_intercept <- suppressWarnings(coef(glm(
      y100_num ~ offset(safe_logit(score_value)),
      data = eval_data,
      family = binomial()
    ))[1])
    calibration_slope <- suppressWarnings(coef(glm(
      y100_num ~ safe_logit(score_value),
      data = eval_data,
      family = binomial()
    ))[2])
  }

  bind_rows(
    tibble(split = split_label, split_role = split_role, diagnostic = "rows", value = nrow(eval_data)),
    tibble(split = split_label, split_role = split_role, diagnostic = "y100_rows", value = sum(eval_data$y100_num)),
    tibble(split = split_label, split_role = split_role, diagnostic = "y100_share", value = mean(eval_data$y100_num)),
    tibble(split = split_label, split_role = split_role, diagnostic = "mean_score", value = mean(eval_data$score_value)),
    tibble(split = split_label, split_role = split_role, diagnostic = "mean_score_minus_y100_share", value = mean(eval_data$score_value) - mean(eval_data$y100_num)),
    tibble(split = split_label, split_role = split_role, diagnostic = "auc", value = rank_auc(eval_data$y100_num, eval_data$score_value)),
    tibble(split = split_label, split_role = split_role, diagnostic = "average_precision", value = average_precision(eval_data$y100_num, eval_data$score_value)),
    tibble(split = split_label, split_role = split_role, diagnostic = "brier_score", value = mean((eval_data$y100_num - eval_data$score_value)^2)),
    tibble(split = split_label, split_role = split_role, diagnostic = "log_loss", value = safe_log_loss(eval_data$y100_num, eval_data$score_value)),
    tibble(split = split_label, split_role = split_role, diagnostic = "top_decile_y100_share", value = mean(eval_data$y100_num[top_decile_rows])),
    tibble(split = split_label, split_role = split_role, diagnostic = "top_decile_capture_share", value = safe_capture_share(eval_data$y100_num, top_decile_rows)),
    tibble(split = split_label, split_role = split_role, diagnostic = "top_quartile_y100_share", value = mean(eval_data$y100_num[top_quartile_rows])),
    tibble(split = split_label, split_role = split_role, diagnostic = "top_quartile_capture_share", value = safe_capture_share(eval_data$y100_num, top_quartile_rows)),
    tibble(split = split_label, split_role = split_role, diagnostic = "calibration_intercept", value = calibration_intercept),
    tibble(split = split_label, split_role = split_role, diagnostic = "calibration_slope", value = calibration_slope),
    tibble(split = split_label, split_role = split_role, diagnostic = paste0("score_quantile_", c("00", "10", "25", "50", "75", "90", "100")), value = as.numeric(quantile(eval_data$score_value, c(0, 0.10, 0.25, 0.50, 0.75, 0.90, 1), names = FALSE, na.rm = TRUE))),
    tibble(split = split_label, split_role = split_role, diagnostic = "mean_classa_prop", value = mean(eval_data$classa_prop)),
    tibble(split = split_label, split_role = split_role, diagnostic = "median_classa_prop", value = median(eval_data$classa_prop))
  )
}

panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

model_rows <- panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    !is.na(y100),
    !is.na(classa_prop),
    classa_prop >= candidate_min_classa_prop,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  mutate(
    y100_num = as.integer(y100),
    log_lotarea = log(lotarea),
    log_allowed_res_area = log_positive(allowed_res_area),
    log_residual_res_area = log_positive(residual_res_area),
    residual_res_share = positive_ratio(residual_res_area, allowed_res_area),
    log_bldgarea = log_positive(bldgarea),
    log_resarea = log_positive(resarea),
    log_comarea = log_positive(comarea),
    log_unitsres = log_positive(unitsres),
    log_unitstotal = log_positive(unitstotal),
    log_assessland = log_positive(assessland),
    log_assesstot = log_positive(assesstot),
    log_assessland_per_allowed_res_area = log_positive(positive_ratio(assessland, allowed_res_area)),
    assessland_share = positive_ratio(assessland, assesstot),
    effective_age = if_else(!is.na(yearbuilt) & yearbuilt > 1800 & yearbuilt <= filing_year, as.numeric(filing_year - yearbuilt), NA_real_),
    zonedist1_clean = str_to_upper(str_squish(zonedist1)),
    zone_base = str_extract(zonedist1_clean, "^[RCM][0-9]+"),
    zone_base = if_else(is.na(zone_base) | zone_base == "", "missing", zone_base),
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
    landuse_code = if_else(is.na(landuse_code) | landuse_code == "", "missing", landuse_code),
    bldgclass_family = str_sub(str_to_upper(str_squish(as.character(bldgclass))), 1L, 1L),
    bldgclass_family = if_else(is.na(bldgclass_family) | bldgclass_family == "", "missing", bldgclass_family),
    prior_site_use = case_when(
      !is.na(unitsres) & unitsres > 0 ~ "existing_residential_units",
      landuse_code == "11" ~ "vacant_land",
      landuse_code == "10" ~ "parking",
      landuse_code %in% c("05", "06") ~ "commercial_industrial",
      landuse_code == "04" ~ "mixed_res_commercial",
      landuse_code %in% c("07", "08") ~ "public_transport_utility",
      landuse_code == "missing" ~ "missing_landuse",
      TRUE ~ "other_no_res_units"
    ),
    borough = hdb_borough_name,
    community_district = as.character(hdb_community_district),
    council_district = as.character(hdb_council_district),
    zipcode_group = as.character(zipcode),
    has_overlay = if_else(!is.na(overlay1) | !is.na(overlay2), "yes", "no"),
    has_special_district = if_else(!is.na(spdist1) | !is.na(spdist2) | !is.na(spdist3), "yes", "no"),
    splitzone_flag = if_else(str_to_upper(str_squish(as.character(splitzone))) %in% c("Y", "YES", "1", "TRUE"), "yes", "no"),
    ltdheight_flag = if_else(!is.na(ltdheight) & str_squish(as.character(ltdheight)) != "", "yes", "no"),
    histdist_flag = if_else(!is.na(histdist) & str_squish(as.character(histdist)) != "", "yes", "no"),
    landmark_flag = if_else(!is.na(landmark) & str_squish(as.character(landmark)) != "", "yes", "no"),
    firm07_flag = if_else(str_to_upper(str_squish(as.character(firm07_flag))) %in% c("1", "Y", "YES", "TRUE"), "yes", "no"),
    pfirm15_flag = if_else(str_to_upper(str_squish(as.character(pfirm15_flag))) %in% c("1", "Y", "YES", "TRUE"), "yes", "no")
  )

train_data <- model_rows |>
  filter(date_filed >= train_start, date_filed <= train_end)

test_data <- model_rows |>
  filter(date_filed >= test_start, date_filed <= test_end)

enriched_numeric_features <- c(
  "log_lotarea", "log_allowed_res_area", "log_residual_res_area", "residual_res_share",
  "residfar", "commfar", "facilfar", "builtfar",
  "log_bldgarea", "log_resarea", "log_comarea", "log_unitsres", "log_unitstotal",
  "numbldgs", "numfloors", "effective_age",
  "log_assessland", "log_assesstot", "log_assessland_per_allowed_res_area", "assessland_share"
)

enriched_categorical_features <- c(
  "borough", "community_district", "council_district",
  "zone_detail", "zone_base", "landuse_code", "bldgclass_family", "prior_site_use",
  "has_overlay", "has_special_district", "splitzone_flag", "ltdheight_flag",
  "histdist_flag", "landmark_flag", "firm07_flag", "pfirm15_flag"
)

design <- prepare_design(train_data, test_data, enriched_numeric_features, enriched_categorical_features, min_category_rows)

ridge_fit <- cv.glmnet(
  x = design$train_matrix,
  y = train_data$y100_num,
  family = "binomial",
  alpha = 0,
  foldid = make_year_foldid(train_data$filing_year),
  type.measure = "deviance"
)

train_eval <- train_data |>
  mutate(
    score_value = as.numeric(predict(ridge_fit, newx = design$train_matrix, s = "lambda.1se", type = "response"))
  )

test_eval <- test_data |>
  mutate(
    score_value = as.numeric(predict(ridge_fit, newx = design$test_matrix, s = "lambda.1se", type = "response"))
  )

coefficient_matrix <- as.matrix(coef(ridge_fit, s = "lambda.1se"))
coefficient_rows <- tibble(
  term = rownames(coefficient_matrix),
  estimate_log_odds = as.numeric(coefficient_matrix[, 1])
) |>
  mutate(
    term_type = case_when(
      term == "(Intercept)" ~ "intercept",
      str_starts(term, "z_") ~ "numeric_standardized",
      str_ends(term, "_missingTRUE") ~ "numeric_missing_indicator",
      TRUE ~ "categorical_indicator"
    ),
    feature = case_when(
      term == "(Intercept)" ~ "intercept",
      str_starts(term, "z_") ~ str_remove(term, "^z_"),
      str_ends(term, "_missingTRUE") ~ str_remove(term, "_missingTRUE$"),
      TRUE ~ NA_character_
    )
  )

for (feature_name in enriched_categorical_features) {
  coefficient_rows$feature[
    is.na(coefficient_rows$feature) &
      str_starts(coefficient_rows$term, make.names(feature_name))
  ] <- feature_name
}

coefficient_rows <- coefficient_rows |>
  mutate(
    level = case_when(
      term_type == "categorical_indicator" & !is.na(feature) ~ str_remove(term, paste0("^", make.names(feature))),
      term_type == "numeric_missing_indicator" ~ "TRUE",
      TRUE ~ NA_character_
    )
  ) |>
  left_join(
    design$reference_levels |> select(feature, reference_level),
    by = "feature",
    relationship = "many-to-one"
  ) |>
  mutate(
    odds_ratio = exp(estimate_log_odds),
    abs_estimate_log_odds = abs(estimate_log_odds),
    coefficient_rank_by_abs_value = rank(-abs_estimate_log_odds, ties.method = "first"),
    candidate_min_classa_prop = candidate_min_classa_prop,
    train_start = train_start,
    train_end = train_end,
    test_start = test_start,
    test_end = test_end,
    lambda_used = ridge_fit$lambda.1se,
    note = case_when(
      term_type == "numeric_standardized" ~ "Numeric coefficient is per one training-sample standard deviation after median imputation.",
      term_type == "numeric_missing_indicator" ~ "Missing indicator is relative to observed values after paired numeric imputation.",
      term_type == "categorical_indicator" ~ "Categorical coefficient is relative to the listed reference level after rare-level pooling.",
      TRUE ~ "Intercept."
    )
  ) |>
  arrange(coefficient_rank_by_abs_value) |>
  select(
    candidate_min_classa_prop, train_start, train_end, test_start, test_end, lambda_used,
    term, term_type, feature, level, reference_level,
    estimate_log_odds, odds_ratio, abs_estimate_log_odds, coefficient_rank_by_abs_value, note
  )

diagnostics <- bind_rows(
  tibble(split = "model", split_role = "model", diagnostic = "candidate_min_classa_prop", value = candidate_min_classa_prop),
  tibble(split = "model", split_role = "model", diagnostic = "train_start", value = as.numeric(train_start)),
  tibble(split = "model", split_role = "model", diagnostic = "train_end", value = as.numeric(train_end)),
  tibble(split = "model", split_role = "model", diagnostic = "test_start", value = as.numeric(test_start)),
  tibble(split = "model", split_role = "model", diagnostic = "test_end", value = as.numeric(test_end)),
  tibble(split = "model", split_role = "model", diagnostic = "lambda_min", value = ridge_fit$lambda.min),
  tibble(split = "model", split_role = "model", diagnostic = "lambda_1se", value = ridge_fit$lambda.1se),
  tibble(split = "model", split_role = "model", diagnostic = "cv_min_deviance", value = min(ridge_fit$cvm)),
  tibble(split = "model", split_role = "model", diagnostic = "cv_1se_deviance", value = ridge_fit$cvm[which(ridge_fit$lambda == ridge_fit$lambda.1se)[1]]),
  tibble(split = "model", split_role = "model", diagnostic = "coefficient_rows_including_intercept", value = nrow(coefficient_rows)),
  tibble(split = "model", split_role = "model", diagnostic = "nonzero_coefficients_excluding_intercept", value = sum(coefficient_rows$term != "(Intercept)" & coefficient_rows$estimate_log_odds != 0)),
  summarize_split_metrics("train_2013_2020", "train", train_eval),
  summarize_split_metrics("test_2021_2022h1", "test", test_eval)
) |>
  mutate(
    model = "ridge_logit_enriched",
    feature_layer = "enriched",
    outcome = "y100",
    candidate_min_classa_prop = candidate_min_classa_prop,
    note = case_when(
      diagnostic %in% c("train_start", "train_end", "test_start", "test_end") ~ "Date is stored as R Date numeric days since 1970-01-01.",
      diagnostic %in% c("calibration_intercept", "calibration_slope") ~ "Calibration diagnostic only; it is not a recalibration step.",
      TRUE ~ NA_character_
    ),
    .before = split
  )

deciles <- bind_rows(
  train_eval |> mutate(split = "train_2013_2020", split_role = "train"),
  test_eval |> mutate(split = "test_2021_2022h1", split_role = "test")
) |>
  group_by(split, split_role) |>
  mutate(score_decile = ntile(score_value, 10L)) |>
  group_by(split, split_role, score_decile) |>
  summarise(
    model = "ridge_logit_enriched",
    feature_layer = "enriched",
    outcome = "y100",
    candidate_min_classa_prop = candidate_min_classa_prop,
    rows = n(),
    y100_rows = sum(y100_num),
    y100_share = mean(y100_num),
    mean_score = mean(score_value),
    min_score = min(score_value),
    max_score = max(score_value),
    mean_classa_prop = mean(classa_prop),
    median_classa_prop = median(classa_prop),
    share_exactly_99 = mean(classa_prop == 99),
    .groups = "drop"
  ) |>
  arrange(split_role, score_decile)

cv_path <- tibble(
  model = "ridge_logit_enriched",
  feature_layer = "enriched",
  outcome = "y100",
  candidate_min_classa_prop = candidate_min_classa_prop,
  lambda = ridge_fit$lambda,
  mean_cv_deviance = ridge_fit$cvm,
  se_cv_deviance = ridge_fit$cvsd,
  upper_cv_deviance = ridge_fit$cvup,
  lower_cv_deviance = ridge_fit$cvlo,
  nonzero_coefficients = ridge_fit$nzero,
  is_lambda_min = lambda == ridge_fit$lambda.min,
  is_lambda_1se = lambda == ridge_fit$lambda.1se
)

reference_levels <- design$reference_levels |>
  mutate(
    model = "ridge_logit_enriched",
    feature_layer = "enriched",
    outcome = "y100",
    candidate_min_classa_prop = candidate_min_classa_prop,
    .before = feature
  )

write_csv_if_changed(coefficient_rows, "../output/ridge_logit_enriched_main_coefficients.csv")
write_csv_if_changed(diagnostics, "../output/ridge_logit_enriched_main_diagnostics.csv")
write_csv_if_changed(deciles, "../output/ridge_logit_enriched_main_deciles.csv")
write_csv_if_changed(cv_path, "../output/ridge_logit_enriched_main_cv_path.csv")
write_csv_if_changed(reference_levels, "../output/ridge_logit_enriched_main_reference_levels.csv")
cat("Wrote ridge logit enriched main-model diagnostics to ../output\n")

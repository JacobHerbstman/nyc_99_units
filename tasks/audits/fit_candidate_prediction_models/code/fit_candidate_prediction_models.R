# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fit_candidate_prediction_models/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(glmnet)
  library(Matrix)
  library(nnet)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

set.seed(20260604)

deadline_421a <- as.Date("2022-06-15")
candidate_min_classa_props <- c(50L, 60L, 70L)
size_bin_levels <- c("50_69", "70_99", "100_149", "150_plus")

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

safe_capture_share <- function(y_values, selected_rows) {
  if (sum(y_values) == 0) {
    return(NA_real_)
  }

  sum(y_values[selected_rows]) / sum(y_values)
}

binary_metrics <- function(window_name, candidate_min_classa, model_name, feature_layer, split_label, split_role, score_kind, eval_data) {
  top_decile_cutoff <- quantile(eval_data$score_value, 0.90, names = FALSE, na.rm = TRUE)
  top_quartile_cutoff <- quantile(eval_data$score_value, 0.75, names = FALSE, na.rm = TRUE)
  top_decile_rows <- eval_data$score_value >= top_decile_cutoff
  top_quartile_rows <- eval_data$score_value >= top_quartile_cutoff

  bind_rows(
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "auc",
      value = rank_auc(eval_data$y100_num, eval_data$score_value)
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "average_precision",
      value = average_precision(eval_data$y100_num, eval_data$score_value)
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "brier_score",
      value = if (score_kind == "probability") mean((eval_data$y100_num - eval_data$score_value)^2) else NA_real_
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "top_decile_y100_share",
      value = mean(eval_data$y100_num[top_decile_rows])
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "top_decile_capture_share",
      value = safe_capture_share(eval_data$y100_num, top_decile_rows)
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "top_quartile_y100_share",
      value = mean(eval_data$y100_num[top_quartile_rows])
    ),
    tibble(
      window = window_name,
      candidate_min_classa_prop = candidate_min_classa,
      model = model_name,
      feature_layer = feature_layer,
      split = split_label,
      split_role = split_role,
      rows = nrow(eval_data),
      outcome = "y100",
      outcome_mean = mean(eval_data$y100_num),
      metric = "top_quartile_capture_share",
      value = safe_capture_share(eval_data$y100_num, top_quartile_rows)
    )
  )
}

continuous_metrics <- function(window_name, candidate_min_classa, model_name, feature_layer, split_label, split_role, eval_data, baseline_mean) {
  tibble(
    window = window_name,
    candidate_min_classa_prop = candidate_min_classa,
    model = model_name,
    feature_layer = feature_layer,
    split = split_label,
    split_role = split_role,
    rows = nrow(eval_data),
    outcome = "log_classa_prop",
    outcome_mean = mean(eval_data$log_units),
    metric = c("rmse", "mean_absolute_error", "r_squared_against_train_mean"),
    value = c(
      sqrt(mean((eval_data$log_units - eval_data$pred_log_units)^2)),
      mean(abs(eval_data$log_units - eval_data$pred_log_units)),
      1 - sum((eval_data$log_units - eval_data$pred_log_units)^2) / sum((eval_data$log_units - baseline_mean)^2)
    )
  )
}

score_bin_summary <- function(window_name, candidate_min_classa, model_name, feature_layer, split_label, split_role, score_kind, eval_data) {
  bind_rows(lapply(c(10L, 5L), function(score_bin_count) {
    eval_data |>
      mutate(score_bin = ntile(score_value, score_bin_count)) |>
      group_by(score_bin) |>
      summarise(
        window = window_name,
        candidate_min_classa_prop = candidate_min_classa,
        model = model_name,
        feature_layer = feature_layer,
        split = split_label,
        split_role = split_role,
        score_kind = score_kind,
        score_bin_count = score_bin_count,
        rows = n(),
        y100_rows = sum(y100_num),
        y100_share = mean(y100_num),
        mean_score = mean(score_value),
        min_score = min(score_value),
        max_score = max(score_value),
        capture_share = sum(y100_num) / sum(eval_data$y100_num),
        mean_classa_prop = mean(classa_prop),
        median_classa_prop = median(classa_prop),
        share_exactly_99 = mean(classa_prop == 99),
        .groups = "drop"
      )
  })) |>
    arrange(score_bin_count, score_bin)
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
    test_matrix = Matrix(test_matrix[, colnames(test_matrix) != "(Intercept)", drop = FALSE], sparse = TRUE)
  )
}

fit_glm_score <- function(train_matrix, test_matrix, train_y) {
  train_frame <- as.data.frame(as.matrix(train_matrix))
  test_frame <- as.data.frame(as.matrix(test_matrix))
  train_frame$y100_num <- train_y
  glm_fit <- glm(y100_num ~ ., data = train_frame, family = binomial())

  list(
    train_score = as.numeric(predict(glm_fit, newdata = train_frame, type = "response")),
    test_score = as.numeric(predict(glm_fit, newdata = test_frame, type = "response"))
  )
}

fit_glmnet_binary_score <- function(train_matrix, test_matrix, train_y, filing_year, alpha_value) {
  cv_fit <- cv.glmnet(
    x = train_matrix,
    y = train_y,
    family = "binomial",
    alpha = alpha_value,
    foldid = make_year_foldid(filing_year),
    type.measure = "deviance"
  )

  list(
    train_score = as.numeric(predict(cv_fit, newx = train_matrix, s = "lambda.1se", type = "response")),
    test_score = as.numeric(predict(cv_fit, newx = test_matrix, s = "lambda.1se", type = "response")),
    lambda_1se = cv_fit$lambda.1se
  )
}

fit_decay_multinomial_score <- function(train_matrix, test_matrix, train_bin) {
  train_frame <- as.data.frame(as.matrix(train_matrix))
  test_frame <- as.data.frame(as.matrix(test_matrix))
  train_frame$size_bin <- droplevels(train_bin)
  multinomial_fit <- multinom(size_bin ~ ., data = train_frame, decay = 1, trace = FALSE, maxit = 1000)

  train_probability <- predict(multinomial_fit, newdata = train_frame, type = "probs")
  test_probability <- predict(multinomial_fit, newdata = test_frame, type = "probs")

  if (is.vector(train_probability)) {
    train_probability <- matrix(train_probability, ncol = 1)
    colnames(train_probability) <- levels(train_frame$size_bin)[1]
  }

  if (is.vector(test_probability)) {
    test_probability <- matrix(test_probability, ncol = 1)
    colnames(test_probability) <- levels(train_frame$size_bin)[1]
  }

  train_positive_columns <- intersect(colnames(train_probability), c("100_149", "150_plus"))
  test_positive_columns <- intersect(colnames(test_probability), c("100_149", "150_plus"))

  list(
    train_score = rowSums(train_probability[, train_positive_columns, drop = FALSE]),
    test_score = rowSums(test_probability[, test_positive_columns, drop = FALSE]),
    decay = 1
  )
}

fit_glmnet_log_units <- function(train_matrix, test_matrix, train_y, filing_year) {
  cv_fit <- cv.glmnet(
    x = train_matrix,
    y = train_y,
    family = "gaussian",
    alpha = 0,
    foldid = make_year_foldid(filing_year),
    type.measure = "mse"
  )

  list(
    train_prediction = as.numeric(predict(cv_fit, newx = train_matrix, s = "lambda.1se")),
    test_prediction = as.numeric(predict(cv_fit, newx = test_matrix, s = "lambda.1se")),
    lambda_1se = cv_fit$lambda.1se
  )
}

append_binary_outputs <- function(output_list, window_name, candidate_min_classa, model_name, feature_layer, train_label, test_label, score_kind, train_eval, test_eval) {
  output_list$fit_summary[[length(output_list$fit_summary) + 1L]] <- bind_rows(
    binary_metrics(window_name, candidate_min_classa, model_name, feature_layer, train_label, "train", score_kind, train_eval),
    binary_metrics(window_name, candidate_min_classa, model_name, feature_layer, test_label, "test", score_kind, test_eval)
  )

  output_list$deciles[[length(output_list$deciles) + 1L]] <- bind_rows(
    score_bin_summary(window_name, candidate_min_classa, model_name, feature_layer, train_label, "train", score_kind, train_eval),
    score_bin_summary(window_name, candidate_min_classa, model_name, feature_layer, test_label, "test", score_kind, test_eval)
  )

  output_list$predictions[[length(output_list$predictions) + 1L]] <- bind_rows(
    train_eval |>
      transmute(window = window_name, candidate_min_classa_prop = candidate_min_classa, model = model_name, feature_layer = feature_layer, split = train_label, split_role = "train", job_number, date_filed, classa_prop, y100_num, score_kind = score_kind, score_value),
    test_eval |>
      transmute(window = window_name, candidate_min_classa_prop = candidate_min_classa, model = model_name, feature_layer = feature_layer, split = test_label, split_role = "test", job_number, date_filed, classa_prop, y100_num, score_kind = score_kind, score_value)
  )

  output_list
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
    classa_prop >= min(candidate_min_classa_props),
    !is.na(lotarea),
    lotarea > 0
  ) |>
  mutate(
    y100_num = as.integer(y100),
    log_units = log(classa_prop),
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
    pfirm15_flag = if_else(str_to_upper(str_squish(as.character(pfirm15_flag))) %in% c("1", "Y", "YES", "TRUE"), "yes", "no"),
    size_bin = case_when(
      classa_prop < 70 ~ "50_69",
      classa_prop < 100 ~ "70_99",
      classa_prop < 150 ~ "100_149",
      TRUE ~ "150_plus"
    ),
    size_bin = factor(size_bin, levels = size_bin_levels)
  )

if (nrow(model_rows) == 0) {
  stop("Candidate model sample is empty.")
}

simple_numeric_features <- c("log_lotarea", "residfar", "builtfar")
simple_categorical_features <- c("borough", "zone_detail", "prior_site_use")

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

window_specs <- list(
  list(
    window = "pre_2018_to_2018_2020",
    train_label = "train_pre_2018",
    test_label = "test_2018_2020",
    train_start = as.Date("2010-01-01"),
    train_end = as.Date("2017-12-31"),
    test_start = as.Date("2018-01-01"),
    test_end = as.Date("2020-12-31"),
    transport_window = FALSE
  ),
  list(
    window = "pre_2021_to_2021_2022h1",
    train_label = "train_2013_2020",
    test_label = "test_2021_2022h1",
    train_start = as.Date("2013-01-01"),
    train_end = as.Date("2020-12-31"),
    test_start = as.Date("2021-01-01"),
    test_end = deadline_421a,
    transport_window = FALSE
  ),
  list(
    window = "pre_2021_to_post_2022_06_15",
    train_label = "train_2013_2020",
    test_label = "post_2022_06_15_regime_shift",
    train_start = as.Date("2013-01-01"),
    train_end = as.Date("2020-12-31"),
    test_start = deadline_421a + 1L,
    test_end = as.Date("2023-12-31"),
    transport_window = TRUE
  )
)

fit_summary_rows <- list()
decile_rows <- list()
prediction_rows <- list()
sample_summary_rows <- list()
size_bin_count_rows <- list()
feature_missingness_rows <- list()

for (candidate_min_classa in candidate_min_classa_props) {
  for (window_spec in window_specs) {
    candidate_rows <- model_rows |>
      filter(classa_prop >= candidate_min_classa)

    train_data <- candidate_rows |>
      filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)

    test_data <- candidate_rows |>
      filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

    if (nrow(train_data) == 0 || nrow(test_data) == 0) {
      stop("Candidate model window has an empty train or test sample: ", window_spec$window, " at ", candidate_min_classa, "+.")
    }

    if (sum(train_data$y100_num) == 0 || sum(train_data$y100_num == 0) == 0 ||
        sum(test_data$y100_num) == 0 || sum(test_data$y100_num == 0) == 0) {
      stop("Candidate model window lacks both y100 classes: ", window_spec$window, " at ", candidate_min_classa, "+.")
    }

    sample_summary_rows[[length(sample_summary_rows) + 1L]] <- bind_rows(
      tibble(
        window = window_spec$window,
        candidate_min_classa_prop = candidate_min_classa,
        split = window_spec$train_label,
        split_role = "train",
        transport_window = window_spec$transport_window,
        rows = nrow(train_data),
        y100_rows = sum(train_data$y100_num),
        y100_share = mean(train_data$y100_num),
        mean_classa_prop = mean(train_data$classa_prop),
        median_classa_prop = median(train_data$classa_prop)
      ),
      tibble(
        window = window_spec$window,
        candidate_min_classa_prop = candidate_min_classa,
        split = window_spec$test_label,
        split_role = "test",
        transport_window = window_spec$transport_window,
        rows = nrow(test_data),
        y100_rows = sum(test_data$y100_num),
        y100_share = mean(test_data$y100_num),
        mean_classa_prop = mean(test_data$classa_prop),
        median_classa_prop = median(test_data$classa_prop)
      )
    )

    size_bin_count_rows[[length(size_bin_count_rows) + 1L]] <- bind_rows(
      train_data |>
        count(size_bin, .drop = FALSE, name = "rows") |>
        mutate(
          window = window_spec$window,
          candidate_min_classa_prop = candidate_min_classa,
          split = window_spec$train_label,
          split_role = "train",
          transport_window = window_spec$transport_window,
          .before = size_bin
        ),
      test_data |>
        count(size_bin, .drop = FALSE, name = "rows") |>
        mutate(
          window = window_spec$window,
          candidate_min_classa_prop = candidate_min_classa,
          split = window_spec$test_label,
          split_role = "test",
          transport_window = window_spec$transport_window,
          .before = size_bin
        )
    )

    for (feature_name in unique(c(simple_numeric_features, enriched_numeric_features))) {
      feature_missingness_rows[[length(feature_missingness_rows) + 1L]] <- bind_rows(
        tibble(
          window = window_spec$window,
          candidate_min_classa_prop = candidate_min_classa,
          split = window_spec$train_label,
          split_role = "train",
          feature = feature_name,
          rows = nrow(train_data),
          missing_rows = sum(is.na(train_data[[feature_name]])),
          missing_share = mean(is.na(train_data[[feature_name]]))
        ),
        tibble(
          window = window_spec$window,
          candidate_min_classa_prop = candidate_min_classa,
          split = window_spec$test_label,
          split_role = "test",
          feature = feature_name,
          rows = nrow(test_data),
          missing_rows = sum(is.na(test_data[[feature_name]])),
          missing_share = mean(is.na(test_data[[feature_name]]))
        )
      )
    }

    simple_design <- prepare_design(train_data, test_data, simple_numeric_features, simple_categorical_features, 10L)
    enriched_design <- prepare_design(train_data, test_data, enriched_numeric_features, enriched_categorical_features, 10L)

    simple_glm_score <- fit_glm_score(simple_design$train_matrix, simple_design$test_matrix, train_data$y100_num)
    train_eval <- train_data |> mutate(score_value = simple_glm_score$train_score)
    test_eval <- test_data |> mutate(score_value = simple_glm_score$test_score)
    model_output <- append_binary_outputs(
      list(fit_summary = fit_summary_rows, deciles = decile_rows, predictions = prediction_rows),
      window_spec$window,
      candidate_min_classa,
      "ordinary_logit_simple",
      "simple",
      window_spec$train_label,
      window_spec$test_label,
      "probability",
      train_eval,
      test_eval
    )
    fit_summary_rows <- model_output$fit_summary
    decile_rows <- model_output$deciles
    prediction_rows <- model_output$predictions

    enriched_glm_score <- fit_glm_score(enriched_design$train_matrix, enriched_design$test_matrix, train_data$y100_num)
    train_eval <- train_data |> mutate(score_value = enriched_glm_score$train_score)
    test_eval <- test_data |> mutate(score_value = enriched_glm_score$test_score)
    model_output <- append_binary_outputs(
      list(fit_summary = fit_summary_rows, deciles = decile_rows, predictions = prediction_rows),
      window_spec$window,
      candidate_min_classa,
      "ordinary_logit_enriched",
      "enriched",
      window_spec$train_label,
      window_spec$test_label,
      "probability",
      train_eval,
      test_eval
    )
    fit_summary_rows <- model_output$fit_summary
    decile_rows <- model_output$deciles
    prediction_rows <- model_output$predictions

    ridge_score <- fit_glmnet_binary_score(enriched_design$train_matrix, enriched_design$test_matrix, train_data$y100_num, train_data$filing_year, 0)
    train_eval <- train_data |> mutate(score_value = ridge_score$train_score)
    test_eval <- test_data |> mutate(score_value = ridge_score$test_score)
    model_output <- append_binary_outputs(
      list(fit_summary = fit_summary_rows, deciles = decile_rows, predictions = prediction_rows),
      window_spec$window,
      candidate_min_classa,
      "ridge_logit_enriched",
      "enriched",
      window_spec$train_label,
      window_spec$test_label,
      "probability",
      train_eval,
      test_eval
    )
    fit_summary_rows <- model_output$fit_summary
    decile_rows <- model_output$deciles
    prediction_rows <- model_output$predictions
    fit_summary_rows[[length(fit_summary_rows) + 1L]] <- tibble(
      window = window_spec$window,
      candidate_min_classa_prop = candidate_min_classa,
      model = "ridge_logit_enriched",
      feature_layer = "enriched",
      split = window_spec$train_label,
      split_role = "train",
      rows = nrow(train_data),
      outcome = "y100",
      outcome_mean = mean(train_data$y100_num),
      metric = "lambda_1se",
      value = ridge_score$lambda_1se
    )

    elastic_score <- fit_glmnet_binary_score(enriched_design$train_matrix, enriched_design$test_matrix, train_data$y100_num, train_data$filing_year, 0.5)
    train_eval <- train_data |> mutate(score_value = elastic_score$train_score)
    test_eval <- test_data |> mutate(score_value = elastic_score$test_score)
    model_output <- append_binary_outputs(
      list(fit_summary = fit_summary_rows, deciles = decile_rows, predictions = prediction_rows),
      window_spec$window,
      candidate_min_classa,
      "elastic_net_logit_enriched",
      "enriched",
      window_spec$train_label,
      window_spec$test_label,
      "probability",
      train_eval,
      test_eval
    )
    fit_summary_rows <- model_output$fit_summary
    decile_rows <- model_output$deciles
    prediction_rows <- model_output$predictions
    fit_summary_rows[[length(fit_summary_rows) + 1L]] <- tibble(
      window = window_spec$window,
      candidate_min_classa_prop = candidate_min_classa,
      model = "elastic_net_logit_enriched",
      feature_layer = "enriched",
      split = window_spec$train_label,
      split_role = "train",
      rows = nrow(train_data),
      outcome = "y100",
      outcome_mean = mean(train_data$y100_num),
      metric = "lambda_1se",
      value = elastic_score$lambda_1se
    )

    multinomial_score <- fit_decay_multinomial_score(enriched_design$train_matrix, enriched_design$test_matrix, train_data$size_bin)
    train_eval <- train_data |> mutate(score_value = multinomial_score$train_score)
    test_eval <- test_data |> mutate(score_value = multinomial_score$test_score)
    model_output <- append_binary_outputs(
      list(fit_summary = fit_summary_rows, deciles = decile_rows, predictions = prediction_rows),
      window_spec$window,
      candidate_min_classa,
      "decay_multinomial_size_bins",
      "enriched",
      window_spec$train_label,
      window_spec$test_label,
      "probability",
      train_eval,
      test_eval
    )
    fit_summary_rows <- model_output$fit_summary
    decile_rows <- model_output$deciles
    prediction_rows <- model_output$predictions
    fit_summary_rows[[length(fit_summary_rows) + 1L]] <- tibble(
      window = window_spec$window,
      candidate_min_classa_prop = candidate_min_classa,
      model = "decay_multinomial_size_bins",
      feature_layer = "enriched",
      split = window_spec$train_label,
      split_role = "train",
      rows = nrow(train_data),
      outcome = "size_bin",
      outcome_mean = mean(train_data$y100_num),
      metric = "decay",
      value = multinomial_score$decay
    )

    log_units_score <- fit_glmnet_log_units(enriched_design$train_matrix, enriched_design$test_matrix, train_data$log_units, train_data$filing_year)
    train_eval <- train_data |>
      mutate(
        pred_log_units = log_units_score$train_prediction,
        score_value = pred_log_units
      )
    test_eval <- test_data |>
      mutate(
        pred_log_units = log_units_score$test_prediction,
        score_value = pred_log_units
      )

    fit_summary_rows[[length(fit_summary_rows) + 1L]] <- bind_rows(
      binary_metrics(window_spec$window, candidate_min_classa, "ridge_log_units_rank", "enriched", window_spec$train_label, "train", "rank", train_eval),
      binary_metrics(window_spec$window, candidate_min_classa, "ridge_log_units_rank", "enriched", window_spec$test_label, "test", "rank", test_eval),
      continuous_metrics(window_spec$window, candidate_min_classa, "ridge_log_units", "enriched", window_spec$train_label, "train", train_eval, mean(train_eval$log_units)),
      continuous_metrics(window_spec$window, candidate_min_classa, "ridge_log_units", "enriched", window_spec$test_label, "test", test_eval, mean(train_eval$log_units)),
      tibble(
        window = window_spec$window,
        candidate_min_classa_prop = candidate_min_classa,
        model = "ridge_log_units",
        feature_layer = "enriched",
        split = window_spec$train_label,
        split_role = "train",
        rows = nrow(train_data),
        outcome = "log_classa_prop",
        outcome_mean = mean(train_data$log_units),
        metric = "lambda_1se",
        value = log_units_score$lambda_1se
      )
    )

    decile_rows[[length(decile_rows) + 1L]] <- bind_rows(
      score_bin_summary(window_spec$window, candidate_min_classa, "ridge_log_units_rank", "enriched", window_spec$train_label, "train", "rank", train_eval),
      score_bin_summary(window_spec$window, candidate_min_classa, "ridge_log_units_rank", "enriched", window_spec$test_label, "test", "rank", test_eval)
    )

    prediction_rows[[length(prediction_rows) + 1L]] <- bind_rows(
      train_eval |>
        transmute(window = window_spec$window, candidate_min_classa_prop = candidate_min_classa, model = "ridge_log_units_rank", feature_layer = "enriched", split = window_spec$train_label, split_role = "train", job_number, date_filed, classa_prop, y100_num, score_kind = "rank", score_value),
      test_eval |>
        transmute(window = window_spec$window, candidate_min_classa_prop = candidate_min_classa, model = "ridge_log_units_rank", feature_layer = "enriched", split = window_spec$test_label, split_role = "test", job_number, date_filed, classa_prop, y100_num, score_kind = "rank", score_value)
    )
  }
}

fit_summary <- bind_rows(fit_summary_rows) |>
  arrange(candidate_min_classa_prop, window, split_role, model, metric)

deciles <- bind_rows(decile_rows) |>
  arrange(candidate_min_classa_prop, window, split_role, model, score_bin_count, score_bin)

predictions <- bind_rows(prediction_rows)
rank_correlation_rows <- list()
top_bin_overlap_rows <- list()

for (candidate_min_classa in candidate_min_classa_props) {
  for (window_name in unique(predictions$window)) {
    window_predictions <- predictions |>
      filter(candidate_min_classa_prop == candidate_min_classa, window == window_name, split_role == "test")
    model_names <- sort(unique(window_predictions$model))

    for (i in seq_along(model_names)) {
      for (j in seq_along(model_names)) {
        if (j <= i) {
          next
        }

        left_scores <- window_predictions |>
          filter(model == model_names[i]) |>
          select(job_number, score_left = score_value)
        right_scores <- window_predictions |>
          filter(model == model_names[j]) |>
          select(job_number, score_right = score_value)
        joined_scores <- left_scores |>
          inner_join(right_scores, by = "job_number", relationship = "one-to-one")

        rank_correlation_rows[[length(rank_correlation_rows) + 1L]] <- tibble(
          window = window_name,
          candidate_min_classa_prop = candidate_min_classa,
          split_role = "test",
          model_left = model_names[i],
          model_right = model_names[j],
          rows = nrow(joined_scores),
          spearman_correlation = cor(joined_scores$score_left, joined_scores$score_right, method = "spearman")
        )

        for (top_share in c(0.10, 0.20, 0.25)) {
          left_cutoff <- quantile(joined_scores$score_left, 1 - top_share, names = FALSE, na.rm = TRUE)
          right_cutoff <- quantile(joined_scores$score_right, 1 - top_share, names = FALSE, na.rm = TRUE)
          left_top <- joined_scores$score_left >= left_cutoff
          right_top <- joined_scores$score_right >= right_cutoff
          overlap_rows <- sum(left_top & right_top)
          union_rows <- sum(left_top | right_top)

          top_bin_overlap_rows[[length(top_bin_overlap_rows) + 1L]] <- tibble(
            window = window_name,
            candidate_min_classa_prop = candidate_min_classa,
            split_role = "test",
            model_left = model_names[i],
            model_right = model_names[j],
            top_share = top_share,
            rows = nrow(joined_scores),
            left_top_rows = sum(left_top),
            right_top_rows = sum(right_top),
            overlap_rows = overlap_rows,
            overlap_share_of_smaller_top_set = overlap_rows / min(sum(left_top), sum(right_top)),
            overlap_jaccard = overlap_rows / union_rows
          )
        }
      }
    }
  }
}

rank_correlations <- bind_rows(rank_correlation_rows) |>
  arrange(candidate_min_classa_prop, window, model_left, model_right)

top_bin_overlap <- bind_rows(top_bin_overlap_rows) |>
  arrange(candidate_min_classa_prop, window, top_share, model_left, model_right)

sample_summary <- bind_rows(sample_summary_rows) |>
  arrange(candidate_min_classa_prop, window, split_role)

size_bin_counts <- bind_rows(size_bin_count_rows) |>
  arrange(candidate_min_classa_prop, window, split_role, size_bin)

feature_missingness <- bind_rows(feature_missingness_rows) |>
  arrange(candidate_min_classa_prop, window, split_role, feature)

write_csv_if_changed(fit_summary, "../output/candidate_prediction_fit_summary.csv")
write_csv_if_changed(deciles, "../output/candidate_prediction_deciles.csv")
write_csv_if_changed(rank_correlations, "../output/candidate_prediction_rank_correlations.csv")
write_csv_if_changed(top_bin_overlap, "../output/candidate_prediction_top_bin_overlap.csv")
write_csv_if_changed(sample_summary, "../output/candidate_prediction_sample_summary.csv")
write_csv_if_changed(size_bin_counts, "../output/candidate_prediction_size_bin_counts.csv")
write_csv_if_changed(feature_missingness, "../output/candidate_prediction_feature_missingness.csv")
cat("Wrote candidate prediction model audit outputs to ../output\n")

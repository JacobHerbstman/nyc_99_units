# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_simple_logit_time_splits/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(Matrix)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

candidate_min_classa_prop <- 50L
deadline_421a <- as.Date("2022-06-15")
min_category_rows <- 10L
reference_window_name <- "train_2010_2020_test_2021_2022h1"

log_positive <- function(x) {
  if_else(!is.na(x) & x > 0, log(x), NA_real_)
}

safe_ratio <- function(numerator, denominator) {
  ifelse(is.na(denominator) | denominator == 0, NA_real_, numerator / denominator)
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

score_group_summary <- function(eval_data, group_count) {
  eval_data |>
    mutate(score_tier = ntile(score_value, group_count)) |>
    group_by(score_tier) |>
    summarise(
      group_count = group_count,
      rows = n(),
      y100_rows = sum(y100_num),
      y100_share = mean(y100_num),
      capture_share = safe_ratio(y100_rows, sum(eval_data$y100_num)),
      mean_score = mean(score_value),
      min_score = min(score_value),
      max_score = max(score_value),
      mean_classa_prop = mean(classa_prop),
      median_classa_prop = median(classa_prop),
      share_exactly_99 = mean(classa_prop == 99),
      .groups = "drop"
    )
}

split_metrics <- function(eval_data, group_count) {
  score_groups <- score_group_summary(eval_data, group_count)
  top_row <- score_groups |> filter(score_tier == group_count)
  bottom_row <- score_groups |> filter(score_tier == 1L)

  tibble(
    group_count = group_count,
    rows = nrow(eval_data),
    y100_rows = sum(eval_data$y100_num),
    y100_share = mean(eval_data$y100_num),
    auc = rank_auc(eval_data$y100_num, eval_data$score_value),
    average_precision = average_precision(eval_data$y100_num, eval_data$score_value),
    brier_score = mean((eval_data$y100_num - eval_data$score_value)^2),
    bottom_tier_rows = bottom_row$rows,
    top_tier_rows = top_row$rows,
    bottom_tier_y100_rows = bottom_row$y100_rows,
    top_tier_y100_rows = top_row$y100_rows,
    bottom_tier_y100_share = bottom_row$y100_share,
    top_tier_y100_share = top_row$y100_share,
    top_tier_capture_share = top_row$capture_share,
    top_minus_bottom_y100_share = top_row$y100_share - bottom_row$y100_share,
    top_over_bottom_y100_share = safe_ratio(top_row$y100_share, bottom_row$y100_share)
  )
}

prepare_design <- function(train_data, test_data) {
  numeric_features <- c("log_lotarea", "residfar", "builtfar")
  categorical_features <- c("borough", "zone_detail", "prior_site_use")
  train_prepared <- train_data
  test_prepared <- test_data
  design_terms <- character()
  scaling_rows <- list()
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

    scaling_rows[[length(scaling_rows) + 1L]] <- tibble(
      feature = feature_name,
      scaled_term = scaled_name,
      impute_value = impute_value,
      train_mean = train_mean,
      train_sd = train_sd
    )
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
  train_matrix <- train_matrix[, colnames(train_matrix) != "(Intercept)", drop = FALSE]
  test_matrix <- test_matrix[, colnames(test_matrix) != "(Intercept)", drop = FALSE]
  keep_columns <- apply(train_matrix, 2, function(x) length(unique(x)) > 1L)

  list(
    train_frame = as.data.frame(train_matrix[, keep_columns, drop = FALSE]),
    test_frame = as.data.frame(test_matrix[, keep_columns, drop = FALSE]),
    scaling = bind_rows(scaling_rows),
    reference_levels = bind_rows(reference_rows)
  )
}

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
    candidate_min_classa_prop = candidate_min_classa_prop,
    model = "ordinary_logit_simple",
    reference_window = window == reference_window_name
  )

write_csv_if_changed(window_specs, "../output/simple_logit_time_window_specs.csv")

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
    capacity_units_850 = allowed_res_area / 850
  )

status_rows <- list()
summary_rows <- list()
tier_rows <- list()
contrast_rows <- list()
example_rows <- list()
coefficient_rows <- list()

for (window_index in seq_len(nrow(window_specs))) {
  window_spec <- window_specs[window_index, ]

  train_data <- model_rows |>
    filter(date_filed >= window_spec$train_start, date_filed <= window_spec$train_end)

  test_data <- model_rows |>
    filter(date_filed >= window_spec$test_start, date_filed <= window_spec$test_end)

  window_status <- "fit"
  status_note <- NA_character_

  if (nrow(train_data) == 0 || nrow(test_data) == 0) {
    window_status <- "skipped_empty_train_or_test"
    status_note <- "Train or test sample has zero rows."
  } else if (length(unique(train_data$y100_num)) < 2L || length(unique(test_data$y100_num)) < 2L) {
    window_status <- "skipped_missing_y100_class"
    status_note <- "Train or test sample does not contain both y100 classes."
  }

  if (window_status != "fit") {
    status_rows[[length(status_rows) + 1L]] <- window_spec |>
      transmute(
        window, model, candidate_min_classa_prop, train_start, train_end, test_start, test_end,
        regime_note, reference_window, train_rows = nrow(train_data), test_rows = nrow(test_data),
        train_y100_rows = sum(train_data$y100_num), test_y100_rows = sum(test_data$y100_num),
        status = window_status, converged = NA, warning_messages = status_note
      )
    next
  }

  design <- prepare_design(train_data, test_data)
  design$train_frame$y100_num <- train_data$y100_num
  warning_messages <- character()

  simple_fit <- withCallingHandlers(
    glm(y100_num ~ ., data = design$train_frame, family = binomial(), control = glm.control(maxit = 100)),
    warning = function(w) {
      warning_messages <<- c(warning_messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  train_score <- withCallingHandlers(
    as.numeric(predict(simple_fit, newdata = design$train_frame, type = "response")),
    warning = function(w) {
      warning_messages <<- c(warning_messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  test_score <- withCallingHandlers(
    as.numeric(predict(simple_fit, newdata = design$test_frame, type = "response")),
    warning = function(w) {
      warning_messages <<- c(warning_messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  train_eval <- train_data |>
    mutate(
      score_value = train_score,
      split = "train",
      split_start = window_spec$train_start,
      split_end = window_spec$train_end
    )

  test_eval <- test_data |>
    mutate(
      score_value = test_score,
      split = "test",
      split_start = window_spec$test_start,
      split_end = window_spec$test_end
    )

  status_rows[[length(status_rows) + 1L]] <- window_spec |>
    transmute(
      window, model, candidate_min_classa_prop, train_start, train_end, test_start, test_end,
      regime_note, reference_window, train_rows = nrow(train_data), test_rows = nrow(test_data),
      train_y100_rows = sum(train_data$y100_num), test_y100_rows = sum(test_data$y100_num),
      status = "fit", converged = simple_fit$converged,
      warning_messages = if_else(length(warning_messages) == 0L, NA_character_, paste(unique(warning_messages), collapse = " | "))
    )

  if (isTRUE(window_spec$reference_window)) {
    coefficient_table <- tibble(
      term = names(coef(simple_fit)),
      estimate_log_odds = as.numeric(coef(simple_fit))
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

    for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
      coefficient_table$feature[
        is.na(coefficient_table$feature) &
          str_starts(coefficient_table$term, make.names(feature_name))
      ] <- feature_name
    }

    coefficient_rows[[length(coefficient_rows) + 1L]] <- coefficient_table |>
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
      left_join(
        design$scaling |> select(feature, impute_value, train_mean, train_sd),
        by = "feature",
        relationship = "many-to-one"
      ) |>
      mutate(
        odds_ratio = exp(estimate_log_odds),
        abs_estimate_log_odds = abs(estimate_log_odds),
        coefficient_rank_by_abs_value = rank(-abs_estimate_log_odds, ties.method = "first"),
        window = window_spec$window,
        model = window_spec$model,
        candidate_min_classa_prop = candidate_min_classa_prop,
        train_start = window_spec$train_start,
        train_end = window_spec$train_end,
        test_start = window_spec$test_start,
        test_end = window_spec$test_end,
        note = case_when(
          term_type == "numeric_standardized" ~ "Numeric coefficient is per one training-sample standard deviation after training-median imputation.",
          term_type == "numeric_missing_indicator" ~ "Missing indicator is relative to observed values after paired numeric imputation.",
          term_type == "categorical_indicator" ~ "Categorical coefficient is relative to the listed reference level after rare-level pooling.",
          TRUE ~ "Intercept."
        )
      ) |>
      arrange(coefficient_rank_by_abs_value) |>
      select(
        window, model, candidate_min_classa_prop, train_start, train_end, test_start, test_end,
        term, term_type, feature, level, reference_level,
        estimate_log_odds, odds_ratio, abs_estimate_log_odds, coefficient_rank_by_abs_value,
        impute_value, train_mean, train_sd, note
      )
  }

  for (group_count in c(3L, 4L)) {
    summary_rows[[length(summary_rows) + 1L]] <- bind_rows(
      split_metrics(train_eval, group_count) |>
        mutate(split = "train", split_start = window_spec$train_start, split_end = window_spec$train_end),
      split_metrics(test_eval, group_count) |>
        mutate(split = "test", split_start = window_spec$test_start, split_end = window_spec$test_end)
    ) |>
      mutate(
        window = window_spec$window,
        model = window_spec$model,
        candidate_min_classa_prop = candidate_min_classa_prop,
        regime_note = window_spec$regime_note,
        reference_window = window_spec$reference_window,
        train_start = window_spec$train_start,
        train_end = window_spec$train_end,
        test_start = window_spec$test_start,
        test_end = window_spec$test_end,
        .before = split
      )

    tier_rows[[length(tier_rows) + 1L]] <- bind_rows(
      score_group_summary(train_eval, group_count) |>
        mutate(split = "train", split_start = window_spec$train_start, split_end = window_spec$train_end),
      score_group_summary(test_eval, group_count) |>
        mutate(split = "test", split_start = window_spec$test_start, split_end = window_spec$test_end)
    ) |>
      mutate(
        window = window_spec$window,
        model = window_spec$model,
        candidate_min_classa_prop = candidate_min_classa_prop,
        regime_note = window_spec$regime_note,
        reference_window = window_spec$reference_window,
        train_start = window_spec$train_start,
        train_end = window_spec$train_end,
        test_start = window_spec$test_start,
        test_end = window_spec$test_end,
        .before = split
      )
  }

  test_terciles <- test_eval |>
    mutate(score_tercile = ntile(score_value, 3L)) |>
    mutate(
      example_category = case_when(
        score_tercile == 3L & y100_num == 1L ~ "top_tercile_y100",
        score_tercile == 3L & y100_num == 0L ~ "top_tercile_below_100",
        score_tercile == 1L & y100_num == 1L ~ "bottom_tercile_y100",
        score_tercile == 1L & y100_num == 0L ~ "bottom_tercile_below_100",
        TRUE ~ NA_character_
      )
    ) |>
    filter(!is.na(example_category)) |>
    group_by(example_category) |>
    arrange(desc(score_value), desc(classa_prop), job_number, .by_group = TRUE) |>
    slice_head(n = 5L) |>
    ungroup() |>
    transmute(
      window = window_spec$window,
      model = window_spec$model,
      regime_note = window_spec$regime_note,
      reference_window = window_spec$reference_window,
      example_category,
      job_number, date_filed, classa_prop, y100_num, score_value, score_tercile,
      bbl, pluto_feature_bbl, hdb_borough_name, address, zonedist1,
      landuse, bldgclass, lotarea, residfar, builtfar, allowed_res_area, capacity_units_850
    )

  example_rows[[length(example_rows) + 1L]] <- test_terciles
}

status <- bind_rows(status_rows) |>
  arrange(test_start, train_start)

summary <- bind_rows(summary_rows) |>
  arrange(test_start, train_start, split, group_count)

tiers <- bind_rows(tier_rows) |>
  arrange(test_start, train_start, split, group_count, score_tier)

contrast <- summary |>
  filter(split == "test") |>
  select(
    window, model, candidate_min_classa_prop, regime_note,
    reference_window, train_start, train_end, test_start, test_end,
    group_count, rows, y100_rows, y100_share, auc, average_precision, brier_score,
    bottom_tier_rows, top_tier_rows, bottom_tier_y100_rows, top_tier_y100_rows,
    bottom_tier_y100_share, top_tier_y100_share, top_tier_capture_share,
    top_minus_bottom_y100_share, top_over_bottom_y100_share
  ) |>
  arrange(group_count, desc(top_minus_bottom_y100_share), desc(top_tier_y100_share))

examples <- bind_rows(example_rows) |>
  arrange(window, example_category, desc(score_value), desc(classa_prop))

reference_coefficients <- bind_rows(coefficient_rows) |>
  arrange(coefficient_rank_by_abs_value)

write_csv_if_changed(status, "../output/simple_logit_time_window_status.csv")
write_csv_if_changed(summary, "../output/simple_logit_time_split_summary.csv")
write_csv_if_changed(tiers, "../output/simple_logit_time_split_tiers.csv")
write_csv_if_changed(contrast, "../output/simple_logit_time_split_contrast.csv")
write_csv_if_changed(examples, "../output/simple_logit_time_split_examples.csv")
write_csv_if_changed(reference_coefficients, "../output/simple_logit_reference_coefficients.csv")

cat("Wrote simple logit time-split audit outputs to ../output\n")

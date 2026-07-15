# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_sales_event_study_simple_logit_exposure/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(fixest)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

candidate_min_classa_prop <- 50L
train_start <- as.Date("2010-01-01")
train_end <- as.Date("2020-12-31")
min_category_rows <- 10L
event_min <- -16L
event_max <- 13L
event_reference <- -2L
semiannual_event_min <- -8L
semiannual_event_max <- 7L
semiannual_event_reference <- -2L

safe_ratio <- function(numerator, denominator) {
  ifelse(is.na(denominator) | denominator == 0, NA_real_, numerator / denominator)
}

clean_model_features <- function(df, borough_field) {
  df |>
    mutate(
      y100_num = if ("y100" %in% names(df)) as.integer(y100) else NA_integer_,
      log_lotarea = if_else(!is.na(lotarea) & lotarea > 0, log(lotarea), NA_real_),
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
      landuse_model_code = if ("landuse" %in% names(df)) as.character(landuse) else as.character(landuse_code),
      landuse_model_code = str_pad(landuse_model_code, 2L, pad = "0"),
      landuse_model_code = if_else(is.na(landuse_model_code) | landuse_model_code == "", "missing", landuse_model_code),
      prior_site_use = case_when(
        !is.na(unitsres) & unitsres > 0 ~ "existing_residential_units",
        landuse_model_code == "11" ~ "vacant_land",
        landuse_model_code == "10" ~ "parking",
        landuse_model_code %in% c("05", "06") ~ "commercial_industrial",
        landuse_model_code == "04" ~ "mixed_res_commercial",
        landuse_model_code %in% c("07", "08") ~ "public_transport_utility",
        landuse_model_code == "missing" ~ "missing_landuse",
        TRUE ~ "other_no_res_units"
      ),
      borough_model = if (borough_field == "hdb_borough_name") hdb_borough_name else standardize_borough_name(borough)
    )
}

prepare_design <- function(train_data, score_data) {
  numeric_features <- c("log_lotarea", "residfar", "builtfar")
  categorical_features <- c("borough_model", "zone_detail", "prior_site_use")
  train_prepared <- train_data
  score_prepared <- score_data
  design_terms <- character()
  scaling_rows <- list()
  reference_rows <- list()

  for (feature_name in numeric_features) {
    missing_name <- paste0(feature_name, "_missing")
    scaled_name <- paste0("z_", feature_name)
    train_values <- train_prepared[[feature_name]]
    score_values <- score_prepared[[feature_name]]
    train_prepared[[missing_name]] <- is.na(train_values)
    score_prepared[[missing_name]] <- is.na(score_values)

    impute_value <- median(train_values, na.rm = TRUE)
    if (is.na(impute_value)) {
      impute_value <- 0
    }

    train_values[is.na(train_values)] <- impute_value
    score_values[is.na(score_values)] <- impute_value
    train_mean <- mean(train_values)
    train_sd <- sd(train_values)

    if (is.na(train_sd) || train_sd == 0) {
      train_sd <- 1
    }

    train_prepared[[scaled_name]] <- (train_values - train_mean) / train_sd
    score_prepared[[scaled_name]] <- (score_values - train_mean) / train_sd
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
    score_values <- str_squish(as.character(score_prepared[[feature_name]]))
    train_values[is.na(train_values) | train_values == ""] <- "missing"
    score_values[is.na(score_values) | score_values == ""] <- "missing"
    train_counts <- sort(table(train_values), decreasing = TRUE)
    keep_levels <- names(train_counts)[train_counts >= min_category_rows]

    if (length(keep_levels) == 0) {
      keep_levels <- names(train_counts)[1]
    }

    train_values[!(train_values %in% keep_levels)] <- "other_rare"
    score_values[!(score_values %in% keep_levels)] <- "other_rare"
    factor_levels <- unique(c(sort(keep_levels), "other_rare"))
    train_prepared[[feature_name]] <- factor(train_values, levels = factor_levels)
    score_prepared[[feature_name]] <- factor(score_values, levels = factor_levels)
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
  score_matrix <- model.matrix(design_formula, score_prepared)
  colnames(train_matrix) <- make.names(colnames(train_matrix), unique = TRUE)
  colnames(score_matrix) <- make.names(colnames(score_matrix), unique = TRUE)
  train_matrix <- train_matrix[, colnames(train_matrix) != "(Intercept)", drop = FALSE]
  score_matrix <- score_matrix[, colnames(score_matrix) != "(Intercept)", drop = FALSE]
  keep_columns <- apply(train_matrix, 2, function(x) length(unique(x)) > 1L)

  list(
    train_frame = as.data.frame(train_matrix[, keep_columns, drop = FALSE]),
    score_frame = as.data.frame(score_matrix[, keep_columns, drop = FALSE]),
    scaling = bind_rows(scaling_rows),
    reference_levels = bind_rows(reference_rows)
  )
}

fit_period_model <- function(analysis_data, outcome_name) {
  if (outcome_name == "sale_incidence") {
    model_data <- analysis_data
    model_formula <- primary_private_sale_acris_q ~ high_exposure:transition + high_exposure:mixed_policy + high_exposure:post_485x | bbl + quarter_start
    fixed_effects <- "bbl + quarter_start"
  } else {
    model_data <- analysis_data |>
      filter(primary_price_complete_sale_acris_q == 1L, primary_price_psf > 0)
    model_formula <- log_primary_price_psf ~ high_exposure:transition + high_exposure:mixed_policy + high_exposure:post_485x | borough + quarter_start
    fixed_effects <- "borough + quarter_start"
  }

  if (nrow(model_data) == 0 || length(unique(model_data$high_exposure)) < 2L) {
    return(tibble(
      outcome = outcome_name,
      term = NA_character_,
      estimate = NA_real_,
      std_error = NA_real_,
      t_value = NA_real_,
      p_value = NA_real_,
      ci_low = NA_real_,
      ci_high = NA_real_,
      observations = nrow(model_data),
      r2 = NA_real_,
      within_r2 = NA_real_,
      fixed_effects = fixed_effects,
      status = "skipped_empty_or_single_exposure_group"
    ))
  }

  model <- feols(model_formula, cluster = ~bbl, data = model_data)

  as.data.frame(coeftable(model)) |>
    rownames_to_column("term") |>
    as_tibble() |>
    transmute(
      outcome = outcome_name,
      term,
      estimate = Estimate,
      std_error = `Std. Error`,
      t_value = `t value`,
      p_value = `Pr(>|t|)`,
      ci_low = estimate - 1.96 * std_error,
      ci_high = estimate + 1.96 * std_error,
      observations = model$nobs,
      r2 = as.numeric(r2(model, type = "r2")),
      within_r2 = as.numeric(r2(model, type = "wr2")),
      fixed_effects,
      status = "fit"
    )
}

fit_event_model <- function(analysis_data, outcome_name) {
  if (outcome_name == "sale_incidence") {
    model_data <- analysis_data |>
      filter(event_time >= event_min, event_time <= event_max)
    model_formula <- primary_private_sale_acris_q ~ i(event_time, high_exposure, ref = event_reference) | bbl + quarter_start
    fixed_effects <- "bbl + quarter_start"
  } else {
    model_data <- analysis_data |>
      filter(
        event_time >= event_min,
        event_time <= event_max,
        primary_price_complete_sale_acris_q == 1L,
        primary_price_psf > 0
      )
    model_formula <- log_primary_price_psf ~ i(event_time, high_exposure, ref = event_reference) | borough + quarter_start
    fixed_effects <- "borough + quarter_start"
  }

  if (nrow(model_data) == 0 || length(unique(model_data$high_exposure)) < 2L) {
    return(tibble(
      outcome = outcome_name,
      term = NA_character_,
      event_time = NA_integer_,
      estimate = NA_real_,
      std_error = NA_real_,
      t_value = NA_real_,
      p_value = NA_real_,
      ci_low = NA_real_,
      ci_high = NA_real_,
      observations = nrow(model_data),
      r2 = NA_real_,
      within_r2 = NA_real_,
      fixed_effects = fixed_effects,
      event_reference = event_reference,
      event_min = event_min,
      event_max = event_max,
      status = "skipped_empty_or_single_exposure_group"
    ))
  }

  model <- feols(model_formula, cluster = ~bbl, data = model_data)

  as.data.frame(coeftable(model)) |>
    rownames_to_column("term") |>
    as_tibble() |>
    transmute(
      outcome = outcome_name,
      term,
      event_time = as.integer(str_extract(term, "-?[0-9]+")),
      estimate = Estimate,
      std_error = `Std. Error`,
      t_value = `t value`,
      p_value = `Pr(>|t|)`,
      ci_low = estimate - 1.96 * std_error,
      ci_high = estimate + 1.96 * std_error,
      observations = model$nobs,
      r2 = as.numeric(r2(model, type = "r2")),
      within_r2 = as.numeric(r2(model, type = "wr2")),
      fixed_effects,
      event_reference = event_reference,
      event_min = event_min,
      event_max = event_max,
      status = "fit"
    )
}

fit_period_model_semiannual <- function(analysis_data, outcome_name) {
  if (outcome_name == "sale_incidence") {
    model_data <- analysis_data
    model_formula <- primary_private_sale_acris_h ~ high_exposure:transition_h + high_exposure:mixed_policy_h + high_exposure:post_485x_h | bbl + half_start
    fixed_effects <- "bbl + half_start"
  } else {
    model_data <- analysis_data |>
      filter(primary_price_complete_sale_acris_h == 1L, primary_price_psf_h > 0)
    model_formula <- log_primary_price_psf_h ~ high_exposure:transition_h + high_exposure:mixed_policy_h + high_exposure:post_485x_h | borough + half_start
    fixed_effects <- "borough + half_start"
  }

  if (nrow(model_data) == 0 || length(unique(model_data$high_exposure)) < 2L) {
    return(tibble(
      outcome = outcome_name,
      term = NA_character_,
      estimate = NA_real_,
      std_error = NA_real_,
      t_value = NA_real_,
      p_value = NA_real_,
      ci_low = NA_real_,
      ci_high = NA_real_,
      observations = nrow(model_data),
      r2 = NA_real_,
      within_r2 = NA_real_,
      fixed_effects = fixed_effects,
      status = "skipped_empty_or_single_exposure_group"
    ))
  }

  model <- feols(model_formula, cluster = ~bbl, data = model_data)

  as.data.frame(coeftable(model)) |>
    rownames_to_column("term") |>
    as_tibble() |>
    transmute(
      outcome = outcome_name,
      term,
      estimate = Estimate,
      std_error = `Std. Error`,
      t_value = `t value`,
      p_value = `Pr(>|t|)`,
      ci_low = estimate - 1.96 * std_error,
      ci_high = estimate + 1.96 * std_error,
      observations = model$nobs,
      r2 = as.numeric(r2(model, type = "r2")),
      within_r2 = as.numeric(r2(model, type = "wr2")),
      fixed_effects,
      status = "fit"
    )
}

fit_event_model_semiannual <- function(analysis_data, outcome_name) {
  if (outcome_name == "sale_incidence") {
    model_data <- analysis_data |>
      filter(event_half_time >= semiannual_event_min, event_half_time <= semiannual_event_max)
    model_formula <- primary_private_sale_acris_h ~ i(event_half_time, high_exposure, ref = semiannual_event_reference) | bbl + half_start
    fixed_effects <- "bbl + half_start"
  } else {
    model_data <- analysis_data |>
      filter(
        event_half_time >= semiannual_event_min,
        event_half_time <= semiannual_event_max,
        primary_price_complete_sale_acris_h == 1L,
        primary_price_psf_h > 0
      )
    model_formula <- log_primary_price_psf_h ~ i(event_half_time, high_exposure, ref = semiannual_event_reference) | borough + half_start
    fixed_effects <- "borough + half_start"
  }

  if (nrow(model_data) == 0 || length(unique(model_data$high_exposure)) < 2L) {
    return(tibble(
      outcome = outcome_name,
      term = NA_character_,
      event_half_time = NA_integer_,
      estimate = NA_real_,
      std_error = NA_real_,
      t_value = NA_real_,
      p_value = NA_real_,
      ci_low = NA_real_,
      ci_high = NA_real_,
      observations = nrow(model_data),
      r2 = NA_real_,
      within_r2 = NA_real_,
      fixed_effects = fixed_effects,
      event_reference = semiannual_event_reference,
      event_min = semiannual_event_min,
      event_max = semiannual_event_max,
      status = "skipped_empty_or_single_exposure_group"
    ))
  }

  model <- feols(model_formula, cluster = ~bbl, data = model_data)

  as.data.frame(coeftable(model)) |>
    rownames_to_column("term") |>
    as_tibble() |>
    transmute(
      outcome = outcome_name,
      term,
      event_half_time = as.integer(str_extract(term, "-?[0-9]+")),
      estimate = Estimate,
      std_error = `Std. Error`,
      t_value = `t value`,
      p_value = `Pr(>|t|)`,
      ci_low = estimate - 1.96 * std_error,
      ci_high = estimate + 1.96 * std_error,
      observations = model$nobs,
      r2 = as.numeric(r2(model, type = "r2")),
      within_r2 = as.numeric(r2(model, type = "wr2")),
      fixed_effects,
      event_reference = semiannual_event_reference,
      event_min = semiannual_event_min,
      event_max = semiannual_event_max,
      status = "fit"
    )
}

hdb_panel <- read_parquet("../input/hdb_mappluto_training_panel.parquet") |>
  as.data.frame() |>
  as_tibble()

training_rows <- hdb_panel |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    date_filed >= train_start,
    date_filed <= train_end,
    !is.na(y100),
    !is.na(classa_prop),
    classa_prop >= candidate_min_classa_prop,
    !is.na(lotarea),
    lotarea > 0
  ) |>
  clean_model_features("hdb_borough_name")

opportunity_panel <- read_parquet("../input/opportunity_lot_quarter_panel.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  mutate(
    primary_private_sale_acris_q = as.integer(primary_private_sale_acris_q),
    primary_price_complete_sale_acris_q = as.integer(primary_price_complete_sale_acris_q),
    primary_price_psf = acris_primary_price_per_allowed_policy_res_sqft_q,
    log_primary_price_psf = if_else(!is.na(primary_price_psf) & primary_price_psf > 0, log(primary_price_psf), NA_real_),
    transition = as.integer(quarter_policy_period == "transition_421a_expired_pre_485x"),
    mixed_policy = as.integer(quarter_policy_period == "mixed_policy_quarter"),
    post_485x = as.integer(quarter_policy_period == "post_485x_adoption"),
    quarter_year = as.integer(format(quarter_start, "%Y")),
    quarter_number = (as.integer(format(quarter_start, "%m")) - 1L) %/% 3L + 1L,
    event_time = (quarter_year - 2022L) * 4L + quarter_number - 3L,
    half_year = quarter_year,
    half_number = if_else(quarter_number <= 2L, 1L, 2L),
    half_start = as.Date(sprintf("%d-%02d-01", half_year, if_else(half_number == 1L, 1L, 7L))),
    event_half_time = (half_year - 2022L) * 2L + half_number - 2L
  )

panel_key_duplicates <- opportunity_panel |>
  count(bbl, quarter_start, name = "rows") |>
  filter(rows > 1L)

opportunity_lots <- opportunity_panel |>
  distinct(bbl, .keep_all = TRUE) |>
  clean_model_features("borough")

design <- prepare_design(training_rows, opportunity_lots)
design$train_frame$y100_num <- training_rows$y100_num

warning_messages <- character()

simple_fit <- withCallingHandlers(
  glm(y100_num ~ ., data = design$train_frame, family = binomial(), control = glm.control(maxit = 100)),
  warning = function(w) {
    warning_messages <<- c(warning_messages, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)

opportunity_score <- withCallingHandlers(
  as.numeric(predict(simple_fit, newdata = design$score_frame, type = "response")),
  warning = function(w) {
    warning_messages <<- c(warning_messages, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)

scored_lots <- opportunity_lots |>
  mutate(
    simple_logit_score = opportunity_score,
    non_staten_island = borough != "5"
  ) |>
  select(
    bbl, borough, borough_model, simple_logit_score, non_staten_island,
    lotarea, residfar, builtfar, allowed_policy_res_sqft, capacity_units_850,
    zonedist1, zone_detail, landuse_code, prior_site_use
  )

analysis_lots <- bind_rows(
  scored_lots |>
    mutate(analysis_universe = "all_boroughs"),
  scored_lots |>
    filter(non_staten_island) |>
    mutate(analysis_universe = "non_staten_island")
) |>
  group_by(analysis_universe) |>
  mutate(
    score_pctile_citywide = percent_rank(simple_logit_score),
    score_tercile = ntile(simple_logit_score, 3L),
    score_quartile = ntile(simple_logit_score, 4L)
  ) |>
  ungroup()

exposure_lot_counts <- bind_rows(
  analysis_lots |>
    group_by(analysis_universe, exposure_definition = "top_vs_bottom_tercile", score_group = score_tercile) |>
    summarise(
      lots = n_distinct(bbl),
      mean_score = mean(simple_logit_score),
      min_score = min(simple_logit_score),
      max_score = max(simple_logit_score),
      mean_capacity_units_850 = mean(capacity_units_850, na.rm = TRUE),
      .groups = "drop"
    ),
  analysis_lots |>
    group_by(analysis_universe, exposure_definition = "top_vs_bottom_quartile", score_group = score_quartile) |>
    summarise(
      lots = n_distinct(bbl),
      mean_score = mean(simple_logit_score),
      min_score = min(simple_logit_score),
      max_score = max(simple_logit_score),
      mean_capacity_units_850 = mean(capacity_units_850, na.rm = TRUE),
      .groups = "drop"
    )
)

panel_by_universe <- bind_rows(
  opportunity_panel |>
    mutate(analysis_universe = "all_boroughs"),
  opportunity_panel |>
    filter(borough != "5") |>
    mutate(analysis_universe = "non_staten_island")
)

tercile_panel <- panel_by_universe |>
  inner_join(
    analysis_lots |> select(bbl, analysis_universe, simple_logit_score, score_group = score_tercile),
    by = c("bbl", "analysis_universe"),
    relationship = "many-to-one"
  ) |>
  filter(score_group %in% c(1L, 3L)) |>
  mutate(
    exposure_definition = "top_vs_bottom_tercile",
    exposure_group = if_else(score_group == 3L, "top_tercile", "bottom_tercile"),
    high_exposure = as.integer(score_group == 3L)
  )

quartile_panel <- panel_by_universe |>
  inner_join(
    analysis_lots |> select(bbl, analysis_universe, simple_logit_score, score_group = score_quartile),
    by = c("bbl", "analysis_universe"),
    relationship = "many-to-one"
  ) |>
  filter(score_group %in% c(1L, 4L)) |>
  mutate(
    exposure_definition = "top_vs_bottom_quartile",
    exposure_group = if_else(score_group == 4L, "top_quartile", "bottom_quartile"),
    high_exposure = as.integer(score_group == 4L)
  )

analysis_panel <- bind_rows(tercile_panel, quartile_panel)

hard_checks <- tibble(
  check_name = c(
    "unique_input_bbl_quarter",
    "all_input_rows_primary_opportunity_lots",
    "training_has_both_y100_classes",
    "all_opportunity_lots_scored",
    "primary_price_positive_when_present",
    "analysis_panel_unique_universe_exposure_bbl_quarter"
  ),
  failed_rows = c(
    nrow(panel_key_duplicates),
    opportunity_panel |> filter(!primary_opp50_850) |> nrow(),
    as.integer(length(unique(training_rows$y100_num)) < 2L),
    scored_lots |> filter(is.na(simple_logit_score)) |> nrow(),
    opportunity_panel |> filter(!is.na(primary_price_psf) & primary_price_psf <= 0) |> nrow(),
    analysis_panel |>
      count(analysis_universe, exposure_definition, bbl, quarter_start, name = "rows") |>
      filter(rows > 1L) |>
      nrow()
  )
) |>
  mutate(passed = failed_rows == 0L)

if (any(!hard_checks$passed)) {
  write_csv_if_changed(hard_checks, "../output/simple_logit_sales_hard_checks.csv")
  stop("Simple-logit sales event-study audit failed at least one hard check.")
}

period_summary <- analysis_panel |>
  group_by(analysis_universe, exposure_definition, exposure_group, quarter_policy_period) |>
  summarise(
    lot_quarters = n(),
    lots = n_distinct(bbl),
    primary_sale_lot_quarters = sum(primary_private_sale_acris_q),
    primary_price_complete_lot_quarters = sum(primary_price_complete_sale_acris_q),
    sale_rate_per_1000_lot_quarters = 1000 * mean(primary_private_sale_acris_q),
    price_complete_sale_rate_per_1000_lot_quarters = 1000 * mean(primary_price_complete_sale_acris_q),
    median_primary_price_per_allowed_sqft = median(primary_price_psf, na.rm = TRUE),
    mean_primary_price_per_allowed_sqft = mean(primary_price_psf, na.rm = TRUE),
    p10_primary_price_per_allowed_sqft = quantile(primary_price_psf, 0.10, na.rm = TRUE, names = FALSE),
    p90_primary_price_per_allowed_sqft = quantile(primary_price_psf, 0.90, na.rm = TRUE, names = FALSE),
    .groups = "drop"
  ) |>
  arrange(analysis_universe, exposure_definition, exposure_group, quarter_policy_period)

semiannual_panel <- analysis_panel |>
  group_by(
    analysis_universe, exposure_definition, exposure_group, high_exposure, score_group,
    bbl, borough, half_start, half_year, half_number, event_half_time
  ) |>
  summarise(
    quarters_in_half = n(),
    simple_logit_score = first(simple_logit_score),
    allowed_policy_res_sqft = first(allowed_policy_res_sqft),
    has_pre = any(quarter_policy_period == "pre_421a_expiration"),
    has_transition = any(quarter_policy_period == "transition_421a_expired_pre_485x"),
    has_mixed_policy = any(quarter_policy_period == "mixed_policy_quarter"),
    has_post_485x = any(quarter_policy_period == "post_485x_adoption"),
    primary_sale_quarters_h = sum(primary_private_sale_acris_q),
    primary_price_complete_sale_quarters_h = sum(primary_price_complete_sale_acris_q),
    primary_alloc_price_allowed_res_area_sum_h = sum(if_else(
      primary_price_complete_sale_acris_q == 1L & !is.na(acris_primary_alloc_price_allowed_res_area_sum_q),
      acris_primary_alloc_price_allowed_res_area_sum_q,
      0
    )),
    .groups = "drop"
  ) |>
  mutate(
    half_policy_period = case_when(
      has_mixed_policy ~ "mixed_policy_half",
      has_pre & !has_transition & !has_mixed_policy & !has_post_485x ~ "pre_421a_expiration",
      has_transition & !has_mixed_policy & !has_post_485x ~ "transition_421a_expired_pre_485x",
      has_post_485x & !has_transition & !has_mixed_policy ~ "post_485x_adoption",
      TRUE ~ "other_policy_half"
    ),
    transition_h = as.integer(half_policy_period == "transition_421a_expired_pre_485x"),
    mixed_policy_h = as.integer(half_policy_period == "mixed_policy_half"),
    post_485x_h = as.integer(half_policy_period == "post_485x_adoption"),
    primary_private_sale_acris_h = as.integer(primary_sale_quarters_h > 0L),
    primary_price_complete_sale_acris_h = as.integer(primary_price_complete_sale_quarters_h > 0L),
    multiple_primary_sale_quarters_h = as.integer(primary_sale_quarters_h > 1L),
    multiple_primary_price_complete_sale_quarters_h = as.integer(primary_price_complete_sale_quarters_h > 1L),
    primary_price_psf_h = if_else(
      primary_price_complete_sale_acris_h == 1L & !is.na(allowed_policy_res_sqft) & allowed_policy_res_sqft > 0,
      primary_alloc_price_allowed_res_area_sum_h / allowed_policy_res_sqft,
      NA_real_
    ),
    log_primary_price_psf_h = if_else(!is.na(primary_price_psf_h) & primary_price_psf_h > 0, log(primary_price_psf_h), NA_real_)
  )

semiannual_period_summary <- semiannual_panel |>
  group_by(analysis_universe, exposure_definition, exposure_group, half_policy_period) |>
  summarise(
    lot_half_years = n(),
    lots = n_distinct(bbl),
    primary_sale_half_years = sum(primary_private_sale_acris_h),
    primary_sale_quarters = sum(primary_sale_quarters_h),
    primary_price_complete_half_years = sum(primary_price_complete_sale_acris_h),
    primary_price_complete_sale_quarters = sum(primary_price_complete_sale_quarters_h),
    multiple_primary_sale_half_years = sum(multiple_primary_sale_quarters_h),
    multiple_primary_price_complete_half_years = sum(multiple_primary_price_complete_sale_quarters_h),
    sale_rate_per_1000_lot_half_years = 1000 * mean(primary_private_sale_acris_h),
    price_complete_sale_rate_per_1000_lot_half_years = 1000 * mean(primary_price_complete_sale_acris_h),
    median_primary_price_per_allowed_sqft = median(primary_price_psf_h, na.rm = TRUE),
    mean_primary_price_per_allowed_sqft = mean(primary_price_psf_h, na.rm = TRUE),
    p10_primary_price_per_allowed_sqft = quantile(primary_price_psf_h, 0.10, na.rm = TRUE, names = FALSE),
    p90_primary_price_per_allowed_sqft = quantile(primary_price_psf_h, 0.90, na.rm = TRUE, names = FALSE),
    .groups = "drop"
  ) |>
  arrange(analysis_universe, exposure_definition, exposure_group, half_policy_period)

semiannual_hard_checks <- tibble(
  check_name = c(
    "semiannual_analysis_panel_unique_universe_exposure_bbl_half",
    "semiannual_analysis_panel_two_quarters_per_half",
    "semiannual_primary_price_positive_when_present"
  ),
  failed_rows = c(
    semiannual_panel |>
      count(analysis_universe, exposure_definition, bbl, half_start, name = "rows") |>
      filter(rows > 1L) |>
      nrow(),
    semiannual_panel |>
      filter(quarters_in_half != 2L) |>
      nrow(),
    semiannual_panel |>
      filter(!is.na(primary_price_psf_h) & primary_price_psf_h <= 0) |>
      nrow()
  )
) |>
  mutate(passed = failed_rows == 0L)

hard_checks <- bind_rows(hard_checks, semiannual_hard_checks)

if (any(!hard_checks$passed)) {
  write_csv_if_changed(hard_checks, "../output/simple_logit_sales_hard_checks.csv")
  stop("Simple-logit sales event-study audit failed at least one hard check.")
}

period_model_rows <- list()
event_model_rows <- list()
semiannual_period_model_rows <- list()
semiannual_event_model_rows <- list()

for (analysis_universe_name in sort(unique(analysis_panel$analysis_universe))) {
  for (exposure_definition_name in sort(unique(analysis_panel$exposure_definition))) {
    model_data <- analysis_panel |>
      filter(
        analysis_universe == analysis_universe_name,
        exposure_definition == exposure_definition_name
      )

    for (outcome_name in c("sale_incidence", "log_price_per_allowed_sqft")) {
      period_model_rows[[length(period_model_rows) + 1L]] <- fit_period_model(model_data, outcome_name) |>
        mutate(
          analysis_universe = analysis_universe_name,
          exposure_definition = exposure_definition_name,
          .before = outcome
        )

      if (analysis_universe_name == "non_staten_island") {
        event_model_rows[[length(event_model_rows) + 1L]] <- fit_event_model(model_data, outcome_name) |>
          mutate(
            analysis_universe = analysis_universe_name,
            exposure_definition = exposure_definition_name,
            .before = outcome
          )
      }
    }
  }
}

for (analysis_universe_name in sort(unique(semiannual_panel$analysis_universe))) {
  for (exposure_definition_name in sort(unique(semiannual_panel$exposure_definition))) {
    model_data <- semiannual_panel |>
      filter(
        analysis_universe == analysis_universe_name,
        exposure_definition == exposure_definition_name
      )

    for (outcome_name in c("sale_incidence", "log_price_per_allowed_sqft")) {
      semiannual_period_model_rows[[length(semiannual_period_model_rows) + 1L]] <- fit_period_model_semiannual(model_data, outcome_name) |>
        mutate(
          analysis_universe = analysis_universe_name,
          exposure_definition = exposure_definition_name,
          .before = outcome
        )

      if (analysis_universe_name == "non_staten_island") {
        semiannual_event_model_rows[[length(semiannual_event_model_rows) + 1L]] <- fit_event_model_semiannual(model_data, outcome_name) |>
          mutate(
            analysis_universe = analysis_universe_name,
            exposure_definition = exposure_definition_name,
            .before = outcome
          )
      }
    }
  }
}

period_did <- bind_rows(period_model_rows) |>
  mutate(
    estimate_per_1000 = if_else(outcome == "sale_incidence", 1000 * estimate, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_low, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_high, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(estimate) - 1), NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_low) - 1), NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_high) - 1), NA_real_)
  ) |>
  arrange(analysis_universe, exposure_definition, outcome, term)

event_study <- bind_rows(event_model_rows) |>
  mutate(
    estimate_per_1000 = if_else(outcome == "sale_incidence", 1000 * estimate, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_low, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_high, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(estimate) - 1), NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_low) - 1), NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_high) - 1), NA_real_)
  ) |>
  arrange(analysis_universe, exposure_definition, outcome, event_time)

semiannual_period_did <- bind_rows(semiannual_period_model_rows) |>
  mutate(
    estimate_per_1000 = if_else(outcome == "sale_incidence", 1000 * estimate, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_low, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_high, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(estimate) - 1), NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_low) - 1), NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_high) - 1), NA_real_)
  ) |>
  arrange(analysis_universe, exposure_definition, outcome, term)

semiannual_event_study <- bind_rows(semiannual_event_model_rows) |>
  mutate(
    estimate_per_1000 = if_else(outcome == "sale_incidence", 1000 * estimate, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_low, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 1000 * ci_high, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(estimate) - 1), NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_low) - 1), NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 100 * (exp(ci_high) - 1), NA_real_)
  ) |>
  arrange(analysis_universe, exposure_definition, outcome, event_half_time)

training_observation_count <- nrow(training_rows)
training_y100_count <- sum(training_rows$y100_num)

reference_coefficients <- tibble(
  term = names(coef(simple_fit)),
  estimate_log_odds = as.numeric(coef(simple_fit))
) |>
  mutate(
    odds_ratio = exp(estimate_log_odds),
    train_start = train_start,
    train_end = train_end,
    candidate_min_classa_prop = candidate_min_classa_prop,
    training_rows = training_observation_count,
    training_y100_rows = training_y100_count,
    converged = simple_fit$converged,
    warning_messages = if_else(length(warning_messages) == 0L, NA_character_, paste(unique(warning_messages), collapse = " | "))
  )

plot_reference_rows <- event_study |>
  filter(status == "fit") |>
  distinct(analysis_universe, exposure_definition, outcome) |>
  mutate(
    term = "reference_period",
    event_time = event_reference,
    estimate = 0,
    std_error = NA_real_,
    t_value = NA_real_,
    p_value = NA_real_,
    ci_low = 0,
    ci_high = 0,
    observations = NA_integer_,
    r2 = NA_real_,
    within_r2 = NA_real_,
    fixed_effects = NA_character_,
    event_reference = event_reference,
    event_min = event_min,
    event_max = event_max,
    status = "reference_period",
    estimate_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_)
  )

plot_data <- bind_rows(event_study, plot_reference_rows) |>
  filter(status %in% c("fit", "reference_period"))

sale_plot <- plot_data |>
  filter(outcome == "sale_incidence") |>
  ggplot(aes(x = event_time, y = estimate_per_1000, ymin = ci_low_per_1000, ymax = ci_high_per_1000)) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey45") +
  geom_vline(xintercept = -0.5, linewidth = 0.3, linetype = "dashed", color = "grey45") +
  geom_errorbar(width = 0.15, linewidth = 0.25, color = "grey35") +
  geom_point(size = 1.4, color = "grey20") +
  facet_wrap(~ exposure_definition, nrow = 1) +
  scale_x_continuous(breaks = seq(event_min, event_max, by = 2)) +
  labs(
    title = "Top-minus-bottom predicted exposure: sale incidence event study",
    subtitle = "Non-Staten-Island opportunity lots; event 0 is 2022 Q3; omitted quarter is 2022 Q1.",
    x = "Quarters relative to 2022 Q3",
    y = "Difference in sale incidence per 1,000 lot-quarters"
  ) +
  theme_minimal(base_size = 11)

price_plot <- plot_data |>
  filter(outcome == "log_price_per_allowed_sqft") |>
  ggplot(aes(x = event_time, y = estimate_percent, ymin = ci_low_percent, ymax = ci_high_percent)) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey45") +
  geom_vline(xintercept = -0.5, linewidth = 0.3, linetype = "dashed", color = "grey45") +
  geom_errorbar(width = 0.15, linewidth = 0.25, color = "grey35") +
  geom_point(size = 1.4, color = "grey20") +
  facet_wrap(~ exposure_definition, nrow = 1) +
  scale_x_continuous(breaks = seq(event_min, event_max, by = 2)) +
  labs(
    title = "Top-minus-bottom predicted exposure: conditional sale-price event study",
    subtitle = "Non-Staten-Island opportunity lots with complete primary prices; event 0 is 2022 Q3.",
    x = "Quarters relative to 2022 Q3",
    y = "Approximate price difference (%)"
  ) +
  theme_minimal(base_size = 11)

ggsave("../output/simple_logit_sales_event_study_sale_incidence.pdf", sale_plot, width = 9, height = 4.8, device = "pdf")
ggsave("../output/simple_logit_sales_event_study_log_price.pdf", price_plot, width = 9, height = 4.8, device = "pdf")

semiannual_plot_reference_rows <- semiannual_event_study |>
  filter(status == "fit") |>
  distinct(analysis_universe, exposure_definition, outcome) |>
  mutate(
    term = "reference_period",
    event_half_time = semiannual_event_reference,
    estimate = 0,
    std_error = NA_real_,
    t_value = NA_real_,
    p_value = NA_real_,
    ci_low = 0,
    ci_high = 0,
    observations = NA_integer_,
    r2 = NA_real_,
    within_r2 = NA_real_,
    fixed_effects = NA_character_,
    event_reference = semiannual_event_reference,
    event_min = semiannual_event_min,
    event_max = semiannual_event_max,
    status = "reference_period",
    estimate_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    ci_low_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    ci_high_per_1000 = if_else(outcome == "sale_incidence", 0, NA_real_),
    estimate_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_),
    ci_low_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_),
    ci_high_percent = if_else(outcome == "log_price_per_allowed_sqft", 0, NA_real_)
  )

semiannual_plot_data <- bind_rows(semiannual_event_study, semiannual_plot_reference_rows) |>
  filter(status %in% c("fit", "reference_period"))

semiannual_sale_plot <- semiannual_plot_data |>
  filter(outcome == "sale_incidence") |>
  ggplot(aes(x = event_half_time, y = estimate_per_1000, ymin = ci_low_per_1000, ymax = ci_high_per_1000)) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey45") +
  geom_vline(xintercept = -0.5, linewidth = 0.3, linetype = "dashed", color = "grey45") +
  geom_errorbar(width = 0.10, linewidth = 0.25, color = "grey35") +
  geom_point(size = 1.4, color = "grey20") +
  facet_wrap(~ exposure_definition, nrow = 1) +
  scale_x_continuous(breaks = seq(semiannual_event_min, semiannual_event_max, by = 1)) +
  labs(
    title = "Top-minus-bottom predicted exposure: semi-annual sale incidence event study",
    subtitle = "Non-Staten-Island opportunity lots; event 0 is 2022 H2; omitted half-year is 2021 H2.",
    x = "Half-years relative to 2022 H2",
    y = "Difference in sale incidence per 1,000 lot-half-years"
  ) +
  theme_minimal(base_size = 11)

semiannual_price_plot <- semiannual_plot_data |>
  filter(outcome == "log_price_per_allowed_sqft") |>
  ggplot(aes(x = event_half_time, y = estimate_percent, ymin = ci_low_percent, ymax = ci_high_percent)) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "grey45") +
  geom_vline(xintercept = -0.5, linewidth = 0.3, linetype = "dashed", color = "grey45") +
  geom_errorbar(width = 0.10, linewidth = 0.25, color = "grey35") +
  geom_point(size = 1.4, color = "grey20") +
  facet_wrap(~ exposure_definition, nrow = 1) +
  scale_x_continuous(breaks = seq(semiannual_event_min, semiannual_event_max, by = 1)) +
  labs(
    title = "Top-minus-bottom predicted exposure: semi-annual conditional sale-price event study",
    subtitle = "Non-Staten-Island opportunity lots with complete primary prices; event 0 is 2022 H2.",
    x = "Half-years relative to 2022 H2",
    y = "Approximate price difference (%)"
  ) +
  theme_minimal(base_size = 11)

ggsave("../output/simple_logit_sales_semiannual_event_study_sale_incidence.pdf", semiannual_sale_plot, width = 9, height = 4.8, device = "pdf")
ggsave("../output/simple_logit_sales_semiannual_event_study_log_price.pdf", semiannual_price_plot, width = 9, height = 4.8, device = "pdf")

write_csv_if_changed(period_did, "../output/simple_logit_sales_period_did.csv")
write_csv_if_changed(event_study, "../output/simple_logit_sales_event_study.csv")
write_csv_if_changed(semiannual_period_did, "../output/simple_logit_sales_semiannual_period_did.csv")
write_csv_if_changed(semiannual_event_study, "../output/simple_logit_sales_semiannual_event_study.csv")
write_csv_if_changed(semiannual_period_summary, "../output/simple_logit_sales_semiannual_period_summary.csv")
write_csv_if_changed(period_summary, "../output/simple_logit_sales_period_summary.csv")
write_csv_if_changed(exposure_lot_counts, "../output/simple_logit_sales_exposure_lot_counts.csv")
write_csv_if_changed(reference_coefficients, "../output/simple_logit_sales_reference_model.csv")
write_csv_if_changed(hard_checks, "../output/simple_logit_sales_hard_checks.csv")

cat("Wrote simple-logit sales event-study audit outputs to ../output\n")

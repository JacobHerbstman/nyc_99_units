# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_floor_space_adjustment/code")
# train_start_year <- 2021L
# train_end_year <- 2022L
# post_year <- 2025L
# min_units <- 50L
# max_units <- 150L
# bunch_units <- 99L
# min_gross_sqft_per_unit <- 300
# min_category_rows <- 10L
# no_notch_min_units <- 6L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/parent_no_notch_model.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 9L) {
  stop(
    "Expected training years, post year, unit bounds, bunching count, ",
    "minimum gross square feet per unit, minimum category rows, and the ",
    "no-notch conditioning floor."
  )
}

train_start_year <- as.integer(args[1])
train_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
max_units <- as.integer(args[5])
bunch_units <- as.integer(args[6])
min_gross_sqft_per_unit <- as.numeric(args[7])
min_category_rows <- as.integer(args[8])
no_notch_min_units <- as.integer(args[9])

if (
  any(is.na(c(
    train_start_year, train_end_year, post_year, min_units, max_units,
    bunch_units, min_gross_sqft_per_unit, min_category_rows,
    no_notch_min_units
  ))) ||
    train_start_year > train_end_year || train_end_year >= post_year ||
    min_units >= bunch_units || bunch_units >= max_units ||
    min_gross_sqft_per_unit <= 0 || min_category_rows < 2L ||
    no_notch_min_units < 1L || no_notch_min_units >= bunch_units
) {
  stop("Floor-space audit arguments are not internally consistent.")
}

prepare_area_model_data <- function(training_rows, scoring_rows) {
  for (feature_name in c("borough", "zone_detail", "prior_site_use")) {
    training_values <- str_squish(as.character(training_rows[[feature_name]]))
    scoring_values <- str_squish(as.character(scoring_rows[[feature_name]]))
    training_values[is.na(training_values) | training_values == ""] <- "missing"
    scoring_values[is.na(scoring_values) | scoring_values == ""] <- "missing"

    training_counts <- table(training_values)
    keep_levels <- names(training_counts)[training_counts >= min_category_rows]
    training_values[!(training_values %in% keep_levels)] <- "other_rare"
    model_levels <- sort(unique(training_values))
    fallback_level <- if ("other_rare" %in% model_levels) {
      "other_rare"
    } else {
      names(sort(training_counts, decreasing = TRUE))[1]
    }
    scoring_values[!(scoring_values %in% keep_levels)] <- fallback_level

    training_rows[[feature_name]] <- factor(
      training_values,
      levels = model_levels
    )
    scoring_rows[[feature_name]] <- factor(
      scoring_values,
      levels = model_levels
    )
  }

  list(training = training_rows, scoring = scoring_rows)
}

fit_area_model <- function(training_rows, scoring_rows) {
  prepared <- prepare_area_model_data(training_rows, scoring_rows)
  fitted_model <- lm(
    log_total_gross_area ~ log_units + log_lotarea + residfar + builtfar +
      borough + zone_detail + prior_site_use,
    data = prepared$training
  )

  if (any(is.na(coef(fitted_model)))) {
    stop("The gross-area model contains aliased coefficients.")
  }

  predictions <- predict(fitted_model, newdata = prepared$scoring)

  if (any(!is.finite(predictions))) {
    stop("The gross-area model produced non-finite predictions.")
  }

  list(
    model = fitted_model,
    training = prepared$training,
    scoring = prepared$scoring,
    predictions = as.numeric(predictions)
  )
}

historical_panel <- read_parquet(
  "../input/historical_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_enhanced_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

dob_initial <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

model_scores <- read_parquet(
  "../input/enhanced_parent_2025_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble()

model_counterfactual <- read_csv(
  "../input/enhanced_parent_2025_counterfactual.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

hpd_parent_summary <- read_csv(
  "../input/hpd_485x_parent_registration_summary.csv",
  show_col_types = FALSE,
  na = c("", "NA")
) |>
  filter(parent_definition == "symmetric_parent")

if (
  nrow(historical_panel) == 0L || nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$parent_id) ||
    anyDuplicated(post_panel$parent_id) ||
    anyDuplicated(membership[c("sample", "root_job_id")]) ||
    anyDuplicated(dob_initial$job_number) ||
    anyDuplicated(model_scores$observation_id) ||
    nrow(model_counterfactual) != 1L ||
    anyDuplicated(hpd_parent_summary$parent_id)
) {
  stop("A floor-space audit input failed identifier QC.")
}

parent_areas <- membership |>
  select(sample, parent_id, root_job_id) |>
  left_join(
    dob_initial |>
      select(
        root_job_id = job_number,
        component_total_construction_floor_area =
          total_construction_floor_area
      ),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  group_by(sample, parent_id) |>
  summarise(
    component_rows = n(),
    positive_area_rows = sum(
      !is.na(component_total_construction_floor_area) &
        component_total_construction_floor_area > 0
    ),
    total_gross_construction_area = if_else(
      positive_area_rows == component_rows,
      sum(component_total_construction_floor_area),
      NA_real_
    ),
    .groups = "drop"
  )

historical_rows <- historical_panel |>
  left_join(
    parent_areas |>
      filter(sample == "historical") |>
      select(-sample),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    gross_sqft_per_dob_unit =
      total_gross_construction_area / units_dob_i1
  )

training_candidates <- historical_rows |>
  filter(
    analysis_status == "historical_fully_observed",
    model_eligible,
    cohort_year >= train_start_year,
    cohort_year <= train_end_year,
    units_dob_i1 >= min_units,
    units_dob_i1 <= max_units
  )

training_rows <- training_candidates |>
  filter(
    !is.na(total_gross_construction_area),
    total_gross_construction_area > 0,
    gross_sqft_per_dob_unit >= min_gross_sqft_per_unit,
    !is.na(log_lotarea),
    !is.na(residfar),
    !is.na(builtfar)
  ) |>
  mutate(
    log_units = log(units_dob_i1),
    log_total_gross_area = log(total_gross_construction_area)
  )

post_candidates <- post_panel |>
  inner_join(
    model_scores |>
      select(
        observation_id,
        score_observed_units = observed_units,
        predicted_log_units,
        probability_exact_99,
        probability_at_least_100
      ),
    by = "observation_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    parent_areas |>
      filter(sample == "post_policy") |>
      select(-sample),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(
    cohort_year == post_year,
    units_hdb_priority >= min_units,
    units_hdb_priority <= max_units
  ) |>
  mutate(
    log_units = log(units_dob_i1),
    log_total_gross_area = log(total_gross_construction_area),
    observed_gross_sqft_per_unit =
      total_gross_construction_area / units_dob_i1
  )

post_rows <- post_candidates |>
  filter(units_hdb_priority == units_dob_i1)

affected_frontier <- model_counterfactual$frontier_from_exact_99
shock_sigma <- model_counterfactual$shock_sigma
affected_unit_grid <- (bunch_units + 1L):floor(affected_frontier + 0.5)
affected_bin_fraction <- pmin(
  pmax(affected_frontier - (affected_unit_grid - 0.5), 0),
  1
)

if (
  !is.finite(affected_frontier) || affected_frontier <= bunch_units + 0.5 ||
    !is.finite(shock_sigma) || shock_sigma <= 0 ||
    length(affected_unit_grid) == 0L ||
    any(affected_bin_fraction <= 0) || any(affected_bin_fraction > 1)
) {
  stop("The affected no-notch range is invalid.")
}

post_rows$affected_range_probability <- NA_real_
post_rows$affected_n0_mean_units <- NA_real_
post_rows$affected_n0_mean_log_units <- NA_real_

for (row_index in which(post_rows$units_hdb_priority == bunch_units)) {
  affected_probability <- exp(rounded_conditional_log_probability(
    affected_unit_grid,
    rep(post_rows$predicted_log_units[row_index], length(affected_unit_grid)),
    shock_sigma,
    no_notch_min_units
  )) * affected_bin_fraction
  probability_sum <- sum(affected_probability)

  if (!is.finite(probability_sum) || probability_sum <= 0) {
    stop("An exact-99 parent has no probability in the affected range.")
  }

  post_rows$affected_range_probability[row_index] <- probability_sum
  post_rows$affected_n0_mean_units[row_index] <- sum(
    affected_unit_grid * affected_probability
  ) / probability_sum
  post_rows$affected_n0_mean_log_units[row_index] <- sum(
    log(affected_unit_grid) * affected_probability
  ) / probability_sum
}

if (
  nrow(training_rows) == 0L || nrow(post_rows) == 0L ||
    any(post_candidates$score_observed_units !=
      post_candidates$units_hdb_priority) ||
    any(post_rows$units_hdb_priority != post_rows$units_dob_i1) ||
    sum(
      post_candidates$units_hdb_priority == bunch_units &
        post_candidates$units_hdb_priority != post_candidates$units_dob_i1
    ) > 0L ||
    any(is.na(post_rows$total_gross_construction_area)) ||
    any(post_rows$total_gross_construction_area <= 0) ||
    any(is.na(post_rows[c("log_lotarea", "residfar", "builtfar")]))
) {
  stop("Training or post-policy floor-space rows failed sample QC.")
}

full_fit <- fit_area_model(training_rows, post_rows)
scoring_observed_units <- full_fit$scoring
scoring_affected_n0 <- scoring_observed_units
scoring_affected_n0$log_units[
  !is.na(scoring_affected_n0$affected_n0_mean_log_units)
] <- scoring_affected_n0$affected_n0_mean_log_units[
  !is.na(scoring_affected_n0$affected_n0_mean_log_units)
]

predicted_log_area_observed_units <- full_fit$predictions
predicted_log_area_affected_n0 <- predict(
  full_fit$model,
  newdata = scoring_affected_n0
)
predicted_log_area_affected_n0[
  is.na(post_rows$affected_n0_mean_log_units)
] <- NA_real_

post_scored <- post_rows |>
  mutate(
    predicted_median_area_at_observed_units =
      exp(predicted_log_area_observed_units),
    predicted_median_area_at_affected_n0 =
      exp(predicted_log_area_affected_n0),
    observed_to_predicted_at_observed_units_ratio =
      total_gross_construction_area /
        predicted_median_area_at_observed_units,
    observed_to_predicted_affected_n0_area_ratio =
      total_gross_construction_area /
        predicted_median_area_at_affected_n0,
    model_implied_area_retention_at_observed_units =
      predicted_median_area_at_observed_units /
        predicted_median_area_at_affected_n0,
    predicted_affected_n0_gross_sqft_per_unit =
      predicted_median_area_at_affected_n0 / affected_n0_mean_units,
    log_area_residual_at_observed_units =
      log_total_gross_area - predicted_log_area_observed_units,
    log_area_gap_from_affected_n0 =
      log_total_gross_area - predicted_log_area_affected_n0,
    unit_group = case_when(
      units_hdb_priority < 90L ~ "50-89 units",
      units_hdb_priority < bunch_units ~ "90-98 units",
      units_hdb_priority == bunch_units ~ "99 units",
      TRUE ~ "100-150 units"
    ),
    parent_structure = if_else(
      component_filings == 1L,
      "One component filing",
      "Multiple component filings"
    )
  ) |>
  left_join(
    hpd_parent_summary |>
      select(
        parent_id,
        hpd_registered_components = registered_component_count,
        hpd_option_b_sub100_components =
          registered_option_b_sub100_count,
        hpd_registration_pattern = descriptive_registration_pattern
      ),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    hpd_public_status = case_when(
      hpd_option_b_sub100_components > 0L ~
        "Public Option B registration",
      hpd_registered_components > 0L ~ "Other public registration",
      TRUE ~ "No public registration match"
    )
  ) |>
  transmute(
    parent_id,
    cohort_date,
    observed_units_hdb = units_hdb_priority,
    observed_units_dob = units_dob_i1,
    unconditional_predicted_log_units = predicted_log_units,
    affected_frontier_units = affected_frontier,
    affected_range_probability,
    affected_n0_mean_units,
    probability_at_least_100,
    unit_group,
    component_filings,
    distinct_bins,
    parent_structure,
    total_gross_construction_area,
    observed_gross_sqft_per_unit,
    predicted_median_area_at_observed_units,
    predicted_median_area_at_affected_n0,
    predicted_affected_n0_gross_sqft_per_unit,
    observed_to_predicted_at_observed_units_ratio,
    observed_to_predicted_affected_n0_area_ratio,
    model_implied_area_retention_at_observed_units,
    log_area_residual_at_observed_units,
    log_area_gap_from_affected_n0,
    hpd_public_status,
    hpd_registered_components = coalesce(hpd_registered_components, 0L),
    hpd_option_b_sub100_components = coalesce(
      hpd_option_b_sub100_components,
      0L
    ),
    hpd_registration_pattern
  ) |>
  arrange(observed_units_hdb, parent_id)

summary_rows <- bind_rows(
  post_scored |>
    mutate(summary_group = unit_group),
  post_scored |>
    filter(observed_units_hdb == bunch_units) |>
    mutate(summary_group = paste0("99 units: ", hpd_public_status))
) |>
  group_by(summary_group) |>
  summarise(
    parents = n(),
    median_observed_units = median(observed_units_hdb),
    median_affected_n0_units = if_else(
      all(is.na(affected_n0_mean_units)),
      NA_real_,
      median(affected_n0_mean_units, na.rm = TRUE)
    ),
    median_total_gross_construction_area = median(
      total_gross_construction_area
    ),
    median_predicted_area_at_affected_n0 = if_else(
      all(is.na(predicted_median_area_at_affected_n0)),
      NA_real_,
      median(predicted_median_area_at_affected_n0, na.rm = TRUE)
    ),
    median_observed_to_predicted_affected_n0_area_ratio = if_else(
      all(is.na(observed_to_predicted_affected_n0_area_ratio)),
      NA_real_,
      median(observed_to_predicted_affected_n0_area_ratio, na.rm = TRUE)
    ),
    median_observed_to_predicted_at_observed_units_ratio = median(
      observed_to_predicted_at_observed_units_ratio
    ),
    median_model_implied_area_retention_at_observed_units = if_else(
      all(is.na(model_implied_area_retention_at_observed_units)),
      NA_real_,
      median(
        model_implied_area_retention_at_observed_units,
        na.rm = TRUE
      )
    ),
    median_observed_gross_sqft_per_unit = median(
      observed_gross_sqft_per_unit
    ),
    median_predicted_affected_n0_gross_sqft_per_unit = if_else(
      all(is.na(predicted_affected_n0_gross_sqft_per_unit)),
      NA_real_,
      median(predicted_affected_n0_gross_sqft_per_unit, na.rm = TRUE)
    ),
    multiple_component_parents = sum(component_filings > 1L),
    public_option_b_parents = sum(
      hpd_public_status == "Public Option B registration"
    ),
    .groups = "drop"
  )

full_training_predictions <- fitted(full_fit$model)

model_diagnostics <- tibble(
  evaluation = "Full model in-sample",
  training_years = paste(train_start_year, train_end_year, sep = "-"),
  training_parents = nrow(training_rows),
  evaluation_parents = nrow(training_rows),
  rmse_log_area = sqrt(mean(
    (training_rows$log_total_gross_area - full_training_predictions)^2
  )),
  median_absolute_percent_error = median(abs(
    exp(training_rows$log_total_gross_area - full_training_predictions) - 1
  )),
  correlation_log_area = cor(
    training_rows$log_total_gross_area,
    full_training_predictions
  ),
  r_squared = summary(full_fit$model)$r.squared,
  log_units_coefficient = coef(full_fit$model)[["log_units"]],
  candidate_parents = nrow(training_candidates),
  candidate_parents_missing_area = sum(
    is.na(training_candidates$total_gross_construction_area)
  ),
  candidate_parents_below_minimum_gross_sqft = sum(
    !is.na(training_candidates$gross_sqft_per_dob_unit) &
      training_candidates$gross_sqft_per_dob_unit <
        min_gross_sqft_per_unit
  ),
  post_candidate_parents = nrow(post_candidates),
  post_unit_disagreement_exclusions = sum(
    post_candidates$units_hdb_priority != post_candidates$units_dob_i1
  )
)

for (evaluation_year in train_start_year:train_end_year) {
  validation_training <- training_rows |>
    filter(cohort_year != evaluation_year)
  validation_rows <- training_rows |>
    filter(cohort_year == evaluation_year)
  validation_fit <- fit_area_model(validation_training, validation_rows)
  validation_residual <-
    validation_rows$log_total_gross_area - validation_fit$predictions

  model_diagnostics <- bind_rows(
    model_diagnostics,
    tibble(
      evaluation = paste0("Hold out ", evaluation_year),
      training_years = paste(
        sort(unique(validation_training$cohort_year)),
        collapse = ";"
      ),
      training_parents = nrow(validation_training),
      evaluation_parents = nrow(validation_rows),
      rmse_log_area = sqrt(mean(validation_residual^2)),
      median_absolute_percent_error = median(abs(
        exp(validation_residual) - 1
      )),
      correlation_log_area = cor(
        validation_rows$log_total_gross_area,
        validation_fit$predictions
      ),
      r_squared = NA_real_,
      log_units_coefficient = coef(validation_fit$model)[["log_units"]],
      candidate_parents = NA_integer_,
      candidate_parents_missing_area = NA_integer_,
      candidate_parents_below_minimum_gross_sqft = NA_integer_,
      post_candidate_parents = NA_integer_,
      post_unit_disagreement_exclusions = NA_integer_
    )
  )
}

coefficient_matrix <- summary(full_fit$model)$coefficients
model_coefficients <- tibble(
  term = rownames(coefficient_matrix),
  estimate = coefficient_matrix[, "Estimate"],
  standard_error = coefficient_matrix[, "Std. Error"],
  t_statistic = coefficient_matrix[, "t value"],
  p_value = coefficient_matrix[, "Pr(>|t|)"]
)

exact_99_rows <- post_scored |>
  filter(observed_units_hdb == bunch_units) |>
  mutate(
    hpd_public_status = factor(
      hpd_public_status,
      levels = c(
        "No public registration match",
        "Public Option B registration",
        "Other public registration"
      )
    )
  )

area_plot <- ggplot(
  post_scored |>
    mutate(
      unit_group = factor(
        unit_group,
        levels = c(
          "50-89 units", "90-98 units", "99 units", "100-150 units"
        )
      ),
      exact_99_status = if_else(
        observed_units_hdb == bunch_units,
        "Exact 99",
        "Other unit count"
      )
    ),
  aes(
    x = unit_group,
    y = observed_to_predicted_at_observed_units_ratio,
    color = exact_99_status
  )
) +
  geom_hline(yintercept = 1, color = "#4D4D4D", linewidth = 0.5) +
  geom_jitter(width = 0.12, height = 0, size = 1.7, alpha = 0.55) +
  stat_summary(
    fun = median,
    geom = "point",
    shape = 18,
    size = 4,
    show.legend = FALSE
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_color_manual(values = c(
    "Other unit count" = "#8C8C8C",
    "Exact 99" = "#D55E00"
  )) +
  labs(
    title = "Exact-99 area residuals resemble nearby projects",
    subtitle = "Diamonds show group medians.",
    x = NULL,
    y = "Observed area / predicted area at observed units",
    color = NULL
  )

retention_plot <- ggplot(
  exact_99_rows,
  aes(
    x = affected_n0_mean_units,
    y = model_implied_area_retention_at_observed_units,
    color = hpd_public_status
  )
) +
  geom_hline(yintercept = 1, color = "#4D4D4D", linewidth = 0.5) +
  geom_point(size = 2.4, alpha = 0.85) +
  scale_y_continuous(
    limits = c(0.84, 1.01),
    labels = percent_format(accuracy = 1)
  ) +
  scale_color_manual(values = c(
    "No public registration match" = "#8C8C8C",
    "Public Option B registration" = "#0072B2",
    "Other public registration" = "#D55E00"
  )) +
  labs(
    title = "The affected scenario implies partial physical downsizing",
    x = "Mean no-notch units conditional on the affected range",
    y = "Predicted area at 99 / predicted area at no-notch size",
    color = NULL
  )

floor_space_figure <- area_plot + retention_plot +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = "Exact-99 parents do not show a fixed-envelope pattern in gross area",
    subtitle = paste0(
      "The 99-unit median area residual is ",
      percent(median(exact_99_rows$observed_to_predicted_at_observed_units_ratio), accuracy = 1),
      "; the other-parent median is ",
      percent(median(
        post_scored$observed_to_predicted_at_observed_units_ratio[
          post_scored$observed_units_hdb != bunch_units
        ]
      ), accuracy = 1), "."
    ),
    caption = paste0(
      "DOB total construction area includes common, mechanical, parking, and ",
      "nonresidential space; it is not residential or apartment area. " ,
      "The right panel conditions on being an affected buncher; it does not ",
      "classify individual parents. HPD points are public registrations, not ",
      "final Eligible Site determinations."
    ),
    theme = theme(
      plot.title = element_text(face = "bold"),
      plot.title.position = "plot",
      plot.caption.position = "plot"
    )
  ) &
  theme_minimal(base_size = 11) &
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(exact_99_rows) == 0L ||
    anyDuplicated(post_scored$parent_id) ||
    any(!is.finite(exact_99_rows$predicted_median_area_at_affected_n0)) ||
    any(exact_99_rows$predicted_median_area_at_affected_n0 <= 0) ||
    any(!is.finite(
      exact_99_rows$observed_to_predicted_affected_n0_area_ratio
    )) ||
    nrow(model_diagnostics) != 1L +
      (train_end_year - train_start_year + 1L)
) {
  stop("Floor-space audit outputs failed final QC.")
}

write_csv_if_changed(
  post_scored,
  "../output/parent_floor_space_ledger.csv"
)
write_csv_if_changed(
  summary_rows,
  "../output/parent_floor_space_summary.csv"
)
write_csv_if_changed(
  model_diagnostics,
  "../output/parent_floor_space_model_diagnostics.csv"
)
write_csv_if_changed(
  model_coefficients,
  "../output/parent_floor_space_model_coefficients.csv"
)
ggsave(
  "../output/parent_floor_space_adjustment.pdf",
  floor_space_figure,
  width = 11,
  height = 6.3,
  device = "pdf"
)
ggsave(
  "../output/parent_floor_space_adjustment.png",
  floor_space_figure,
  width = 11,
  height = 6.3,
  dpi = 180,
  bg = "white"
)

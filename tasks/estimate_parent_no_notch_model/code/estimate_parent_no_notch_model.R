# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_parent_no_notch_model/code")
# unit_spec <- "hdb_priority"
# cohort_sample <- "mature"
# post_year <- 2025L
# minimum_followup_days <- 180L
# min_units <- 6L
# minimum_category_rows <- 30L
# counterfactual_max_units <- 400L
# plot_min_units <- 50L
# plot_max_units <- 220L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 9L) {
  stop(
    "Expected unit and cohort specifications, post year, minimum follow-up, ",
    "unit and category floors, counterfactual maximum units, and plot limits."
  )
}

unit_spec <- args[1]
cohort_sample <- args[2]
post_year <- as.integer(args[3])
minimum_followup_days <- as.integer(args[4])
min_units <- as.integer(args[5])
minimum_category_rows <- as.integer(args[6])
counterfactual_max_units <- as.integer(args[7])
plot_min_units <- as.integer(args[8])
plot_max_units <- as.integer(args[9])

if (
  !(unit_spec %in% c("hdb_priority", "dob_i1_complete_case")) ||
  !(cohort_sample %in% c("mature", "completed_365")) ||
  (unit_spec == "dob_i1_complete_case" && cohort_sample != "mature") ||
  any(is.na(c(
    post_year, minimum_followup_days, min_units, minimum_category_rows,
    counterfactual_max_units,
    plot_min_units, plot_max_units
  ))) ||
    minimum_followup_days < 1L ||
    minimum_followup_days >= 365L ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    counterfactual_max_units < 120L ||
    plot_min_units < min_units ||
    plot_min_units >= plot_max_units ||
    plot_max_units > counterfactual_max_units
) {
  stop("Parent-model arguments are not internally consistent.")
}

source("../../_lib/parent_no_notch_model.R")

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

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

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id) ||
    anyDuplicated(membership[c("sample", "job_number")])
) {
  stop("Symmetric parent-model inputs failed key QC.")
}

training_rows <- historical_panel |>
  filter(
    model_eligible,
    analysis_status == "historical_fully_observed",
    cohort_year >= 2019L,
    cohort_year <= 2022L
  ) |>
  mutate(
    units = units_hdb_priority,
    log_units = log(units)
  )

post_followup <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(
    parent_id, cohort_date, source_end_date,
    left_window_observed
  ) |>
  mutate(
    observed_followup_days = as.integer(source_end_date - cohort_date)
  )

if (
  anyDuplicated(post_followup$parent_id) ||
    any(is.na(post_followup$observed_followup_days))
) {
  stop("Post-policy follow-up is not unique and complete by parent.")
}

post_rows <- post_panel |>
  left_join(
    post_followup |>
      select(parent_id, observed_followup_days, left_window_observed),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(cohort_year == post_year)

if (cohort_sample == "mature") {
  post_rows <- post_rows |>
    filter(
      left_window_observed,
      observed_followup_days >= minimum_followup_days
    )
  cohort_label <- paste0(
    post_year, " cohorts observed for at least ",
    minimum_followup_days, " days"
  )
  model_sample_name <- paste0("mature_", minimum_followup_days)
  reported_followup_days <- minimum_followup_days
  cohort_caption <- paste0(
    "A post-policy cohort enters after ", minimum_followup_days,
    " observed days; parent links continue through day 365."
  )
} else {
  post_rows <- post_rows |>
    filter(analysis_status == paste0("completed_", post_year, "_cohort"))
  cohort_label <- paste0(
    post_year, " cohorts with a complete 365-day forward window"
  )
  model_sample_name <- "completed_365"
  reported_followup_days <- 365L
  cohort_caption <- paste0(
    "Post-policy cohorts have complete 365-day forward windows; historical ",
    "and post parents use the same link rule."
  )
}

observed_post_parents <- nrow(post_rows)

if (unit_spec == "hdb_priority") {
  score_rows <- post_rows |>
    filter(model_eligible) |>
    mutate(
      units = units_hdb_priority,
      log_units = log(units)
    )
  model_name <- paste0(
    "symmetric_parent_2019_2022_", model_sample_name, "_", post_year
  )
  unit_label <- "HDB units (primary)"
} else {
  score_rows <- post_rows |>
    filter(model_eligible, units_dob_i1 >= min_units) |>
    mutate(
      units = units_dob_i1,
      log_units = log(units)
    )
  model_name <- paste0(
    "symmetric_parent_2019_2022_", model_sample_name, "_", post_year,
    "_dob_i1"
  )
  unit_label <- "DOB initial-filing units (sensitivity)"
}

fitted_model <- fit_rounded_mle(
  training_rows,
  score_rows,
  min_units,
  minimum_category_rows,
  model_formula
)

scores <- score_rows |>
  mutate(
    unit_definition = unit_spec,
    cohort_sample = model_sample_name,
    minimum_observed_followup_days = reported_followup_days,
    predicted_log_units = fitted_model$test_mu,
    probability_observed = exp(rounded_conditional_log_probability(
      units,
      predicted_log_units,
      fitted_model$sigma,
      min_units
    )),
    probability_exact_99 = exp(rounded_conditional_log_probability(
      rep(99L, n()),
      predicted_log_units,
      fitted_model$sigma,
      min_units
    )),
    probability_at_least_100 = exp(
      pnorm(
        (log(99.5) - predicted_log_units) / fitted_model$sigma,
        lower.tail = FALSE,
        log.p = TRUE
      ) - pnorm(
        (log(min_units - 0.5) - predicted_log_units) /
          fitted_model$sigma,
        lower.tail = FALSE,
        log.p = TRUE
      )
    )
  ) |>
  select(
    observation_id, unit_definition, cohort_sample,
    minimum_observed_followup_days, observed_units = units,
    component_filings,
    predicted_log_units, probability_observed,
    probability_exact_99, probability_at_least_100
  ) |>
  arrange(observation_id)

expected_counts <- numeric(counterfactual_max_units + 1L)

for (score_row in seq_len(nrow(scores))) {
  expected_counts <- expected_counts + unit_distribution(
    scores$predicted_log_units[score_row],
    fitted_model$sigma,
    min_units,
    counterfactual_max_units
  )
}

observed_counts <- tabulate(
  scores$observed_units + 1L,
  nbins = counterfactual_max_units + 1L
)

distribution <- tibble(
  model = model_name,
  unit_definition = unit_spec,
  cohort_sample = model_sample_name,
  minimum_observed_followup_days = reported_followup_days,
  units = min_units:counterfactual_max_units,
  expected_count = expected_counts[
    (min_units:counterfactual_max_units) + 1L
  ],
  observed_count = observed_counts[
    (min_units:counterfactual_max_units) + 1L
  ]
)

observed_exact_99 <- sum(scores$observed_units == 99L)
expected_exact_99 <- sum(scores$probability_exact_99)
observed_100_plus <- sum(scores$observed_units >= 100L)
expected_100_plus <- sum(scores$probability_at_least_100)
excess_exact_99 <- observed_exact_99 - expected_exact_99
missing_100_plus <- expected_100_plus - observed_100_plus

counterfactual <- tibble(
  model = model_name,
  unit_definition = unit_spec,
  cohort_sample = model_sample_name,
  minimum_observed_followup_days = reported_followup_days,
  requires_complete_left_window = TRUE,
  training_parents = nrow(training_rows),
  observed_2025_parents = observed_post_parents,
  model_eligible_2025_parents = sum(post_rows$model_eligible),
  scoreable_2025_parents = nrow(scores),
  excluded_unscoreable_2025_parents =
    observed_post_parents - nrow(scores),
  component_filings = sum(scores$component_filings),
  observed_exact_99,
  expected_no_notch_exact_99 = expected_exact_99,
  excess_exact_99,
  observed_100_plus,
  expected_no_notch_100_plus = expected_100_plus,
  missing_100_plus,
  conservation_gap = excess_exact_99 - missing_100_plus,
  frontier_from_exact_99 = solve_discrete_frontier(
    excess_exact_99,
    distribution,
    100L
  ),
  frontier_from_missing_100_plus = solve_discrete_frontier(
    missing_100_plus,
    distribution,
    100L
  ),
  mean_n0_from_exact_99 = implied_affected_mean(
    excess_exact_99,
    distribution,
    100L
  ),
  mean_n0_from_missing_100_plus = implied_affected_mean(
    missing_100_plus,
    distribution,
    100L
  ),
  shock_sigma = fitted_model$sigma
)

parameters <- tibble(
  model = model_name,
  unit_definition = unit_spec,
  training_start_year = 2019L,
  training_end_year = 2022L,
  training_parents = nrow(training_rows),
  training_year_mean = fitted_model$training_year_mean,
  term = c(names(fitted_model$coefficients), "shock_sigma"),
  estimate = c(fitted_model$coefficients, fitted_model$sigma)
)

if (
  any(!is.finite(parameters$estimate)) ||
    any(scores$probability_observed < 0) ||
    any(scores$probability_exact_99 < 0) ||
    any(scores$probability_at_least_100 < 0) ||
    any(scores$probability_at_least_100 > 1 + 1e-10) ||
    !is.finite(counterfactual$conservation_gap)
) {
  stop("Symmetric parent-model outputs failed final QC.")
}

counterfactual_plot <- distribution |>
  filter(units >= plot_min_units, units <= plot_max_units) |>
  ggplot(aes(x = units)) +
  geom_col(
    aes(y = observed_count),
    fill = "#B8B8B8",
    width = 0.9
  ) +
  geom_line(
    aes(y = expected_count),
    color = "#1769AA",
    linewidth = 0.9
  ) +
  geom_vline(xintercept = 99.5, color = "#E6550D", linetype = "dashed") +
  scale_x_continuous(
    breaks = c(plot_min_units, 75L, 100L, 125L, 150L, 175L, 198L, plot_max_units),
    expand = expansion(mult = c(0.005, 0.01))
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(
    title = "Parent opportunities bunch below the 100-unit threshold",
    subtitle = paste0(
      cohort_label, " and the no-notch distribution estimated from fully ",
      "observed 2019-2022 cohorts; ", unit_label
    ),
    x = "Proposed dwelling units per parent opportunity",
    y = "Parent opportunities",
    caption = paste0(
      "Gray bars are observed counts. The blue line is the fitted no-notch ",
      "distribution. ", cohort_caption
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.title.position = "plot"
  )

if (unit_spec == "hdb_priority" && cohort_sample == "mature") {
  write_csv_if_changed(
    counterfactual,
    "../output/enhanced_parent_2025_counterfactual.csv"
  )
  write_csv_if_changed(
    parameters,
    "../output/enhanced_parent_model_parameters.csv"
  )
  write_parquet_if_changed(
    scores,
    "../output/enhanced_parent_2025_scores.parquet"
  )
  write_csv_if_changed(
    distribution,
    "../output/enhanced_parent_2025_distribution.csv"
  )
  ggsave(
    "../output/enhanced_parent_2025_counterfactual.pdf",
    counterfactual_plot,
    width = 10,
    height = 6.5,
    bg = "white"
  )
} else if (unit_spec == "hdb_priority") {
  write_csv_if_changed(
    counterfactual,
    "../output/enhanced_parent_completed_365_2025_counterfactual.csv"
  )
  write_parquet_if_changed(
    scores,
    "../output/enhanced_parent_completed_365_2025_scores.parquet"
  )
  write_csv_if_changed(
    distribution,
    "../output/enhanced_parent_completed_365_2025_distribution.csv"
  )
  ggsave(
    "../output/enhanced_parent_completed_365_2025_counterfactual.pdf",
    counterfactual_plot,
    width = 10,
    height = 6.5,
    bg = "white"
  )
} else {
  write_csv_if_changed(
    counterfactual,
    "../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.csv"
  )
  write_csv_if_changed(
    parameters,
    "../output/enhanced_parent_dob_i1_complete_case_model_parameters.csv"
  )
  write_parquet_if_changed(
    scores,
    "../output/enhanced_parent_dob_i1_complete_case_2025_scores.parquet"
  )
  write_csv_if_changed(
    distribution,
    "../output/enhanced_parent_dob_i1_complete_case_2025_distribution.csv"
  )
  ggsave(
    "../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.pdf",
    counterfactual_plot,
    width = 10,
    height = 6.5,
    bg = "white"
  )
}

cat(
  "Wrote symmetric parent-model results for ",
  unit_spec, " and ", model_sample_name, " to ../output\n"
)

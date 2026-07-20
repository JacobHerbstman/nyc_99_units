# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_no_notch_model/code")
# min_units <- 6L
# minimum_category_rows <- 30L
# counterfactual_max_units <- 400L
# plot_min_units <- 50L
# plot_max_units <- 220L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/parent_no_notch_model.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop(
    "Expected five arguments: minimum units, minimum category rows, ",
    "counterfactual maximum units, and plot limits."
  )
}

min_units <- as.integer(args[1])
minimum_category_rows <- as.integer(args[2])
counterfactual_max_units <- as.integer(args[3])
plot_min_units <- as.integer(args[4])
plot_max_units <- as.integer(args[5])

if (
  any(is.na(c(
    min_units, minimum_category_rows, counterfactual_max_units,
    plot_min_units, plot_max_units
  ))) ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    counterfactual_max_units < 120L ||
    plot_min_units < min_units ||
    plot_min_units >= plot_max_units ||
    plot_max_units > counterfactual_max_units
) {
  stop("Symmetric-parent model arguments are not internally consistent.")
}

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

production_counterfactual <- read_csv(
  "../input/enhanced_parent_2025_counterfactual.csv",
  show_col_types = FALSE
)

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id) ||
    nrow(production_counterfactual) != 1L
) {
  stop("A symmetric-parent model input failed key QC.")
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

specifications <- tribble(
  ~cohort_sample, ~unit_definition,
  "completed_2025", "hdb_priority",
  "descriptive_all_2025", "hdb_priority",
  "completed_2025", "dob_i1",
  "descriptive_all_2025", "dob_i1"
)

counterfactual_rows <- list()
parameter_rows <- list()
score_rows_out <- list()
distribution_rows <- list()

for (specification_row in seq_len(nrow(specifications))) {
  cohort_sample <- specifications$cohort_sample[specification_row]
  unit_definition <- specifications$unit_definition[specification_row]

  if (cohort_sample == "completed_2025") {
    cohort_rows <- post_panel |>
      filter(analysis_status == "completed_2025_cohort")
  } else {
    cohort_rows <- post_panel |>
      filter(cohort_year == 2025L)
  }

  if (unit_definition == "hdb_priority") {
    score_rows <- cohort_rows |>
      filter(model_eligible) |>
      mutate(
        units = units_hdb_priority,
        log_units = log(units)
      )
  } else {
    score_rows <- cohort_rows |>
      filter(model_eligible) |>
      mutate(
        units = units_dob_i1,
        log_units = log(units)
      )
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
      cohort_sample = cohort_sample,
      unit_definition = unit_definition,
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
      observation_id, parent_id, analysis_status, cohort_date,
      cohort_sample, unit_definition, observed_units = units,
      component_filings, component_jobs, predicted_log_units,
      probability_observed, probability_exact_99,
      probability_at_least_100
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
    cohort_sample = cohort_sample,
    unit_definition = unit_definition,
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

  counterfactual_rows[[specification_row]] <- tibble(
    model = "symmetric_365_day_parent_full_window",
    cohort_sample,
    unit_definition,
    linkage_universe_start_year = 2018L,
    linkage_universe_end_year = 2023L,
    requested_training_cohort_start_year = 2019L,
    requested_training_cohort_end_year = 2022L,
    training_cohort_start_year = min(training_rows$cohort_year),
    training_cohort_end_year = max(training_rows$cohort_year),
    training_parents = nrow(training_rows),
    observed_cohort_parents = nrow(cohort_rows),
    scoreable_cohort_parents = nrow(scores),
    excluded_unscoreable_parents = nrow(cohort_rows) - nrow(scores),
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

  parameter_rows[[specification_row]] <- tibble(
    model = "symmetric_365_day_parent_full_window",
    cohort_sample,
    unit_definition,
    training_parents = nrow(training_rows),
    training_year_mean = fitted_model$training_year_mean,
    term = c(names(fitted_model$coefficients), "shock_sigma"),
    estimate = c(fitted_model$coefficients, fitted_model$sigma)
  )

  score_rows_out[[specification_row]] <- scores
  distribution_rows[[specification_row]] <- distribution
}

counterfactuals <- bind_rows(counterfactual_rows)
parameters <- bind_rows(parameter_rows)
scores <- bind_rows(score_rows_out)
distributions <- bind_rows(distribution_rows)

comparison <- bind_rows(
  production_counterfactual |>
    transmute(
      specification = "production completed 2025 cohorts",
      training_parents,
      scoreable_2025_parents,
      observed_exact_99,
      expected_no_notch_exact_99,
      excess_exact_99,
      observed_100_plus,
      expected_no_notch_100_plus,
      missing_100_plus,
      conservation_gap,
      frontier_from_exact_99,
      mean_n0_from_exact_99
    ),
  counterfactuals |>
    filter(unit_definition == "hdb_priority") |>
    transmute(
      specification = recode(
        cohort_sample,
        completed_2025 = "symmetric completed 2025 cohorts",
        descriptive_all_2025 = "symmetric all observed 2025 cohorts"
      ),
      training_parents,
      scoreable_2025_parents = scoreable_cohort_parents,
      observed_exact_99,
      expected_no_notch_exact_99,
      excess_exact_99,
      observed_100_plus,
      expected_no_notch_100_plus,
      missing_100_plus,
      conservation_gap,
      frontier_from_exact_99,
      mean_n0_from_exact_99
    )
)

plot_data <- distributions |>
  filter(
    unit_definition == "hdb_priority",
    units >= plot_min_units,
    units <= plot_max_units
  ) |>
  mutate(
    cohort_label = recode(
      cohort_sample,
      completed_2025 = "Completed 2025 cohorts",
      descriptive_all_2025 = "All observed 2025 cohorts"
    ),
    cohort_label = factor(
      cohort_label,
      levels = c(
        "Completed 2025 cohorts",
        "All observed 2025 cohorts"
      )
    )
  )

counterfactual_plot <- ggplot(plot_data, aes(x = units)) +
  geom_col(
    aes(y = observed_count),
    fill = "#0072B2",
    width = 0.82
  ) +
  geom_line(
    aes(y = expected_count),
    color = "#4D4D4D",
    linewidth = 0.7
  ) +
  geom_vline(xintercept = 99.5, color = "#D55E00", linetype = "dashed") +
  facet_wrap(~cohort_label, ncol = 1L, scales = "free_y") +
  scale_x_continuous(breaks = c(50, 75, 99, 120, 150, 180, 220)) +
  labs(
    title = "Symmetric parent cohorts still show excess mass at 99 units",
    subtitle = paste0(
      "Bars: observed parent totals. Gray line: fitted no-notch distribution.\n",
      "The all-cohort panel includes right-censored late-2025 parents."
    ),
    x = "Observed dwelling units per parent opportunity",
    y = "Parents",
    caption = paste0(
      "Model training uses fully observed historical 365-day parent cohorts. ",
      "No unobserved companion is imputed."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    legend.position = "none"
  )

if (
  nrow(training_rows) == 0L ||
    nrow(counterfactuals) != 4L ||
    any(!is.finite(parameters$estimate)) ||
    any(scores$probability_observed < 0) ||
    any(scores$probability_exact_99 < 0) ||
    any(scores$probability_at_least_100 < 0) ||
    any(scores$probability_at_least_100 > 1 + 1e-10) ||
    any(counterfactuals$observed_exact_99 < 0)
) {
  stop("Symmetric-parent model outputs failed final QC.")
}

write_csv_if_changed(
  counterfactuals,
  "../output/symmetric_parent_model_counterfactuals.csv"
)
write_csv_if_changed(
  comparison,
  "../output/symmetric_parent_model_comparison.csv"
)
write_csv_if_changed(
  parameters,
  "../output/symmetric_parent_model_parameters.csv"
)
write_parquet_if_changed(
  scores,
  "../output/symmetric_parent_model_scores.parquet"
)
write_csv_if_changed(
  distributions,
  "../output/symmetric_parent_model_distributions.csv"
)
ggsave(
  "../output/symmetric_parent_model_counterfactuals.pdf",
  counterfactual_plot,
  width = 8.5,
  height = 7.5,
  bg = "white"
)

cat("Wrote symmetric-parent no-notch model outputs to ../output\n")

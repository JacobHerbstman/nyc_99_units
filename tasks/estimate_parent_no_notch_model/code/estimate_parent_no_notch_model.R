# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/estimate_parent_no_notch_model/code")
# unit_spec <- "hdb_priority"
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

if (length(args) != 6L) {
  stop(
    "Expected six arguments: unit specification, minimum units, minimum ",
    "category rows, counterfactual maximum units, and plot limits."
  )
}

unit_spec <- args[1]
min_units <- as.integer(args[2])
minimum_category_rows <- as.integer(args[3])
counterfactual_max_units <- as.integer(args[4])
plot_min_units <- as.integer(args[5])
plot_max_units <- as.integer(args[6])

if (
  !(unit_spec %in% c("hdb_priority", "dob_i1_complete_case")) ||
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

if (
  nrow(historical_panel) == 0L ||
    nrow(post_panel) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id)
) {
  stop("Enhanced-parent model inputs failed key QC.")
}

training_rows <- historical_panel |>
  filter(model_eligible, filing_year >= 2019L, date_last_filed <= as.Date("2023-12-31"))

model_eligible_post_parents <- sum(post_panel$model_eligible)

if (unit_spec == "hdb_priority") {
  score_rows <- post_panel |>
    filter(model_eligible) |>
    mutate(
      units = units_hdb_priority,
      log_units = log(units)
    )
  model_name <- "enhanced_parent_2019_2023"
  unit_label <- "HDB units (primary)"
} else {
  score_rows <- post_panel |>
    filter(
      model_eligible,
      dob_i1_complete,
      units_dob_i1 >= min_units
    ) |>
    mutate(
      units = units_dob_i1,
      log_units = log(units)
    )
  model_name <- "enhanced_parent_2019_2023_dob_i1_complete_case"
  unit_label <- "DOB initial-filing units (complete-case sensitivity)"
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
    observation_id, unit_definition, observed_units = units,
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
  unit_definition = unit_spec,
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
  training_parents = nrow(training_rows),
  model_eligible_2025_parents = model_eligible_post_parents,
  scoreable_2025_parents = nrow(scores),
  excluded_2025_parents_unit_definition =
    model_eligible_post_parents - nrow(scores),
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
  training_end_year = 2023L,
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
  stop("Enhanced-parent model outputs failed final QC.")
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
    title = "Enhanced-parent filings bunch below the 100-unit threshold",
    subtitle = paste0(
      "Observed 2025 parent counts and the no-notch distribution estimated ",
      "from 2019-2023; ", unit_label
    ),
    x = "Proposed dwelling units per enhanced parent",
    y = "Parent opportunities",
    caption = paste0(
      "Gray bars are observed counts. The blue line is the fitted no-notch ",
      "distribution. Parent links combine conservative historical signals ",
      "with corroborated exact parcel adjacency."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    plot.title.position = "plot"
  )

if (unit_spec == "hdb_priority") {
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

cat("Wrote enhanced-parent no-notch results for ", unit_spec, " to ../output\n")

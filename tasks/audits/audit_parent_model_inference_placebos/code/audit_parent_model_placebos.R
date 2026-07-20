# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_model_inference_placebos/code")
# training_start_year <- 2019L
# training_end_year <- 2022L
# pseudo_start_year <- 2020L
# pseudo_end_year <- 2022L
# training_endpoints_text <- "2020,2021,2022"
# min_units <- 6L
# minimum_category_rows <- 30L
# threshold_min <- 80L
# threshold_max <- 120L
# counterfactual_max_units <- 400L
# post_year <- 2025L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/parent_no_notch_model.R")
source("parent_model_audit_functions.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 11L) {
  stop(
    "Expected training years, pseudo years, training endpoints, unit and ",
    "category floors, threshold bounds, distribution maximum, and post year."
  )
}

training_start_year <- as.integer(args[1])
training_end_year <- as.integer(args[2])
pseudo_start_year <- as.integer(args[3])
pseudo_end_year <- as.integer(args[4])
training_endpoints_text <- args[5]
min_units <- as.integer(args[6])
minimum_category_rows <- as.integer(args[7])
threshold_min <- as.integer(args[8])
threshold_max <- as.integer(args[9])
counterfactual_max_units <- as.integer(args[10])
post_year <- as.integer(args[11])
training_endpoint_years <- as.integer(str_split(
  training_endpoints_text,
  ",",
  simplify = TRUE
))

if (
  any(is.na(c(
    training_start_year, training_end_year,
    pseudo_start_year, pseudo_end_year, training_endpoint_years,
    min_units, minimum_category_rows, threshold_min, threshold_max,
    counterfactual_max_units, post_year
  ))) ||
    training_start_year >= training_end_year ||
    pseudo_start_year <= training_start_year ||
    pseudo_start_year > pseudo_end_year ||
    pseudo_end_year > training_end_year ||
    any(training_endpoint_years < pseudo_start_year) ||
    any(training_endpoint_years > training_end_year) ||
    anyDuplicated(training_endpoint_years) ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    threshold_min <= min_units ||
    threshold_min > 100L ||
    threshold_max < 100L ||
    threshold_min >= threshold_max ||
    counterfactual_max_units <= threshold_max ||
    post_year <= training_end_year
) {
  stop("Parent-model placebo arguments are not internally consistent.")
}

model_formula <- log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use

historical_panel <- read_parquet(
  "../input/historical_symmetric_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_symmetric_parent_model_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_rows <- post_panel |>
  filter(
    model_eligible,
    analysis_status == "completed_2025_cohort",
    cohort_year == post_year
  ) |>
  mutate(
    units = units_hdb_priority,
    log_units = log(units)
  )

historical_rows <- historical_panel |>
  filter(
    model_eligible,
    analysis_status == "historical_fully_observed",
    cohort_year >= training_start_year,
    cohort_year <= training_end_year
  )

if (
  nrow(historical_rows) == 0L ||
    nrow(post_rows) == 0L ||
    anyDuplicated(historical_rows$observation_id) ||
    anyDuplicated(post_rows$observation_id) ||
    !identical(sort(unique(historical_rows$cohort_year)),
      training_start_year:training_end_year)
) {
  stop("Parent-model placebo samples failed key QC.")
}

preferred_fit <- fit_rounded_mle(
  historical_rows,
  post_rows,
  min_units,
  minimum_category_rows,
  model_formula
)
preferred_distribution <- expected_unit_distribution(
  preferred_fit$test_mu,
  preferred_fit$sigma,
  min_units,
  counterfactual_max_units
)

threshold_placebos <- bind_rows(lapply(
  threshold_min:threshold_max,
  function(threshold_units) {
    no_notch_moments(
      post_rows$units,
      preferred_fit$test_mu,
      preferred_fit$sigma,
      preferred_distribution,
      min_units,
      threshold_units
    )
  }
)) |>
  mutate(
    sample = paste0("post_", post_year),
    training_start_year,
    training_end_year,
    actual_policy_threshold = threshold_units == 100L,
    .before = 1L
  )

pseudo_year_rows <- list()

for (pseudo_year in pseudo_start_year:pseudo_end_year) {
  pseudo_training_rows <- historical_panel |>
    filter(
      model_eligible,
      analysis_status == "historical_fully_observed",
      cohort_year >= training_start_year,
      cohort_year < pseudo_year
    )
  pseudo_score_rows <- historical_panel |>
    filter(
      model_eligible,
      analysis_status == "historical_fully_observed",
      cohort_year == pseudo_year
    )
  pseudo_fit <- fit_rounded_mle(
    pseudo_training_rows,
    pseudo_score_rows,
    min_units,
    minimum_category_rows,
    model_formula
  )
  pseudo_distribution <- expected_unit_distribution(
    pseudo_fit$test_mu,
    pseudo_fit$sigma,
    min_units,
    counterfactual_max_units
  )
  pseudo_year_rows[[length(pseudo_year_rows) + 1L]] <-
    no_notch_moments(
      pseudo_score_rows$units,
      pseudo_fit$test_mu,
      pseudo_fit$sigma,
      pseudo_distribution,
      min_units,
      100L
    ) |>
    mutate(
      pseudo_policy_year = pseudo_year,
      training_start_year,
      training_end_year = pseudo_year - 1L,
      training_parents = nrow(pseudo_training_rows),
      .before = 1L
    )
}

pseudo_years <- bind_rows(pseudo_year_rows) |>
  arrange(pseudo_policy_year)

leave_one_year_out_rows <- list()

for (omitted_year in training_start_year:training_end_year) {
  leave_out_training_rows <- historical_rows |>
    filter(cohort_year != omitted_year)
  leave_out_fit <- fit_rounded_mle(
    leave_out_training_rows,
    post_rows,
    min_units,
    minimum_category_rows,
    model_formula
  )
  leave_out_distribution <- expected_unit_distribution(
    leave_out_fit$test_mu,
    leave_out_fit$sigma,
    min_units,
    counterfactual_max_units
  )
  leave_one_year_out_rows[[length(leave_one_year_out_rows) + 1L]] <-
    no_notch_moments(
      post_rows$units,
      leave_out_fit$test_mu,
      leave_out_fit$sigma,
      leave_out_distribution,
      min_units,
      100L
    ) |>
    mutate(
      omitted_year,
      training_parents = nrow(leave_out_training_rows),
      .before = 1L
    )
}

leave_one_year_out <- bind_rows(leave_one_year_out_rows) |>
  arrange(omitted_year)

training_endpoint_rows <- list()

for (training_endpoint in training_endpoint_years) {
  endpoint_training_rows <- historical_panel |>
    filter(
      model_eligible,
      analysis_status == "historical_fully_observed",
      cohort_year >= training_start_year,
      cohort_year <= training_endpoint
    )
  endpoint_fit <- fit_rounded_mle(
    endpoint_training_rows,
    post_rows,
    min_units,
    minimum_category_rows,
    model_formula
  )
  endpoint_distribution <- expected_unit_distribution(
    endpoint_fit$test_mu,
    endpoint_fit$sigma,
    min_units,
    counterfactual_max_units
  )
  training_endpoint_rows[[length(training_endpoint_rows) + 1L]] <-
    no_notch_moments(
      post_rows$units,
      endpoint_fit$test_mu,
      endpoint_fit$sigma,
      endpoint_distribution,
      min_units,
      100L
    ) |>
    mutate(
      training_start_year,
      training_end_year = training_endpoint,
      training_parents = nrow(endpoint_training_rows),
      .before = 1L
    )
}

training_endpoints <- bind_rows(training_endpoint_rows) |>
  arrange(training_end_year)

if (
  nrow(threshold_placebos) != threshold_max - threshold_min + 1L ||
    nrow(pseudo_years) != pseudo_end_year - pseudo_start_year + 1L ||
    nrow(leave_one_year_out) !=
      training_end_year - training_start_year + 1L ||
    nrow(training_endpoints) != length(training_endpoint_years) ||
    any(!is.finite(threshold_placebos$conservation_gap)) ||
    any(!is.finite(pseudo_years$conservation_gap)) ||
    any(!is.finite(leave_one_year_out$conservation_gap)) ||
    any(!is.finite(training_endpoints$conservation_gap))
) {
  stop("Parent-model placebo outputs failed final QC.")
}

placebo_plot <- threshold_placebos |>
  select(
    threshold_units,
    `Excess exact mass` = excess_exact_bunch_units,
    `Missing above threshold` = missing_at_or_above_threshold
  ) |>
  tidyr::pivot_longer(
    -threshold_units,
    names_to = "moment",
    values_to = "value"
  ) |>
  ggplot(aes(x = threshold_units, y = value, color = moment)) +
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.4) +
  geom_vline(xintercept = 100, color = "#E6550D", linetype = "dashed") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.4) +
  scale_x_continuous(breaks = seq(threshold_min, threshold_max, by = 5L)) +
  scale_color_manual(values = c("#1769AA", "#8C510A")) +
  labs(
    title = "The parent-level excess is concentrated at the policy threshold",
    subtitle = paste0(
      "Fully observed 2019-", training_end_year,
      " parents scored on completed ", post_year, " cohorts"
    ),
    x = "Candidate threshold",
    y = "Mass relative to no-notch prediction",
    color = NULL,
    caption = paste0(
      "Excess exact mass is observed minus expected at T-1. Missing-above ",
      "mass is expected minus observed at or above T."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot"
  )

write_csv_if_changed(
  pseudo_years,
  "../output/parent_model_pseudo_policy_years.csv"
)
write_csv_if_changed(
  threshold_placebos,
  "../output/parent_model_threshold_placebos.csv"
)
write_csv_if_changed(
  leave_one_year_out,
  "../output/parent_model_leave_one_year_out.csv"
)
write_csv_if_changed(
  training_endpoints,
  "../output/parent_model_training_endpoints.csv"
)
ggsave(
  "../output/parent_model_threshold_placebos.pdf",
  placebo_plot,
  width = 9,
  height = 5.5,
  bg = "white"
)

cat("Wrote preferred parent-model placebo and training checks to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_no_notch_placebos/code")
# universe_min_units <- 6L
# placebo_thresholds_text <- "90,100,110,120"
# post_year <- 2025L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected universe floor, comma-separated thresholds, and post year.")
}

universe_min_units <- as.integer(args[1])
placebo_thresholds_text <- args[2]
post_year <- as.integer(args[3])
placebo_thresholds <- as.integer(str_split(
  placebo_thresholds_text,
  ",",
  simplify = TRUE
))

if (
  any(is.na(c(universe_min_units, placebo_thresholds, post_year))) ||
    universe_min_units < 1L ||
    any(placebo_thresholds <= universe_min_units) ||
    anyDuplicated(placebo_thresholds) ||
    !100L %in% placebo_thresholds ||
    post_year <= max(2016L:2022L)
) {
  stop("Placebo arguments are not internally consistent.")
}

log_one_minus_exp <- function(log_value) {
  result <- numeric(length(log_value))
  use_log1p <- log_value < log(0.5)
  result[use_log1p] <- log1p(-exp(log_value[use_log1p]))
  result[!use_log1p] <- log(-expm1(log_value[!use_log1p]))
  result
}

log_normal_interval_probability <- function(lower_z, upper_z) {
  result <- numeric(length(lower_z))
  use_upper_tail <- lower_z > 0

  if (any(!use_upper_tail)) {
    upper_log_cdf <- pnorm(upper_z[!use_upper_tail], log.p = TRUE)
    lower_log_cdf <- pnorm(lower_z[!use_upper_tail], log.p = TRUE)
    result[!use_upper_tail] <- upper_log_cdf + log_one_minus_exp(
      lower_log_cdf - upper_log_cdf
    )
  }

  if (any(use_upper_tail)) {
    lower_log_survival <- pnorm(
      lower_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    upper_log_survival <- pnorm(
      upper_z[use_upper_tail],
      lower.tail = FALSE,
      log.p = TRUE
    )
    result[use_upper_tail] <- lower_log_survival + log_one_minus_exp(
      upper_log_survival - lower_log_survival
    )
  }

  result
}

probability_exact_units <- function(units, predicted_log_units, sigma) {
  lower_z <- (log(units - 0.5) - predicted_log_units) / sigma
  upper_z <- (log(units + 0.5) - predicted_log_units) / sigma
  floor_z <- (
    log(universe_min_units - 0.5) - predicted_log_units
  ) / sigma
  exp(
    log_normal_interval_probability(lower_z, upper_z) -
      pnorm(floor_z, lower.tail = FALSE, log.p = TRUE)
  )
}

probability_at_least_threshold <- function(
    threshold, predicted_log_units, sigma) {
  floor_log_survival <- pnorm(
    (log(universe_min_units - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  threshold_log_survival <- pnorm(
    (log(threshold - 0.5) - predicted_log_units) / sigma,
    lower.tail = FALSE,
    log.p = TRUE
  )
  pmin(pmax(exp(
    threshold_log_survival - floor_log_survival
  ), 0), 1)
}

out_of_time_predictions <- read_parquet(
  "../input/no_notch_time_adaptation_out_of_time_predictions.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    (training_floor == 6L & timing == "expanding") |
      (training_floor == 11L & timing == "rolling_5_year")
  ) |>
  mutate(
    model_role = if_else(
      training_floor == 6L,
      "preferred_full_distribution",
      "required_sample_robustness"
    ),
    period_year = filing_year,
    period_status = if_else(
      period_year == 2022L,
      "pre_policy_partial_year_through_june_15",
      "pre_policy_full_year_placebo"
    ),
    shock_sigma = sigma,
    observed_units = units
  ) |>
  select(
    model_role, model, period_year, period_status, observation_id,
    job_number, date_filed, observed_units, predicted_log_units, shock_sigma
  )

post_scores <- read_parquet(
  "../input/no_notch_post_policy_exposure_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    model_role,
    model,
    period_year = filing_year,
    period_status = "post_policy_2025",
    observation_id,
    job_number,
    date_filed,
    observed_units,
    predicted_log_units,
    shock_sigma
  ) |>
  filter(period_year == post_year)

prediction_rows <- bind_rows(out_of_time_predictions, post_scores) |>
  arrange(model_role, period_year, job_number)

if (
  nrow(prediction_rows) == 0L ||
    anyDuplicated(prediction_rows[c(
      "model_role", "period_year", "job_number"
    )]) ||
    n_distinct(prediction_rows$model_role) != 2L ||
    !all(2016L:2022L %in% prediction_rows$period_year) ||
    !post_year %in% prediction_rows$period_year
) {
  stop("Placebo prediction rows failed sample QC.")
}

moment_rows <- list()

for (model_role_value in unique(prediction_rows$model_role)) {
  for (period_year_value in unique(
    prediction_rows$period_year[
      prediction_rows$model_role == model_role_value
    ]
  )) {
    year_rows <- prediction_rows |>
      filter(
        model_role == model_role_value,
        period_year == period_year_value
      )

    for (threshold_value in placebo_thresholds) {
      bunch_value <- threshold_value - 1L
      expected_exact <- sum(probability_exact_units(
        bunch_value,
        year_rows$predicted_log_units,
        year_rows$shock_sigma
      ))
      expected_above <- sum(probability_at_least_threshold(
        threshold_value,
        year_rows$predicted_log_units,
        year_rows$shock_sigma
      ))
      observed_exact <- sum(year_rows$observed_units == bunch_value)
      observed_above <- sum(year_rows$observed_units >= threshold_value)
      excess_exact <- observed_exact - expected_exact
      missing_above <- expected_above - observed_above
      moment_rows[[length(moment_rows) + 1L]] <- tibble(
        model_role = model_role_value,
        model = unique(year_rows$model),
        period_year = period_year_value,
        period_status = unique(year_rows$period_status),
        threshold_units = threshold_value,
        bunch_units = bunch_value,
        scoreable_filings = nrow(year_rows),
        observed_exact_bunch_units = observed_exact,
        expected_no_notch_exact_bunch_units = expected_exact,
        excess_exact_bunch_units = excess_exact,
        observed_at_or_above_threshold = observed_above,
        expected_no_notch_at_or_above_threshold = expected_above,
        missing_at_or_above_threshold = missing_above,
        conservation_gap = excess_exact - missing_above
      )
    }
  }
}

placebo_moments <- bind_rows(moment_rows) |>
  arrange(model_role, threshold_units, period_year)

placebo_summary <- placebo_moments |>
  filter(period_status == "pre_policy_full_year_placebo") |>
  group_by(model_role, model, threshold_units, bunch_units) |>
  summarise(
    full_placebo_years = n(),
    mean_excess_exact_bunch_units = mean(excess_exact_bunch_units),
    sd_excess_exact_bunch_units = sd(excess_exact_bunch_units),
    minimum_excess_exact_bunch_units = min(excess_exact_bunch_units),
    maximum_excess_exact_bunch_units = max(excess_exact_bunch_units),
    mean_missing_at_or_above_threshold = mean(
      missing_at_or_above_threshold
    ),
    sd_missing_at_or_above_threshold = sd(
      missing_at_or_above_threshold
    ),
    minimum_missing_at_or_above_threshold = min(
      missing_at_or_above_threshold
    ),
    maximum_missing_at_or_above_threshold = max(
      missing_at_or_above_threshold
    ),
    .groups = "drop"
  ) |>
  left_join(
    placebo_moments |>
      filter(
        period_year == post_year,
        threshold_units == 100L
      ) |>
      select(
        model_role,
        post_2025_excess_exact_99 = excess_exact_bunch_units,
        post_2025_missing_100_plus = missing_at_or_above_threshold
      ),
    by = "model_role",
    relationship = "many-to-one"
  ) |>
  arrange(model_role, threshold_units)

model_labels <- c(
  preferred_full_distribution = "Preferred: floor 6, expanding history",
  required_sample_robustness = "Robustness: floor 11, rolling five years"
)

placebo_plot <- placebo_moments |>
  mutate(
    model_label = factor(
      model_labels[model_role],
      levels = unname(model_labels)
    ),
    threshold_label = paste0("Threshold ", threshold_units),
    plot_value = excess_exact_bunch_units,
    post_2025 = period_year == post_year
  ) |>
  ggplot(aes(
    x = factor(period_year),
    y = factor(threshold_label, levels = paste0(
      "Threshold ", sort(placebo_thresholds, decreasing = TRUE)
    )),
    fill = plot_value
  )) +
  geom_tile(color = "white", linewidth = 0.8) +
  geom_text(
    aes(
      label = number(plot_value, accuracy = 0.1),
      fontface = if_else(post_2025, "bold", "plain")
    ),
    size = 3.2,
    show.legend = FALSE
  ) +
  facet_wrap(vars(model_label), ncol = 1L) +
  scale_fill_gradient2(
    low = "#2C7BB6",
    mid = "white",
    high = "#D7191C",
    midpoint = 0,
    name = "Observed minus\nexpected mass"
  ) +
  labs(
    title = "The 2025 excess at 99 is far outside the pre-policy placebos",
    subtitle = paste0(
      "Cells report observed minus predicted filings one unit below each ",
      "candidate threshold. 2022 covers January 1--June 15."
    ),
    x = "Out-of-time test year",
    y = NULL,
    caption = paste0(
      "Each pre-policy cell is scored by a model trained only on earlier years. ",
      "The policy estimate is the 2025, threshold-100 cell."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "#F2F2F2", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(placebo_moments) !=
    2L * (length(2016L:2022L) + 1L) * length(placebo_thresholds) ||
    any(!is.finite(placebo_moments$expected_no_notch_exact_bunch_units)) ||
    any(!is.finite(
      placebo_moments$expected_no_notch_at_or_above_threshold
    )) ||
    nrow(placebo_summary) != 2L * length(placebo_thresholds)
) {
  stop("Placebo outputs failed final QC.")
}

write_csv_if_changed(
  placebo_moments,
  "../output/no_notch_placebo_moments.csv"
)
write_csv_if_changed(
  placebo_summary,
  "../output/no_notch_placebo_summary.csv"
)
ggsave(
  "../output/no_notch_placebo_heatmap.pdf",
  placebo_plot,
  width = 10,
  height = 8,
  device = "pdf"
)
ggsave(
  "../output/no_notch_placebo_heatmap.png",
  placebo_plot,
  width = 10,
  height = 8,
  dpi = 180,
  bg = "white"
)

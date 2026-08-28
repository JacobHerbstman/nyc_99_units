# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_tail_counterfactual/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

tail_cutoff <- 99L
exact_count_max <- 149L
pooled_count <- 150L

historical_tail <- readRDS("../output/tail_pre_c99.rds")
post_tail <- readRDS("../output/tail_post_c99.rds")
calibration_weights <- read_csv(
  "../output/tail_pre_c99_calibration_weights.csv",
  show_col_types = FALSE
)

if (
  nrow(historical_tail) == 0L || nrow(post_tail) == 0L ||
    nrow(calibration_weights) != nrow(historical_tail) ||
    anyDuplicated(historical_tail$observation_id) ||
    anyDuplicated(post_tail$observation_id) ||
    anyDuplicated(calibration_weights$observation_id) ||
    !setequal(
      historical_tail$observation_id,
      calibration_weights$observation_id
    ) ||
    any(historical_tail$total_units < tail_cutoff) ||
    any(post_tail$total_units < tail_cutoff)
) {
  stop("A c=99 counterfactual input failed row or identifier QC.")
}

historical_weighted <- historical_tail |>
  left_join(
    calibration_weights |>
      select(observation_id, calibration_weight),
    by = "observation_id",
    relationship = "one-to-one"
  )

if (
  any(is.na(historical_weighted$calibration_weight)) ||
    any(historical_weighted$calibration_weight <= 0) ||
    abs(sum(historical_weighted$calibration_weight) - nrow(post_tail)) > 1e-7
) {
  stop("Historical calibration weights failed counterfactual QC.")
}

counterfactual_counts <- historical_weighted |>
  mutate(count_value = pmin(total_units, pooled_count)) |>
  group_by(count_value) |>
  summarise(
    counterfactual_weighted_count = sum(calibration_weight),
    .groups = "drop"
  )

observed_counts <- post_tail |>
  mutate(count_value = pmin(total_units, pooled_count)) |>
  count(count_value, name = "observed_2025_count")

exact_counts <- tibble(
  count_value = seq.int(tail_cutoff, pooled_count)
) |>
  left_join(
    counterfactual_counts,
    by = "count_value",
    relationship = "one-to-one"
  ) |>
  left_join(
    observed_counts,
    by = "count_value",
    relationship = "one-to-one"
  ) |>
  mutate(
    count_label = if_else(
      count_value == pooled_count,
      paste0(pooled_count, "+"),
      as.character(count_value)
    ),
    counterfactual_weighted_count = coalesce(
      counterfactual_weighted_count,
      0
    ),
    observed_2025_count = coalesce(observed_2025_count, 0L),
    observed_minus_counterfactual =
      observed_2025_count - counterfactual_weighted_count
  ) |>
  select(
    count_value, count_label, observed_2025_count,
    counterfactual_weighted_count, observed_minus_counterfactual
  )

counterfactual_total <- sum(exact_counts$counterfactual_weighted_count)
observed_total <- sum(exact_counts$observed_2025_count)

if (
  abs(counterfactual_total - nrow(post_tail)) > 1e-7 ||
    observed_total != nrow(post_tail)
) {
  stop("The c=99 exact-count distributions do not preserve target mass.")
}

observed_at_99 <- exact_counts$observed_2025_count[
  exact_counts$count_value == tail_cutoff
]
counterfactual_at_99 <- exact_counts$counterfactual_weighted_count[
  exact_counts$count_value == tail_cutoff
]
excess_at_99 <- observed_at_99 - counterfactual_at_99

observed_at_least_100 <- sum(
  exact_counts$observed_2025_count[exact_counts$count_value >= 100L]
)
counterfactual_at_least_100 <- sum(
  exact_counts$counterfactual_weighted_count[
    exact_counts$count_value >= 100L
  ]
)
missing_mass_at_least_100 <-
  counterfactual_at_least_100 - observed_at_least_100
accounting_residual <- excess_at_99 - missing_mass_at_least_100

if (abs(accounting_residual) > 1e-7) {
  stop("The c=99 excess-mass accounting identity failed.")
}

cumulative_diagnostics <- exact_counts |>
  filter(count_value >= 100L, count_value <= exact_count_max) |>
  arrange(count_value) |>
  mutate(
    structural_cumulative_counterfactual_mass = cumsum(
      counterfactual_weighted_count
    ),
    observed_count_deficit =
      counterfactual_weighted_count - observed_2025_count,
    observed_cumulative_missing_mass = cumsum(observed_count_deficit),
    excess_at_99 = excess_at_99
  )

structural_reaching_rows <- cumulative_diagnostics |>
  filter(structural_cumulative_counterfactual_mass >= excess_at_99)

if (excess_at_99 <= 0) {
  frontier_status <- "no_positive_excess_at_99"
  frontier_final_count <- NA_integer_
  mass_before_final_count <- NA_real_
  counterfactual_mass_at_final_count <- NA_real_
  fraction_of_final_count <- NA_real_
  continuous_frontier <- NA_real_
  affected_project_mean_no_notch_units <- NA_real_
} else if (nrow(structural_reaching_rows) == 0L) {
  frontier_status <- "frontier_at_least_150"
  frontier_final_count <- NA_integer_
  mass_before_final_count <- sum(
    cumulative_diagnostics$counterfactual_weighted_count
  )
  counterfactual_mass_at_final_count <- NA_real_
  fraction_of_final_count <- NA_real_
  continuous_frontier <- NA_real_
  affected_project_mean_no_notch_units <- NA_real_
} else {
  frontier_status <- "frontier_reached_below_150"
  frontier_final_count <- structural_reaching_rows$count_value[1]
  mass_before_final_count <- sum(
    cumulative_diagnostics$counterfactual_weighted_count[
      cumulative_diagnostics$count_value < frontier_final_count
    ]
  )
  counterfactual_mass_at_final_count <-
    cumulative_diagnostics$counterfactual_weighted_count[
      cumulative_diagnostics$count_value == frontier_final_count
    ]
  fraction_of_final_count <-
    (excess_at_99 - mass_before_final_count) /
    counterfactual_mass_at_final_count
  continuous_frontier <- frontier_final_count + fraction_of_final_count

  fully_allocated_rows <- cumulative_diagnostics |>
    filter(count_value < frontier_final_count)
  affected_project_mean_no_notch_units <- (
    sum(
      fully_allocated_rows$count_value *
        fully_allocated_rows$counterfactual_weighted_count
    ) +
      frontier_final_count * fraction_of_final_count *
        counterfactual_mass_at_final_count
  ) / excess_at_99
}

observed_reaching_rows <- cumulative_diagnostics |>
  filter(observed_cumulative_missing_mass >= excess_at_99)

frontier_summary <- tibble(
  frontier_status,
  excess_at_99,
  counterfactual_mass_100_to_149 = sum(
    cumulative_diagnostics$counterfactual_weighted_count
  ),
  frontier_final_count,
  mass_before_final_count,
  counterfactual_mass_at_final_count,
  fraction_of_final_count,
  continuous_frontier,
  affected_project_mean_no_notch_units,
  observed_missing_mass_reaches_excess_by_149 =
    nrow(observed_reaching_rows) > 0L,
  first_observed_missing_mass_reach_count = if (
    nrow(observed_reaching_rows) > 0L
  ) observed_reaching_rows$count_value[1] else NA_integer_
)

counterfactual_summary <- tibble(
  tail_cutoff,
  post_policy_parents = nrow(post_tail),
  historical_parents = nrow(historical_tail),
  observed_at_99,
  counterfactual_at_99,
  excess_at_99,
  observed_at_least_100,
  counterfactual_at_least_100,
  missing_mass_at_least_100,
  accounting_residual,
  observed_total,
  counterfactual_total
)

plot_data <- bind_rows(
  exact_counts |>
    transmute(
      count_value,
      parent_mass = observed_2025_count,
      distribution = "Observed 2025"
    ),
  exact_counts |>
    transmute(
      count_value,
      parent_mass = counterfactual_weighted_count,
      distribution = "Weighted no-notch"
    )
) |>
  filter(count_value <= exact_count_max)

exact_count_plot <- ggplot(
  plot_data,
  aes(x = count_value, y = parent_mass, fill = distribution)
) +
  geom_col(
    position = position_dodge(width = 0.82),
    width = 0.76
  ) +
  geom_vline(xintercept = 99.5, linewidth = 0.4, linetype = "dashed") +
  scale_x_continuous(
    breaks = c(99L, seq.int(100L, 145L, by = 5L), 149L)
  ) +
  scale_fill_manual(
    values = c(
      "Observed 2025" = "#C44E52",
      "Weighted no-notch" = "#4C72B0"
    )
  ) +
  labs(
    x = "Parent-project units",
    y = "Parent mass",
    fill = NULL,
    title = "Observed and weighted no-notch parent counts",
    subtitle = "Strict c=99 invariant-tail sample; exact counts through 149",
    caption = paste0(
      "The 150+ category is omitted from the plot: observed = ",
      exact_counts$observed_2025_count[
        exact_counts$count_value == pooled_count
      ],
      "; weighted no-notch = ",
      round(
        exact_counts$counterfactual_weighted_count[
          exact_counts$count_value == pooled_count
        ],
        1
      ),
      "."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    text = element_text(color = "black")
  )

cumulative_plot_data <- bind_rows(
  cumulative_diagnostics |>
    transmute(
      count_value,
      cumulative_mass = structural_cumulative_counterfactual_mass,
      series = "Counterfactual mass from 100 through m"
    ),
  cumulative_diagnostics |>
    transmute(
      count_value,
      cumulative_mass = observed_cumulative_missing_mass,
      series = "Counterfactual minus observed mass through m"
    )
)

cumulative_plot <- ggplot(
  cumulative_plot_data,
  aes(x = count_value, y = cumulative_mass, color = series)
) +
  geom_hline(
    yintercept = excess_at_99,
    linewidth = 0.5,
    linetype = "dashed",
    color = "#222222"
  ) +
  geom_line(linewidth = 0.9) +
  scale_x_continuous(breaks = seq.int(100L, 150L, by = 5L)) +
  scale_color_manual(
    values = c(
      "Counterfactual mass from 100 through m" = "#4C72B0",
      "Counterfactual minus observed mass through m" = "#DD8452"
    )
  ) +
  labs(
    x = "Upper endpoint m",
    y = "Cumulative parent mass",
    color = NULL,
    title = "Cumulative counterfactual mass and observed deficit",
    subtitle = "Dashed line is estimated excess mass at exactly 99 units"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    text = element_text(color = "black")
  )

write_csv_if_changed(
  exact_counts,
  "../output/counterfactual_exact_counts_c99.csv"
)
write_csv_if_changed(
  counterfactual_summary,
  "../output/counterfactual_summary_c99.csv"
)
write_csv_if_changed(
  cumulative_diagnostics,
  "../output/counterfactual_cumulative_diagnostics_c99.csv"
)
write_csv_if_changed(
  frontier_summary,
  "../output/counterfactual_structural_frontier_c99.csv"
)
ggsave(
  "../output/counterfactual_exact_counts_c99.png",
  exact_count_plot,
  width = 12,
  height = 6,
  dpi = 200,
  bg = "white"
)
ggsave(
  "../output/counterfactual_cumulative_diagnostics_c99.png",
  cumulative_plot,
  width = 10,
  height = 6,
  dpi = 200,
  bg = "white"
)

cat("Wrote the c=99 weighted counterfactual point estimate to ../output\n")

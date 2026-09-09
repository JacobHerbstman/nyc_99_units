# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_scale_shape_counterfactual/code")
# minimum_units <- 50L
# exact_plot_maximum <- 300L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Expected the minimum and maximum exact unit counts.")
}
minimum_units <- as.integer(args[1])
exact_plot_maximum <- as.integer(args[2])
if (any(is.na(c(minimum_units, exact_plot_maximum))) || minimum_units >= exact_plot_maximum) {
  stop("Descriptive-audit unit bounds are inconsistent.")
}

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as.data.frame() |>
  as_tibble()
parent_total_exact_distribution <- read_csv(
  "../input/parent_total_exact_distribution_50_300.csv",
  show_col_types = FALSE
)
existing_annualized <- read_csv(
  "../input/parent_unit_distribution_annualized_50_300.csv",
  show_col_types = FALSE
)
existing_normalized <- read_csv(
  "../input/parent_unit_distribution_normalized_density_50_300_ab.csv",
  show_col_types = FALSE
)

period_levels <- parents |>
  distinct(sample, period) |>
  arrange(match(sample, c("historical", "post_policy"))) |>
  pull(period)
parents_ab <- parents |>
  filter(included_ab) |>
  mutate(period = factor(period, levels = period_levels))

if (
  length(period_levels) != 2L ||
    nrow(parents_ab) == 0L ||
    anyDuplicated(parents_ab[c("sample", "parent_id")])
) {
  stop("Descriptive audit sample failed parent-level QC.")
}

parent_total_reproduction_qc <- bind_rows(
  existing_annualized |>
    filter(
      sample_scope == "A/B rental opportunities",
      str_detect(period, "2019|2025")
    ) |>
    mutate(
      sample = if_else(str_detect(period, "2019"), "historical", "post_policy")
    ) |>
    select(sample, unit_count, existing_count = parent_count) |>
    left_join(
      parent_total_exact_distribution |>
        mutate(
          sample = if_else(
            as.character(period) == period_levels[1],
            "historical",
            "post_policy"
          )
        ) |>
        select(
          sample,
          unit_count = parent_total_units,
          reconstructed_count = parent_count
        ),
      by = c("sample", "unit_count"),
      relationship = "one-to-one"
    ) |>
    summarise(
      check = "annualized_50_300_parent_counts",
      compared_cells = n(),
      maximum_absolute_difference = max(abs(
        existing_count - reconstructed_count
      )),
      .groups = "drop"
    ),
  existing_normalized |>
    filter(str_detect(density_period, "2019-2022|post")) |>
    mutate(
      sample = if_else(
        str_detect(density_period, "2019-2022"),
        "historical",
        "post_policy"
      )
    ) |>
    select(sample, unit_count, existing_count = parent_count) |>
    left_join(
      parent_total_exact_distribution |>
        mutate(
          sample = if_else(
            as.character(period) == period_levels[1],
            "historical",
            "post_policy"
          )
        ) |>
        select(
          sample,
          unit_count = parent_total_units,
          reconstructed_count = parent_count
        ),
      by = c("sample", "unit_count"),
      relationship = "one-to-one"
    ) |>
    summarise(
      check = "normalized_50_300_parent_counts",
      compared_cells = n(),
      maximum_absolute_difference = max(abs(
        existing_count - reconstructed_count
      )),
      .groups = "drop"
    )
)

if (
  any(is.na(parent_total_reproduction_qc$maximum_absolute_difference)) ||
    any(parent_total_reproduction_qc$maximum_absolute_difference != 0)
) {
  stop("The scale-shape task does not reproduce the existing 50-300 counts.")
}

near_198_placebo_totals <- parents_ab |>
  filter(parent_total_units >= 190L, parent_total_units <= 205L) |>
  count(
    period,
    parent_total_units,
    sorted_component_vector,
    n_components,
    name = "parent_count"
  ) |>
  complete(
    period = factor(period, levels = period_levels),
    parent_total_units = 190:205,
    fill = list(parent_count = 0L)
  ) |>
  arrange(period, parent_total_units, desc(parent_count))

support_rows <- list(
  "All 6+ A/B opportunities" = parents_ab |> filter(parent_total_units >= 6L),
  "30+ A/B opportunities" = parents_ab |> filter(parent_total_units >= 30L),
  "50+ A/B opportunities; 301+ retained" =
    parents_ab |> filter(parent_total_units >= minimum_units),
  "50-300 A/B opportunities" = parents_ab |>
    filter(
      parent_total_units >= minimum_units,
      parent_total_units <= exact_plot_maximum
    ),
  "50+ A/B opportunities; 501+ retained" =
    parents_ab |> filter(parent_total_units >= minimum_units)
)
support_sensitivity_rows <- list()

for (support_name in names(support_rows)) {
  support_data <- support_rows[[support_name]]
  support_sensitivity_rows[[support_name]] <- support_data |>
    group_by(period) |>
    summarise(
      support = support_name,
      opportunity_count = n(),
      share_exact_99 = mean(parent_total_units == 99L),
      share_100_149 = mean(parent_total_units >= 100L & parent_total_units <= 149L),
      share_exact_150 = mean(parent_total_units == 150L),
      share_exact_198 = mean(parent_total_units == 198L),
      share_250_300 = mean(parent_total_units >= 250L & parent_total_units <= 300L),
      share_above_300 = mean(parent_total_units > 300L),
      share_above_500 = mean(parent_total_units > 500L),
      .groups = "drop"
    )
}
support_sensitivity <- bind_rows(support_sensitivity_rows) |>
  arrange(support, factor(period, levels = period_levels))

historical_year_distribution <- parents_ab |>
  filter(sample == "historical", parent_total_units >= minimum_units) |>
  count(cohort_year, parent_total_units, name = "parent_count") |>
  complete(
    cohort_year = 2019:2022,
    parent_total_units = seq.int(minimum_units, max(parents_ab$parent_total_units)),
    fill = list(parent_count = 0L)
  ) |>
  group_by(cohort_year) |>
  mutate(
    opportunity_count = sum(parent_count),
    normalized_share = parent_count / opportunity_count,
    cumulative_share = cumsum(normalized_share)
  ) |>
  ungroup() |>
  arrange(cohort_year, parent_total_units)

historical_pairwise_stability_rows <- list()
for (year_a in 2019:2021) {
  for (year_b in (year_a + 1L):2022) {
    pair_rows <- historical_year_distribution |>
      filter(cohort_year %in% c(year_a, year_b)) |>
      select(cohort_year, parent_total_units, normalized_share, cumulative_share) |>
      pivot_wider(
        names_from = cohort_year,
        values_from = c(normalized_share, cumulative_share),
        names_sep = "__"
      )
    historical_pairwise_stability_rows[[paste(year_a, year_b)]] <- tibble(
      year_a,
      year_b,
      total_variation_distance = 0.5 * sum(abs(
        pair_rows[[paste0("normalized_share__", year_a)]] -
          pair_rows[[paste0("normalized_share__", year_b)]]
      )),
      maximum_absolute_cdf_difference = max(abs(
        pair_rows[[paste0("cumulative_share__", year_a)]] -
          pair_rows[[paste0("cumulative_share__", year_b)]]
      ))
    )
  }
}
historical_pairwise_stability <- bind_rows(historical_pairwise_stability_rows)
historical_exact_shares <- historical_year_distribution |>
  filter(parent_total_units %in% c(99L, 100L, 149L, 150L, 198L, 200L)) |>
  select(
    cohort_year,
    parent_total_units,
    parent_count,
    opportunity_count,
    normalized_share
  )
splitting_verification_summary <- parents_ab |>
  filter(multi_component) |>
  count(period, splitting_verification_status, name = "parent_count") |>
  group_by(period) |>
  mutate(conditional_share = parent_count / sum(parent_count)) |>
  ungroup()

write_csv_if_changed(
  parent_total_reproduction_qc,
  "../output/parent_total_reproduction_qc.csv"
)
write_csv_if_changed(near_198_placebo_totals, "../output/near_198_placebo_totals.csv")
write_csv_if_changed(support_sensitivity, "../output/support_sensitivity.csv")
write_csv_if_changed(
  historical_pairwise_stability,
  "../output/historical_pairwise_stability.csv"
)
write_csv_if_changed(historical_exact_shares, "../output/historical_exact_shares.csv")
write_csv_if_changed(
  splitting_verification_summary,
  "../output/splitting_verification_summary.csv"
)

cat("Wrote descriptive scale-shape audits to ../output\n")

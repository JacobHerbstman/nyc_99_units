# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_tail_counterfactual/code")
# historical_start_year <- 2017L
# historical_end_year <- 2022L
# post_year <- 2025L
# min_units <- 6L
# tail_cutoff <- 99L
# minimum_followup_days <- 180L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected historical start and end years, post year, minimum units, ",
    "tail cutoff, and minimum follow-up days."
  )
}

historical_start_year <- as.integer(args[1])
historical_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
tail_cutoff <- as.integer(args[5])
minimum_followup_days <- as.integer(args[6])

if (
  any(is.na(c(
    historical_start_year, historical_end_year, post_year, min_units,
    tail_cutoff, minimum_followup_days
  ))) ||
    historical_start_year > historical_end_year ||
    historical_end_year >= post_year ||
    min_units < 1L || min_units >= tail_cutoff ||
    tail_cutoff != 99L ||
    minimum_followup_days < 1L || minimum_followup_days >= 365L
) {
  stop("Parent-tail sample arguments are not internally consistent.")
}

historical_panel <- read_parquet(
  "../input/historical_parent_site_characteristics.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_panel <- read_parquet(
  "../input/post_policy_parent_site_characteristics.parquet"
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
    nrow(membership) == 0L ||
    anyDuplicated(historical_panel$observation_id) ||
    anyDuplicated(post_panel$observation_id) ||
    anyDuplicated(membership[c("sample", "root_job_id")])
) {
  stop("A parent-tail source failed identifier QC.")
}

historical_preferred <- historical_panel |>
  filter(
    analysis_status == "historical_fully_observed",
    cohort_year >= historical_start_year,
    cohort_year <= historical_end_year,
    composition_eligible,
    units_hdb_priority >= min_units
  )

post_followup <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(
    parent_id, cohort_date, source_end_date, left_window_observed
  ) |>
  mutate(
    observed_followup_days = as.integer(source_end_date - cohort_date)
  )

if (
  nrow(historical_preferred) == 0L ||
    nrow(post_followup) == 0L ||
    anyDuplicated(post_followup$parent_id) ||
    any(is.na(post_followup$observed_followup_days))
) {
  stop("Historical or post follow-up samples failed QC.")
}

post_mature <- post_panel |>
  left_join(
    post_followup |>
      select(
        parent_id, observed_followup_days, left_window_observed
      ),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(
    cohort_year == post_year,
    left_window_observed,
    observed_followup_days >= minimum_followup_days
  )

post_preferred <- post_mature |>
  filter(
    composition_eligible,
    units_hdb_priority >= min_units
  )

historical_tail <- historical_preferred |>
  filter(units_hdb_priority >= tail_cutoff) |>
  transmute(
    period = "historical",
    observation_id,
    parent_id,
    cohort_date,
    cohort_year,
    total_units = units_hdb_priority,
    component_filings,
    number_unique_lots = feature_lots,
    multi_lot_indicator = as.integer(feature_lots > 1L),
    lot_area_sqft = lotarea,
    log_lot_area = log(lotarea),
    residential_far = residfar,
    built_far = builtfar,
    residential_capacity_sqft = lotarea * residfar,
    built_capacity_sqft = lotarea * builtfar,
    redevelopment_slack_sqft = pmax(
      lotarea * residfar - lotarea * builtfar,
      0
    ),
    zero_residential_capacity = as.integer(lotarea * residfar == 0),
    zero_redevelopment_slack = as.integer(
      pmax(lotarea * residfar - lotarea * builtfar, 0) == 0
    ),
    borough = str_squish(as.character(borough)),
    zoning_category = str_squish(as.character(zone_detail)),
    prior_site_use = str_squish(as.character(prior_site_use)),
    observed_followup_days = NA_integer_
  )

post_tail <- post_preferred |>
  filter(units_hdb_priority >= tail_cutoff) |>
  transmute(
    period = as.character(post_year),
    observation_id,
    parent_id,
    cohort_date,
    cohort_year,
    total_units = units_hdb_priority,
    component_filings,
    number_unique_lots = feature_lots,
    multi_lot_indicator = as.integer(feature_lots > 1L),
    lot_area_sqft = lotarea,
    log_lot_area = log(lotarea),
    residential_far = residfar,
    built_far = builtfar,
    residential_capacity_sqft = lotarea * residfar,
    built_capacity_sqft = lotarea * builtfar,
    redevelopment_slack_sqft = pmax(
      lotarea * residfar - lotarea * builtfar,
      0
    ),
    zero_residential_capacity = as.integer(lotarea * residfar == 0),
    zero_redevelopment_slack = as.integer(
      pmax(lotarea * residfar - lotarea * builtfar, 0) == 0
    ),
    borough = str_squish(as.character(borough)),
    zoning_category = str_squish(as.character(zone_detail)),
    prior_site_use = str_squish(as.character(prior_site_use)),
    observed_followup_days
  )

required_tail_variables <- c(
  "observation_id", "parent_id", "total_units", "number_unique_lots",
  "lot_area_sqft", "log_lot_area", "residential_far", "built_far",
  "residential_capacity_sqft", "built_capacity_sqft",
  "redevelopment_slack_sqft", "borough", "zoning_category",
  "prior_site_use"
)

if (
  nrow(historical_tail) == 0L || nrow(post_tail) == 0L ||
    anyDuplicated(historical_tail$observation_id) ||
    anyDuplicated(post_tail$observation_id) ||
    any(historical_tail$total_units < tail_cutoff) ||
    any(post_tail$total_units < tail_cutoff) ||
    any(!complete.cases(historical_tail[required_tail_variables])) ||
    any(!complete.cases(post_tail[required_tail_variables])) ||
    any(historical_tail$lot_area_sqft <= 0) ||
    any(post_tail$lot_area_sqft <= 0)
) {
  stop("A strict 99-or-more parent sample failed final row QC.")
}

sample_flow <- tibble(
  sample_stage = c(
    paste0(
      "historical_preferred_",
      historical_start_year,
      "_",
      historical_end_year
    ),
    "historical_tail_at_least_99",
    paste0(post_year, "_mature_left_window_observed"),
    paste0(post_year, "_preferred_usable"),
    paste0(post_year, "_tail_at_least_99")
  ),
  parents = c(
    nrow(historical_preferred),
    nrow(historical_tail),
    nrow(post_mature),
    nrow(post_preferred),
    nrow(post_tail)
  )
)

historical_year_summary <- historical_preferred |>
  group_by(cohort_year) |>
  summarise(
    all_usable_parents = n(),
    tail_parents = sum(units_hdb_priority >= tail_cutoff),
    exact_95 = sum(units_hdb_priority == 95L),
    exact_96 = sum(units_hdb_priority == 96L),
    exact_97 = sum(units_hdb_priority == 97L),
    exact_98 = sum(units_hdb_priority == 98L),
    exact_99 = sum(units_hdb_priority == 99L),
    exact_100 = sum(units_hdb_priority == 100L),
    at_least_100 = sum(units_hdb_priority >= 100L),
    at_least_150 = sum(units_hdb_priority >= 150L),
    .groups = "drop"
  ) |>
  mutate(period = as.character(cohort_year), .before = 1) |>
  select(-cohort_year)

analysis_samples_summary <- bind_rows(
  historical_preferred |>
    summarise(
      period = paste0(
        "historical_", historical_start_year, "_", historical_end_year
      ),
      all_usable_parents = n(),
      tail_parents = sum(units_hdb_priority >= tail_cutoff),
      exact_95 = sum(units_hdb_priority == 95L),
      exact_96 = sum(units_hdb_priority == 96L),
      exact_97 = sum(units_hdb_priority == 97L),
      exact_98 = sum(units_hdb_priority == 98L),
      exact_99 = sum(units_hdb_priority == 99L),
      exact_100 = sum(units_hdb_priority == 100L),
      at_least_100 = sum(units_hdb_priority >= 100L),
      at_least_150 = sum(units_hdb_priority >= 150L)
    ),
  historical_year_summary,
  post_preferred |>
    summarise(
      period = as.character(post_year),
      all_usable_parents = n(),
      tail_parents = sum(units_hdb_priority >= tail_cutoff),
      exact_95 = sum(units_hdb_priority == 95L),
      exact_96 = sum(units_hdb_priority == 96L),
      exact_97 = sum(units_hdb_priority == 97L),
      exact_98 = sum(units_hdb_priority == 98L),
      exact_99 = sum(units_hdb_priority == 99L),
      exact_100 = sum(units_hdb_priority == 100L),
      at_least_100 = sum(units_hdb_priority >= 100L),
      at_least_150 = sum(units_hdb_priority >= 150L)
    )
)

analysis_sample_qc <- bind_rows(
  historical_tail |>
    summarise(
      period = first(period),
      parents = n(),
      duplicate_observation_ids = sum(duplicated(observation_id)),
      missing_parent_ids = sum(is.na(parent_id) | parent_id == ""),
      below_tail_cutoff = sum(total_units < tail_cutoff),
      missing_lot_area = sum(is.na(lot_area_sqft)),
      missing_residential_far = sum(is.na(residential_far)),
      missing_built_far = sum(is.na(built_far)),
      zero_residential_capacity = sum(zero_residential_capacity),
      zero_redevelopment_slack = sum(zero_redevelopment_slack),
      multi_lot_parents = sum(multi_lot_indicator)
    ),
  post_tail |>
    summarise(
      period = first(period),
      parents = n(),
      duplicate_observation_ids = sum(duplicated(observation_id)),
      missing_parent_ids = sum(is.na(parent_id) | parent_id == ""),
      below_tail_cutoff = sum(total_units < tail_cutoff),
      missing_lot_area = sum(is.na(lot_area_sqft)),
      missing_residential_far = sum(is.na(residential_far)),
      missing_built_far = sum(is.na(built_far)),
      zero_residential_capacity = sum(zero_residential_capacity),
      zero_redevelopment_slack = sum(zero_redevelopment_slack),
      multi_lot_parents = sum(multi_lot_indicator)
    )
)

continuous_balance_variables <- c(
  "log_lot_area", "residential_far", "built_far",
  "residential_capacity_sqft", "built_capacity_sqft",
  "redevelopment_slack_sqft", "number_unique_lots",
  "multi_lot_indicator", "zero_residential_capacity",
  "zero_redevelopment_slack"
)

balance_summary_rows <- list()

for (sample_data in list(historical_tail, post_tail)) {
  for (variable_name in continuous_balance_variables) {
    variable_values <- sample_data[[variable_name]]
    balance_summary_rows[[length(balance_summary_rows) + 1L]] <- tibble(
      period = sample_data$period[1],
      variable = variable_name,
      nonmissing = sum(!is.na(variable_values)),
      mean = mean(variable_values, na.rm = TRUE),
      standard_deviation = sd(variable_values, na.rm = TRUE),
      minimum = min(variable_values, na.rm = TRUE),
      median = median(variable_values, na.rm = TRUE),
      maximum = max(variable_values, na.rm = TRUE)
    )
  }
}

balance_variable_summary <- bind_rows(balance_summary_rows)

historical_category_counts <- bind_rows(
  historical_tail |>
    count(level = borough, name = "historical_parents") |>
    mutate(variable = "borough"),
  historical_tail |>
    count(level = zoning_category, name = "historical_parents") |>
    mutate(variable = "zoning_category"),
  historical_tail |>
    count(level = prior_site_use, name = "historical_parents") |>
    mutate(variable = "prior_site_use")
) |>
  select(variable, level, historical_parents)

post_category_counts <- bind_rows(
  post_tail |>
    count(level = borough, name = "post_parents") |>
    mutate(variable = "borough"),
  post_tail |>
    count(level = zoning_category, name = "post_parents") |>
    mutate(variable = "zoning_category"),
  post_tail |>
    count(level = prior_site_use, name = "post_parents") |>
    mutate(variable = "prior_site_use")
) |>
  select(variable, level, post_parents)

category_support <- full_join(
  historical_category_counts,
  post_category_counts,
  by = c("variable", "level"),
  relationship = "one-to-one"
) |>
  mutate(
    historical_parents = coalesce(historical_parents, 0L),
    post_parents = coalesce(post_parents, 0L),
    support_status = case_when(
      historical_parents == 0L ~ "post_only_overlap_failure",
      post_parents == 0L ~ "historical_only",
      TRUE ~ "shared"
    )
  ) |>
  arrange(variable, level)

if (any(category_support$support_status == "post_only_overlap_failure")) {
  stop("The 2025 tail contains a category absent from the historical tail.")
}

write_csv_if_changed(
  analysis_samples_summary,
  "../output/analysis_samples_summary.csv"
)
write_csv_if_changed(
  sample_flow,
  "../output/analysis_sample_flow.csv"
)
write_csv_if_changed(
  analysis_sample_qc,
  "../output/analysis_sample_qc.csv"
)
write_csv_if_changed(
  balance_variable_summary,
  "../output/balance_variable_summary_unweighted_c99.csv"
)
write_csv_if_changed(
  category_support,
  "../output/category_support_c99.csv"
)
saveRDS(historical_tail, "../output/tail_pre_c99.rds", version = 3)
saveRDS(post_tail, "../output/tail_post_c99.rds", version = 3)

cat(
  "Wrote strict c=99 parent-tail samples and diagnostics to ../output\n"
)

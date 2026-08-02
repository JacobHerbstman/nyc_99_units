# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_mass_balance/code")
# training_start_year <- 2019L
# training_end_year <- 2022L
# post_year <- 2025L
# min_units <- 6L
# minimum_category_rows <- 30L
# threshold_units <- 100L
# unit_bin_upper_bounds_text <- "29,49,79,98,99,119,149,199"
# local_lower_units <- 50L
# local_upper_units <- 150L
# support_lower <- 0.01
# support_upper <- 0.99
# maturity_days <- 180L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")
source("../../../_lib/parent_no_notch_model.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 12L) {
  stop(
    "Expected training and post years, model floors, policy threshold, unit ",
    "bin bounds, local range, support quantiles, and maturity days."
  )
}

training_start_year <- as.integer(args[1])
training_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
min_units <- as.integer(args[4])
minimum_category_rows <- as.integer(args[5])
threshold_units <- as.integer(args[6])
unit_bin_upper_bounds_text <- args[7]
local_lower_units <- as.integer(args[8])
local_upper_units <- as.integer(args[9])
support_lower <- as.numeric(args[10])
support_upper <- as.numeric(args[11])
maturity_days <- as.integer(args[12])
unit_bin_upper_bounds <- as.integer(strsplit(
  unit_bin_upper_bounds_text,
  ",",
  fixed = TRUE
)[[1]])

if (
  any(is.na(c(
    training_start_year, training_end_year, post_year, min_units,
    minimum_category_rows, threshold_units, unit_bin_upper_bounds,
    local_lower_units, local_upper_units, support_lower, support_upper,
    maturity_days
  ))) ||
    training_start_year >= training_end_year ||
    post_year <= training_end_year ||
    min_units < 1L ||
    minimum_category_rows < 2L ||
    threshold_units <= min_units ||
    is.unsorted(unit_bin_upper_bounds, strictly = TRUE) ||
    unit_bin_upper_bounds[1] < min_units ||
    !all(c(threshold_units - 2L, threshold_units - 1L) %in%
      unit_bin_upper_bounds) ||
    local_lower_units >= threshold_units ||
    local_upper_units < threshold_units ||
    support_lower <= 0 ||
    support_upper >= 1 ||
    support_lower >= support_upper ||
    maturity_days < 1L ||
    maturity_days >= 365L
) {
  stop("Parent mass-balance audit arguments are not internally consistent.")
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

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_scores <- read_parquet(
  "../input/enhanced_parent_2025_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_distribution <- read_csv(
  "../input/enhanced_parent_2025_distribution.csv",
  show_col_types = FALSE
) |>
  filter(unit_definition == "hdb_priority")

counterfactual <- read_csv(
  "../input/enhanced_parent_2025_counterfactual.csv",
  show_col_types = FALSE
) |>
  filter(unit_definition == "hdb_priority")

universal_parent_membership <- read_parquet(
  "../input/provisional_parent_universal_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

pseudo_policy_years <- read_csv(
  "../input/parent_model_pseudo_policy_years.csv",
  show_col_types = FALSE
)

historical_rows <- historical_panel |>
  filter(
    model_eligible,
    analysis_status == "historical_fully_observed",
    cohort_year >= training_start_year,
    cohort_year <= training_end_year
  )

post_followup <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(
    parent_id, cohort_date, source_end_date,
    left_window_observed
  ) |>
  mutate(observed_followup_days = as.integer(source_end_date - cohort_date))

post_rows <- post_panel |>
  left_join(
    post_followup |>
      select(parent_id, observed_followup_days, left_window_observed),
    by = "parent_id",
    relationship = "one-to-one"
  ) |>
  filter(
    model_eligible,
    cohort_year == post_year,
    left_window_observed,
    observed_followup_days >= maturity_days
  ) |>
  mutate(
    units = units_hdb_priority,
    log_units = log(units)
  )

if (
  nrow(historical_rows) == 0L ||
    nrow(post_rows) == 0L ||
    nrow(counterfactual) != 1L ||
    anyDuplicated(historical_rows$observation_id) ||
    anyDuplicated(post_rows$observation_id) ||
    anyDuplicated(post_followup$parent_id) ||
    anyDuplicated(post_scores$observation_id) ||
    anyDuplicated(universal_parent_membership$root_job_id) ||
    nrow(post_scores) != nrow(post_rows) ||
    !setequal(post_scores$observation_id, post_rows$observation_id) ||
    counterfactual$training_parents != nrow(historical_rows) ||
    counterfactual$scoreable_2025_parents != nrow(post_rows) ||
    counterfactual$minimum_observed_followup_days != maturity_days ||
    !identical(
      sort(unique(historical_rows$filing_year)),
      training_start_year:training_end_year
    )
) {
  stop("Parent mass-balance inputs failed sample and key QC.")
}

post_rows <- post_rows |>
  left_join(
    post_scores |>
      select(
        observation_id,
        predicted_log_units,
        probability_exact_99,
        probability_at_least_100
      ),
    by = "observation_id",
    relationship = "one-to-one"
  )

if (
  any(!is.finite(post_rows$predicted_log_units)) ||
    any(!is.finite(post_rows$probability_exact_99)) ||
    any(!is.finite(post_rows$probability_at_least_100))
) {
  stop("Production parent scores are incomplete after the safe join.")
}

score_rows <- bind_rows(
  historical_rows |> mutate(score_sample = "historical"),
  post_rows |> mutate(score_sample = "post")
)
support_fit <- fit_rounded_mle(
  historical_rows,
  score_rows,
  min_units,
  minimum_category_rows,
  model_formula
)
score_rows$predicted_log_units <- support_fit$test_mu
historical_rows$predicted_log_units <- score_rows$predicted_log_units[
  score_rows$score_sample == "historical"
]
refit_post_predictions <- score_rows$predicted_log_units[
  score_rows$score_sample == "post"
]

if (max(abs(
  refit_post_predictions - post_rows$predicted_log_units
)) > 1e-8) {
  stop("Audit refit does not reproduce the production parent predictions.")
}

unit_bin_breaks <- c(
  min_units - 1L,
  unit_bin_upper_bounds,
  Inf
)
unit_bin_labels <- c(
  paste0(
    c(min_units, unit_bin_upper_bounds[-length(unit_bin_upper_bounds)] + 1L),
    "-",
    unit_bin_upper_bounds
  ),
  paste0(tail(unit_bin_upper_bounds, 1L) + 1L, "+")
)

annual_rows <- bind_rows(
  historical_rows |>
    mutate(display_year = filing_year),
  post_rows |>
    mutate(display_year = post_year)
) |>
  mutate(
    unit_bin = factor(
      cut(
        units,
        breaks = unit_bin_breaks,
        labels = unit_bin_labels,
        right = TRUE
      ),
      levels = unit_bin_labels
    )
  )

if (any(is.na(annual_rows$unit_bin))) {
  stop("At least one parent falls outside the requested unit bins.")
}

annual_parent_counts <- annual_rows |>
  count(display_year, unit_bin, .drop = FALSE, name = "parents") |>
  arrange(display_year, unit_bin)

observed_by_bin <- post_rows |>
  mutate(
    unit_bin = factor(
      cut(
        units,
        breaks = unit_bin_breaks,
        labels = unit_bin_labels,
        right = TRUE
      ),
      levels = unit_bin_labels
    )
  ) |>
  count(unit_bin, .drop = FALSE, name = "observed_parents")

expected_below_last_bin <- post_distribution |>
  filter(units <= max(unit_bin_upper_bounds)) |>
  mutate(
    unit_bin = factor(
      cut(
        units,
        breaks = unit_bin_breaks,
        labels = unit_bin_labels,
        right = TRUE
      ),
      levels = unit_bin_labels
    )
  ) |>
  group_by(unit_bin, .drop = FALSE) |>
  summarise(expected_parents = sum(expected_count), .groups = "drop") |>
  filter(unit_bin != tail(unit_bin_labels, 1L))

expected_by_bin <- bind_rows(
  expected_below_last_bin,
  tibble(
    unit_bin = factor(
      tail(unit_bin_labels, 1L),
      levels = unit_bin_labels
    ),
    expected_parents = nrow(post_rows) -
      sum(expected_below_last_bin$expected_parents)
  )
)

mass_balance_by_bin <- observed_by_bin |>
  left_join(
    expected_by_bin,
    by = "unit_bin",
    relationship = "one-to-one"
  ) |>
  mutate(
    residual_observed_minus_expected =
      observed_parents - expected_parents,
    unit_bin = as.character(unit_bin)
  )

threshold_mass_balance <- tibble(
  region = c(
    paste0("below_", threshold_units - 1L),
    paste0("exact_", threshold_units - 1L),
    paste0("at_least_", threshold_units)
  ),
  observed_parents = c(
    nrow(post_rows) - counterfactual$observed_exact_99 -
      counterfactual$observed_100_plus,
    counterfactual$observed_exact_99,
    counterfactual$observed_100_plus
  ),
  expected_parents = c(
    nrow(post_rows) - counterfactual$expected_no_notch_exact_99 -
      counterfactual$expected_no_notch_100_plus,
    counterfactual$expected_no_notch_exact_99,
    counterfactual$expected_no_notch_100_plus
  )
) |>
  mutate(
    residual_observed_minus_expected =
      observed_parents - expected_parents,
    missing_expected_mass = expected_parents - observed_parents,
    reported_conservation_gap = counterfactual$conservation_gap
  )

structure_levels <- c(
  "singleton_exact_99",
  "singleton_other",
  "repeated_99_parent",
  "one_99_with_other_filings",
  "mixed_multi_filing_without_99"
)

parent_structure_mass_balance <- post_rows |>
  mutate(
    parent_structure = case_when(
      component_filings == 1L & units == threshold_units - 1L ~
        "singleton_exact_99",
      component_filings == 1L ~ "singleton_other",
      exact_99_component_filings >= 2L ~ "repeated_99_parent",
      exact_99_component_filings == 1L ~ "one_99_with_other_filings",
      TRUE ~ "mixed_multi_filing_without_99"
    )
  ) |>
  group_by(parent_structure) |>
  summarise(
    parents = n(),
    component_filings = sum(component_filings),
    exact_99_component_filings = sum(exact_99_component_filings),
    observed_exact_99_parents = sum(units == threshold_units - 1L),
    expected_exact_99_parents = sum(probability_exact_99),
    excess_exact_99_parents =
      observed_exact_99_parents - expected_exact_99_parents,
    observed_100_plus_parents = sum(units >= threshold_units),
    expected_100_plus_parents = sum(probability_at_least_100),
    missing_100_plus_parents =
      expected_100_plus_parents - observed_100_plus_parents,
    conservation_gap =
      excess_exact_99_parents - missing_100_plus_parents,
    .groups = "drop"
  ) |>
  right_join(
    tibble(parent_structure = structure_levels),
    by = "parent_structure",
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      -parent_structure,
      ~ replace_na(.x, 0)
    ),
    parent_structure = factor(
      parent_structure,
      levels = structure_levels
    )
  ) |>
  arrange(parent_structure) |>
  mutate(parent_structure = as.character(parent_structure))

parent_structure_mass_balance <- bind_rows(
  parent_structure_mass_balance,
  parent_structure_mass_balance |>
    summarise(
      parent_structure = "all_parents",
      across(where(is.numeric), sum)
    )
)

preferred_exact_99_broad_links <- post_rows |>
  filter(
    units == threshold_units - 1L,
    component_filings == 1L
  ) |>
  select(
    observation_id,
    root_job_id = component_jobs
  ) |>
  mutate(
    root_job_id = str_remove(root_job_id, "-I1$")
  ) |>
  left_join(
    universal_parent_membership |>
      select(
        root_job_id,
        provisional_parent_opportunity_id,
        all_dob_root_jobs,
        all_dob_proposed_units,
        all_dob_exact_99_jobs,
        parent_structure
      ),
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    broad_link_class = case_when(
      is.na(provisional_parent_opportunity_id) ~
        "unmatched_to_broad_universe",
      parent_structure == "unlinked_single_99" ~
        "unlinked_single_99",
      parent_structure == "repeated_99_parent" ~
        "repeated_99_parent",
      parent_structure == "one_99_with_other_jobs" ~
        "one_99_with_other_jobs",
      TRUE ~ "dob_source_disagreement_multi_job"
    )
  )

broad_link_parent_totals <- preferred_exact_99_broad_links |>
  filter(!is.na(provisional_parent_opportunity_id)) |>
  distinct(
    broad_link_class,
    provisional_parent_opportunity_id,
    .keep_all = TRUE
  ) |>
  group_by(broad_link_class) |>
  summarise(
    broad_universal_parents = n(),
    broad_parent_dob_jobs = sum(all_dob_root_jobs),
    broad_parent_dob_units = sum(all_dob_proposed_units),
    .groups = "drop"
  )

preferred_exact_99_broad_link_sensitivity <-
  preferred_exact_99_broad_links |>
  count(
    broad_link_class,
    name = "preferred_exact_99_parents"
  ) |>
  left_join(
    broad_link_parent_totals,
    by = "broad_link_class",
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      c(
        broad_universal_parents,
        broad_parent_dob_jobs,
        broad_parent_dob_units
      ),
      ~ replace_na(.x, 0)
    ),
    share_of_preferred_exact_99 =
      preferred_exact_99_parents / nrow(preferred_exact_99_broad_links)
  ) |>
  arrange(desc(preferred_exact_99_parents))

preferred_exact_99_broad_link_sensitivity <- bind_rows(
  preferred_exact_99_broad_link_sensitivity,
  preferred_exact_99_broad_link_sensitivity |>
    summarise(
      broad_link_class = "all_preferred_exact_99",
      across(
        c(
          preferred_exact_99_parents,
          broad_universal_parents,
          broad_parent_dob_jobs,
          broad_parent_dob_units,
          share_of_preferred_exact_99
        ),
        sum
      )
    )
)

categorical_variables <- c("borough", "zone_detail", "prior_site_use")

parent_composition_comparison <- bind_rows(lapply(
  categorical_variables,
  function(variable_name) {
    historical_levels <- historical_rows |>
      transmute(level = coalesce(
        as.character(.data[[variable_name]]),
        "missing"
      ))
    post_levels <- post_rows |>
      transmute(level = coalesce(
        as.character(.data[[variable_name]]),
        "missing"
      ))
    comparison_levels <- sort(unique(c(
      historical_levels$level,
      post_levels$level
    )))
    historical_counts <- historical_levels |>
      count(level, name = "historical_parents")
    post_counts <- post_levels |>
      count(level, name = "post_parents")
    historical_annual_shares <- historical_rows |>
      transmute(
        display_year = filing_year,
        level = coalesce(
          as.character(.data[[variable_name]]),
          "missing"
        )
      ) |>
      count(display_year, level, name = "parents") |>
      complete(
        display_year = training_start_year:training_end_year,
        level = comparison_levels,
        fill = list(parents = 0L)
      ) |>
      group_by(display_year) |>
      mutate(share = parents / sum(parents)) |>
      ungroup() |>
      group_by(level) |>
      summarise(
        historical_annual_mean_share = mean(share),
        historical_annual_min_share = min(share),
        historical_annual_max_share = max(share),
        .groups = "drop"
      )

    tibble(level = comparison_levels) |>
      left_join(
        historical_counts,
        by = "level",
        relationship = "one-to-one"
      ) |>
      left_join(
        post_counts,
        by = "level",
        relationship = "one-to-one"
      ) |>
      left_join(
        historical_annual_shares,
        by = "level",
        relationship = "one-to-one"
      ) |>
      mutate(
        variable = variable_name,
        historical_parents = replace_na(historical_parents, 0L),
        post_parents = replace_na(post_parents, 0L),
        historical_pooled_share =
          historical_parents / nrow(historical_rows),
        post_share = post_parents / nrow(post_rows),
        post_minus_historical_percentage_points =
          100 * (post_share - historical_pooled_share),
        post_outside_historical_annual_range =
          post_share < historical_annual_min_share |
          post_share > historical_annual_max_share,
        post_level_unseen_historically =
          historical_parents == 0L & post_parents > 0L,
        .before = 1L
      )
  }
)) |>
  arrange(variable, level)

support_variables <- c(
  "log_lotarea",
  "residfar",
  "builtfar",
  "predicted_log_units"
)
support_groups <- list(
  all_2025_parents = post_rows,
  exact_99_2025_parents = post_rows |>
    filter(units == threshold_units - 1L)
)

parent_covariate_support <- bind_rows(lapply(
  support_variables,
  function(variable_name) {
    historical_values <- historical_rows[[variable_name]]
    historical_values <- historical_values[is.finite(historical_values)]
    historical_lower <- unname(quantile(
      historical_values,
      support_lower
    ))
    historical_upper <- unname(quantile(
      historical_values,
      support_upper
    ))
    historical_sd <- sd(historical_values)

    bind_rows(lapply(
      names(support_groups),
      function(group_name) {
        post_values <- support_groups[[group_name]][[variable_name]]
        finite_post_values <- post_values[is.finite(post_values)]

        tibble(
          variable = variable_name,
          post_group = group_name,
          post_parents = length(post_values),
          post_nonmissing = length(finite_post_values),
          post_missing = sum(!is.finite(post_values)),
          historical_min = min(historical_values),
          historical_support_lower = historical_lower,
          historical_mean = mean(historical_values),
          historical_support_upper = historical_upper,
          historical_max = max(historical_values),
          post_mean = mean(finite_post_values),
          post_median = median(finite_post_values),
          standardized_mean_difference =
            (mean(finite_post_values) - mean(historical_values)) /
            historical_sd,
          post_below_historical_min = sum(
            finite_post_values < min(historical_values)
          ),
          post_above_historical_max = sum(
            finite_post_values > max(historical_values)
          ),
          post_outside_historical_range = sum(
            finite_post_values < min(historical_values) |
            finite_post_values > max(historical_values)
          ),
          post_outside_historical_percentile_range = sum(
            finite_post_values < historical_lower |
            finite_post_values > historical_upper
          )
        )
      }
    ))
  }
))

parent_placebo_conservation_gaps <- bind_rows(
  pseudo_policy_years |>
    transmute(
      sample = "historical_pseudo_policy_year",
      sample_year = pseudo_policy_year,
      parents = scoreable_parents,
      observed_exact_99 = observed_exact_bunch_units,
      expected_exact_99 = expected_no_notch_exact_bunch_units,
      excess_exact_99 = excess_exact_bunch_units,
      observed_100_plus = observed_at_or_above_threshold,
      expected_100_plus = expected_no_notch_at_or_above_threshold,
      missing_100_plus = missing_at_or_above_threshold,
      missing_below_99 = conservation_gap,
      conservation_gap
    ),
  counterfactual |>
    transmute(
      sample = "post_policy",
      sample_year = post_year,
      parents = scoreable_2025_parents,
      observed_exact_99,
      expected_exact_99 = expected_no_notch_exact_99,
      excess_exact_99,
      observed_100_plus,
      expected_100_plus = expected_no_notch_100_plus,
      missing_100_plus,
      missing_below_99 = conservation_gap,
      conservation_gap
    )
) |>
  arrange(sample_year)

annual_parent_local_mass <- annual_rows |>
  mutate(
    local_region = case_when(
      units >= local_lower_units & units <= threshold_units - 2L ~
        paste0(local_lower_units, "-", threshold_units - 2L),
      units == threshold_units - 1L ~
        paste0("Exact ", threshold_units - 1L),
      units >= threshold_units & units <= local_upper_units ~
        paste0(threshold_units, "-", local_upper_units),
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(local_region)) |>
  count(display_year, local_region, name = "parents") |>
  complete(
    display_year = c(training_start_year:training_end_year, post_year),
    local_region = c(
      paste0(local_lower_units, "-", threshold_units - 2L),
      paste0("Exact ", threshold_units - 1L),
      paste0(threshold_units, "-", local_upper_units)
    ),
    fill = list(parents = 0L)
  ) |>
  mutate(
    local_region = as.character(local_region)
  )

parent_prediction_support_scores <- bind_rows(
  historical_rows |>
    transmute(sample = paste0(training_start_year, "-", training_end_year),
      predicted_log_units),
  post_rows |>
    transmute(sample = as.character(post_year), predicted_log_units)
)

mass_balance_qc <- tibble(
  check = c(
    "historical_model_parents",
    "post_model_parents",
    "post_component_filings",
    "post_exact_99_parents",
    "post_100_plus_parents",
    "preferred_conservation_gap",
    "missing_below_99",
    "threshold_identity_error",
    "broad_bin_observed_total_error",
    "broad_bin_expected_total_error",
    "structure_parent_total_error",
    "structure_exact_mass_error",
    "structure_100_plus_mass_error",
    "maximum_production_score_reproduction_error",
    "post_categorical_levels_unseen_historically",
    "preferred_exact_99_broad_membership_matches",
    "preferred_exact_99_absorbed_by_broad_links"
  ),
  value = c(
    nrow(historical_rows),
    nrow(post_rows),
    sum(post_rows$component_filings),
    sum(post_rows$units == threshold_units - 1L),
    sum(post_rows$units >= threshold_units),
    counterfactual$conservation_gap,
    threshold_mass_balance$missing_expected_mass[
      threshold_mass_balance$region == paste0("below_", threshold_units - 1L)
    ],
    counterfactual$conservation_gap -
      threshold_mass_balance$missing_expected_mass[
        threshold_mass_balance$region ==
          paste0("below_", threshold_units - 1L)
      ],
    sum(mass_balance_by_bin$observed_parents) - nrow(post_rows),
    sum(mass_balance_by_bin$expected_parents) - nrow(post_rows),
    parent_structure_mass_balance$parents[
      parent_structure_mass_balance$parent_structure == "all_parents"
    ] - nrow(post_rows),
    parent_structure_mass_balance$expected_exact_99_parents[
      parent_structure_mass_balance$parent_structure == "all_parents"
    ] - counterfactual$expected_no_notch_exact_99,
    parent_structure_mass_balance$expected_100_plus_parents[
      parent_structure_mass_balance$parent_structure == "all_parents"
    ] - counterfactual$expected_no_notch_100_plus,
    max(abs(refit_post_predictions - post_rows$predicted_log_units)),
    sum(parent_composition_comparison$post_parents[
      parent_composition_comparison$post_level_unseen_historically
    ]),
    sum(!is.na(
      preferred_exact_99_broad_links$provisional_parent_opportunity_id
    )),
    sum(
      preferred_exact_99_broad_links$broad_link_class !=
        "unlinked_single_99"
    )
  )
)

if (
  any(abs(as.numeric(mass_balance_qc$value[8:14])) > 1e-6) ||
    any(!is.finite(mass_balance_by_bin$expected_parents)) ||
    any(!is.finite(parent_covariate_support$standardized_mean_difference)) ||
    anyDuplicated(parent_composition_comparison[c("variable", "level")]) ||
    preferred_exact_99_broad_link_sensitivity$preferred_exact_99_parents[
      preferred_exact_99_broad_link_sensitivity$broad_link_class ==
        "all_preferred_exact_99"
    ] != counterfactual$observed_exact_99 ||
    nrow(parent_placebo_conservation_gaps) !=
      training_end_year - training_start_year + 1L
) {
  stop("Parent mass-balance outputs failed final QC.")
}

write_csv_if_changed(
  threshold_mass_balance,
  "../output/parent_threshold_mass_balance.csv"
)
write_csv_if_changed(
  mass_balance_by_bin,
  "../output/parent_mass_balance_by_unit_bin.csv"
)
write_csv_if_changed(
  annual_parent_counts,
  "../output/annual_parent_counts_by_unit_bin.csv"
)
write_csv_if_changed(
  annual_parent_local_mass,
  "../output/annual_parent_local_mass.csv"
)
write_csv_if_changed(
  parent_structure_mass_balance,
  "../output/parent_structure_mass_balance.csv"
)
write_csv_if_changed(
  preferred_exact_99_broad_link_sensitivity,
  "../output/preferred_exact_99_broad_link_sensitivity.csv"
)
write_csv_if_changed(
  parent_composition_comparison,
  "../output/parent_composition_comparison.csv"
)
write_csv_if_changed(
  parent_covariate_support,
  "../output/parent_covariate_support.csv"
)
write_parquet_if_changed(
  parent_prediction_support_scores,
  "../output/parent_prediction_support_scores.parquet"
)
write_csv_if_changed(
  parent_placebo_conservation_gaps,
  "../output/parent_placebo_conservation_gaps.csv"
)
write_csv_if_changed(
  mass_balance_qc,
  "../output/parent_mass_balance_qc.csv"
)

cat("Wrote parent mass-balance audit outputs to ../output\n")

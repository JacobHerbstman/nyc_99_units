# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_provisional_parent_no_notch/code")
# universe_min_units <- 6L
# threshold_units <- 100L
# nearby_meters <- 100
# max_filing_days <- 365L
# simulation_draws <- 20000L
# simulation_seed <- 990100L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tibble)
  library(tidyr)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 6L) {
  stop(
    "Expected universe floor, threshold, nearby meters, maximum filing days, ",
    "simulation draws, and simulation seed."
  )
}

universe_min_units <- as.integer(args[1])
threshold_units <- as.integer(args[2])
nearby_meters <- as.numeric(args[3])
max_filing_days <- as.integer(args[4])
simulation_draws <- as.integer(args[5])
simulation_seed <- as.integer(args[6])
bunch_units <- threshold_units - 1L

if (
  any(is.na(c(
    universe_min_units, threshold_units, nearby_meters,
    max_filing_days, simulation_draws, simulation_seed
  ))) ||
    universe_min_units < 1L ||
    threshold_units <= universe_min_units ||
    nearby_meters <= 0 ||
    max_filing_days < 1L ||
    simulation_draws < 1000L
) {
  stop("Parent no-notch arguments are not internally consistent.")
}

expected_bunching_mass <- function(frontier, score_rows) {
  lower_z <- (
    log(threshold_units - 0.5) - score_rows$predicted_log_units
  ) / score_rows$shock_sigma
  upper_z <- (
    log(frontier) - score_rows$predicted_log_units
  ) / score_rows$shock_sigma
  floor_z <- (
    log(universe_min_units - 0.5) - score_rows$predicted_log_units
  ) / score_rows$shock_sigma
  interval_probability <- pmax(
    pnorm(lower_z, lower.tail = FALSE) -
      pnorm(upper_z, lower.tail = FALSE),
    0
  )
  sum(interval_probability / pnorm(floor_z, lower.tail = FALSE))
}

solve_filing_frontier <- function(target_mass, score_rows) {
  maximum_mass <- expected_bunching_mass(Inf, score_rows)

  if (target_mass < 0 || target_mass > maximum_mass + 1e-8) {
    return(NA_real_)
  }

  if (abs(target_mass - maximum_mass) <= 1e-8) {
    return(Inf)
  }

  lower_frontier <- threshold_units - 0.5

  if (target_mass == 0) {
    return(lower_frontier)
  }

  upper_frontier <- threshold_units * 2
  expansion_steps <- 0L

  while (expected_bunching_mass(upper_frontier, score_rows) < target_mass) {
    upper_frontier <- upper_frontier * 2
    expansion_steps <- expansion_steps + 1L

    if (expansion_steps > 30L || !is.finite(upper_frontier)) {
      return(NA_real_)
    }
  }

  uniroot(
    function(frontier) {
      expected_bunching_mass(frontier, score_rows) - target_mass
    },
    interval = c(lower_frontier, upper_frontier),
    tol = 1e-8
  )$root
}

job_crosswalk <- read_parquet(
  "../input/developer_opportunity_job_crosswalk.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  arrange(filing_date, root_job_id) |>
  mutate(universal_row_id = row_number())

exact_99_casebook <- read_csv(
  "../input/developer_opportunity_exact_99_casebook.csv",
  show_col_types = FALSE
)

scores <- read_parquet(
  "../input/no_notch_post_policy_exposure_scores.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(job_crosswalk) < 2L ||
    anyDuplicated(job_crosswalk$root_job_id) ||
    anyDuplicated(exact_99_casebook$root_job_id) ||
    anyDuplicated(scores[c("job_number", "model_role")]) ||
    n_distinct(scores$model_role) != 2L
) {
  stop("Parent no-notch inputs failed identifier QC.")
}

pair_index <- t(combn(seq_len(nrow(job_crosswalk)), 2L))

universal_strong_pairs <- bind_cols(
  job_crosswalk[pair_index[, 1L], ] |>
    select(
      universal_row_id, root_job_id, filing_date, dob_bbl,
      lot_history_group_bbl, latitude, longitude, owner_match_key,
      description_referenced_job_id, description_project_code
    ) |>
    rename_with(~ paste0(.x, "_1")),
  job_crosswalk[pair_index[, 2L], ] |>
    select(
      universal_row_id, root_job_id, filing_date, dob_bbl,
      lot_history_group_bbl, latitude, longitude, owner_match_key,
      description_referenced_job_id, description_project_code
    ) |>
    rename_with(~ paste0(.x, "_2"))
) |>
  mutate(
    filing_days_apart = abs(as.integer(filing_date_1 - filing_date_2)),
    distance_meters = 6371000 * pi / 180 * sqrt(
      ((longitude_2 - longitude_1) *
        cos((latitude_1 + latitude_2) * pi / 360))^2 +
        (latitude_2 - latitude_1)^2
    ),
    same_filing_bbl = !is.na(dob_bbl_1) & dob_bbl_1 == dob_bbl_2,
    same_lot_history_group = !is.na(lot_history_group_bbl_1) &
      lot_history_group_bbl_1 == lot_history_group_bbl_2,
    same_owner_nearby = !is.na(owner_match_key_1) &
      owner_match_key_1 == owner_match_key_2 &
      !is.na(distance_meters) & distance_meters <= nearby_meters,
    description_cross_reference =
      (!is.na(description_referenced_job_id_1) &
        description_referenced_job_id_1 == root_job_id_2) |
      (!is.na(description_referenced_job_id_2) &
        description_referenced_job_id_2 == root_job_id_1),
    same_description_project_code =
      !is.na(description_project_code_1) &
      description_project_code_1 == description_project_code_2,
    strong_parent_link = filing_days_apart <= max_filing_days & (
      same_filing_bbl |
        same_lot_history_group |
        same_owner_nearby |
        description_cross_reference |
        same_description_project_code
    )
  ) |>
  filter(strong_parent_link) |>
  select(
    universal_row_id_1, universal_row_id_2, root_job_id_1, root_job_id_2,
    filing_days_apart, distance_meters, same_filing_bbl,
    same_lot_history_group, same_owner_nearby,
    description_cross_reference, same_description_project_code
  ) |>
  arrange(root_job_id_1, root_job_id_2)

message("Constructed ", nrow(universal_strong_pairs), " universal strong links.")

component <- seq_len(nrow(job_crosswalk))

if (nrow(universal_strong_pairs) > 0L) {
  for (pair_row in seq_len(nrow(universal_strong_pairs))) {
    left_component <- component[
      universal_strong_pairs$universal_row_id_1[pair_row]
    ]
    right_component <- component[
      universal_strong_pairs$universal_row_id_2[pair_row]
    ]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <-
      merged_component
  }
}

component_ids <- tibble(
  universal_row_id = seq_len(nrow(job_crosswalk)),
  component
) |>
  group_by(component) |>
  mutate(component_first_row = min(universal_row_id)) |>
  ungroup() |>
  mutate(
    provisional_parent_opportunity_id = sprintf(
      "universal_parent_%04d",
      match(component_first_row, sort(unique(component_first_row)))
    )
  ) |>
  select(universal_row_id, provisional_parent_opportunity_id)

job_membership <- job_crosswalk |>
  left_join(
    component_ids,
    by = "universal_row_id",
    relationship = "one-to-one"
  ) |>
  select(
    provisional_parent_opportunity_id, root_job_id, filing_date, filing_year,
    proposed_units, dob_bbl, dob_bin, address, owner_name,
    candidate_parent_opportunity_id
  )

parent_inventory <- job_membership |>
  group_by(provisional_parent_opportunity_id) |>
  summarise(
    all_dob_root_jobs = n(),
    all_dob_proposed_units = sum(proposed_units),
    all_dob_exact_99_jobs = sum(proposed_units == bunch_units),
    all_dob_distinct_bins = n_distinct(dob_bin, na.rm = TRUE),
    all_dob_distinct_bbls = n_distinct(dob_bbl, na.rm = TRUE),
    first_filing_date = min(filing_date),
    last_filing_date = max(filing_date),
    root_job_ids = paste(sort(root_job_id), collapse = ";"),
    .groups = "drop"
  ) |>
  mutate(
    parent_structure = case_when(
      all_dob_root_jobs == 1L & all_dob_exact_99_jobs == 0L ~
        "singleton_without_99",
      all_dob_root_jobs == 1L & all_dob_exact_99_jobs == 1L ~
        "unlinked_single_99",
      all_dob_root_jobs > 1L & all_dob_exact_99_jobs == 0L ~
        "multiple_jobs_without_99",
      all_dob_exact_99_jobs == 1L ~ "one_99_with_other_jobs",
      all_dob_exact_99_jobs >= 2L ~ "repeated_99_parent"
    )
  )

universal_membership_output <- job_membership |>
  left_join(
    parent_inventory,
    by = "provisional_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  arrange(provisional_parent_opportunity_id, filing_date, root_job_id)

message(
  "Constructed ", nrow(parent_inventory),
  " provisional parents from ", nrow(job_membership), " DOB jobs."
)

score_membership <- scores |>
  left_join(
    job_membership |>
      select(
        root_job_id,
        provisional_parent_opportunity_id,
        dob_proposed_units = proposed_units
      ),
    by = c("job_number" = "root_job_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    matched_to_dob_parent_universe = !is.na(provisional_parent_opportunity_id),
    provisional_parent_opportunity_id = if_else(
      matched_to_dob_parent_universe,
      provisional_parent_opportunity_id,
      paste0("unmatched_score_singleton_", job_number)
    ),
    dob_proposed_units = if_else(
      matched_to_dob_parent_universe,
      dob_proposed_units,
      observed_units
    )
  ) |>
  left_join(
    parent_inventory |>
      select(
        provisional_parent_opportunity_id,
        all_dob_root_jobs,
        all_dob_proposed_units,
        all_dob_exact_99_jobs,
        all_dob_distinct_bins,
        all_dob_distinct_bbls,
        parent_structure
      ),
    by = "provisional_parent_opportunity_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    all_dob_root_jobs = coalesce(all_dob_root_jobs, 1L),
    all_dob_proposed_units = coalesce(
      all_dob_proposed_units,
      observed_units
    ),
    all_dob_exact_99_jobs = coalesce(
      all_dob_exact_99_jobs,
      as.integer(observed_units == bunch_units)
    ),
    all_dob_distinct_bins = coalesce(all_dob_distinct_bins, 1L),
    all_dob_distinct_bbls = coalesce(all_dob_distinct_bbls, 1L),
    parent_structure = coalesce(
      parent_structure,
      if_else(
        observed_units == bunch_units,
        "unlinked_single_99",
        "singleton_without_99"
      )
    )
  ) |>
  group_by(model_role, provisional_parent_opportunity_id) |>
  mutate(
    scoreable_parent_members = n(),
    scoreable_observed_units_sum = sum(observed_units),
    scoreable_dob_units_sum = sum(dob_proposed_units),
    fixed_companion_units = pmax(
      first(all_dob_proposed_units) - scoreable_dob_units_sum,
      0
    ),
    observed_parent_units =
      scoreable_observed_units_sum + fixed_companion_units
  ) |>
  ungroup() |>
  arrange(model_role, provisional_parent_opportunity_id, job_number)

if (
  nrow(score_membership) != nrow(scores) ||
    anyDuplicated(score_membership[c("job_number", "model_role")]) ||
    any(score_membership$fixed_companion_units < 0) ||
    any(score_membership$observed_parent_units < score_membership$observed_units)
) {
  stop("Parent membership failed row or unit-accounting QC.")
}

message(
  "Mapped ", n_distinct(score_membership$job_number),
  " scoreable filings into ",
  n_distinct(score_membership$provisional_parent_opportunity_id),
  " provisional parents."
)

parent_score_rows <- list()
parent_draws <- list()

for (model_role_value in unique(score_membership$model_role)) {
  model_membership <- score_membership |>
    filter(model_role == model_role_value)
  set.seed(simulation_seed)

  for (parent_id_value in unique(
    model_membership$provisional_parent_opportunity_id
  )) {
    parent_members <- model_membership |>
      filter(provisional_parent_opportunity_id == parent_id_value)
    floor_cdf <- pnorm(
      (
        log(universe_min_units - 0.5) -
          parent_members$predicted_log_units
      ) / parent_members$shock_sigma
    )
    uniforms <- matrix(
      runif(simulation_draws * nrow(parent_members)),
      nrow = simulation_draws,
      ncol = nrow(parent_members)
    )
    target_cdf <- sweep(
      uniforms,
      2L,
      1 - floor_cdf,
      `*`
    )
    target_cdf <- sweep(target_cdf, 2L, floor_cdf, `+`)
    latent_log_units <- sweep(
      qnorm(target_cdf),
      2L,
      parent_members$shock_sigma,
      `*`
    )
    latent_log_units <- sweep(
      latent_log_units,
      2L,
      parent_members$predicted_log_units,
      `+`
    )
    simulated_member_units <- matrix(
      pmax(
        universe_min_units,
        floor(exp(latent_log_units) + 0.5)
      ),
      nrow = simulation_draws,
      ncol = nrow(parent_members)
    )
    simulated_parent_units <- rowSums(simulated_member_units) +
      parent_members$fixed_companion_units[1]
    parent_draws[[paste(model_role_value, parent_id_value, sep = "|")]] <-
      simulated_parent_units
    parent_score_rows[[length(parent_score_rows) + 1L]] <- parent_members |>
      slice(1L) |>
      transmute(
        provisional_parent_opportunity_id,
        model_role,
        model,
        parent_structure,
        matched_to_dob_parent_universe = all(
          model_membership$matched_to_dob_parent_universe[
            model_membership$provisional_parent_opportunity_id == parent_id_value
          ]
        ),
        all_dob_root_jobs,
        all_dob_proposed_units,
        all_dob_exact_99_jobs,
        all_dob_distinct_bins,
        all_dob_distinct_bbls,
        scoreable_parent_members,
        fixed_companion_units,
        observed_parent_units,
        predicted_parent_q10_units = as.integer(quantile(
          simulated_parent_units, 0.10, names = FALSE, type = 1
        )),
        predicted_parent_median_units = as.integer(quantile(
          simulated_parent_units, 0.50, names = FALSE, type = 1
        )),
        predicted_parent_q90_units = as.integer(quantile(
          simulated_parent_units, 0.90, names = FALSE, type = 1
        )),
        probability_parent_exact_99 = mean(
          simulated_parent_units == bunch_units
        ),
        probability_parent_at_least_100 = mean(
          simulated_parent_units >= threshold_units
        ),
        probability_observed_parent_units = mean(
          simulated_parent_units == observed_parent_units
        )
      )
  }

  message("Finished parent simulation for ", model_role_value, ".")
}

parent_scores <- bind_rows(parent_score_rows) |>
  arrange(model_role, provisional_parent_opportunity_id)

parent_scale_summary <- parent_scores |>
  group_by(model_role, model, parent_structure) |>
  summarise(
    provisional_parents = n(),
    scoreable_filings = sum(scoreable_parent_members),
    parents_with_fixed_companions = sum(fixed_companion_units > 0),
    median_observed_parent_units = median(observed_parent_units),
    median_predicted_parent_units = median(predicted_parent_median_units),
    median_absolute_log_error = median(abs(
      log(observed_parent_units) - log(predicted_parent_median_units)
    )),
    observed_exact_99_parents = sum(observed_parent_units == bunch_units),
    expected_no_notch_exact_99_parents = sum(probability_parent_exact_99),
    observed_100_plus_parents = sum(observed_parent_units >= threshold_units),
    expected_no_notch_100_plus_parents = sum(
      probability_parent_at_least_100
    ),
    .groups = "drop"
  ) |>
  arrange(model_role, parent_structure)

parent_mass_balance_rows <- list()

for (model_role_value in unique(parent_scores$model_role)) {
  model_parents <- parent_scores |>
    filter(model_role == model_role_value)
  observed_exact_99 <- sum(model_parents$observed_parent_units == bunch_units)
  expected_exact_99 <- sum(model_parents$probability_parent_exact_99)
  observed_100_plus <- sum(
    model_parents$observed_parent_units >= threshold_units
  )
  expected_100_plus <- sum(model_parents$probability_parent_at_least_100)
  excess_exact_99 <- observed_exact_99 - expected_exact_99
  missing_100_plus <- expected_100_plus - observed_100_plus
  all_model_draws <- parent_draws[
    str_starts(names(parent_draws), paste0(model_role_value, "|"))
  ]
  simulated_100_plus_units <- unlist(
    lapply(all_model_draws, function(draw_values) {
      draw_values[draw_values >= threshold_units]
    }),
    use.names = FALSE
  )
  maximum_moved_mass <- length(simulated_100_plus_units) / simulation_draws
  exact_99_order_statistic <- ceiling(excess_exact_99 * simulation_draws)
  missing_100_order_statistic <- ceiling(missing_100_plus * simulation_draws)
  frontier_from_exact_99 <- if (
    exact_99_order_statistic >= 1L &&
      excess_exact_99 <= maximum_moved_mass
  ) {
    sort.int(
      simulated_100_plus_units,
      partial = exact_99_order_statistic
    )[exact_99_order_statistic]
  } else if (exact_99_order_statistic == 0L) {
    threshold_units - 1L
  } else {
    NA_integer_
  }
  frontier_from_missing_100_plus <- if (
    missing_100_order_statistic >= 1L &&
      missing_100_plus <= maximum_moved_mass
  ) {
    sort.int(
      simulated_100_plus_units,
      partial = missing_100_order_statistic
    )[missing_100_order_statistic]
  } else if (missing_100_order_statistic == 0L) {
    threshold_units - 1L
  } else {
    NA_integer_
  }

  parent_mass_balance_rows[[length(parent_mass_balance_rows) + 1L]] <- tibble(
    model_role = model_role_value,
    model = unique(model_parents$model),
    provisional_parents = nrow(model_parents),
    observed_exact_99,
    expected_no_notch_exact_99 = expected_exact_99,
    excess_exact_99,
    observed_100_plus,
    expected_no_notch_100_plus = expected_100_plus,
    missing_100_plus,
    conservation_gap = excess_exact_99 - missing_100_plus,
    frontier_from_exact_99,
    frontier_from_missing_100_plus,
    interpretation = paste0(
      "diagnostic_only_parent_total_is_not_the_legal_100_unit_choice_margin"
    )
  )
}

parent_mass_balance <- bind_rows(parent_mass_balance_rows) |>
  arrange(model_role)

message("Finished parent-level mass-balance diagnostics.")

structure_groups <- bind_rows(
  score_membership |>
    mutate(structure_sample = "all_scoreable_filings"),
  score_membership |>
    filter(parent_structure %in% c(
      "singleton_without_99", "unlinked_single_99"
    )) |>
    mutate(structure_sample = "universal_singletons"),
  score_membership |>
    filter(parent_structure == "one_99_with_other_jobs") |>
    mutate(structure_sample = "one_99_with_other_jobs"),
  score_membership |>
    filter(parent_structure == "repeated_99_parent") |>
    mutate(structure_sample = "repeated_99_parent"),
  score_membership |>
    filter(parent_structure == "multiple_jobs_without_99") |>
    mutate(structure_sample = "multiple_jobs_without_99")
)

structure_mass_balance_rows <- list()

for (model_role_value in unique(structure_groups$model_role)) {
  for (structure_sample_value in unique(
    structure_groups$structure_sample[
      structure_groups$model_role == model_role_value
    ]
  )) {
    group_scores <- structure_groups |>
      filter(
        model_role == model_role_value,
        structure_sample == structure_sample_value
      )
    observed_exact_99 <- sum(group_scores$observed_units == bunch_units)
    expected_exact_99 <- sum(group_scores$probability_exact_99)
    observed_100_plus <- sum(group_scores$observed_units >= threshold_units)
    expected_100_plus <- sum(group_scores$probability_at_least_100)
    excess_exact_99 <- observed_exact_99 - expected_exact_99
    missing_100_plus <- expected_100_plus - observed_100_plus
    structure_mass_balance_rows[[length(structure_mass_balance_rows) + 1L]] <-
      tibble(
        model_role = model_role_value,
        model = unique(group_scores$model),
        structure_sample = structure_sample_value,
        scoreable_filings = nrow(group_scores),
        provisional_parents = n_distinct(
          group_scores$provisional_parent_opportunity_id
        ),
        observed_exact_99,
        expected_no_notch_exact_99 = expected_exact_99,
        excess_exact_99,
        observed_100_plus,
        expected_no_notch_100_plus = expected_100_plus,
        missing_100_plus,
        conservation_gap = excess_exact_99 - missing_100_plus,
        frontier_from_exact_99 = solve_filing_frontier(
          excess_exact_99, group_scores
        ),
        frontier_from_missing_100_plus = solve_filing_frontier(
          missing_100_plus, group_scores
        ),
        classification_warning = if_else(
          structure_sample_value %in% c(
            "one_99_with_other_jobs", "repeated_99_parent"
          ),
          "post_outcome_structure_diagnostic_not_identification_sample",
          "universal_grouping_rule_applied_before_structure_label"
        )
      )
  }
}

structure_mass_balance <- bind_rows(structure_mass_balance_rows) |>
  arrange(model_role, structure_sample)

anchored_exact_99_structure_exposure <- score_membership |>
  filter(observed_units == bunch_units) |>
  left_join(
    exact_99_casebook |>
      select(root_job_id, candidate_parent_structure),
    by = c("job_number" = "root_job_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    anchored_structure = coalesce(
      candidate_parent_structure,
      "HDB exact 99 not in DOB exact-99 casebook"
    )
  ) |>
  group_by(model_role, model, anchored_structure) |>
  summarise(
    exact_99_filings = n(),
    expected_no_notch_exact_99 = sum(probability_exact_99),
    excess_exact_99 = exact_99_filings - expected_no_notch_exact_99,
    available_probability_mass_at_or_above_100 = sum(
      probability_at_least_100
    ),
    excess_99_minus_available_crossing_mass =
      excess_exact_99 - available_probability_mass_at_or_above_100,
    mean_probability_at_or_above_100 = mean(probability_at_least_100),
    median_probability_at_or_above_100 = median(probability_at_least_100),
    median_predicted_no_notch_units = median(predicted_median_units),
    .groups = "drop"
  ) |>
  arrange(model_role, anchored_structure)

membership_output <- score_membership |>
  filter(model_role == "preferred_full_distribution") |>
  select(
    provisional_parent_opportunity_id, parent_structure,
    job_number, date_filed, observed_units, dob_proposed_units,
    matched_to_dob_parent_universe, all_dob_root_jobs,
    all_dob_proposed_units, all_dob_exact_99_jobs,
    scoreable_parent_members, fixed_companion_units,
    observed_parent_units, probability_at_least_100,
    predicted_median_units
  ) |>
  arrange(parent_structure, provisional_parent_opportunity_id, job_number)

parent_score_qc <- tibble(
  metric = c(
    "dob_companion_universe_jobs",
    "universal_strong_links",
    "universal_parent_components",
    "scoreable_2025_filings",
    "scoreable_filings_matched_to_dob_universe",
    "scoreable_filings_unmatched_to_dob_universe",
    "scoreable_exact_99_filings",
    "scoreable_exact_99_filings_matched_to_dob_universe",
    "parents_with_multiple_scoreable_members",
    "parents_with_fixed_unscored_companion_units",
    "simulation_draws",
    "simulation_seed"
  ),
  value = c(
    nrow(job_crosswalk),
    nrow(universal_strong_pairs),
    n_distinct(job_membership$provisional_parent_opportunity_id),
    n_distinct(scores$job_number),
    n_distinct(score_membership$job_number[
      score_membership$matched_to_dob_parent_universe
    ]),
    n_distinct(score_membership$job_number[
      !score_membership$matched_to_dob_parent_universe
    ]),
    n_distinct(score_membership$job_number[
      score_membership$observed_units == bunch_units
    ]),
    n_distinct(score_membership$job_number[
      score_membership$observed_units == bunch_units &
        score_membership$matched_to_dob_parent_universe
    ]),
    n_distinct(parent_scores$provisional_parent_opportunity_id[
      parent_scores$scoreable_parent_members > 1L
    ]),
    n_distinct(parent_scores$provisional_parent_opportunity_id[
      parent_scores$fixed_companion_units > 0
    ]),
    simulation_draws,
    simulation_seed
  )
)

plot_labels <- c(
  singleton_without_99 = "Singleton without 99",
  unlinked_single_99 = "Unlinked single 99",
  multiple_jobs_without_99 = "Multiple jobs without 99",
  one_99_with_other_jobs = "One 99 plus other jobs",
  repeated_99_parent = "Repeated-99 parent"
)

parent_plot <- parent_scores |>
  filter(model_role == "preferred_full_distribution") |>
  mutate(
    structure_label = factor(
      plot_labels[parent_structure],
      levels = unname(plot_labels)
    )
  ) |>
  ggplot(aes(
    x = predicted_parent_median_units,
    y = observed_parent_units,
    color = structure_label
  )) +
  geom_abline(
    slope = 1,
    intercept = 0,
    color = "#555555",
    linewidth = 0.55,
    linetype = "dashed"
  ) +
  geom_point(alpha = 0.68, size = 2) +
  scale_x_log10(labels = label_number(big.mark = ",")) +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  scale_color_manual(values = c(
    "Singleton without 99" = "#8C8C8C",
    "Unlinked single 99" = "#D95F02",
    "Multiple jobs without 99" = "#7570B3",
    "One 99 plus other jobs" = "#1B9E77",
    "Repeated-99 parent" = "#E7298A"
  )) +
  labs(
    title = "Provisional aggregation moves split projects away from 99",
    subtitle = paste0(
      "Predicted parent scale sums iid filing-level no-notch draws; unscored ",
      "companion units are fixed at observed values."
    ),
    x = "Predicted median no-notch parent units",
    y = "Observed provisional parent units",
    color = NULL,
    caption = paste0(
      "Dashed line is equality. Parent IDs are audit constructs, not validated ",
      "485-x sites or final economic ownership groups."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

structure_plot_labels <- c(
  universal_singletons = "Universal singletons",
  one_99_with_other_jobs = "One 99 plus other jobs",
  repeated_99_parent = "Repeated-99 parents"
)

structure_plot <- structure_mass_balance |>
  filter(
    model_role == "preferred_full_distribution",
    structure_sample %in% names(structure_plot_labels)
  ) |>
  select(
    structure_sample,
    `Excess exact-99 filings` = excess_exact_99,
    `Missing 100-plus filings` = missing_100_plus
  ) |>
  pivot_longer(
    cols = -structure_sample,
    names_to = "mass_moment",
    values_to = "filings"
  ) |>
  mutate(
    structure_label = factor(
      structure_plot_labels[structure_sample],
      levels = unname(structure_plot_labels)
    )
  ) |>
  ggplot(aes(x = structure_label, y = filings, fill = mass_moment)) +
  geom_col(position = position_dodge(width = 0.78), width = 0.68) +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.4) +
  scale_fill_manual(values = c(
    "Excess exact-99 filings" = "#D95F02",
    "Missing 100-plus filings" = "#1B9E77"
  )) +
  labs(
    title = "The filing-level mass imbalance differs by provisional structure",
    subtitle = paste0(
      "Preferred no-notch model. Bars use all scoreable filings belonging to ",
      "each universal parent structure."
    ),
    x = NULL,
    y = "Observed deviation from no-notch prediction",
    fill = NULL,
    caption = paste0(
      "Mixed and repeated labels use observed 99-unit outcomes and are therefore ",
      "diagnostic subgroups, not pre-treatment identification samples."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom",
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

if (
  nrow(parent_scores) !=
    n_distinct(scores$model_role) *
      n_distinct(score_membership$provisional_parent_opportunity_id) ||
    anyDuplicated(parent_scores[c(
      "provisional_parent_opportunity_id", "model_role"
    )]) ||
    any(!is.finite(parent_scores$predicted_parent_median_units)) ||
    any(parent_scores$predicted_parent_median_units < universe_min_units) ||
    nrow(parent_mass_balance) != n_distinct(scores$model_role) ||
    sum(anchored_exact_99_structure_exposure$exact_99_filings) !=
      n_distinct(scores$model_role) *
        n_distinct(scores$job_number[scores$observed_units == bunch_units]) ||
    nrow(universal_membership_output) != nrow(job_crosswalk) ||
    anyDuplicated(universal_membership_output$root_job_id) ||
    n_distinct(universal_membership_output$provisional_parent_opportunity_id) !=
      nrow(parent_inventory) ||
    nrow(parent_score_qc) != 12L
) {
  stop("Parent no-notch outputs failed final QC.")
}

write_parquet_if_changed(
  parent_scores,
  "../output/provisional_parent_no_notch_scores.parquet"
)
write_parquet_if_changed(
  universal_membership_output,
  "../output/provisional_parent_universal_membership.parquet"
)
write_parquet_if_changed(
  universal_strong_pairs,
  "../output/provisional_parent_universal_links.parquet"
)
write_csv_if_changed(
  membership_output,
  "../output/provisional_parent_membership.csv"
)
write_csv_if_changed(
  parent_scale_summary,
  "../output/provisional_parent_scale_summary.csv"
)
write_csv_if_changed(
  parent_mass_balance,
  "../output/provisional_parent_mass_balance.csv"
)
write_csv_if_changed(
  structure_mass_balance,
  "../output/provisional_parent_structure_mass_balance.csv"
)
write_csv_if_changed(
  anchored_exact_99_structure_exposure,
  "../output/anchored_exact_99_structure_exposure.csv"
)
write_csv_if_changed(
  parent_score_qc,
  "../output/provisional_parent_score_qc.csv"
)
ggsave(
  "../output/provisional_parent_predicted_vs_observed.pdf",
  parent_plot,
  width = 10,
  height = 7.5,
  device = "pdf"
)
ggsave(
  "../output/provisional_parent_predicted_vs_observed.png",
  parent_plot,
  width = 10,
  height = 7.5,
  dpi = 180,
  bg = "white"
)
ggsave(
  "../output/provisional_parent_structure_mass_balance.pdf",
  structure_plot,
  width = 9,
  height = 6.5,
  device = "pdf"
)
ggsave(
  "../output/provisional_parent_structure_mass_balance.png",
  structure_plot,
  width = 9,
  height = 6.5,
  dpi = 180,
  bg = "white"
)

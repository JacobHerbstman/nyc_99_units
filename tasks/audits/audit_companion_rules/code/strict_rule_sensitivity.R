# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_companion_rules/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(igraph)
  library(tibble)
})
source("../../../shared/code/scale_shape_helpers.R")
source("../../../shared/code/write_data_report.R")

minimum_units <- 50L
pooled_tail_start <- 301L
strict_metres <- 60
strict_days <- 30L

# A stricter companion rule: a link supported only by a shared owner counts
# when the filings are within 60 m or filed within 30 days. Every hand-reviewed
# link meeting either condition was a companion; links beyond both are the
# mixed group. Production parents split where the remaining links no longer
# connect their filings.
pair_key <- function(a, b) paste(pmin(a, b), pmax(a, b))

owner_links <- read_parquet("../input/owner_proximity_links.parquet") |>
  transmute(sample, pair = pair_key(job_number_1, job_number_2), distance_metres, days_apart)
links <- read_parquet("../input/symmetric_parent_links.parquet") |>
  transmute(sample, job_number_1, job_number_2, link_reason,
    pair = pair_key(job_number_1, job_number_2)) |>
  left_join(owner_links, by = c("sample", "pair"), relationship = "one-to-one") |>
  mutate(owner_only = link_reason == "same_owner_nearby",
    beyond_strict = owner_only & distance_metres > strict_metres & days_apart > strict_days)
stopifnot(!anyNA(links$distance_metres[links$owner_only]))

membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  transmute(sample, job_number, root_job_id, parent_id, additive_component, date_filed)
stopifnot(!anyDuplicated(membership[c("sample", "job_number")]))

# Pieces are connected components of a parent's filings under the kept links.
# A piece of a split parent is named after its earliest filing.
assign_pieces <- function(kept_links) {
  graph <- graph_from_data_frame(
    kept_links |> transmute(from = paste(sample, job_number_1), to = paste(sample, job_number_2)),
    directed = FALSE,
    vertices = membership |> transmute(name = paste(sample, job_number)))
  membership |>
    mutate(component = components(graph)$membership[paste(sample, job_number)]) |>
    group_by(parent_id) |>
    mutate(split = n_distinct(component) > 1) |>
    group_by(parent_id, component) |>
    mutate(piece_id = if_else(split, paste0(parent_id, "__", job_number[which.min(date_filed)]), parent_id)) |>
    ungroup()
}

production_pieces <- assign_pieces(links)
strict_pieces <- assign_pieces(links |> filter(!beyond_strict))
stopifnot(!any(production_pieces$split))

# Outcomes are recomputed from constituent units. Each piece keeps its parent's
# site traits, exposure classification and composition eligibility: land,
# zoning and neighbourhood are fixed, so the check isolates the change in
# organization.
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  as_tibble() |>
  filter(included_ab, composition_eligible)
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |>
  filter(parent_id %in% parents$parent_id) |>
  select(sample, parent_id, root_job_id, constituent_units, address)

form_parents <- function(pieces) {
  additive <- pieces |> filter(additive_component) |> select(sample, parent_id, root_job_id, piece_id)
  stopifnot(!anyDuplicated(additive[c("sample", "parent_id", "root_job_id")]))
  constituents |>
    left_join(additive, by = c("sample", "parent_id", "root_job_id"), relationship = "one-to-one") |>
    group_by(sample, parent_id, piece_id) |>
    summarise(
      parent_total_units = sum(constituent_units),
      n_components = n(),
      exact_99x2 = n() == 2L && all(constituent_units == 99L),
      addresses = paste(address, collapse = "; "),
      .groups = "drop") |>
    mutate(multi_component = n_components > 1, three_plus = n_components >= 3) |>
    left_join(parents |> select(-sample, -parent_total_units, -n_components, -exact_99x2, -multi_component),
      by = "parent_id", relationship = "many-to-one")
}

production <- form_parents(production_pieces)
strict <- form_parents(strict_pieces)
panel_check <- production |>
  inner_join(parents, by = "parent_id", suffix = c("", "_panel"), relationship = "one-to-one")
stopifnot(
  nrow(panel_check) == nrow(parents),
  all(panel_check$parent_total_units == panel_check$parent_total_units_panel),
  all(panel_check$n_components == panel_check$n_components_panel),
  all(panel_check$exact_99x2 == panel_check$exact_99x2_panel)
)

summarise_rule <- function(data, rule) {
  data <- data |> filter(parent_total_units >= minimum_units)
  historical <- data |> filter(sample == "historical")
  post <- data |> filter(sample == "post_policy")
  historical <- calibrate_historical_to_target(historical, post)$historical
  weight <- historical$calibration_weight / sum(historical$calibration_weight)
  moments <- local_shape_moments(
    weighted_exact_distribution(historical, "parent_total_units", "calibration_weight",
      minimum_units, pooled_tail_start),
    weighted_exact_distribution(post |> mutate(observation_weight = 1), "parent_total_units",
      "observation_weight", minimum_units, pooled_tail_start),
    "Parent total")
  tibble(
    rule = rule,
    historical_parents = nrow(historical),
    post_parents = nrow(post),
    effective_sample_size = 1 / sum(weight^2),
    historical_share_exact_99 = sum(weight * (historical$parent_total_units == 99)),
    post_share_exact_99 = mean(post$parent_total_units == 99),
    post_exact_99_parents = sum(post$parent_total_units == 99),
    post_exact_99x2 = sum(post$exact_99x2),
    excess_at_99 = moments$estimate[moments$moment == "excess_at_99"],
    excess_at_198 = moments$estimate[moments$moment == "excess_at_198"],
    cumulative_deficit_100_149 = moments$estimate[moments$moment == "cumulative_deficit_100_149"],
    historical_share_multi_component = sum(weight * historical$multi_component),
    post_share_multi_component = mean(post$multi_component),
    historical_share_three_plus = sum(weight * historical$three_plus),
    post_share_three_plus = mean(post$three_plus)
  )
}

sensitivity <- bind_rows(
  summarise_rule(production, "production"),
  summarise_rule(strict, "strict_owner_links")
)

# The weighting-sample parents the stricter rule splits, one row per piece,
# including pieces below 50 units.
split_pieces <- strict |>
  filter(parent_id %in% production$parent_id[production$parent_total_units >= minimum_units],
    parent_id %in% strict_pieces$parent_id[strict_pieces$split]) |>
  select(sample, parent_id, piece_id, parent_total_units, n_components, addresses)

SaveData(sensitivity, "rule", "../output/strict_rule_sensitivity.csv")
SaveData(split_pieces, c("sample", "piece_id"), "../output/strict_rule_splits.csv")

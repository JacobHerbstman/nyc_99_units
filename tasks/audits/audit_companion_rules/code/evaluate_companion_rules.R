# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_companion_rules/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(purrr)
  library(sf)
  library(tidyr)
})
source("../../../shared/code/write_data_report.R")

identity <- read_parquet("../output/filing_identity.parquet") |>
  filter(!is.na(latitude), !is.na(longitude))

# Candidate pairs: filings in different current parents, same period, within
# 250 metres and 365 days. Placebo pairs 1-2 km apart measure how often the
# identity keys match by chance.
points <- identity |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE) |>
  st_transform(2263)

find_pairs <- function(data, low_metres, high_metres) {
  map_dfr(split(data, data$sample), function(group) {
    near <- st_is_within_distance(group, group, dist = high_metres / 0.3048)
    pairs <- tibble(i = rep(seq_along(near), lengths(near)), j = unlist(near)) |> filter(i < j)
    a <- st_drop_geometry(group)[pairs$i, ]
    b <- st_drop_geometry(group)[pairs$j, ]
    tibble(
      sample = a$sample, job_a = a$job_number, job_b = b$job_number,
      parent_a = a$parent_id, parent_b = b$parent_id,
      units_a = a$units, units_b = b$units,
      bbl_a = a$filing_bbl, bbl_b = b$filing_bbl,
      distance_metres = as.numeric(st_distance(group[pairs$i, ], group[pairs$j, ], by_element = TRUE)) * 0.3048,
      days_apart = abs(as.numeric(a$date_filed - b$date_filed)),
      first_date = pmin(a$date_filed, b$date_filed),
      same_block = coalesce(a$block == b$block, FALSE),
      same_business = coalesce(a$owner_key == b$owner_key, FALSE),
      same_person = coalesce(a$owner_person_key == b$owner_person_key, FALSE),
      same_applicant = coalesce(a$applicant_license == b$applicant_license, FALSE)
    ) |>
      filter(distance_metres >= low_metres, days_apart <= 365)
  })
}

pairs <- find_pairs(points, 0, 250) |>
  mutate(same_parent = parent_a == parent_b, cross_lot = coalesce(bbl_a != bbl_b, TRUE))
placebo <- find_pairs(points, 1000, 2000) |> filter(parent_a != parent_b)

# Independent confirmation: DOF recorded a lot merger, split or reconfiguration
# involving both filing lots within three years of the first filing.
dof_changes <- read_parquet("../input/dof_transaction_headers.parquet") |>
  transmute(transaction_id = TRANS_NUM, change_date = as.Date(Change_Date), change_type = Change_Type) |>
  distinct() |>
  filter(change_type %in% c("Lot Merger", "Lot Apportionment", "Lot Reconfiguration"))
lot_changes <- read_parquet("../input/dof_lot_actions.parquet") |>
  transmute(transaction_id = TRANS_NUM, bbl = BBL) |>
  distinct() |>
  inner_join(dof_changes, by = "transaction_id", relationship = "many-to-one") |>
  group_by(bbl) |>
  summarise(changes = list(tibble(transaction_id, change_date)), .groups = "drop")
pairs <- pairs |>
  left_join(lot_changes |> rename(changes_a = changes), by = c("bbl_a" = "bbl"), relationship = "many-to-one") |>
  left_join(lot_changes |> rename(changes_b = changes), by = c("bbl_b" = "bbl"), relationship = "many-to-one") |>
  mutate(dof_confirmed = coalesce(bbl_a == bbl_b, FALSE) | pmap_lgl(list(changes_a, changes_b, first_date), function(a, b, first) {
    if (is.null(a) || is.null(b)) return(FALSE)
    shared <- a |> filter(transaction_id %in% b$transaction_id)
    any(abs(as.numeric(shared$change_date - first)) <= 3 * 365)
  })) |>
  select(-changes_a, -changes_b)

source("rule_definitions.R")

# Chance matches: identity matches per filing in the 1-2 km ring, scaled to the
# area within the rule's distance. Same-block rules use a 100 m disc.
ring_area <- pi * (2000^2 - 1000^2)
filings_by_period <- identity |> count(sample, name = "filings")

rule_summary <- pmap_dfr(rules, function(identity_rule, space_rule, max_days) {
  radius <- if (space_rule == "same_block") 100 else space_rules[[space_rule]]
  linked <- pairs |> mutate(link = rule_links(pairs, identity_rule, space_rule, max_days))
  chance <- placebo |>
    mutate(match = eval(identity_rules[[identity_rule]], placebo) & days_apart <= max_days) |>
    group_by(sample) |> summarise(ring_matches = sum(match), .groups = "drop")
  linked |>
    group_by(sample) |>
    summarise(
      new_links = sum(link & !same_parent),
      new_parent_pairs = n_distinct(paste(parent_a, parent_b)[link & !same_parent]),
      new_links_dof_confirmed = sum(link & !same_parent & dof_confirmed),
      new_links_same_applicant = sum(link & !same_parent & same_applicant),
      existing_cross_lot_links = sum(same_parent & cross_lot),
      existing_cross_lot_found = sum(same_parent & cross_lot & link),
      .groups = "drop") |>
    left_join(chance, by = "sample") |>
    mutate(identity_rule, space_rule, max_days,
      expected_chance_links = ring_matches * pi * radius^2 / ring_area,
      .before = 1)
})

SaveData(pairs, c("sample", "job_a", "job_b"), "../output/candidate_pairs.parquet")
SaveData(rule_summary, c("identity_rule", "space_rule", "max_days", "sample"), "../output/rule_summary.csv")

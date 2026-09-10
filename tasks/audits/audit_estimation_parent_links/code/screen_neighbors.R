# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
# near_metres <- 200
# near_days <- 365
library(arrow)
library(dplyr)
library(readr)
args <- commandArgs(trailingOnly = TRUE)
if (interactive()) args <- c(as.character(near_metres), as.character(near_days))
stopifnot(length(args) == 2)
near_metres <- as.numeric(args[1])
near_days <- as.integer(args[2])
stopifnot(is.finite(near_metres), near_metres > 0, !is.na(near_days), near_days > 0)

parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  filter(included_ab, parent_total_units >= 50, composition_eligible)
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
hdb <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
historical <- read_parquet("../input/historical_parent_filing_link_fields.parquet")
stopifnot(!anyDuplicated(hdb$job_number), !anyDuplicated(dob$job_number),
  !anyDuplicated(membership[c("sample", "root_job_id")]), !anyDuplicated(historical$job_number))
pool <- bind_rows(
  hdb |> filter(job_type == "New Building", classaprop > 0) |>
    transmute(sample = "historical", root_job_id = job_number, date = as.Date(datefiled),
      address = paste(addressnum, addressst), units = classaprop, bbl = as.character(bbl),
      latitude = as.numeric(latitude), longitude = as.numeric(longitude), description = job_desc, owner = NA_character_, applicant = NA_character_),
  dob |> filter(proposed_dwelling_units > 0) |>
    transmute(sample = "post_policy", root_job_id = job_number, date = filing_date,
      address, units = proposed_dwelling_units, bbl = filing_bbl, latitude, longitude,
      description = job_description, owner = NA_character_,
      applicant = paste(applicant_first_name, applicant_last_name))) |>
  left_join(membership |> select(sample, root_job_id, parent_id, filing_role),
    by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  left_join(historical |> transmute(root_job_id = job_number, historical_owner = pluto_owner_name),
    by = "root_job_id", relationship = "many-to-one") |>
  left_join(dob |> transmute(root_job_id = job_number,
    dob_owner = toupper(trimws(paste(coalesce(owner_business_name, ""), coalesce(owner_first_name, ""), coalesce(owner_last_name, ""))))),
    by = "root_job_id", relationship = "many-to-one") |>
  mutate(dob_owner = if_else(dob_owner %in% c("", "PR", "PRIVATE", "NOT APPLICABLE"), NA_character_, dob_owner),
    owner = coalesce(dob_owner, historical_owner))
anchors <- membership |> semi_join(parents, by = "parent_id") |>
  select(sample, root_job_id, parent_id, additive_component) |>
  left_join(pool |> select(-parent_id), by = c("sample", "root_job_id"), relationship = "one-to-one")
stopifnot(!anyNA(anchors$date))

# Explicit spatial pair enumeration, not a join on nonunique geographic keys.
matches <- list()
for (i in seq_len(nrow(anchors))) {
  a <- anchors[i, ]
  candidates <- pool |> filter(sample == a$sample, root_job_id != a$root_job_id,
    is.na(parent_id) | parent_id != a$parent_id,
    abs(as.numeric(date - a$date)) <= near_days)
  # Local equirectangular distance; adequate for a 200 m screening radius in NYC.
  distance <- 6371000 * sqrt(((candidates$longitude - a$longitude) * pi / 180 *
    cos((candidates$latitude + a$latitude) / 2 * pi / 180))^2 +
    ((candidates$latitude - a$latitude) * pi / 180)^2)
  same_lot <- !is.na(candidates$bbl) & !is.na(a$bbl) & candidates$bbl == a$bbl
  keep <- same_lot | (!is.na(distance) & distance <= near_metres)
  if (!any(keep)) next
  candidates <- candidates[keep, ]
  matches[[length(matches) + 1]] <- candidates |>
    transmute(sample, neighbor_parent = parent_id, parent_id = a$parent_id, anchor_job = a$root_job_id,
      anchor_address = a$address, anchor_date = a$date, anchor_owner = a$owner,
      neighbor_job = root_job_id,
      neighbor_address = address, neighbor_date = date, neighbor_units = units,
      neighbor_owner = owner, neighbor_applicant = applicant, neighbor_description = description,
      neighbor_role = filing_role, distance_metres = round(distance[keep], 1),
      days_apart = abs(as.integer(date - a$date)), same_lot = same_lot[keep],
      same_owner = !is.na(owner) & !is.na(a$owner) & nzchar(owner) & owner == a$owner)
}
neighbors <- bind_rows(matches) |>
  arrange(sample, parent_id, neighbor_job, desc(same_lot), desc(same_owner), distance_metres, days_apart, anchor_job) |>
  group_by(sample, parent_id, neighbor_job) |> slice_head(n = 1) |> ungroup() |>
  arrange(sample, parent_id, neighbor_job)
stopifnot(!anyDuplicated(neighbors[c("sample", "parent_id", "neighbor_job")]))
# Preserve the original review records; remap retired anchors to current parents.
review <- read_csv("neighbor_evidence.csv", show_col_types = FALSE) |>
  rename(original_parent_id = parent_id) |>
  mutate(job_number = sub("^.*__", "", original_parent_id)) |>
  left_join(membership |> select(job_number, parent_id), by = "job_number", relationship = "many-to-one")
stopifnot(!anyNA(review$parent_id),
  !anyDuplicated(review[c("original_parent_id", "neighbor_job")]))
review <- review |> semi_join(neighbors, by = c("parent_id", "neighbor_job")) |>
  arrange(original_parent_id) |>
  group_by(parent_id, neighbor_job) |>
  summarise(across(c(review_decision, review_note),
    ~ paste(unique(.x), collapse = " | ")), .groups = "drop")
multi <- parents |> filter(n_components > 1)
neighbors <- neighbors |>
  left_join(review, by = c("parent_id", "neighbor_job"), relationship = "one-to-one") |>
  mutate(review_scope = if_else(parent_id %in% multi$parent_id,
    "Current multi-parent review", "Broader screen only"),
    review_decision = coalesce(review_decision, "Not individually adjudicated"))
decisions <- read_csv("../input/pair_decisions.csv", show_col_types = FALSE) |>
  filter(review_decision == "reject")
rejections <- bind_rows(
  decisions |> transmute(sample, job_number = job_number_1,
    neighbor_job = sub("-I1$", "", job_number_2), manual_note = review_basis),
  decisions |> transmute(sample, job_number = job_number_2,
    neighbor_job = sub("-I1$", "", job_number_1), manual_note = review_basis)) |>
  left_join(membership |> select(sample, job_number, parent_id),
    by = c("sample", "job_number"), relationship = "many-to-one") |>
  group_by(parent_id, neighbor_job) |>
  summarise(manual_note = paste(sort(unique(manual_note)), collapse = " | "), .groups = "drop")
stopifnot(!anyNA(rejections$parent_id), !anyDuplicated(rejections[c("parent_id", "neighbor_job")]))
neighbors <- neighbors |>
  left_join(rejections, by = c("parent_id", "neighbor_job"), relationship = "one-to-one") |>
  mutate(review_decision = if_else(!is.na(manual_note), "Rejected in manual source (see qualification)", review_decision),
    review_note = coalesce(manual_note, review_note)) |> select(-manual_note)
write_csv(neighbors, "../output/nearby_filings.csv", na = "")
cat("Estimation parents:", nrow(parents), "; anchor filings:", nrow(anchors),
  "; anchors missing coordinates:", sum(!complete.cases(anchors[c("latitude", "longitude")])),
  "; nearby parent-filing pairs:", nrow(neighbors), "\n")

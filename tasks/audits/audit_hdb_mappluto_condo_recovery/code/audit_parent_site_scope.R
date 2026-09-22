# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
library(sf)
library(stringr)
library(tidyr)
source("../../../shared/code/write_data_report.R")

parents <- read_csv("../output/dof_parent_coverage.csv", show_col_types = FALSE) |>
  filter(composition_eligible) |>
  rename(prior_unresolved = unresolved, dof_candidate_area_sqft = candidate_area_sqft)
panel <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  select(parent_id, cohort_date, parent_last_filing_date, n_components_eq_99, component_job_numbers)
# The linkage universes overlap in calendar time outside the canonical cohorts.
# Use canonical parents to identify membership; the broad filing search remains.
members <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  semi_join(panel, by = "parent_id")
# Historical members keep archived metadata. The broader search also includes
# later proposals and records omitted from the latest housing release.
hdb <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet")
hdb_old <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet")
historical_jobs <- members$root_job_id[members$sample == "historical"]
hdb <- bind_rows(hdb_old |> filter(job_number %in% historical_jobs),
  hdb |> filter(!job_number %in% historical_jobs),
  hdb_old |> filter(!job_number %in% historical_jobs) |> anti_join(hdb, by = "job_number"))
hdb_raw <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet")
hdb_raw_old <- read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet")
hdb_raw_old <- hdb_raw_old |> mutate(across(any_of(c("latitude", "longitude")), as.numeric))
hdb_raw <- bind_rows(
  hdb_raw_old |> filter(job_number %in% historical_jobs) |> select(job_number, job_desc, latitude, longitude),
  hdb_raw |> filter(!job_number %in% historical_jobs) |> select(job_number, job_desc, latitude, longitude),
  hdb_raw_old |> filter(!job_number %in% historical_jobs) |> anti_join(hdb_raw, by = "job_number") |>
    select(job_number, job_desc, latitude, longitude))
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
physical_events <- read_parquet("../output/dof_events.parquet") |>
  filter(reversible | change_type %in% c("Lot Merger", "Lot Apportionment", "Lot Reconfiguration",
    "Boundary Line", "Lot Number Change", "Block", "Digital Alteration Book", "Digital Alteration Book Wizard"))
events <- physical_events |> filter(reversible)
condos <- read_parquet("../output/dof_condo_links.parquet") |> filter(valid_bbl)
geometry <- read_csv("../output/dof_all_parent_geometry.csv", show_col_types = FALSE)
overlaps <- read_parquet("../output/dof_all_parent_overlaps.parquet") |> filter(material)
maps <- read_parquet("../output/dof_geometry_lots.parquet")
calendar <- read_csv("../input/mappluto_release_calendar.csv", show_col_types = FALSE) |>
  mutate(vintage = tolower(gsub(".", "_", vintage, fixed = TRUE)))
bis <- read_csv("../output/bis_filing_sites.csv", show_col_types = FALSE,
                col_types = cols(job_number = col_character()))
bis_parents <- read_csv("../output/bis_parent_site_comparison.csv", show_col_types = FALSE)
documents <- read_csv("parent_site_document_review.csv", show_col_types = FALSE,
  col_types = cols(reference_bbls = col_character(), development_bbls = col_character(),
    document_id = col_character(), reviewed_filing_bbls = col_character(), reviewed_hdb_bbls = col_character(),
    reviewed_retained_bbls = col_character(), reviewed_ancillary_jobs = col_character(),
    reviewed_physical_transactions = col_character(), reviewed_original_bbls = col_character(),
    reviewed_component_jobs = col_character()))
stopifnot(!anyDuplicated(documents$parent_id), !anyNA(documents$reviewed_component_jobs))
# Preserve each review's original scope. An archived source may change the
# parent membership or remove it from the current weighting sample.
document_coverage <- documents |> select(parent_id, reviewed_component_jobs, reference_vintage) |>
  left_join(panel |> select(parent_id, component_job_numbers),
    by = "parent_id", relationship = "one-to-one") |>
  left_join(parents |> select(parent_id, vintages), by = "parent_id", relationship = "one-to-one") |>
  mutate(applicability = case_when(
    is.na(component_job_numbers) ~ "Parent absent from current panel",
    is.na(vintages) ~ "Outside current weighting sample",
    !mapply(setequal, str_split(reviewed_component_jobs, ";"),
      str_split(component_job_numbers, ";")) ~ "Constituent membership changed",
    !mapply(function(vintage, choices) vintage %in% choices,
      reference_vintage, str_split(vintages, ";")) ~ "Reference vintage changed",
    TRUE ~ "Applicable"))
documents <- documents |> semi_join(document_coverage |> filter(applicability == "Applicable"),
  by = "parent_id")
reviewed_changes <- documents |>
  filter(!is.na(reviewed_physical_transactions)) |>
  select(parent_id, document_date, reviewed_physical_transactions) |>
  separate_longer_delim(reviewed_physical_transactions, ";") |>
  left_join(physical_events |> transmute(
    reviewed_physical_transactions = as.character(transaction_id), change_date),
    by = "reviewed_physical_transactions", relationship = "many-to-one")
stopifnot(!anyNA(reviewed_changes$change_date),
  all(reviewed_changes$document_date >= reviewed_changes$change_date))
membership_reviews <- read_csv("parent_site_membership_review.csv", show_col_types = FALSE,
  col_types = cols(job_number_1 = col_character(), job_number_2 = col_character()))
pending_membership <- membership_reviews |>
  filter(implementation_status != "implemented") |>
  select(job_number_1, job_number_2) |> pivot_longer(everything(), values_to = "job_number") |>
  distinct(job_number) |>
  left_join(members |> select(job_number, parent_id), by = "job_number", relationship = "one-to-one")
stopifnot(!anyNA(pending_membership$parent_id))
implemented_membership <- membership_reviews |>
  filter(implementation_status == "implemented") |>
  left_join(members |> select(job_number_1 = job_number, parent_1 = parent_id),
    by = "job_number_1", relationship = "many-to-one") |>
  left_join(members |> select(job_number_2 = job_number, parent_2 = parent_id),
    by = "job_number_2", relationship = "many-to-one")
stopifnot(all(implemented_membership$review_decision == "accept"),
  !anyNA(implemented_membership$parent_1), !anyNA(implemented_membership$parent_2),
  all(implemented_membership$parent_1 == implemented_membership$parent_2))
# Check each decision against its named archival vintage. The complete 2023
# table also recovers post-policy source parcels omitted by the polygon search.
reference_lots <- read_parquet("../input/dcp_mappluto_archive_23v3_1.parquet") |>
  transmute(vintage = "23v3_1", bbl, lotarea) |>
  bind_rows(maps |> filter(vintage != "23v3_1") |>
    transmute(vintage, bbl, lotarea = recorded_area_sqft))
document_reference <- documents |> select(parent_id, reference_vintage, reference_bbls) |>
  separate_longer_delim(reference_bbls, ";") |>
  left_join(reference_lots, by = c("reference_vintage" = "vintage", "reference_bbls" = "bbl"),
    relationship = "many-to-one") |>
  group_by(parent_id) |> summarise(checked_reference_area = sum(lotarea), .groups = "drop")
documents <- documents |>
  left_join(document_reference, by = "parent_id", relationship = "one-to-one") |>
  left_join(calendar |> select(reference_vintage = vintage, safe_available_date),
    by = "reference_vintage", relationship = "many-to-one") |>
  left_join(panel |> select(parent_id, cohort_date), by = "parent_id", relationship = "one-to-one")
# A reviewed multi-filing parent can use one common pre-first-filing vintage.
# It must be a constituent's original vintage, with every named parcel checked.
stopifnot(!anyDuplicated(documents$parent_id), all(documents$parent_id %in% parents$parent_id),
  all(mapply(function(vintage, vintages) vintage %in% strsplit(vintages, ";")[[1]],
    documents$reference_vintage, parents$vintages[match(documents$parent_id, parents$parent_id)])),
  all(documents$safe_available_date <= documents$cohort_date),
  all(!is.na(documents$checked_reference_area)),
  all(documents$checked_reference_area == documents$reference_recorded_area_sqft),
  all(documents$decision %in% c("complete_reference_parcel_supported",
    "recorded_development_boundary_supported")),
  all(!is.na(documents$development_area_sqft) & documents$development_area_sqft > 0))
stopifnot(nrow(parents) > 0, !anyDuplicated(parents$parent_id),
  !anyDuplicated(hdb$job_number), !anyDuplicated(hdb_raw$job_number), !anyDuplicated(dob$job_number),
  !anyDuplicated(members$job_number), !anyDuplicated(members$root_job_id), !anyNA(members$root_job_id))

# Search every saved New Building filing, including small residential projects
# and DOB NOW nonresidential jobs. HDB does not cover all legacy nonresidential
# jobs. Keep both source BBLs; dates and units retain HDB priority when present.
filings <- full_join(
  hdb |> filter(job_type == "New Building") |>
    transmute(job_number, hdb_release = release, hdb_bbl = bbl, hdb_date = date_filed,
      hdb_units = classa_prop, hdb_status = job_status, hdb_address = address,
      hdb_completed = date_completed, hdb_permit = date_permit),
  dob |> transmute(job_number, dob_bbl = filing_bbl, dob_date = filing_date,
    dob_units = proposed_dwelling_units, dob_status = filing_status,
    dob_address = address, dob_description = job_description,
    dob_latitude = latitude, dob_longitude = longitude,
    dob_completed = signoff_date, dob_permit = first_permit_date),
  by = "job_number", relationship = "one-to-one") |>
  left_join(hdb_raw |> transmute(job_number = as.character(job_number),
    hdb_description = job_desc, hdb_latitude = latitude, hdb_longitude = longitude),
    by = "job_number", relationship = "one-to-one") |>
  left_join(members |> select(job_number = root_job_id, filing_parent_id = parent_id, additive_component,
    filing_role, original_filing_date, replacement_job_number),
    by = "job_number", relationship = "one-to-one") |>
  mutate(archived_member = job_number %in% historical_jobs,
    filing_date = coalesce(original_filing_date, hdb_date, dob_date),
    completed_date = if_else(archived_member, hdb_completed, coalesce(hdb_completed, dob_completed)),
    permit_date = if_else(archived_member, hdb_permit, coalesce(hdb_permit, dob_permit)),
    units = coalesce(hdb_units, dob_units),
    status = if_else(archived_member, hdb_status, coalesce(dob_status, hdb_status)),
    address = coalesce(hdb_address, dob_address),
    description = if_else(archived_member, hdb_description, coalesce(dob_description, hdb_description)),
    latitude = if_else(archived_member, hdb_latitude, coalesce(hdb_latitude, dob_latitude)),
    longitude = if_else(archived_member, hdb_longitude, coalesce(hdb_longitude, dob_longitude)),
    inactive = coalesce(!additive_component, FALSE) |
      str_detect(str_to_upper(coalesce(status, "")), "WITHDRAW|CANCEL"),
    school_description = str_detect(str_to_upper(coalesce(description, "")), "SCHOOL|EDUCATION"),
    observed_nonresidential = !is.na(units) & units == 0)
stopifnot(!anyDuplicated(filings$job_number))

# Each lot carries a list of filings. This represents overlapping memberships
# explicitly rather than expanding a many-to-many filing join.
filing_lots <- filings |> select(job_number, hdb_bbl, dob_bbl) |>
  pivot_longer(-job_number, values_to = "bbl") |> filter(!is.na(bbl)) |>
  select(job_number, bbl) |> distinct() |>
  bind_rows(members |> transmute(job_number = root_job_id, bbl = filing_bbl)) |>
  filter(!is.na(bbl)) |> distinct()
condo_sets <- condos |> group_by(filing_bbl) |>
  summarise(base_bbls = list(sort(unique(base_bbl))), .groups = "drop")
filing_lots <- bind_rows(filing_lots,
  filing_lots |> inner_join(condo_sets, by = c("bbl" = "filing_bbl"), relationship = "many-to-one") |>
    select(job_number, base_bbls) |> unnest_longer(base_bbls, values_to = "bbl")) |> distinct()
lot_jobs <- filing_lots |> group_by(bbl) |> summarise(jobs = list(sort(unique(job_number))), .groups = "drop")
job_lookup <- setNames(lot_jobs$jobs, lot_jobs$bbl)

# Reconstruct the full transaction envelope, retaining the extra successor lots
# at partial splits. An envelope finds possible shared land; it does not allocate
# every ancestor parcel to the parent. Original/zoning lists add observed scope.
original_lots <- bis |> select(parent_id, block_bbl, original_lots, zoning_lots) |>
  pivot_longer(ends_with("_lots"), values_to = "text") |>
  mutate(lot = str_extract_all(coalesce(text, ""), "\\b[0-9]{5}\\b")) |>
  unnest_longer(lot) |> mutate(bbl = paste0(block_bbl, sprintf("%04d", as.integer(lot)))) |>
  distinct(parent_id, bbl)
reviewed_lots <- documents |> select(parent_id, reference_bbls, development_bbls) |>
  pivot_longer(-parent_id, values_to = "bbl") |> separate_longer_delim(bbl, ";") |>
  select(parent_id, bbl) |> distinct()
event_index <- events |> mutate(event_row = row_number()) |> select(event_row, all_bbls) |>
  unnest_longer(all_bbls, values_to = "bbl") |> group_by(bbl) |>
  summarise(rows = list(event_row), .groups = "drop")
event_lookup <- setNames(event_index$rows, event_index$bbl)
reference_dates <- geometry |> select(parent_id, vintage) |>
  left_join(calendar |> select(vintage, safe_available_date), by = "vintage", relationship = "many-to-one") |>
  group_by(parent_id) |> summarise(reference_date = min(safe_available_date), .groups = "drop")
parents <- parents |> left_join(panel, by = "parent_id", relationship = "one-to-one") |>
  left_join(reference_dates, by = "parent_id", relationship = "one-to-one")
stopifnot(!anyNA(parents$reference_date))

# A tabular reference release can lack polygons. Use a neighboring release only
# if every candidate lot is present, recorded areas agree with the reference,
# the map predates filing, and DOF records no intervening physical lot change.
missing_reference <- geometry |> filter(old_lots == 0, !mixed_vintages,
  mapped_lots == requested_lots) |>
  left_join(parents |> select(parent_id, reference_date, cohort_date, candidate_bbls,
    dof_candidate_area_sqft), by = "parent_id", relationship = "many-to-one")
reference_recovery <- list()
recovered_lots <- list()
for (i in seq_len(nrow(missing_reference))) {
  row <- missing_reference[i, ]
  bbls <- strsplit(row$candidate_bbls, ";")[[1]]
  available <- maps |> filter(bbl %in% bbls, vintage != "25v4") |> group_by(vintage) |>
    summarise(lots = n(), recorded_area = sum(recorded_area_sqft), .groups = "drop") |>
    left_join(calendar |> select(vintage, safe_available_date), by = "vintage", relationship = "many-to-one") |>
    filter(lots == length(bbls), safe_available_date <= row$cohort_date,
      abs(recorded_area - row$dof_candidate_area_sqft) <= 1) |>
    arrange(abs(as.integer(safe_available_date - row$reference_date)), safe_available_date)
  available$physical_changes <- vapply(available$safe_available_date, function(date) {
    sum(physical_events$change_date > min(date, row$reference_date) &
      physical_events$change_date <= max(date, row$reference_date) &
      vapply(physical_events$all_bbls, function(x) any(x %in% bbls), logical(1)))
  }, integer(1))
  selected <- available |> filter(physical_changes == 0) |> slice_head(n = 1)
  if (!nrow(selected)) next
  earlier <- maps |> filter(vintage == selected$vintage, bbl %in% bbls) |> st_as_sf(wkt = "wkt", crs = 2263)
  later <- maps |> filter(vintage == "25v4", bbl %in% strsplit(row$mapped_bbls, ";")[[1]]) |>
    st_as_sf(wkt = "wkt", crs = 2263)
  old_union <- st_union(earlier)
  new_union <- st_union(later)
  intersection <- sum(as.numeric(st_area(st_intersection(old_union, new_union))))
  old_outside <- 1 - intersection / as.numeric(st_area(old_union))
  new_outside <- 1 - intersection / as.numeric(st_area(new_union))
  reference_recovery[[i]] <- tibble(parent_id = row$parent_id,
    recovered_reference_vintage = selected$vintage, recovered_reference_date = selected$safe_available_date,
    recovered_reference_area = row$dof_candidate_area_sqft, recovered_reference_lots = length(bbls),
    recovered_reference_complete = new_outside <= 0.02,
    recovered_reference_whole = old_outside <= 0.02 & new_outside <= 0.02,
    recovered_old_outside_share = old_outside, recovered_new_outside_share = new_outside,
    wkt = st_as_text(old_union, digits = 17))
  recovered_lots[[i]] <- tibble(parent_id = row$parent_id, vintage = row$vintage, bbl = bbls)
}
reference_recovery <- bind_rows(reference_recovery)
recovered_lots <- bind_rows(recovered_lots)

envelopes <- vector("list", nrow(parents))
site_lot_rows <- vector("list", nrow(parents))
for (i in seq_len(nrow(parents))) {
  id <- parents$parent_id[i]
  seed <- unique(c(strsplit(parents$filing_bbls[i], ";")[[1]],
    strsplit(parents$hdb_bbls[i], ";")[[1]],
    strsplit(parents$candidate_bbls[i], ";")[[1]],
    overlaps$bbl[overlaps$parent_id == id], original_lots$bbl[original_lots$parent_id == id],
    reviewed_lots$bbl[reviewed_lots$parent_id == id]))
  seed <- seed[!is.na(seed)]
  bases <- condos$base_bbl[condos$filing_bbl %in% seed]
  bbls <- union(seed, bases)
  repeat {
    rows <- sort(unique(unlist(event_lookup[bbls])))
    rows <- rows[events$change_date[rows] > parents$reference_date[i]]
    expanded <- union(bbls, unlist(events$all_bbls[rows]))
    if (setequal(expanded, bbls)) break
    bbls <- expanded
  }
  envelopes[[i]] <- tibble(parent_id = id, envelope_lots = length(bbls),
    transactions = paste(events$transaction_id[rows], collapse = ";"),
    first_change = if (length(rows)) min(events$change_date[rows]) else as.Date(NA),
    last_change = if (length(rows)) max(events$change_date[rows]) else as.Date(NA))
  site_lot_rows[[i]] <- tibble(parent_id = id, bbl = sort(bbls), direct_site_evidence = bbl %in% seed)
}
envelopes <- bind_rows(envelopes)
site_lots <- bind_rows(site_lot_rows)

# Exact lot/condominium links and locations in earlier polygons are separate
# evidence. A future lot number can differ even though its filing point occupies
# the same earlier land. Spatial points locate filings, not building boundaries.
lot_matches <- site_lots |> mutate(jobs = unname(job_lookup[bbl])) |>
  unnest_longer(jobs, values_to = "job_number") |>
  group_by(parent_id, job_number) |> summarise(
    matched_bbls = paste(sort(bbl), collapse = ";"), direct_lot_match = any(direct_site_evidence),
    .groups = "drop")
old_sites <- overlaps |> select(parent_id, vintage, bbl) |>
  left_join(maps |> select(vintage, bbl, wkt), by = c("vintage", "bbl"), relationship = "many-to-one") |>
  st_as_sf(wkt = "wkt", crs = 2263) |> group_by(parent_id) |> summarise(.groups = "drop")
old_sites <- bind_rows(old_sites, reference_recovery |> select(parent_id, wkt) |> st_as_sf(wkt = "wkt", crs = 2263))
stopifnot(!anyDuplicated(old_sites$parent_id))
points <- filings |> filter(!is.na(latitude), !is.na(longitude),
  between(latitude, 40, 42), between(longitude, -75, -73)) |>
  select(job_number, latitude, longitude) |> st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
  st_transform(2263)
hits <- st_intersects(old_sites, points)
point_matches <- tibble(parent_id = old_sites$parent_id, point_rows = unclass(hits)) |>
  unnest_longer(point_rows) |> transmute(parent_id, job_number = points$job_number[point_rows], point_in_earlier_land = TRUE)

# A transaction can include neighboring developments. When another parent has
# complete mapped parcels, check its entire later footprint, not just its point.
later_lots <- geometry |> filter(mapped_lots == requested_lots) |>
  select(parent_id, mapped_bbls) |> distinct() |> separate_longer_delim(mapped_bbls, ";") |>
  rename(bbl = mapped_bbls) |>
  left_join(maps |> filter(vintage == "25v4") |> select(bbl, wkt), by = "bbl", relationship = "many-to-one") |>
  st_as_sf(wkt = "wkt", crs = 2263) |> group_by(parent_id) |> summarise(.groups = "drop")
intersections <- st_intersection(st_geometry(old_sites), st_geometry(later_lots))
indices <- attr(intersections, "idx")
parent_overlap <- tibble(parent_id = old_sites$parent_id[indices[, 1]],
  filing_parent_id = later_lots$parent_id[indices[, 2]],
  other_parent_overlap_sqft = as.numeric(st_area(intersections)))
stopifnot(!anyDuplicated(parent_overlap[c("parent_id", "filing_parent_id")]))
matches <- full_join(lot_matches, point_matches, by = c("parent_id", "job_number"), relationship = "one-to-one") |>
  left_join(filings |> select(job_number, filing_parent_id, filing_date, units, status, address,
    archived_member, hdb_release,
    completed_date, permit_date, inactive, observed_nonresidential, school_description, description),
    by = "job_number", relationship = "many-to-one") |>
  left_join(parents |> select(parent_id, reference_date, cohort_date), by = "parent_id", relationship = "many-to-one") |>
  left_join(parent_overlap, by = c("parent_id", "filing_parent_id"), relationship = "many-to-one") |>
  mutate(direct_lot_match = coalesce(direct_lot_match, FALSE),
    point_in_earlier_land = coalesce(point_in_earlier_land, FALSE),
    own_parent = coalesce(parent_id == filing_parent_id, FALSE),
    after_reference = !is.na(filing_date) & filing_date >= reference_date,
    earlier_construction = coalesce(filing_date < reference_date &
      (completed_date >= reference_date | (is.na(completed_date) & permit_date <= reference_date)), FALSE),
    mapped_other_parent_separate = filing_parent_id %in% later_lots$parent_id &
      parent_id %in% old_sites$parent_id & coalesce(other_parent_overlap_sqft, 0) <= 1,
    other_live_filing = !own_parent & !inactive & (after_reference | earlier_construction) &
      !(mapped_other_parent_separate & !direct_lot_match),
    evidence = case_when(direct_lot_match ~ "Recorded or earlier overlapping lot",
      point_in_earlier_land ~ "Filing point in earlier parcel union", TRUE ~ "DOF transaction envelope only")) |>
  arrange(parent_id, filing_date, job_number)

# Earlier filings can describe alternative plans or buildings already captured
# in the reference map. Keep their source status and historical observation;
# this review only settles land overlap for the saved components and vintage.
filing_reviews <- read_csv("parent_site_filing_review.csv", show_col_types = FALSE,
  col_types = cols(other_job_number = col_character())) |>
  left_join(panel |> select(parent_id, component_job_numbers),
    by = "parent_id", relationship = "many-to-one") |>
  left_join(parents |> select(parent_id, vintages),
    by = "parent_id", relationship = "many-to-one") |>
  mutate(filing_review_applicable = !is.na(component_job_numbers) & !is.na(vintages) &
    mapply(setequal, str_split(expected_component_jobs, ";"), str_split(component_job_numbers, ";")) &
    mapply(setequal, str_split(reference_vintages, ";"), str_split(vintages, ";")))
stopifnot(!anyDuplicated(filing_reviews[c("parent_id", "other_job_number")]),
  all(filing_reviews$decision %in% c("same_ground_alternative", "preexisting_building_in_reference")))
matches <- matches |>
  left_join(filing_reviews |> transmute(parent_id, job_number = other_job_number,
    filing_review_applicable, filing_review_decision = decision,
    filing_review_source = source_url, filing_review_basis = review_basis),
    by = c("parent_id", "job_number"), relationship = "one-to-one") |>
  mutate(documented_alternative_plan = coalesce(filing_review_applicable &
    filing_review_decision == "same_ground_alternative", FALSE),
    documented_prior_building = coalesce(filing_review_applicable &
      filing_review_decision == "preexisting_building_in_reference", FALSE))

# A recorded partition can place another filing entirely on retained land.
# Preserve that filing in the evidence table; exclude it from scope conflicts
# only when every matched lot is in the explicitly reviewed retained-lot list.
matches <- matches |>
  left_join(documents |> select(parent_id, reviewed_retained_bbls, reviewed_ancillary_jobs),
    by = "parent_id", relationship = "many-to-one") |>
  mutate(documented_separate_site = !own_parent & !is.na(reviewed_retained_bbls) &
    mapply(function(lots, retained) all(strsplit(coalesce(lots, ""), ";")[[1]] %in%
      strsplit(coalesce(retained, ""), ";")[[1]]) & !is.na(lots), matched_bbls, reviewed_retained_bbls),
    documented_ancillary_filing = observed_nonresidential & !is.na(reviewed_ancillary_jobs) &
      mapply(function(job, jobs) job %in% strsplit(coalesce(jobs, ""), ";")[[1]],
        job_number, reviewed_ancillary_jobs),
    site_scope_conflict = other_live_filing & !documented_separate_site &
      !documented_ancillary_filing & !documented_alternative_plan & !documented_prior_building)

# Overlapping reference parcels flag allocation between estimation parents even
# when an older component was filed before the other parent's reference date.
shared_lots <- bind_rows(overlaps |> select(parent_id, vintage, bbl), recovered_lots) |> distinct() |>
  group_by(vintage, bbl) |> mutate(parents_on_old_lot = n_distinct(parent_id)) |> ungroup() |>
  group_by(parent_id) |> summarise(shared_earlier_lots = sum(parents_on_old_lot > 1), .groups = "drop")
companions <- matches |> group_by(parent_id) |> summarise(
  other_direct_filings = sum(site_scope_conflict & (direct_lot_match | point_in_earlier_land)),
  other_envelope_filings = sum(site_scope_conflict & !direct_lot_match & !point_in_earlier_land),
  other_estimation_parents = n_distinct(filing_parent_id[site_scope_conflict & filing_parent_id %in% parents$parent_id]),
  other_nonresidential_filings = sum(site_scope_conflict & observed_nonresidential),
  other_school_descriptions = sum(site_scope_conflict & school_description),
  documented_separate_filings = sum(other_live_filing & documented_separate_site),
  documented_alternative_plans = sum(other_live_filing & documented_alternative_plan),
  documented_prior_buildings = sum(other_live_filing & documented_prior_building),
  other_job_numbers = paste(sort(job_number[site_scope_conflict]), collapse = ";"), .groups = "drop")
bis_scope <- bis |> group_by(parent_id) |> summarise(bis_filings = n(),
  shared_zoning_site = any(parents_sharing_zoning_list > 1, na.rm = TRUE), .groups = "drop")
geometry_scope <- geometry |> group_by(parent_id) |> summarise(
  mapped_later_complete = all(mapped_lots == requested_lots),
  earlier_map_complete = all(earlier_coverage_share >= 0.98 & !is.na(earlier_coverage_share)),
  whole_earlier_parcels = all(geometry_pattern == "Whole earlier parcels align"),
  old_area_sqft = if (n() == 1L) first(old_recorded_sqft) else NA_real_,
  old_lots = if (n() == 1L) first(old_lots) else NA_integer_,
  mapped_earlier_bbls = if (n() == 1L) first(old_bbls) else NA_character_,
  earlier_outside_share = max(old_outside_share),
  later_outside_share = max(later_uncovered_share), .groups = "drop") |>
  left_join(reference_recovery |> select(-wkt), by = "parent_id", relationship = "one-to-one") |>
  mutate(earlier_map_complete = coalesce(recovered_reference_complete, earlier_map_complete),
    whole_earlier_parcels = coalesce(recovered_reference_whole, whole_earlier_parcels),
    old_area_sqft = coalesce(recovered_reference_area, old_area_sqft),
    old_lots = coalesce(recovered_reference_lots, old_lots),
    earlier_outside_share = coalesce(recovered_old_outside_share, earlier_outside_share),
    later_outside_share = coalesce(recovered_new_outside_share, later_outside_share))
review <- parents |>
  left_join(geometry_scope, by = "parent_id", relationship = "one-to-one") |>
  left_join(envelopes, by = "parent_id", relationship = "one-to-one") |>
  left_join(companions, by = "parent_id", relationship = "one-to-one") |>
  left_join(shared_lots, by = "parent_id", relationship = "one-to-one") |>
  left_join(bis_scope, by = "parent_id", relationship = "one-to-one") |>
  left_join(bis_parents |> select(parent_id, original_bbls, original_recorded_sqft,
    original_lots_match_spatial_lots), by = "parent_id", relationship = "one-to-one") |>
  left_join(document_coverage |> select(parent_id, document_applicability = applicability),
    by = "parent_id", relationship = "one-to-one") |>
  left_join(documents |> transmute(parent_id, document_id, document_decision = decision,
    documented_area_basis = area_basis, reviewed_filing_bbls, reviewed_hdb_bbls,
    reviewed_physical_transactions, reviewed_original_bbls,
    documented_development_bbls = development_bbls,
    documented_development_area_sqft = development_area_sqft,
    documented_reference_bbls = reference_bbls,
    documented_reference_vintage = reference_vintage,
    documented_reference_area_sqft = reference_recorded_area_sqft),
    by = "parent_id", relationship = "one-to-one") |>
  mutate(across(c(other_direct_filings, other_envelope_filings, other_estimation_parents,
    other_nonresidential_filings, other_school_descriptions, shared_earlier_lots, bis_filings), ~coalesce(.x, 0L)),
    shared_zoning_site = coalesce(shared_zoning_site, FALSE),
    # Clear a reviewed original-lot mismatch only for its exact saved lot list.
    # The raw lot list and spatial comparison remain in the output.
    documented_original_crosswalk = coalesce(
      reviewed_original_bbls == original_bbls, FALSE),
    recorded_site_disagrees = bis_filings > 0 & !is.na(original_bbls) &
      coalesce(!original_lots_match_spatial_lots, FALSE) & !documented_original_crosswalk,
    shared_land = shared_earlier_lots > 0 | other_direct_filings > 0 | shared_zoning_site,
    broader_transaction_site = other_envelope_filings > 0,
    documented_source_crosswalk = coalesce(!is.na(document_id) &
      reviewed_filing_bbls == filing_bbls & reviewed_hdb_bbls == hdb_bbls, FALSE),
    # An explicitly reviewed source crosswalk can also distinguish a filed
    # development from the wider condominium named by its administrative BBL.
    # Clear only the exact physical transactions covered by the source review.
    documented_physical_changes = !is.na(reviewed_physical_transactions) &
      mapply(setequal, str_split(unusual_transactions, ";"),
        str_split(reviewed_physical_transactions, ";")),
    source_scope_question = coalesce(document_applicability != "Applicable", FALSE) |
      (mixed_vintages & is.na(documented_reference_vintage)) |
      (unusual_change & !documented_physical_changes) |
      ((condo_scope_review | source_bbl_disagreement) & !documented_source_crosswalk),
    membership_review_pending = parent_id %in% pending_membership$parent_id,
    # Complete successor sets preserve the whole earlier site. Require all
    # filing lots in DOF, fully reversed transactions, and the same old lot set
    # in the reference geometry. Partial splits cannot pass this rule.
    dof_complete_successors = !mapped_later_complete & !partial_change & !source_scope_question &
      unmapped_filing_lots == 0 & unmatched_lots == 0 & !is.na(applied_transactions) &
      coalesce(mapped_earlier_bbls == candidate_bbls & old_area_sqft == dof_candidate_area_sqft, FALSE),
    # Recorded boundaries can cover whole archival parcels or allocate part of
    # one. Their area basis is explicit; shared-land and filing flags remain.
    documented_whole_site = coalesce(document_decision == "complete_reference_parcel_supported", FALSE),
    documented_allocation = coalesce(document_decision == "recorded_development_boundary_supported", FALSE),
    reference_coverage_supported = (earlier_map_complete & !is.na(old_area_sqft)) |
      documented_whole_site | documented_allocation,
    boundary_reconstructed = mapped_later_complete | dof_complete_successors | documented_whole_site | documented_allocation,
    whole_site_supported = whole_earlier_parcels | dof_complete_successors | documented_whole_site | documented_allocation,
    boundary_basis = case_when(documented_allocation ~ "Recorded development boundary",
      documented_whole_site ~ "Recorded complete-site diagram",
      dof_complete_successors ~ "Complete DOF successor set", TRUE ~ "Parcel map comparison"),
    unresolved = !boundary_reconstructed | !reference_coverage_supported | !whole_site_supported |
      shared_land | broader_transaction_site | recorded_site_disagrees | source_scope_question |
      membership_review_pending,
    status = case_when(
      !boundary_reconstructed ~ "Missing later parcel map",
      !reference_coverage_supported ~ "Incomplete earlier map or area",
      shared_land ~ "Shared earlier land or other filing",
      broader_transaction_site ~ "Other filing in transaction envelope",
      recorded_site_disagrees ~ "Filing lot list differs from mapped site",
      source_scope_question ~ "Source or reference-date disagreement",
      membership_review_pending ~ "Parent membership review or implementation pending",
      !whole_site_supported ~ "Partial earlier parcels require allocation",
      TRUE ~ "Supported by available parcel and filing checks"),
    candidate_area_sqft = if_else(!unresolved,
      coalesce(documented_development_area_sqft, old_area_sqft), NA_real_),
    candidate_area_change_pct = 100 * (candidate_area_sqft / lot_area_sqft - 1)) |>
  arrange(sample, parent_id)
stopifnot(nrow(review) == nrow(parents), !anyDuplicated(review$parent_id),
  all(!is.na(review$unresolved)), !anyDuplicated(matches[c("parent_id", "job_number")]),
  setequal(matches$parent_id[matches$own_parent], parents$parent_id))
summary <- review |> group_by(sample, prior_unresolved, unresolved, status) |>
  summarise(parents = n(), parent_units = sum(parent_total_units),
    exact_99_parents = sum(n_components_eq_99 > 0), .groups = "drop")
stopifnot(sum(summary$parents) == nrow(parents))
SaveData(site_lots, c("parent_id", "bbl"), "../output/parent_site_lot_envelopes.parquet")
SaveData(matches, c("parent_id", "job_number"), "../output/parent_site_other_filings.csv")
SaveData(review, "parent_id", "../output/parent_site_scope.csv")
SaveData(summary, c("sample", "prior_unresolved", "unresolved", "status"), "../output/parent_site_scope_summary.csv")
SaveData(document_coverage, "parent_id", "../output/parent_site_document_coverage.csv")
print(summary, n = Inf, width = Inf)

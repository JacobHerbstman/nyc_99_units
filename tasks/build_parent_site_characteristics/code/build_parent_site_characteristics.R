# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/build_parent_site_characteristics/code")
# sample_name <- "historical"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  sample_name <- args[1]
}
stopifnot(sample_name %in% c("historical", "post_policy"))

# Pre-existing parcel characteristics of each parent's site: land area, FARs,
# existing building floor, borough and community district. Proposed units are
# carried only as the parent outcome.
collapse_category <- function(x, mixed = "Mixed") {
  values <- sort(unique(x[!is.na(x) & x != ""]))
  if (length(values) == 0L) "missing" else if (length(values) == 1L) values else mixed
}
boroughs <- c(`1` = "Manhattan", `2` = "Bronx", `3` = "Brooklyn", `4` = "Queens", `5` = "Staten Island")
lot_fields <- function(lots) {
  lots |>
    mutate(broad_zoning_far = pmax(residfar, commfar, facilfar, maxallwfar, na.rm = TRUE),
      # MapPLUTO codes a lot outside any community district as 0.
      community_district = na_if(as.character(as.integer(cd)), "0"))
}
# FARs are land-weighted over the lots that report them.
area_weighted <- function(far, lotarea) {
  area <- sum(lotarea[!is.na(far)])
  if (!is.na(area) && area > 0) sum(lotarea * far, na.rm = TRUE) / area else NA_real_
}
read_release <- function(release, bbls) {
  read_parquet(paste0("../input/", sanitize_file_stub(paste("dcp_mappluto_archive", release)), ".parquet"),
    col_select = c(bbl, lotarea, lotfront, bldgarea, residfar, commfar, facilfar, maxallwfar, builtfar, borough, cd)) |>
    filter(bbl %in% bbls) |>
    mutate(borough = unname(boroughs[as.character(borough)])) |>
    lot_fields()
}

membership <- read_parquet("../input/symmetric_parent_membership.parquet") |> filter(sample == sample_name)
stopifnot(nrow(membership) > 0L, !anyDuplicated(membership$job_number))

# Each filing's lot: historically the filing's own pre-filing release; after
# the policy, the fixed 2023 map (23v3.1), before the policy could change sites.
if (sample_name == "historical") {
  site_panel <- read_parquet("../input/historical_hdb_mappluto_site_panel.parquet")
  stopifnot(all(membership$job_number %in% site_panel$job_number))
  members <- membership |>
    left_join(site_panel |> transmute(job_number, feature_bbl = normalize_bbl_field(pluto_feature_bbl),
        hdb_bin = na_if(str_squish(bin), ""), lotarea, residfar, commfar, facilfar, maxallwfar, builtfar,
        borough = hdb_borough_name, cd = pluto_cd, reference_source_id = pluto_source_id_used,
        reference_version = pluto_version_used, reference_date = pluto_safe_available_date_used),
      by = "job_number", relationship = "one-to-one") |>
    lot_fields() |>
    mutate(feature_method = if_else(is.na(feature_bbl), "missing_lagged_mappluto", "filing_specific_lagged_mappluto"))
  stopifnot(!any(members$lotarea <= 0, na.rm = TRUE))
} else {
  site_panel <- read_parquet("../input/hdb_mappluto_site_panel.parquet")
  fixed_lots <- read_release("23v3.1", unique(c(site_panel$pluto_feature_bbl, membership$filing_bbl)))
  stopifnot(!anyDuplicated(fixed_lots$bbl))
  members <- membership |>
    left_join(site_panel |> transmute(root_job_id = job_number, hdb_feature_bbl = normalize_bbl_field(pluto_feature_bbl),
      hdb_bin = na_if(str_squish(bin), "")), by = "root_job_id", relationship = "many-to-one") |>
    mutate(feature_bbl = case_when(hdb_feature_bbl %in% fixed_lots$bbl ~ hdb_feature_bbl,
        filing_bbl %in% fixed_lots$bbl ~ filing_bbl),
      feature_method = case_when(!is.na(feature_bbl) & feature_bbl == hdb_feature_bbl ~ "hdb_feature_bbl_fixed_23v3_1",
        !is.na(feature_bbl) ~ "filing_bbl_fixed_23v3_1", TRUE ~ "unmatched_fixed_23v3_1")) |>
    left_join(fixed_lots |> select(-bldgarea) |> rename(feature_bbl = bbl), by = "feature_bbl",
      relationship = "many-to-one") |>
    mutate(reference_source_id = "dcp_mappluto_archive", reference_version = "23v3.1",
      reference_date = as.Date("2023-12-28"))
}

# Building identifiers: the archived HDB BIN historically; after the policy the
# DOB BIN, falling back to HDB.
dob_bins <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(root_job_id = job_number, dob_bin = na_if(str_squish(bin), ""))
stopifnot(!anyDuplicated(dob_bins$root_job_id))
members <- members |>
  left_join(dob_bins, by = "root_job_id", relationship = "many-to-one") |>
  mutate(bin = if (sample_name == "historical") hdb_bin else coalesce(dob_bin, hdb_bin))
stopifnot(nrow(members) == nrow(membership))

parents <- members |>
  arrange(parent_id, date_filed, job_number) |>
  group_by(sample, parent_id) |>
  summarise(cohort_date = first(cohort_date), units = sum(units[additive_component]),
    component_filings = sum(additive_component), component_jobs = paste(job_number[additive_component], collapse = ";"),
    duplicate_bin_rows = pmax(sum(!is.na(bin) & additive_component) -
      n_distinct(bin[!is.na(bin) & additive_component]), 0L),
    distinct_valid_dob_bins = n_distinct(dob_bin[additive_component & !is.na(dob_bin) &
      str_detect(dob_bin, "^[1-5][0-9]{6}$")]),
    feature_complete = all(!is.na(feature_bbl) & !is.na(lotarea) & lotarea > 0),
    feature_methods = paste(sort(unique(feature_method)), collapse = ";"), .groups = "drop")

# One row per distinct lot of a parent.
site_lots <- members |>
  filter(!is.na(feature_bbl)) |>
  arrange(parent_id, date_filed, job_number) |>
  distinct(sample, parent_id, feature_bbl, .keep_all = TRUE) |>
  mutate(feature_lots = 1L)

# Lots merged soon after filing. Developers often file under the one lot that
# survives a merger DOF records months later, so the reference map shows only
# that lot. Lots DOF merged into a filing lot after its reference map and no
# more than 180 days after the parent's first filing are added, in both
# periods; later mergers are ignored, so recent parents with less follow-up are
# measured the same way. Only mergers with one surviving lot count, and only
# for citywide MapPLUTO reference releases (2018 onward).
merger_window_days <- 180L
dof_snapshot_date <- as.Date("2026-09-15")
dof_changes <- read_parquet("../input/dof_transaction_headers.parquet") |>
  transmute(transaction_id = TRANS_NUM, change_date = as.Date(Change_Date), change_type = Change_Type) |>
  distinct()
stopifnot(!anyDuplicated(dof_changes$transaction_id))
dof_mergers <- read_parquet("../input/dof_lot_actions.parquet") |>
  transmute(transaction_id = TRANS_NUM, bbl = BBL, action = Lot_Action) |>
  distinct() |>
  inner_join(dof_changes |> filter(change_type == "Lot Merger"), by = "transaction_id", relationship = "many-to-one") |>
  group_by(transaction_id, change_date) |>
  filter(sum(action %in% c("Affected", "New")) == 1L, any(action == "Dropped")) |>
  summarise(surviving_bbl = bbl[action %in% c("Affected", "New")], merged_bbl = list(bbl[action == "Dropped"]),
    .groups = "drop") |>
  group_by(surviving_bbl) |>
  summarise(mergers = list(tibble(change_date, merged_bbl)), .groups = "drop")
merged_lots <- site_lots |>
  filter(reference_source_id == "dcp_mappluto_archive") |>
  select(sample, parent_id, feature_bbl, reference_version, reference_date, cohort_date) |>
  inner_join(dof_mergers, by = c("feature_bbl" = "surviving_bbl"), relationship = "many-to-one") |>
  unnest(mergers) |>
  filter(change_date > as.Date(reference_date), change_date <= as.Date(cohort_date) + merger_window_days) |>
  unnest_longer(merged_bbl) |>
  distinct(sample, parent_id, reference_version, merged_bbl) |>
  anti_join(site_lots |> select(parent_id, merged_bbl = feature_bbl), by = c("parent_id", "merged_bbl"))
# A merged lot missing from the reference release adds no land.
merged_lots <- bind_rows(lapply(unique(merged_lots$reference_version), function(version) {
  merged_lots |>
    filter(reference_version == version) |>
    inner_join(read_release(version, merged_lots$merged_bbl[merged_lots$reference_version == version]) |>
      select(-bldgarea), by = c("merged_bbl" = "bbl"), relationship = "many-to-one")
})) |>
  filter(lotarea > 0) |>
  transmute(sample, parent_id, feature_bbl = merged_bbl, lotarea, residfar, broad_zoning_far, builtfar, borough,
    community_district, feature_lots = 1L)
stopifnot(!anyDuplicated(merged_lots[c("parent_id", "feature_bbl")]))
site_lots <- bind_rows(site_lots, merged_lots)
parents <- parents |>
  left_join(count(merged_lots, parent_id, name = "merged_lots_added"), by = "parent_id", relationship = "one-to-one") |>
  mutate(merged_lots_added = coalesce(merged_lots_added, 0L),
    merger_window_complete = as.Date(cohort_date) + merger_window_days <= dof_snapshot_date)

# Starting lots: the tax lots the site occupied before its own mergers and
# subdivisions. From the lots of the parent's buildings at filing (the lagged
# match historically; after the policy the DOB filing lot, which a recent
# subdivision may have created), each DOF merger or subdivision from two years
# before the first filing to 180 days after it is undone once, newest first: a
# merger into a site lot adds the lots it absorbed, and a subdivision replaces
# the lots it created with the lot they came from. The window is the same in
# both periods, relative to the first filing.
starting_window_days <- 730L
lot_transactions <- read_parquet("../input/dof_lot_actions.parquet") |>
  transmute(transaction_id = TRANS_NUM, bbl = BBL, action = Lot_Action) |>
  distinct() |>
  inner_join(dof_changes |> filter(change_type %in% c("Lot Merger", "Lot Apportionment")), by = "transaction_id",
    relationship = "many-to-one") |>
  group_by(transaction_id, change_date, change_type) |>
  summarise(blocks = list(unique(str_sub(bbl, 1, 6))), original = list(bbl[action %in% c("Affected", "Dropped")]),
    created = list(bbl[action == "New"]), surviving = list(bbl[action %in% c("Affected", "New")]),
    absorbed = list(bbl[action == "Dropped"]), .groups = "drop")
transactions_by_block <- lot_transactions |> unnest_longer(blocks) |> split(~blocks)
starting_lot_set <- function(lots, first_filing) {
  blocks <- intersect(unique(str_sub(lots, 1, 6)), names(transactions_by_block))
  if (length(blocks) == 0L) return(lots)
  window <- bind_rows(transactions_by_block[blocks]) |>
    distinct(transaction_id, .keep_all = TRUE) |>
    filter(change_date >= first_filing - starting_window_days, change_date <= first_filing + merger_window_days) |>
    arrange(desc(change_date), desc(transaction_id))
  for (i in seq_len(nrow(window))) {
    if (window$change_type[i] == "Lot Merger" && any(window$surviving[[i]] %in% lots)) {
      lots <- union(lots, window$absorbed[[i]])
    }
    if (window$change_type[i] == "Lot Apportionment" && any(window$created[[i]] %in% lots) &&
        length(window$original[[i]]) > 0L) {
      lots <- union(setdiff(lots, window$created[[i]]), window$original[[i]])
    }
  }
  lots
}
parent_lots <- members |>
  filter(additive_component) |>
  arrange(parent_id, date_filed, job_number) |>
  mutate(lot = if (sample_name == "historical") coalesce(feature_bbl, filing_bbl) else
    coalesce(filing_bbl, feature_bbl)) |>
  filter(!is.na(lot)) |>
  group_by(parent_id) |>
  summarise(first_filing = as.Date(first(cohort_date)), lots = list(unique(lot)),
    record_lots = list(unique(na.omit(c(feature_bbl, filing_bbl)))),
    reference = if_else(is.na(first(reference_version)), NA_character_,
      sanitize_file_stub(paste(first(reference_source_id), first(reference_version)))), .groups = "drop") |>
  rowwise() |>
  mutate(starting_set = list(starting_lot_set(lots, first_filing))) |>
  ungroup()
starting_lots <- parent_lots |> transmute(parent_id, starting_lots = lengths(starting_set))

# The whole site from its recorded zoning lot. A zoning lot description (ACRIS
# ZONE) lists every tax lot a development's zoning lot combines. One listing a
# lot of the parent's buildings (its DOB filing lot or mapped lot, in both
# periods), dated from two years before the first filing to 180 days after it,
# applies; most are recorded within months of the filing, and the window is the
# same in both periods. Its other lots, after undoing mergers and
# subdivisions as above, are built on when vacant in the parent's reference
# release (no building floor or vacant land use) or demolished from three years
# before the first filing to 180 days after it, and otherwise lend floor area
# while their buildings remain. Condominium unit lots belong to a remaining
# building. The site lots are the starting lots and the built-on lots; their
# land, residential FAR and street frontage come from the reference release.
acris_snapshot_date <- as.Date("2026-10-01")
zoning_documents <- read_csv("../input/acris_zoning_lots_20261001_zoning_lot_documents.csv",
  col_types = cols(.default = col_character())) |>
  filter(doc_type == "ZONE") |>
  distinct(document_id, document_date = as.Date(str_sub(document_date, 1, 10)))
stopifnot(!anyDuplicated(zoning_documents$document_id), !anyNA(zoning_documents$document_date))
zoning_parcels <- read_csv("../input/acris_zoning_lots_20261001_zoning_lot_parcels.csv",
  col_types = cols(.default = col_character())) |>
  filter(document_id %in% zoning_documents$document_id, !between(as.integer(lot), 1001L, 7500L)) |>
  distinct(document_id, bbl = sprintf("%s%05d%04d", borough, as.integer(block), as.integer(lot)))
documents_by_lot <- split(zoning_parcels$document_id, zoning_parcels$bbl)
lots_by_document <- split(zoning_parcels$bbl, zoning_parcels$document_id)
document_dates <- setNames(zoning_documents$document_date, zoning_documents$document_id)
zoning_lot_documents <- function(lots, first_filing) {
  documents <- unique(unlist(documents_by_lot[intersect(lots, names(documents_by_lot))], use.names = FALSE))
  documents[document_dates[documents] >= first_filing - 730L & document_dates[documents] <= first_filing + 180L]
}
demolitions <- bind_rows(
  read_csv("../input/dob_demolition_filings_20261001_bis_demolitions.csv",
    col_types = cols(.default = col_character())) |>
    transmute(borough = c(MANHATTAN = "1", BRONX = "2", BROOKLYN = "3", QUEENS = "4", `STATEN ISLAND` = "5")[borough],
      block, lot, filing_date = as.Date(pre__filing_date, format = "%m/%d/%Y")),
  read_csv("../input/dob_demolition_filings_20261001_dob_now_demolitions.csv",
    col_types = cols(.default = col_character())) |>
    transmute(borough = str_sub(bbl, 1, 1), block, lot, filing_date = as.Date(str_sub(filing_date, 1, 10)))) |>
  filter(!is.na(borough), !is.na(filing_date), !is.na(suppressWarnings(as.integer(block))),
    !is.na(suppressWarnings(as.integer(lot)))) |>
  distinct(bbl = sprintf("%s%05d%04d", borough, as.integer(block), as.integer(lot)), filing_date)
demolition_dates <- split(demolitions$filing_date, demolitions$bbl)
sites <- parent_lots |>
  rowwise() |>
  mutate(documents = list(zoning_lot_documents(record_lots, first_filing)),
    zoning_set = list(starting_lot_set(unique(c(lots, unlist(lots_by_document[documents], use.names = FALSE))),
      first_filing)),
    other_lots = list(setdiff(zoning_set, starting_set)),
    demolished = list(other_lots[vapply(other_lots, function(lot) {
      dates <- demolition_dates[[lot]]
      !is.null(dates) && any(between(as.numeric(dates - first_filing), -3 * 365.25, 180))
    }, logical(1))])) |>
  ungroup()
release_lots <- bind_rows(lapply(unique(na.omit(sites$reference)), function(release) {
  in_release <- which(sites$reference == release)
  wanted <- unique(unlist(c(sites$starting_set[in_release], sites$other_lots[in_release])))
  read_parquet(paste0("../input/", release, ".parquet"),
    col_select = c(bbl, lotarea, lotfront, bldgarea, residfar, landuse)) |>
    filter(bbl %in% wanted) |>
    mutate(reference = release)
}))
stopifnot(!anyDuplicated(release_lots[c("reference", "bbl")]))
site_lots_table <- sites |>
  select(parent_id, reference, starting_set, other_lots, demolished) |>
  pivot_longer(c(starting_set, other_lots), names_to = "role", values_to = "bbl") |>
  unnest_longer(bbl) |>
  left_join(release_lots, by = c("reference", "bbl"), relationship = "many-to-one") |>
  mutate(built_on = role == "starting_set" | coalesce(bldgarea == 0 | landuse == "11", FALSE) |
    mapply(function(lot, removed) lot %in% removed, bbl, demolished))
site_measures <- site_lots_table |>
  group_by(parent_id) |>
  summarise(site_lots = sum(built_on), air_rights_donor_lots = sum(!built_on),
    site_lots_unmapped = sum(built_on & is.na(lotarea)), site_lot_area_sqft = sum(lotarea[built_on], na.rm = TRUE),
    site_residential_far = area_weighted(residfar[built_on], lotarea[built_on]),
    site_frontage_ft = sum(lotfront[built_on], na.rm = TRUE), .groups = "drop") |>
  left_join(sites |> transmute(parent_id, zoning_lot_record = lengths(documents) > 0L,
    zoning_lot_window_complete = first_filing + 180L <= acris_snapshot_date), by = "parent_id",
    relationship = "one-to-one")
parents <- parents |>
  left_join(starting_lots, by = "parent_id", relationship = "one-to-one") |>
  left_join(site_measures, by = "parent_id", relationship = "one-to-one")

# Reviewed land decisions (site_lot_decisions.csv) replace a parent's whole lot
# set with documented lots from a named release. Retained floor or a documented
# archive correction is deducted before computing existing density.
decisions <- read_csv("../input/site_lot_decisions.csv", show_col_types = FALSE,
  col_types = cols(reference_bbls = col_character())) |>
  filter(sample == sample_name)
decision_lots <- decisions |>
  select(parent_id, reference_vintage, reference_bbls) |>
  mutate(bbl = reference_bbls) |>
  separate_longer_delim(bbl, ";")
reviewed_parents <- decisions |>
  distinct(parent_id, expected_component_jobs) |>
  left_join(parents |> select(parent_id, component_jobs), by = "parent_id", relationship = "one-to-one")
stopifnot(!anyNA(decisions$built_floor_area_estimated), !anyDuplicated(decision_lots[c("parent_id", "bbl")]),
  all(reviewed_parents$expected_component_jobs == reviewed_parents$component_jobs))
decision_lots <- decision_lots |>
  left_join(bind_rows(lapply(unique(decision_lots$reference_vintage), function(vintage) {
    read_release(vintage, decision_lots$bbl) |> mutate(reference_vintage = vintage)
  })), by = c("reference_vintage", "bbl"), relationship = "many-to-one") |>
  group_by(parent_id, reference_vintage, reference_bbls) |>
  summarise(recorded_area = sum(lotarea), bldgarea = sum(bldgarea), frontage = sum(lotfront), feature_lots = n(),
    residential_fars = n_distinct(residfar), broad_fars = n_distinct(broad_zoning_far), residfar = first(residfar),
    broad_zoning_far = first(broad_zoning_far), borough = collapse_category(borough),
    community_district = collapse_category(community_district), .groups = "drop")
reviewed_lots <- decisions |>
  left_join(decision_lots, by = c("parent_id", "reference_vintage", "reference_bbls"), relationship = "one-to-one")
stopifnot(!anyNA(reviewed_lots$recorded_area), !anyNA(reviewed_lots$bldgarea), !anyNA(reviewed_lots$residfar),
  all(reviewed_lots$residential_fars == 1L), all(reviewed_lots$broad_fars == 1L),
  all(reviewed_lots$reference_recorded_area_sqft == reviewed_lots$recorded_area),
  all(reviewed_lots$development_area_sqft > 0), all(reviewed_lots$excluded_building_area_sqft >= 0),
  all(reviewed_lots$excluded_building_area_sqft <= reviewed_lots$bldgarea))
site_lots <- bind_rows(site_lots |> filter(!parent_id %in% reviewed_parents$parent_id),
  reviewed_lots |> transmute(sample, parent_id, feature_bbl = reference_bbls, feature_lots,
    lotarea = development_area_sqft, residfar, broad_zoning_far,
    builtfar = (bldgarea - excluded_building_area_sqft) / development_area_sqft, borough, community_district))
parents <- parents |>
  mutate(reviewed = parent_id %in% reviewed_parents$parent_id,
    feature_complete = feature_complete | reviewed,
    feature_methods = if_else(reviewed, "reviewed_parcel_allocation", feature_methods),
    merged_lots_added = if_else(reviewed, 0L, merged_lots_added)) |>
  # A reviewed parent starts on the earlier parcels its decision names.
  left_join(reviewed_lots |> group_by(parent_id) |> summarise(reviewed_lots = sum(feature_lots)), by = "parent_id",
    relationship = "one-to-one") |>
  mutate(starting_lots = if_else(reviewed, reviewed_lots, starting_lots))
# The site measures of a reviewed parent are its documented parcels.
parents <- parents |>
  left_join(reviewed_lots |> group_by(parent_id) |>
      summarise(reviewed_area = sum(development_area_sqft),
        reviewed_far = area_weighted(residfar, development_area_sqft), reviewed_frontage = sum(frontage),
        .groups = "drop"),
    by = "parent_id", relationship = "one-to-one") |>
  mutate(site_lots = if_else(reviewed, reviewed_lots, site_lots),
    air_rights_donor_lots = if_else(reviewed, 0L, air_rights_donor_lots),
    site_lots_unmapped = if_else(reviewed, 0L, site_lots_unmapped),
    site_lot_area_sqft = if_else(reviewed, reviewed_area, site_lot_area_sqft),
    site_residential_far = if_else(reviewed, reviewed_far, site_residential_far),
    site_frontage_ft = if_else(reviewed, reviewed_frontage, site_frontage_ft))

features <- site_lots |>
  group_by(sample, parent_id) |>
  summarise(feature_lots = sum(feature_lots), residfar = area_weighted(residfar, lotarea),
    broad_zoning_far = area_weighted(broad_zoning_far, lotarea), builtfar = area_weighted(builtfar, lotarea),
    borough = collapse_category(borough), community_district = collapse_category(community_district),
    lotarea = sum(lotarea), .groups = "drop")

# A parent enters the comparison with complete positive-area land and distinct
# building identifiers. Later DOB BINs can corroborate distinct buildings for a
# historical parent whose filings and land were reviewed. Under 150 square
# feet of permitted residential floor per proposed unit, the recorded land is
# a fragment of the site.
panel <- parents |>
  left_join(features, by = c("sample", "parent_id"), relationship = "one-to-one") |>
  mutate(reviewed_distinct_buildings = sample == "historical" & duplicate_bin_rows > 0L & reviewed &
      distinct_valid_dob_bins == component_filings,
    composition_eligible = feature_complete & coalesce(lotarea > 0, FALSE) &
      (duplicate_bin_rows == 0L | reviewed_distinct_buildings),
    built_floor_area_estimated = parent_id %in% decisions$parent_id[decisions$built_floor_area_estimated],
    implausible_site = !is.na(lotarea) & lotarea * pmax(residfar, broad_zoning_far) / units < 150) |>
  arrange(cohort_date, parent_id) |>
  select(sample, parent_id, units, composition_eligible, feature_methods, feature_lots, lotarea, residfar,
    builtfar, built_floor_area_estimated, merged_lots_added, merger_window_complete, starting_lots, site_lots,
    site_lot_area_sqft, site_residential_far, site_frontage_ft, air_rights_donor_lots, site_lots_unmapped,
    zoning_lot_record, zoning_lot_window_complete, implausible_site, borough, community_district)

SaveData(panel, "parent_id", sprintf("../output/%s_parent_site_characteristics.parquet", sample_name))

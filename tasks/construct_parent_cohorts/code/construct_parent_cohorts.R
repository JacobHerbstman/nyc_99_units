# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_parent_cohorts/code")
# historical_link_start_year <- 2010L
# historical_cohort_start_year <- 2011L
# historical_end_year <- 2023L
# post_comparison_start_year <- 2023L
# post_cohort_year <- 2025L
# max_filing_days <- 365L
# corroboration_days <- 30L
# post_geometry_vintage <- "23v3.1"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(sf)
  library(stringr)
  library(tibble)
})

source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 8L)
  historical_link_start_year <- as.integer(args[1])
  historical_cohort_start_year <- as.integer(args[2])
  historical_end_year <- as.integer(args[3])
  post_comparison_start_year <- as.integer(args[4])
  post_cohort_year <- as.integer(args[5])
  max_filing_days <- as.integer(args[6])
  corroboration_days <- as.integer(args[7])
  post_geometry_vintage <- args[8]
}

if (
  any(is.na(c(
    historical_link_start_year, historical_cohort_start_year,
    historical_end_year, post_comparison_start_year, post_cohort_year,
    max_filing_days, corroboration_days
  ))) ||
    historical_link_start_year > historical_cohort_start_year ||
    historical_cohort_start_year > historical_end_year ||
    post_comparison_start_year > post_cohort_year ||
    post_cohort_year <= historical_end_year ||
    max_filing_days < 1L ||
    corroboration_days < 0L ||
    corroboration_days > max_filing_days ||
    !nzchar(post_geometry_vintage)
) {
  stop("Symmetric parent-cohort arguments are not internally consistent.")
}

assign_components <- function(rows, links, max_days, blocked = tibble(job_number_1 = character(),
    job_number_2 = character())) {
  rows <- rows |>
    arrange(date_filed, job_number) |>
    mutate(row_id = row_number())
  component <- seq_len(nrow(rows))
  left_index <- match(links$job_number_1, rows$job_number)
  right_index <- match(links$job_number_2, rows$job_number)
  blocked_left <- match(blocked$job_number_1, rows$job_number)
  blocked_right <- match(blocked$job_number_2, rows$job_number)
  keep_blocked <- !is.na(blocked_left) & !is.na(blocked_right)
  blocked_left <- blocked_left[keep_blocked]
  blocked_right <- blocked_right[keep_blocked]

  if (any(is.na(left_index)) || any(is.na(right_index))) {
    stop("A parent link refers to a filing outside its declared universe.")
  }

  for (link_row in seq_len(nrow(links))) {
    left_component <- component[left_index[link_row]]
    right_component <- component[right_index[link_row]]
    if (left_component == right_component) next
    merging <- component %in% c(left_component, right_component)
    # Pairwise links can form a chain longer than the parent observation window.
    if (as.integer(max(rows$date_filed[merging]) - min(rows$date_filed[merging])) > max_days) next
    # A rejected pair never ends up in one parent, even through a chain of links.
    splits_rejection <- (component[blocked_left] == left_component & component[blocked_right] == right_component) |
      (component[blocked_left] == right_component & component[blocked_right] == left_component)
    if (any(splits_rejection)) next
    component[merging] <- min(left_component, right_component)
  }

  rows |>
    mutate(component = component)
}

historical_rows <- read_parquet("../input/historical_parent_filing_link_fields.parquet") |>
  filter(
    filing_year >= historical_link_start_year,
    filing_year <= historical_end_year
  ) |>
  arrange(date_filed, job_number)

historical_candidates <- read_parquet("../input/historical_parent_candidate_pairs.parquet")

historical_adjacency <- read_parquet("../input/historical_polygon_adjacency_pairs.parquet")

pair_decisions <- read_csv("../input/pair_decisions.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character()))
stopifnot(!anyNA(pair_decisions),
  all(pair_decisions$sample %in% c("historical", "post_policy")),
  all(pair_decisions$review_decision %in% c("accept", "reject")),
  all(pair_decisions$job_number_1 != pair_decisions$job_number_2),
  !anyDuplicated(data.frame(sample = pair_decisions$sample,
    first = pmin(pair_decisions$job_number_1, pair_decisions$job_number_2),
    second = pmax(pair_decisions$job_number_1, pair_decisions$job_number_2))))
# A reviewed link applies only when both proposals exist in that sample's source.
# Missing or sub-six-unit historical proposals are recorded in the coverage output.
historical_link_reviews <- pair_decisions |>
  filter(sample == "historical", job_number_1 %in% historical_rows$job_number,
    job_number_2 %in% historical_rows$job_number) |>
  select(-sample, -review_date)
post_link_reviews <- pair_decisions |> filter(sample == "post_policy") |> select(-sample, -review_date)
post_parent_reviews <- read_csv("../input/post_parent_reviews.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character()))
post_filing_roles <- read_csv("../input/post_parent_filing_roles.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character()))
historical_filing_roles <- read_csv("../input/historical_filing_roles.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character()))
stopifnot(!anyDuplicated(historical_filing_roles$job_number),
  all(historical_filing_roles$job_number %in% historical_rows$job_number),
  all(historical_filing_roles$filing_role %in% c("nonresidential_filing", "superseded_alternative")))
unit_decisions <- read_csv("../input/unit_decisions.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character(), reviewed_units = col_integer()))
stopifnot(!anyNA(unit_decisions),
  all(unit_decisions$unit_definition == "documented_proposed_design"),
  all(unit_decisions$reviewed_units > 0L),
  !anyDuplicated(unit_decisions[c("sample", "root_job_id")]))

historical_geometry_coverage <- read_parquet("../input/historical_polygon_geometry_coverage.parquet")

post_rows <- read_parquet("../output/post_policy_filing_link_fields.parquet") |>
  arrange(filing_date, job_number)

mappluto_inventory <- read_csv(
  "../input/mappluto_files.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

mappluto_files <- mappluto_inventory |>
  filter(
    source_id == "dcp_mappluto_archive",
    file_role == "mappluto_shapefile_zip",
    vintage == post_geometry_vintage
  ) |>
  select(raw_path)

# Unit priority is independent of sample size and land-data coverage.
# A recorded zero is zero Class A dwellings, not a missing HDB observation.
hdb_post_jobs <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet") |>
  select(job_number, hdb_units = classa_prop)
stopifnot(all(is.na(hdb_post_jobs$hdb_units) |
  (hdb_post_jobs$hdb_units >= 0 & hdb_post_jobs$hdb_units == round(hdb_post_jobs$hdb_units))))
hdb_post_jobs <- hdb_post_jobs |> mutate(hdb_units = as.integer(hdb_units))

if (
  nrow(historical_rows) == 0L ||
    nrow(post_rows) == 0L ||
    nrow(mappluto_files) != 1L ||
    anyDuplicated(historical_rows$job_number) ||
    anyDuplicated(hdb_post_jobs$job_number) ||
    anyDuplicated(post_rows$job_number) ||
    anyDuplicated(post_rows$root_job_id) ||
    anyDuplicated(
      historical_candidates[c("job_number_1", "job_number_2")]
    ) ||
    anyDuplicated(
      historical_adjacency[c("job_number_1", "job_number_2")]
    ) ||
    anyDuplicated(
      historical_link_reviews[c("job_number_1", "job_number_2")]
    ) ||
    any(!historical_link_reviews$review_decision %in% c("accept", "reject")) ||
    any(!historical_link_reviews$job_number_1 %in% historical_rows$job_number) ||
    any(!historical_link_reviews$job_number_2 %in% historical_rows$job_number) ||
    anyDuplicated(post_parent_reviews$reviewed_parent_id) ||
    any(!post_parent_reviews$review_decision %in% c("accept", "reject", "unresolved")) ||
    any(!post_parent_reviews$configuration_action %in% c(
      "keep_additive", "split", "exclude_superseded",
      "split_and_exclude_superseded"
    )) ||
    anyDuplicated(post_link_reviews[c("job_number_1", "job_number_2")]) ||
    any(!post_link_reviews$review_decision %in% c("accept", "reject")) ||
    any(!post_link_reviews$job_number_1 %in% post_rows$job_number) ||
    any(!post_link_reviews$job_number_2 %in% post_rows$job_number) ||
    anyDuplicated(post_filing_roles$job_number) ||
    any(!post_filing_roles$filing_role %in% "superseded_alternative") ||
    any(!post_filing_roles$job_number %in% post_rows$job_number) ||
    any(!post_filing_roles$replacement_job_number %in% post_rows$job_number) ||
    anyDuplicated(historical_geometry_coverage$job_number) ||
    !setequal(
      historical_geometry_coverage$job_number,
      historical_rows$job_number
    )
) {
  stop("A symmetric parent-cohort input failed identifier QC.")
}

historical_pair_fields <- historical_candidates |>
  filter(
    job_number_1 %in% historical_rows$job_number,
    job_number_2 %in% historical_rows$job_number
  ) |>
  transmute(
    job_number_1,
    job_number_2,
    same_filing_bbl,
    strict_lot_history_link =
      strict_prefiling_lot_link | same_archived_lot_history_group,
    later_lot_history_candidate =
      current_crosswalk_prefiling_dated_lot_link |
      post_filing_lot_history_link,
    explicit_job_reference,
    same_project_code,
    historical_same_owner_support =
      strict_prefiling_owner_nearby | dob_owner_nearby,
    high_confidence_prefiling_signal
  )

historical_adjacency_fields <- historical_adjacency |>
  filter(
    job_number_1 %in% historical_rows$job_number,
    job_number_2 %in% historical_rows$job_number
  ) |>
  transmute(
    job_number_1,
    job_number_2,
    adjacency_same_filing_bbl = same_filing_bbl,
    adjacency_strict_lot_history_link =
      strict_prefiling_lot_link | same_archived_lot_history_group,
    adjacency_explicit_job_reference = explicit_job_reference,
    adjacency_same_owner_support =
      strict_prefiling_owner_nearby | dob_owner_nearby,
    adjacency_high_confidence = high_confidence_prefiling_signal,
    exact_polygon_touch,
    corroborated_exact_adjacency
  )

historical_pairs <- full_join(
  historical_pair_fields,
  historical_adjacency_fields,
  by = c("job_number_1", "job_number_2"),
  relationship = "one-to-one"
) |>
  full_join(
    historical_link_reviews,
    by = c("job_number_1", "job_number_2"),
    relationship = "one-to-one"
  ) |>
  mutate(
    same_filing_bbl = coalesce(
      same_filing_bbl,
      adjacency_same_filing_bbl,
      FALSE
    ),
    strict_lot_history_link = coalesce(
      strict_lot_history_link,
      adjacency_strict_lot_history_link,
      FALSE
    ),
    later_lot_history_candidate = coalesce(
      later_lot_history_candidate,
      FALSE
    ),
    explicit_job_reference = coalesce(
      explicit_job_reference,
      adjacency_explicit_job_reference,
      FALSE
    ),
    same_project_code = coalesce(same_project_code, FALSE),
    same_owner_support = coalesce(
      historical_same_owner_support,
      adjacency_same_owner_support,
      FALSE
    ),
    exact_polygon_touch = coalesce(exact_polygon_touch, FALSE),
    corroborated_exact_adjacency = coalesce(
      corroborated_exact_adjacency,
      FALSE
    ),
    high_confidence_prefiling_signal = coalesce(
      high_confidence_prefiling_signal,
      adjacency_high_confidence,
      FALSE
    ),
    mechanical_link =
      high_confidence_prefiling_signal | corroborated_exact_adjacency,
    reviewed_accept = coalesce(review_decision == "accept", FALSE),
    reviewed_reject = coalesce(review_decision == "reject", FALSE),
    enhanced_link =
      (mechanical_link & !reviewed_reject) | reviewed_accept
  ) |>
  mutate(
    later_lot_history_candidate_only =
      later_lot_history_candidate & !enhanced_link
  ) |>
  select(
    job_number_1, job_number_2,
    same_filing_bbl, strict_lot_history_link,
    later_lot_history_candidate, later_lot_history_candidate_only,
    explicit_job_reference,
    same_project_code, same_owner_support, exact_polygon_touch,
    corroborated_exact_adjacency, mechanical_link,
    reviewed_accept, reviewed_reject, review_basis, review_source,
    enhanced_link
  )

historical_links <- historical_pairs |>
  filter(enhanced_link) |>
  left_join(
    historical_rows |>
      select(
        job_number_1 = job_number,
        date_filed_1 = date_filed,
        filing_bbl_1 = filing_bbl
      ),
    by = "job_number_1",
    relationship = "many-to-one"
  ) |>
  left_join(
    historical_rows |>
      select(
        job_number_2 = job_number,
        date_filed_2 = date_filed,
        filing_bbl_2 = filing_bbl
      ),
    by = "job_number_2",
    relationship = "many-to-one"
  ) |>
  mutate(
    sample = "historical",
    filing_days_apart = as.integer(date_filed_2 - date_filed_1)
  )

archive_listing <- system2(
  "unzip",
  c("-Z1", sprintf("../input/nyc_mappluto_%s_arc_shp.zip", sanitize_file_stub(post_geometry_vintage))),
  stdout = TRUE,
  stderr = FALSE
)
shapefile_entry <- archive_listing[
  str_to_lower(basename(archive_listing)) == "mappluto.shp"
][1]
needed_post_bbls <- sort(unique(post_rows$filing_bbl))
needed_post_bbls <- needed_post_bbls[!is.na(needed_post_bbls)]

if (is.na(shapefile_entry) || !nzchar(shapefile_entry)) {
  stop("The selected post MapPLUTO archive has no MapPLUTO.shp.")
}

post_lots <- st_read(
  paste0(
    "/vsizip/", sprintf("../input/nyc_mappluto_%s_arc_shp.zip", sanitize_file_stub(post_geometry_vintage)), "/", shapefile_entry
  ),
  query = paste0(
    "SELECT BBL FROM MapPLUTO WHERE BBL IN (",
    paste(needed_post_bbls, collapse = ","),
    ")"
  ),
  quiet = TRUE,
  stringsAsFactors = FALSE
) |>
  mutate(bbl = normalize_bbl_field(BBL)) |>
  select(bbl)

if (
  anyDuplicated(st_drop_geometry(post_lots)$bbl) ||
    any(!st_is_valid(post_lots))
) {
  stop("Post MapPLUTO filing-lot geometries failed QC.")
}

post_touch_index <- st_touches(post_lots)
post_touch_rows <- rep(seq_len(nrow(post_lots)), lengths(post_touch_index))
post_touch_columns <- unlist(post_touch_index, use.names = FALSE)
post_touch_edges <- tibble(
  left_row = post_touch_rows,
  right_row = post_touch_columns
) |>
  filter(left_row < right_row) |>
  transmute(
    bbl_low = pmin(post_lots$bbl[left_row], post_lots$bbl[right_row]),
    bbl_high = pmax(post_lots$bbl[left_row], post_lots$bbl[right_row]),
    exact_polygon_touch = TRUE
  )

if (anyDuplicated(post_touch_edges[c("bbl_low", "bbl_high")])) {
  stop("Post exact-touch edges are not unique by BBL pair.")
}

post_row_ids <- seq_len(nrow(post_rows))
post_right_endpoints <- findInterval(
  post_rows$filing_date + max_filing_days,
  post_rows$filing_date
)
post_pair_counts <- pmax(post_right_endpoints - post_row_ids, 0L)
post_left_rows <- rep(post_row_ids, post_pair_counts)
post_right_rows <- unlist(
  Map(
    function(left_row, right_endpoint) {
      if (right_endpoint <= left_row) integer() else {
        seq.int(left_row + 1L, right_endpoint)
      }
    },
    post_row_ids,
    post_right_endpoints
  ),
  use.names = FALSE
)

post_pairs <- tibble(
  job_number_1 = post_rows$job_number[post_left_rows],
  job_number_2 = post_rows$job_number[post_right_rows],
  root_job_id_1 = post_rows$root_job_id[post_left_rows],
  root_job_id_2 = post_rows$root_job_id[post_right_rows],
  date_filed_1 = post_rows$filing_date[post_left_rows],
  date_filed_2 = post_rows$filing_date[post_right_rows],
  filing_bbl_1 = post_rows$filing_bbl[post_left_rows],
  filing_bbl_2 = post_rows$filing_bbl[post_right_rows],
  site_linkage_bbl_1 = post_rows$site_linkage_bbl[post_left_rows],
  site_linkage_bbl_2 = post_rows$site_linkage_bbl[post_right_rows],
  historical_appbbl_1 = post_rows$historical_appbbl[post_left_rows],
  historical_appbbl_2 = post_rows$historical_appbbl[post_right_rows],
  lot_history_group_bbl_1 =
    post_rows$lot_history_group_bbl[post_left_rows],
  lot_history_group_bbl_2 =
    post_rows$lot_history_group_bbl[post_right_rows],
  appbbl_change_after_filing_1 =
    post_rows$appbbl_change_after_filing[post_left_rows],
  appbbl_change_after_filing_2 =
    post_rows$appbbl_change_after_filing[post_right_rows],
  owner_match_key_1 = post_rows$owner_match_key[post_left_rows],
  owner_match_key_2 = post_rows$owner_match_key[post_right_rows],
  description_reference_1 =
    post_rows$description_referenced_job_id[post_left_rows],
  description_reference_2 =
    post_rows$description_referenced_job_id[post_right_rows],
  project_code_1 = post_rows$description_project_code[post_left_rows],
  project_code_2 = post_rows$description_project_code[post_right_rows]
) |>
  mutate(
    filing_days_apart = as.integer(date_filed_2 - date_filed_1),
    bbl_low = pmin(filing_bbl_1, filing_bbl_2),
    bbl_high = pmax(filing_bbl_1, filing_bbl_2),
    same_filing_bbl =
      !is.na(filing_bbl_1) & !is.na(filing_bbl_2) &
      coalesce(filing_bbl_1 == filing_bbl_2, FALSE),
    same_site_linkage_bbl =
      !is.na(site_linkage_bbl_1) & !is.na(site_linkage_bbl_2) &
      coalesce(site_linkage_bbl_1 == site_linkage_bbl_2, FALSE),
    strict_lot_history_link =
      !is.na(lot_history_group_bbl_1) &
      !is.na(lot_history_group_bbl_2) &
      coalesce(
        lot_history_group_bbl_1 == lot_history_group_bbl_2,
        FALSE
      ) &
      (!is.na(historical_appbbl_1) | !is.na(historical_appbbl_2)) &
      !coalesce(appbbl_change_after_filing_1, FALSE) &
      !coalesce(appbbl_change_after_filing_2, FALSE),
    later_lot_history_candidate =
      !is.na(lot_history_group_bbl_1) &
      !is.na(lot_history_group_bbl_2) &
      coalesce(
        lot_history_group_bbl_1 == lot_history_group_bbl_2,
        FALSE
      ) &
      (!is.na(historical_appbbl_1) | !is.na(historical_appbbl_2)) &
      (coalesce(appbbl_change_after_filing_1, FALSE) |
        coalesce(appbbl_change_after_filing_2, FALSE)),
    same_owner_support =
      !is.na(owner_match_key_1) & !is.na(owner_match_key_2) &
      coalesce(owner_match_key_1 == owner_match_key_2, FALSE),
    explicit_job_reference =
      (!is.na(description_reference_1) &
        (coalesce(description_reference_1 == job_number_2, FALSE) |
          coalesce(description_reference_1 == root_job_id_2, FALSE))) |
      (!is.na(description_reference_2) &
        (coalesce(description_reference_2 == job_number_1, FALSE) |
          coalesce(description_reference_2 == root_job_id_1, FALSE))),
    same_project_code =
      !is.na(project_code_1) & !is.na(project_code_2) &
      coalesce(project_code_1 == project_code_2, FALSE)
  ) |>
  left_join(
    post_touch_edges,
    by = c("bbl_low", "bbl_high"),
    relationship = "many-to-one"
  ) |>
  mutate(
    exact_polygon_touch = coalesce(exact_polygon_touch, FALSE),
    corroborated_exact_adjacency =
      exact_polygon_touch &
      (filing_days_apart <= corroboration_days | same_owner_support),
    automatic_link =
      same_filing_bbl |
      same_site_linkage_bbl |
      strict_lot_history_link |
      explicit_job_reference |
      same_project_code |
      corroborated_exact_adjacency
  )

automatic_post_membership <- assign_components(
  post_rows |>
    transmute(job_number, date_filed = filing_date),
  post_pairs |>
    filter(automatic_link) |>
    select(job_number_1, job_number_2),
  Inf # Provisional groups identify the saved post-policy review records.
) |>
  group_by(component) |>
  mutate(
    reviewed_parent_id = paste(
      "post_policy",
      first(job_number),
      sep = "__"
    )
  ) |>
  ungroup()

expected_reviewed_parent_ids <- post_pairs |>
  filter(automatic_link, same_site_linkage_bbl, !same_filing_bbl) |>
  select(job_number = job_number_1) |>
  bind_rows(
    post_pairs |>
      filter(automatic_link, same_site_linkage_bbl, !same_filing_bbl) |>
      select(job_number = job_number_2)
  ) |>
  distinct() |>
  left_join(
    automatic_post_membership |>
      select(job_number, reviewed_parent_id),
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  pull(reviewed_parent_id) |>
  unique()

if (
  !setequal(
    expected_reviewed_parent_ids,
    post_parent_reviews$reviewed_parent_id
  ) ||
    nrow(anti_join(
      post_link_reviews,
      post_pairs,
      by = c("job_number_1", "job_number_2")
    )) > 0L
) {
  stop("Post parent-review files do not cover the declared filing pairs.")
}

post_pairs <- post_pairs |>
  left_join(
    post_link_reviews,
    by = c("job_number_1", "job_number_2"),
    relationship = "one-to-one"
  ) |>
  mutate(
    reviewed_accept = coalesce(review_decision == "accept", FALSE),
    reviewed_reject = coalesce(review_decision == "reject", FALSE),
    enhanced_link =
      (automatic_link & !reviewed_reject) | reviewed_accept
  ) |>
  mutate(
    later_lot_history_candidate_only =
      later_lot_history_candidate & !enhanced_link
  )

post_links <- post_pairs |>
  filter(enhanced_link) |>
  mutate(
    sample = "post_policy"
  ) |>
  select(
    sample, job_number_1, job_number_2,
    date_filed_1, date_filed_2, filing_days_apart,
    filing_bbl_1, filing_bbl_2,
    site_linkage_bbl_1, site_linkage_bbl_2,
    same_filing_bbl, same_site_linkage_bbl, strict_lot_history_link,
    later_lot_history_candidate, explicit_job_reference,
    same_project_code, same_owner_support, exact_polygon_touch,
    corroborated_exact_adjacency,
    reviewed_accept, reviewed_reject, review_basis, review_source,
    enhanced_link
  )

# Companion filings on nearby lots with the same owner (owner_proximity_links,
# from construct_owner_proximity_links.R). They join after the automatic and
# reviewed links, the 365-day parent window still applies, and a rejected pair
# never links.
rejected_pairs <- pair_decisions |>
  filter(review_decision == "reject") |>
  transmute(sample, pair_key = paste(pmin(job_number_1, job_number_2), pmax(job_number_1, job_number_2)))
filing_fields <- bind_rows(
  historical_rows |> transmute(sample = "historical", job_number, date_filed, filing_bbl,
    site_linkage_bbl = filing_bbl),
  post_rows |> transmute(sample = "post_policy", job_number, date_filed = filing_date, filing_bbl,
    site_linkage_bbl)
)
owner_links <- read_parquet("../output/owner_proximity_links.parquet") |>
  mutate(pair_key = paste(pmin(job_number_1, job_number_2), pmax(job_number_1, job_number_2))) |>
  anti_join(rejected_pairs, by = c("sample", "pair_key")) |>
  left_join(filing_fields |> rename_with(~ paste0(.x, "_a"), -sample),
    by = c("sample", "job_number_1" = "job_number_a"), relationship = "many-to-one") |>
  left_join(filing_fields |> rename_with(~ paste0(.x, "_b"), -sample),
    by = c("sample", "job_number_2" = "job_number_b"), relationship = "many-to-one") |>
  mutate(a_first = date_filed_a < date_filed_b |
    (date_filed_a == date_filed_b & job_number_1 < job_number_2)) |>
  transmute(sample, pair_key,
    job_number_1 = if_else(a_first, job_number_1, job_number_2),
    job_number_2 = if_else(a_first, job_number_2, job_number_1),
    date_filed_1 = if_else(a_first, date_filed_a, date_filed_b),
    date_filed_2 = if_else(a_first, date_filed_b, date_filed_a),
    filing_bbl_1 = if_else(a_first, filing_bbl_a, filing_bbl_b),
    filing_bbl_2 = if_else(a_first, filing_bbl_b, filing_bbl_a),
    site_linkage_bbl_1 = if_else(a_first, site_linkage_bbl_a, site_linkage_bbl_b),
    site_linkage_bbl_2 = if_else(a_first, site_linkage_bbl_b, site_linkage_bbl_a),
    filing_days_apart = as.integer(date_filed_2 - date_filed_1))
stopifnot(!anyNA(owner_links$date_filed_1), !anyNA(owner_links$date_filed_2))

links <- bind_rows(
  historical_links |>
    mutate(
      site_linkage_bbl_1 = filing_bbl_1,
      site_linkage_bbl_2 = filing_bbl_2,
      same_site_linkage_bbl = same_filing_bbl
    ) |>
    select(
      sample, job_number_1, job_number_2,
      date_filed_1, date_filed_2, filing_days_apart,
      filing_bbl_1, filing_bbl_2,
      site_linkage_bbl_1, site_linkage_bbl_2,
      same_filing_bbl, same_site_linkage_bbl, strict_lot_history_link,
      later_lot_history_candidate, explicit_job_reference,
      same_project_code, same_owner_support, exact_polygon_touch,
      corroborated_exact_adjacency,
      reviewed_accept, reviewed_reject, review_basis, review_source,
      enhanced_link
    ),
  post_links
) |>
  mutate(pair_key = paste(pmin(job_number_1, job_number_2), pmax(job_number_1, job_number_2)))
links <- bind_rows(
  links,
  owner_links |> anti_join(links, by = c("sample", "pair_key"))
) |>
  mutate(
    same_owner_nearby = paste(sample, pair_key) %in% paste(owner_links$sample, owner_links$pair_key),
    across(c(same_filing_bbl, same_site_linkage_bbl, strict_lot_history_link,
      later_lot_history_candidate, explicit_job_reference, same_project_code,
      same_owner_support, exact_polygon_touch, corroborated_exact_adjacency,
      reviewed_accept, reviewed_reject, enhanced_link), ~ coalesce(.x, FALSE))
  ) |>
  select(-pair_key) |>
  mutate(
    link_reason = str_remove(
      paste0(
        if_else(same_filing_bbl, "same_filing_bbl;", ""),
        if_else(
          same_site_linkage_bbl & !same_filing_bbl,
          "same_site_linkage_bbl;",
          ""
        ),
        if_else(
          strict_lot_history_link,
          "strict_lot_history_link;",
          ""
        ),
        if_else(
          explicit_job_reference,
          "explicit_job_reference;",
          ""
        ),
        if_else(same_project_code, "same_project_code;", ""),
        if_else(
          corroborated_exact_adjacency,
          "corroborated_exact_adjacency;",
          ""
        ),
        if_else(reviewed_accept, "reviewed_accept;", ""),
        if_else(same_owner_nearby, "same_owner_nearby;", "")
      ),
      ";$"
    )
  ) |>
  arrange(sample, date_filed_1, job_number_1, job_number_2)

historical_member_rows <- historical_rows |>
  left_join(historical_filing_roles |> select(job_number, filing_role, replacement_job_number),
    by = "job_number", relationship = "one-to-one") |>
  transmute(
    sample = "historical",
    root_job_id = job_number,
    job_number,
    date_filed,
    filing_year,
    units,
    hdb_priority_units = units,
    dob_i1_units = NA_integer_,
    unit_source = "hdb",
    hdb_release, historical_active, hdb_job_status,
    filing_role = coalesce(filing_role, "additive_component"),
    additive_component = filing_role == "additive_component",
    replacement_job_number,
    filing_bbl,
    site_linkage_bbl = filing_bbl
  ) |>
  left_join(
    historical_geometry_coverage |>
      select(job_number, geometry_available),
    by = "job_number",
    relationship = "one-to-one"
  )

post_member_rows <- post_rows |>
  left_join(
    post_filing_roles,
    by = "job_number",
    relationship = "one-to-one"
  ) |>
  left_join(
    hdb_post_jobs |>
      select(root_job_id = job_number, hdb_units),
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    dob_i1_units = units,
    hdb_priority_units = coalesce(hdb_units, dob_i1_units),
    unit_source = if_else(!is.na(hdb_units), "hdb", "dob_i1"),
    filing_role = coalesce(filing_role, "additive_component"),
    additive_component = filing_role == "additive_component"
  ) |>
  transmute(
    sample = "post_policy",
    root_job_id,
    job_number,
    date_filed = filing_date,
    filing_year,
    units = hdb_priority_units,
    hdb_priority_units,
    dob_i1_units,
    unit_source,
    hdb_release = if_else(unit_source == "hdb", "25Q4", NA_character_),
    historical_active = NA,
    hdb_job_status = NA_character_,
    filing_role,
    additive_component,
    replacement_job_number,
    filing_bbl,
    site_linkage_bbl,
    geometry_available = filing_bbl %in% post_lots$bbl
  )

historical_membership <- assign_components(
  historical_member_rows,
  bind_rows(
    historical_links |>
      arrange(desc(reviewed_accept), date_filed_1, date_filed_2) |>
      select(job_number_1, job_number_2),
    owner_links |> filter(sample == "historical") |>
      arrange(date_filed_1, date_filed_2) |> select(job_number_1, job_number_2)
  ),
  max_filing_days,
  pair_decisions |> filter(sample == "historical", review_decision == "reject") |>
    select(job_number_1, job_number_2)
)
post_membership <- assign_components(
  post_member_rows,
  bind_rows(
    post_links |>
      arrange(desc(reviewed_accept), date_filed_1, date_filed_2) |>
      select(job_number_1, job_number_2),
    owner_links |> filter(sample == "post_policy") |>
      arrange(date_filed_1, date_filed_2) |> select(job_number_1, job_number_2)
  ),
  max_filing_days,
  pair_decisions |> filter(sample == "post_policy", review_decision == "reject") |>
    select(job_number_1, job_number_2)
)

post_filing_role_qc <- post_membership |>
  filter(filing_role == "superseded_alternative") |>
  select(job_number, component, replacement_job_number) |>
  left_join(
    post_membership |>
      select(
        replacement_job_number = job_number,
        replacement_component = component
      ),
    by = "replacement_job_number",
    relationship = "many-to-one"
  )

if (
  nrow(post_filing_role_qc) != nrow(post_filing_roles) ||
    any(is.na(post_filing_role_qc$replacement_component)) ||
    any(
      post_filing_role_qc$component !=
        post_filing_role_qc$replacement_component
    )
) {
  stop("A superseded filing is not grouped with its reviewed replacement.")
}

membership <- bind_rows(historical_membership, post_membership)
# The candidate tables retain the evidence for links spanning separate windows.
member_keys <- paste(membership$sample, membership$job_number)
links <- links |>
  filter(membership$component[match(paste(sample, job_number_1), member_keys)] ==
    membership$component[match(paste(sample, job_number_2), member_keys)])

# A withdrawn application and its unique subsequent filing describe one building.
dob_filings <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(root_job_id = job_number, bin = as.character(bin),
    dob_i1_units = proposed_dwelling_units,
    filing_status, withdrawal_date = current_status_date,
    owner = str_squish(str_to_upper(paste(coalesce(owner_business_name, ""),
      coalesce(owner_first_name, ""), coalesce(owner_last_name, "")))),
    applicant = str_squish(str_to_upper(paste(coalesce(applicant_first_name, ""),
      coalesce(applicant_last_name, ""), coalesce(applicant_business_name, "")))))
stopifnot(!anyDuplicated(dob_filings$root_job_id))
# DOB comparisons use the actual source; unavailable legacy records stay missing.
membership$dob_i1_units <- dob_filings$dob_i1_units[
  match(membership$root_job_id, dob_filings$root_job_id)]
refiling_fields <- membership |>
  left_join(dob_filings |> select(-dob_i1_units),
    by = "root_job_id", relationship = "many-to-one")
replacement_index <- rep(NA_integer_, nrow(membership))
# Post-policy replacements require the observed withdrawal event and matching
# DOB owner/applicant identifiers. Historical roles use the archived source below.
for (i in which(refiling_fields$sample == "post_policy" &
    refiling_fields$filing_status == "Filing Withdrawn" &
    !is.na(refiling_fields$withdrawal_date) &
    str_detect(refiling_fields$bin, "^[1-5][0-9]{6}$") &
    !refiling_fields$owner %in% c("", "PR", "PRIVATE", "NOT APPLICABLE") &
    refiling_fields$applicant != "")) {
  candidates <- which(refiling_fields$sample == refiling_fields$sample[i] &
    refiling_fields$bin == refiling_fields$bin[i] &
    refiling_fields$owner == refiling_fields$owner[i] &
    refiling_fields$applicant == refiling_fields$applicant[i] &
    refiling_fields$date_filed > refiling_fields$date_filed[i] &
    refiling_fields$date_filed > refiling_fields$withdrawal_date[i] &
    refiling_fields$filing_status != "Filing Withdrawn")
  if (length(candidates) > 1L) stop("Multiple refiling candidates for ", membership$job_number[i])
  if (length(candidates) == 1L) replacement_index[i] <- candidates
}

# At the historical snapshot, one nonwithdrawn proposal can replace earlier
# withdrawn versions of the same building. Require the same archived BIN, BBL,
# exact address, and a single surviving application within the one-year window.
# Several withdrawn versions may share that successor. No withdrawal date is imputed.
archived_identifiers <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet") |>
  select(job_number, hdb_bin = bin, hdb_address = address)
archived_buildings <- membership |>
  filter(sample == "historical") |>
  left_join(archived_identifiers, by = "job_number", relationship = "one-to-one") |>
  filter(str_detect(hdb_bin, "^[1-5][0-9]{6}$"), !is.na(filing_bbl),
    !is.na(hdb_address), hdb_address != "") |>
  group_by(component, hdb_bin, filing_bbl, hdb_address) |>
  filter(n() > 1L, sum(hdb_job_status != "9. Withdrawn") == 1L) |>
  mutate(replacement_job = job_number[hdb_job_status != "9. Withdrawn"],
    replacement_date = date_filed[hdb_job_status != "9. Withdrawn"]) |>
  filter(replacement_date == max(date_filed),
    max(date_filed) - min(date_filed) <= max_filing_days,
    hdb_job_status == "9. Withdrawn", date_filed < replacement_date) |>
  ungroup()
archived_original <- match(archived_buildings$job_number, membership$job_number[membership$sample == "historical"])
historical_index <- which(membership$sample == "historical")
archived_original <- historical_index[archived_original]
archived_replacement <- historical_index[match(archived_buildings$replacement_job,
  membership$job_number[historical_index])]
stopifnot(!anyNA(archived_original), !anyNA(archived_replacement))
replacement_index[archived_original] <- archived_replacement
manual_original <- which(membership$sample == "historical" &
  membership$filing_role == "superseded_alternative")
manual_replacement <- historical_index[match(membership$replacement_job_number[manual_original],
  membership$job_number[historical_index])]
stopifnot(!anyNA(manual_replacement))
replacement_index[manual_original] <- manual_replacement

original_index <- which(!is.na(replacement_index))
new_index <- replacement_index[original_index]
stopifnot(!anyDuplicated(new_index[membership$sample[original_index] == "post_policy"]),
  all(membership$sample[original_index] == membership$sample[new_index]),
  all(membership$component[original_index] == membership$component[new_index]),
  all(membership$additive_component[new_index]))
# A conflicting manual role or a pair outside an existing parent requires review.
stopifnot(all(is.na(membership$replacement_job_number[original_index]) |
  membership$replacement_job_number[original_index] == membership$job_number[new_index]))
membership$original_filing_date <- membership$date_filed
membership$refiled <- FALSE
membership$refiling_date <- as.Date(NA)
membership$refiled[c(original_index, new_index)] <- TRUE
membership$refiling_date[original_index] <- membership$date_filed[new_index]
membership$refiling_date[new_index] <- membership$date_filed[new_index]
for (j in unique(new_index)) {
  membership$original_filing_date[j] <- min(membership$date_filed[original_index[new_index == j]])
}
membership$refiling_basis <- NA_character_
membership$refiling_basis[c(original_index, new_index)] <- if_else(
  membership$sample[c(original_index, new_index)] == "historical",
  "archived_same_building_alternatives", "dated_dob_withdrawal_and_refiling")
membership$refiling_basis[c(manual_original, manual_replacement)] <- "reviewed_archived_alternative"
membership$filing_role[original_index] <- "superseded_refiling"
membership$additive_component[original_index] <- FALSE
membership$replacement_job_number[original_index] <- membership$job_number[new_index]
stopifnot(all(membership$refiled == !is.na(membership$refiling_date)),
  all(membership$refiling_date[membership$refiled] > membership$original_filing_date[membership$refiled]))

membership <- membership |>
  mutate(
    filing_role = if_else(additive_component & units == 0L,
      "zero_class_a", filing_role),
    additive_component = additive_component & units > 0L
  ) |>
  left_join(unit_decisions |> select(sample, root_job_id,
    documented_units = reviewed_units, documented_unit_definition = unit_definition,
    documented_unit_source_date = source_date, documented_unit_source = review_source),
    by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  arrange(sample, date_filed, job_number) |>
  group_by(sample, component) |>
  mutate(
    parent_anchor_job = first(job_number),
    parent_id = paste(sample, parent_anchor_job, sep = "__"),
    cohort_date = first(date_filed),
    cohort_year = as.integer(format(cohort_date, "%Y")),
    parent_last_filing_date = max(date_filed),
    parent_span_days = as.integer(parent_last_filing_date - cohort_date),
    parent_source_filings = n(),
    parent_observed_filings = sum(additive_component),
    parent_source_units = sum(hdb_priority_units),
    parent_source_units_dob_i1 = sum(dob_i1_units),
    parent_observed_units = sum(units[additive_component]),
    parent_observed_units_dob_i1 = sum(dob_i1_units[additive_component]),
    parent_source_exact_99_filings = sum(hdb_priority_units == 99L),
    parent_exact_99_filings = sum(
      units == 99L & additive_component
    ),
    parent_source_exact_99_filings_dob_i1 = sum(dob_i1_units == 99L),
    parent_exact_99_filings_dob_i1 = sum(
      dob_i1_units == 99L & additive_component
    ),
    member_order = row_number()
  ) |>
  ungroup() |>
  group_by(sample) |>
  mutate(
    source_start_date = min(date_filed),
    source_end_date = max(date_filed),
    left_window_observed =
      cohort_date - max_filing_days >= source_start_date,
    right_window_observed =
      cohort_date + max_filing_days <= source_end_date,
    full_window_observed =
      left_window_observed & right_window_observed
  ) |>
  ungroup() |>
  mutate(
    analysis_status = case_when(
      sample == "historical" &
        cohort_year < historical_cohort_start_year ~
        "historical_linkage_padding",
      sample == "historical" & full_window_observed ~
        "historical_fully_observed",
      sample == "historical" &
        !left_window_observed & !right_window_observed ~
        "historical_both_boundaries_exposed",
      sample == "historical" & !left_window_observed ~
        "historical_left_boundary_exposed",
      sample == "historical" & !right_window_observed ~
        "historical_right_boundary_exposed",
      sample == "post_policy" &
        cohort_year < post_comparison_start_year ~
        "post_linkage_padding",
      sample == "post_policy" &
        cohort_year < post_cohort_year & full_window_observed ~
        "completed_pre_policy_comparison_cohort",
      sample == "post_policy" &
        cohort_year < post_cohort_year & !left_window_observed ~
        "left_boundary_pre_policy_comparison_cohort",
      sample == "post_policy" & cohort_year < post_cohort_year ~
        "right_censored_pre_policy_comparison_cohort",
      sample == "post_policy" &
        cohort_year == post_cohort_year &
        !left_window_observed & !right_window_observed ~
        "both_boundaries_exposed_2025_cohort",
      sample == "post_policy" &
        cohort_year == post_cohort_year & !left_window_observed ~
        "left_boundary_exposed_2025_cohort",
      sample == "post_policy" &
        cohort_year == post_cohort_year & full_window_observed ~
        "completed_2025_cohort",
      sample == "post_policy" & cohort_year == post_cohort_year ~
        "right_censored_2025_cohort",
      sample == "post_policy" & cohort_year > post_cohort_year ~
        "later_2026_cohort",
      TRUE ~ "unclassified"
    )
  ) |>
  select(-row_id)

if (
  anyDuplicated(links[c("sample", "job_number_1", "job_number_2")]) ||
    any(links$filing_days_apart > max_filing_days) ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    nrow(membership) != nrow(historical_rows) + nrow(post_rows) ||
    any(is.na(membership$geometry_available)) ||
    any(membership$units < 0L) ||
    any(membership$additive_component & membership$units == 0L) ||
    any((membership$parent_observed_filings == 0L) !=
      (membership$parent_observed_units == 0L)) ||
    any(membership$parent_span_days > max_filing_days) ||
    any(membership$analysis_status == "unclassified")
) {
  stop("Symmetric parent-cohort outputs failed final QC.")
}

# Manual decisions must survive component construction, including transitive paths.
reviewed_components <- pair_decisions |>
  left_join(membership |> select(sample, job_number_1 = job_number, parent_1 = parent_id),
    by = c("sample", "job_number_1"), relationship = "many-to-one") |>
  left_join(membership |> select(sample, job_number_2 = job_number, parent_2 = parent_id),
    by = c("sample", "job_number_2"), relationship = "many-to-one")
reviewed_components <- reviewed_components |>
  mutate(applies_to_source = !is.na(parent_1) & !is.na(parent_2))
stopifnot(all(reviewed_components$applies_to_source[reviewed_components$sample == "post_policy"]),
  all((reviewed_components$parent_1[reviewed_components$applies_to_source] ==
    reviewed_components$parent_2[reviewed_components$applies_to_source]) ==
    (reviewed_components$review_decision[reviewed_components$applies_to_source] == "accept")),
  nrow(anti_join(unit_decisions, membership, by = c("sample", "root_job_id"))) == 0L,
  all(membership$units == membership$hdb_priority_units))

SaveData(reviewed_components, c("sample", "job_number_1", "job_number_2"),
  "../output/pair_decision_coverage.csv")
SaveData(membership, c("sample", "job_number"), "../output/symmetric_parent_membership.parquet")
SaveData(links, NULL, "../output/symmetric_parent_links.parquet")

cat("Wrote symmetric parent cohorts to ../output\n")

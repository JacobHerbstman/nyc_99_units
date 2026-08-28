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

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 8L) {
  stop(
    "Expected eight arguments: historical link start, cohort start and end ",
    "years, post comparison start and cohort years, maximum filing days, ",
    "corroboration days, and post geometry vintage."
  )
}

historical_link_start_year <- as.integer(args[1])
historical_cohort_start_year <- as.integer(args[2])
historical_end_year <- as.integer(args[3])
post_comparison_start_year <- as.integer(args[4])
post_cohort_year <- as.integer(args[5])
max_filing_days <- as.integer(args[6])
corroboration_days <- as.integer(args[7])
post_geometry_vintage <- args[8]

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

assign_components <- function(rows, links) {
  rows <- rows |>
    arrange(date_filed, job_number) |>
    mutate(row_id = row_number())
  component <- seq_len(nrow(rows))
  left_index <- match(links$job_number_1, rows$job_number)
  right_index <- match(links$job_number_2, rows$job_number)

  if (any(is.na(left_index)) || any(is.na(right_index))) {
    stop("A parent link refers to a filing outside its declared universe.")
  }

  for (link_row in seq_len(nrow(links))) {
    left_component <- component[left_index[link_row]]
    right_component <- component[right_index[link_row]]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <-
      merged_component
  }

  rows |>
    mutate(component = component)
}

historical_rows <- read_parquet(
  "../input/historical_parent_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    filing_year >= historical_link_start_year,
    filing_year <= historical_end_year
  ) |>
  arrange(date_filed, job_number)

historical_candidates <- read_parquet(
  "../input/historical_parent_candidate_pairs.parquet"
) |>
  as.data.frame() |>
  as_tibble()

historical_adjacency <- read_parquet(
  "../input/historical_polygon_adjacency_pairs.parquet"
) |>
  as.data.frame() |>
  as_tibble()

historical_link_reviews <- read_csv(
  "historical_parent_link_reviews.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

historical_geometry_coverage <- read_parquet(
  "../input/historical_polygon_geometry_coverage.parquet"
) |>
  as.data.frame() |>
  as_tibble()

post_rows <- read_parquet(
  "../input/post_policy_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
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

hdb_post_jobs <- read_parquet(
  "../input/hdb_mappluto_training_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  select(
    job_number, filing_year, classa_prop,
    classa_prop_integer, primary_leakage_safe_sample, lotarea
  ) |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= 6,
    !is.na(lotarea),
    lotarea > 0,
    filing_year >= post_comparison_start_year,
    filing_year <= post_cohort_year
  ) |>
  mutate(hdb_units = as.integer(round(classa_prop)))

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
  left_join(
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
  c("-Z1", mappluto_files$raw_path),
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
    "/vsizip/", mappluto_files$raw_path, "/", shapefile_entry
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
    enhanced_link =
      same_filing_bbl |
      strict_lot_history_link |
      explicit_job_reference |
      same_project_code |
      corroborated_exact_adjacency
  ) |>
  mutate(
    later_lot_history_candidate_only =
      later_lot_history_candidate & !enhanced_link
  )

post_links <- post_pairs |>
  filter(enhanced_link) |>
  mutate(
    sample = "post_policy",
    reviewed_accept = FALSE,
    reviewed_reject = FALSE,
    review_basis = NA_character_,
    review_source = NA_character_
  ) |>
  select(
    sample, job_number_1, job_number_2,
    date_filed_1, date_filed_2, filing_days_apart,
    filing_bbl_1, filing_bbl_2,
    same_filing_bbl, strict_lot_history_link,
    later_lot_history_candidate, explicit_job_reference,
    same_project_code, same_owner_support, exact_polygon_touch,
    corroborated_exact_adjacency,
    reviewed_accept, reviewed_reject, review_basis, review_source,
    enhanced_link
  )

links <- bind_rows(
  historical_links |>
    select(
      sample, job_number_1, job_number_2,
      date_filed_1, date_filed_2, filing_days_apart,
      filing_bbl_1, filing_bbl_2,
      same_filing_bbl, strict_lot_history_link,
      later_lot_history_candidate, explicit_job_reference,
      same_project_code, same_owner_support, exact_polygon_touch,
      corroborated_exact_adjacency,
      reviewed_accept, reviewed_reject, review_basis, review_source,
      enhanced_link
    ),
  post_links
) |>
  mutate(
    link_reason = str_remove(
      paste0(
        if_else(same_filing_bbl, "same_filing_bbl;", ""),
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
        if_else(reviewed_accept, "reviewed_accept;", "")
      ),
      ";$"
    )
  ) |>
  arrange(sample, date_filed_1, job_number_1, job_number_2)

historical_member_rows <- historical_rows |>
  transmute(
    sample = "historical",
    root_job_id = job_number,
    job_number,
    date_filed,
    filing_year,
    units,
    hdb_priority_units = units,
    dob_i1_units = units,
    unit_source = "hdb",
    filing_bbl
  ) |>
  left_join(
    historical_geometry_coverage |>
      select(job_number, geometry_available),
    by = "job_number",
    relationship = "one-to-one"
  )

post_member_rows <- post_rows |>
  left_join(
    hdb_post_jobs |>
      select(root_job_id = job_number, hdb_units),
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    dob_i1_units = units,
    hdb_priority_units = coalesce(hdb_units, dob_i1_units),
    unit_source = if_else(!is.na(hdb_units), "hdb", "dob_i1")
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
    filing_bbl,
    geometry_available = filing_bbl %in% post_lots$bbl
  )

historical_membership <- assign_components(
  historical_member_rows,
  historical_links |>
    select(job_number_1, job_number_2)
)
post_membership <- assign_components(
  post_member_rows,
  post_links |>
    select(job_number_1, job_number_2)
)

membership <- bind_rows(historical_membership, post_membership) |>
  arrange(sample, date_filed, job_number) |>
  group_by(sample, component) |>
  mutate(
    parent_anchor_job = first(job_number),
    parent_id = paste(sample, parent_anchor_job, sep = "__"),
    cohort_date = first(date_filed),
    cohort_year = as.integer(format(cohort_date, "%Y")),
    parent_last_filing_date = max(date_filed),
    parent_span_days = as.integer(parent_last_filing_date - cohort_date),
    parent_observed_filings = n(),
    parent_observed_units = sum(hdb_priority_units),
    parent_observed_units_dob_i1 = sum(dob_i1_units),
    parent_exact_99_filings = sum(hdb_priority_units == 99L),
    parent_exact_99_filings_dob_i1 = sum(dob_i1_units == 99L),
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
    any(membership$parent_span_days > max_filing_days) ||
    any(membership$analysis_status == "unclassified")
) {
  stop("Symmetric parent-cohort outputs failed final QC.")
}

write_parquet_if_changed(
  membership,
  "../output/symmetric_parent_membership.parquet"
)
write_parquet_if_changed(
  links,
  "../output/symmetric_parent_links.parquet"
)

cat("Wrote symmetric parent cohorts to ../output\n")

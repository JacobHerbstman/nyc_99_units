# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_cohorts/code")
# historical_link_start_year <- 2018L
# historical_cohort_start_year <- 2019L
# historical_end_year <- 2023L
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

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 7L) {
  stop(
    "Expected seven arguments: historical link start, cohort start and end ",
    "years, post cohort year, maximum filing days, corroboration days, and ",
    "post geometry vintage."
  )
}

historical_link_start_year <- as.integer(args[1])
historical_cohort_start_year <- as.integer(args[2])
historical_end_year <- as.integer(args[3])
post_cohort_year <- as.integer(args[4])
max_filing_days <- as.integer(args[5])
corroboration_days <- as.integer(args[6])
post_geometry_vintage <- args[7]

if (
  any(is.na(c(
    historical_link_start_year, historical_cohort_start_year,
    historical_end_year, post_cohort_year,
    max_filing_days, corroboration_days
  ))) ||
    historical_link_start_year > historical_cohort_start_year ||
    historical_cohort_start_year > historical_end_year ||
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

summarize_link_signals <- function(pairs, sample_name) {
  signals <- c(
    "same_filing_bbl",
    "strict_lot_history_link",
    "later_lot_history_candidate",
    "later_lot_history_candidate_only",
    "explicit_job_reference",
    "same_project_code",
    "corroborated_exact_adjacency",
    "enhanced_link"
  )

  bind_rows(lapply(signals, function(signal) {
    selected <- coalesce(pairs[[signal]], FALSE)
    selected_jobs <- c(
      pairs$job_number_1[selected],
      pairs$job_number_2[selected]
    )
    tibble(
      sample = sample_name,
      signal,
      eligible_pairs = nrow(pairs),
      signal_pairs = sum(selected),
      distinct_jobs = n_distinct(selected_jobs)
    )
  }))
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

post_rows <- read_parquet(
  "../input/post_policy_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  arrange(filing_date, job_number)

mappluto_files <- read_csv(
  "../input/mappluto_files.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
) |>
  filter(
    source_id == "dcp_mappluto_archive",
    file_role == "mappluto_shapefile_zip",
    vintage == post_geometry_vintage
  ) |>
  transmute(
    raw_path = if_else(
      str_detect(raw_path, "^[.][.]/[.][.]/[.][.]/"),
      str_replace(raw_path, "^[.][.]/[.][.]/[.][.]/", "../../../../"),
      raw_path
    )
  )

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
    filing_year == post_cohort_year
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
    enhanced_link =
      high_confidence_prefiling_signal | corroborated_exact_adjacency
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
    corroborated_exact_adjacency, enhanced_link
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
  mutate(sample = "post_policy") |>
  select(
    sample, job_number_1, job_number_2,
    date_filed_1, date_filed_2, filing_days_apart,
    filing_bbl_1, filing_bbl_2,
    same_filing_bbl, strict_lot_history_link,
    later_lot_history_candidate, explicit_job_reference,
    same_project_code, same_owner_support, exact_polygon_touch,
    corroborated_exact_adjacency, enhanced_link
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
      corroborated_exact_adjacency, enhanced_link
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
        )
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
    filing_bbl,
    geometry_available =
      pluto_source_id_used == "dcp_mappluto_archive"
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
      sample == "post_policy" & cohort_year < post_cohort_year ~
        "prior_2024_cohort",
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

cohort_inventory <- membership |>
  arrange(sample, parent_id, date_filed, job_number) |>
  group_by(sample, parent_id) |>
  summarise(
    parent_anchor_job = first(parent_anchor_job),
    cohort_date = first(cohort_date),
    cohort_year = first(cohort_year),
    parent_last_filing_date = first(parent_last_filing_date),
    parent_span_days = first(parent_span_days),
    parent_observed_filings = first(parent_observed_filings),
    parent_observed_units = first(parent_observed_units),
    parent_observed_units_dob_i1 = first(parent_observed_units_dob_i1),
    parent_exact_99_filings = first(parent_exact_99_filings),
    parent_exact_99_filings_dob_i1 =
      first(parent_exact_99_filings_dob_i1),
    distinct_filing_bbls = n_distinct(filing_bbl[!is.na(filing_bbl)]),
    cross_calendar_year = n_distinct(filing_year) > 1L,
    all_geometry_available = all(geometry_available),
    source_start_date = first(source_start_date),
    source_end_date = first(source_end_date),
    left_window_observed = first(left_window_observed),
    right_window_observed = first(right_window_observed),
    full_window_observed = first(full_window_observed),
    analysis_status = first(analysis_status),
    component_root_jobs = paste(root_job_id, collapse = ";"),
    component_jobs = paste(job_number, collapse = ";"),
    component_units = paste(hdb_priority_units, collapse = ";"),
    component_units_dob_i1 = paste(dob_i1_units, collapse = ";"),
    component_unit_sources = paste(unit_source, collapse = ";"),
    .groups = "drop"
  ) |>
  arrange(sample, cohort_date, parent_anchor_job)

post_job_link_evidence <- bind_rows(
  links |>
    filter(sample == "post_policy") |>
    transmute(
      job_number = job_number_1,
      linked_job_number = job_number_2,
      link_reason
    ),
  links |>
    filter(sample == "post_policy") |>
    transmute(
      job_number = job_number_2,
      linked_job_number = job_number_1,
      link_reason
    )
) |>
  group_by(job_number) |>
  summarise(
    directly_linked_jobs = paste(
      sort(unique(linked_job_number)),
      collapse = ";"
    ),
    direct_link_reasons = paste(
      sort(unique(link_reason)),
      collapse = "|"
    ),
    .groups = "drop"
  )

exact_99_path_rows <- bind_rows(
  membership |>
    filter(
      sample == "post_policy",
      filing_year == post_cohort_year,
      hdb_priority_units == 99L
    ) |>
    mutate(unit_definition = "hdb_priority"),
  membership |>
    filter(
      sample == "post_policy",
      filing_year == post_cohort_year,
      dob_i1_units == 99L
    ) |>
    mutate(unit_definition = "dob_i1")
) |>
  transmute(
    unit_definition,
    exact_99_root_job_id = root_job_id,
    exact_99_job_number = job_number,
    exact_99_filing_date = date_filed,
    exact_99_filing_bbl = filing_bbl,
    exact_99_hdb_priority_units = hdb_priority_units,
    exact_99_dob_i1_units = dob_i1_units,
    exact_99_geometry_available = geometry_available,
    parent_id
  ) |>
  left_join(
    cohort_inventory |>
      filter(sample == "post_policy") |>
      select(-sample),
    by = "parent_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    post_job_link_evidence,
    by = c("exact_99_job_number" = "job_number"),
    relationship = "many-to-one"
  ) |>
  left_join(
    hdb_post_jobs |>
      transmute(
        exact_99_root_job_id = job_number,
        hdb_classa_units = hdb_units
      ),
    by = "exact_99_root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    parent_companion_filings = parent_observed_filings - 1L,
    parent_is_singleton = parent_observed_filings == 1L,
    parent_observed_units_equal_198 = parent_observed_units == 198L,
    parent_observed_units_dob_i1_equal_198 =
      parent_observed_units_dob_i1 == 198L,
    hdb_model_match = !is.na(hdb_classa_units),
    hdb_dob_units_match = hdb_classa_units == 99L,
    directly_linked_jobs = coalesce(directly_linked_jobs, "none"),
    direct_link_reasons = coalesce(direct_link_reasons, "none")
  ) |>
  arrange(unit_definition, exact_99_filing_date, exact_99_job_number)

exact_99_paths <- exact_99_path_rows |>
  filter(unit_definition == "hdb_priority")

exact_99_paths_dob_i1 <- exact_99_path_rows |>
  filter(unit_definition == "dob_i1")

cohort_summary <- bind_rows(
  cohort_inventory |>
    group_by(sample, cohort_group = analysis_status) |>
    summarise(
      parent_count = n(),
      observed_filings = sum(parent_observed_filings),
      observed_units = sum(parent_observed_units),
      observed_units_dob_i1 = sum(parent_observed_units_dob_i1),
      exact_99_filings = sum(parent_exact_99_filings),
      exact_99_filings_dob_i1 = sum(parent_exact_99_filings_dob_i1),
      .groups = "drop"
    ),
  cohort_inventory |>
    filter(sample == "post_policy", cohort_year == post_cohort_year) |>
    summarise(
      sample = "post_policy",
      cohort_group = "descriptive_all_2025_cohorts",
      parent_count = n(),
      observed_filings = sum(parent_observed_filings),
      observed_units = sum(parent_observed_units),
      observed_units_dob_i1 = sum(parent_observed_units_dob_i1),
      exact_99_filings = sum(parent_exact_99_filings),
      exact_99_filings_dob_i1 = sum(parent_exact_99_filings_dob_i1)
    )
) |>
  arrange(sample, cohort_group)

link_summary <- bind_rows(
  summarize_link_signals(historical_pairs, "historical"),
  summarize_link_signals(post_pairs, "post_policy")
)

hdb_dob_filing_id_matches <- intersect(
  hdb_post_jobs$job_number,
  post_rows$job_number
)
hdb_dob_root_matches <- inner_join(
  hdb_post_jobs |>
    transmute(root_job_id = job_number, hdb_units),
  post_rows |>
    filter(filing_year == post_cohort_year) |>
    transmute(root_job_id, dob_units = units),
  by = "root_job_id",
  relationship = "one-to-one"
)

cohort_qc <- tibble(
  check = c(
    "historical_filings",
    "post_filings",
    "post_snapshot_date",
    "historical_enhanced_links",
    "post_enhanced_links",
    "historical_components_over_365_days",
    "post_components_over_365_days",
    "post_geometry_vintage",
    "post_filings_with_geometry",
    "post_geometry_filing_share",
    "hdb_post_model_filings",
    "dob_post_link_filings",
    "hdb_dob_filing_id_matches",
    "hdb_dob_root_job_matches",
    "hdb_dob_unit_disagreements",
    "hdb_dob_exact_99_classification_disagreements",
    "observed_2025_exact_99_filings_hdb_priority",
    "observed_2025_exact_99_filings_dob_i1",
    "observed_2025_exact_99_filings_with_geometry",
    "observed_2025_exact_99_filings_with_hdb_model_match",
    "exact_99_filings_in_prior_2024_parent",
    "exact_99_filings_in_left_boundary_exposed_2025_parent",
    "exact_99_filings_in_completed_2025_parent",
    "exact_99_filings_in_right_censored_2025_parent",
    "imputed_companions"
  ),
  value = as.character(c(
    nrow(historical_member_rows),
    nrow(post_member_rows),
    as.character(max(post_member_rows$date_filed)),
    nrow(historical_links),
    nrow(post_links),
    sum(
      cohort_inventory$sample == "historical" &
        cohort_inventory$parent_span_days > max_filing_days
    ),
    sum(
      cohort_inventory$sample == "post_policy" &
        cohort_inventory$parent_span_days > max_filing_days
    ),
    post_geometry_vintage,
    sum(post_member_rows$geometry_available),
    round(mean(post_member_rows$geometry_available), 6),
    nrow(hdb_post_jobs),
    nrow(post_rows),
    length(hdb_dob_filing_id_matches),
    nrow(hdb_dob_root_matches),
    sum(hdb_dob_root_matches$hdb_units != hdb_dob_root_matches$dob_units),
    sum(
      (hdb_dob_root_matches$hdb_units == 99L) !=
        (hdb_dob_root_matches$dob_units == 99L)
    ),
    nrow(exact_99_paths),
    nrow(exact_99_paths_dob_i1),
    sum(exact_99_paths$exact_99_geometry_available),
    sum(exact_99_paths$hdb_model_match),
    sum(exact_99_paths$analysis_status == "prior_2024_cohort"),
    sum(
      exact_99_paths$analysis_status ==
        "left_boundary_exposed_2025_cohort"
    ),
    sum(exact_99_paths$analysis_status == "completed_2025_cohort"),
    sum(
      exact_99_paths$analysis_status == "right_censored_2025_cohort"
    ),
    0L
  ))
)

if (
  anyDuplicated(links[c("sample", "job_number_1", "job_number_2")]) ||
    any(links$filing_days_apart > max_filing_days) ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    nrow(membership) != nrow(historical_rows) + nrow(post_rows) ||
    anyDuplicated(cohort_inventory[c("sample", "parent_id")]) ||
    any(cohort_inventory$parent_span_days > max_filing_days) ||
    nrow(exact_99_paths) != sum(
      post_member_rows$filing_year == post_cohort_year &
        post_member_rows$hdb_priority_units == 99L
    ) ||
    nrow(exact_99_paths_dob_i1) != sum(
      post_member_rows$filing_year == post_cohort_year &
        post_member_rows$dob_i1_units == 99L
    ) ||
    any(is.na(exact_99_paths$analysis_status)) ||
    any(cohort_inventory$analysis_status == "unclassified")
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
write_csv_if_changed(
  cohort_inventory,
  "../output/symmetric_parent_cohort_inventory.csv"
)
write_csv_if_changed(
  exact_99_paths,
  "../output/symmetric_parent_2025_exact_99_paths.csv"
)
write_csv_if_changed(
  exact_99_paths_dob_i1,
  "../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv"
)
write_csv_if_changed(
  link_summary,
  "../output/symmetric_parent_link_summary.csv"
)
write_csv_if_changed(
  cohort_summary,
  "../output/symmetric_parent_cohort_summary.csv"
)
write_csv_if_changed(
  cohort_qc,
  "../output/symmetric_parent_cohort_qc.csv"
)

cat("Wrote symmetric parent-cohort audit outputs to ../output\n")

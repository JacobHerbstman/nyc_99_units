# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_historical_parent_link_feasibility/code")
# nearby_meters <- 100
# review_meters <- 250
# max_filing_days <- 365L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3L) {
  stop("Expected three arguments: nearby meters, review meters, and maximum filing days.")
}

nearby_meters <- as.numeric(args[1])
review_meters <- as.numeric(args[2])
max_filing_days <- as.integer(args[3])

if (
  any(is.na(c(nearby_meters, review_meters, max_filing_days))) ||
    nearby_meters <= 0 ||
    review_meters < nearby_meters ||
    max_filing_days < 0L
) {
  stop("Audit arguments are not internally consistent.")
}

filings <- read_parquet("../output/historical_parent_filing_link_fields.parquet") |>
  as.data.frame() |>
  as_tibble() |>
  arrange(date_filed, job_number)

source_inventory <- read_csv(
  "../output/historical_parent_source_inventory.csv",
  show_col_types = FALSE
)

filing_coverage_by_year <- read_csv(
  "../output/historical_parent_filing_coverage_by_year.csv",
  show_col_types = FALSE
)

if (nrow(filings) == 0L || anyDuplicated(filings$job_number)) {
  stop("Historical parent-link filing fields failed identifier QC.")
}

owner_filing_counts <- table(filings$pluto_owner_match_key)
filings$pluto_owner_filing_count <- as.integer(
  owner_filing_counts[filings$pluto_owner_match_key]
)

filing_rows <- seq_len(nrow(filings))
right_endpoints <- findInterval(
  filings$date_filed + max_filing_days,
  filings$date_filed
)
pair_counts <- pmax(right_endpoints - filing_rows, 0L)
left_rows <- rep(filing_rows, pair_counts)
right_rows <- unlist(
  Map(
    function(left_row, right_endpoint) {
      if (right_endpoint <= left_row) integer() else {
        seq.int(left_row + 1L, right_endpoint)
      }
    },
    filing_rows,
    right_endpoints
  ),
  use.names = FALSE
)

filing_days_apart <- as.integer(
  filings$date_filed[right_rows] - filings$date_filed[left_rows]
)
distance_meters <- 6371000 * pi / 180 * sqrt(
  ((filings$hdb_longitude[right_rows] -
    filings$hdb_longitude[left_rows]) *
    cos((filings$hdb_latitude[left_rows] +
      filings$hdb_latitude[right_rows]) * pi / 360))^2 +
    (filings$hdb_latitude[right_rows] -
      filings$hdb_latitude[left_rows])^2
)
same_filing_bbl <- !is.na(filings$filing_bbl[left_rows]) &
  coalesce(
    filings$filing_bbl[left_rows] == filings$filing_bbl[right_rows],
    FALSE
  )
same_prefiling_feature_bbl <-
  !is.na(filings$prefiling_feature_bbl[left_rows]) &
  coalesce(
    filings$prefiling_feature_bbl[left_rows] ==
      filings$prefiling_feature_bbl[right_rows],
    FALSE
  )
same_archived_lot_history_group <-
  !is.na(filings$archived_lot_history_group[left_rows]) &
  coalesce(
    filings$archived_lot_history_group[left_rows] ==
      filings$archived_lot_history_group[right_rows],
    FALSE
  ) &
  (!is.na(filings$archived_appbbl[left_rows]) |
    !is.na(filings$archived_appbbl[right_rows])) &
  !filings$appbbl_recovery_used[left_rows] &
  !filings$appbbl_recovery_used[right_rows]
same_pluto_owner <- !is.na(filings$pluto_owner_match_key[left_rows]) &
  coalesce(
    filings$pluto_owner_match_key[left_rows] ==
      filings$pluto_owner_match_key[right_rows],
    FALSE
  )
same_dob_owner <- !is.na(filings$dob_owner_match_key[left_rows]) &
  coalesce(
    filings$dob_owner_match_key[left_rows] ==
      filings$dob_owner_match_key[right_rows],
    FALSE
  )
explicit_job_reference <-
  str_detect(
    coalesce(filings$description_referenced_jobs[left_rows], ""),
    fixed(filings$job_number[right_rows])
  ) |
  str_detect(
    coalesce(filings$description_referenced_jobs[right_rows], ""),
    fixed(filings$job_number[left_rows])
  )
same_project_code <-
  !is.na(filings$description_project_code[left_rows]) &
  coalesce(
    filings$description_project_code[left_rows] ==
      filings$description_project_code[right_rows],
    FALSE
  )

retain <-
  (!is.na(distance_meters) & distance_meters <= review_meters) |
  same_filing_bbl |
  same_prefiling_feature_bbl |
  same_archived_lot_history_group |
  explicit_job_reference |
  same_project_code

candidate_pairs <- tibble(
  job_number_1 = filings$job_number[left_rows[retain]],
  job_number_2 = filings$job_number[right_rows[retain]],
  filing_year_1 = filings$filing_year[left_rows[retain]],
  filing_year_2 = filings$filing_year[right_rows[retain]],
  date_filed_1 = filings$date_filed[left_rows[retain]],
  date_filed_2 = filings$date_filed[right_rows[retain]],
  units_1 = filings$units[left_rows[retain]],
  units_2 = filings$units[right_rows[retain]],
  filing_bbl_1 = filings$filing_bbl[left_rows[retain]],
  filing_bbl_2 = filings$filing_bbl[right_rows[retain]],
  prefiling_feature_bbl_1 =
    filings$prefiling_feature_bbl[left_rows[retain]],
  prefiling_feature_bbl_2 =
    filings$prefiling_feature_bbl[right_rows[retain]],
  archived_appbbl_1 = filings$archived_appbbl[left_rows[retain]],
  archived_appbbl_2 = filings$archived_appbbl[right_rows[retain]],
  archived_appdate_1 = filings$archived_appdate[left_rows[retain]],
  archived_appdate_2 = filings$archived_appdate[right_rows[retain]],
  appbbl_recovery_used_1 =
    filings$appbbl_recovery_used[left_rows[retain]],
  appbbl_recovery_used_2 =
    filings$appbbl_recovery_used[right_rows[retain]],
  appbbl_future_appdate_used_1 =
    filings$appbbl_future_appdate_used_for_linkage[left_rows[retain]],
  appbbl_future_appdate_used_2 =
    filings$appbbl_future_appdate_used_for_linkage[right_rows[retain]],
  pluto_owner_name_1 = filings$pluto_owner_name[left_rows[retain]],
  pluto_owner_name_2 = filings$pluto_owner_name[right_rows[retain]],
  pluto_owner_filing_count_1 =
    filings$pluto_owner_filing_count[left_rows[retain]],
  pluto_owner_filing_count_2 =
    filings$pluto_owner_filing_count[right_rows[retain]],
  dob_owner_name_1 = filings$dob_owner_name[left_rows[retain]],
  dob_owner_name_2 = filings$dob_owner_name[right_rows[retain]],
  description_referenced_jobs_1 =
    filings$description_referenced_jobs[left_rows[retain]],
  description_referenced_jobs_2 =
    filings$description_referenced_jobs[right_rows[retain]],
  description_project_code_1 =
    filings$description_project_code[left_rows[retain]],
  description_project_code_2 =
    filings$description_project_code[right_rows[retain]],
  filing_days_apart = .env$filing_days_apart[retain],
  distance_meters = .env$distance_meters[retain],
  same_filing_bbl = .env$same_filing_bbl[retain],
  same_prefiling_feature_bbl = .env$same_prefiling_feature_bbl[retain],
  feature_link_uses_current_appbbl_recovery =
    .env$same_prefiling_feature_bbl[retain] &
    (filings$appbbl_recovery_used[left_rows[retain]] |
      filings$appbbl_recovery_used[right_rows[retain]]),
  feature_link_uses_post_filing_appbbl =
    .env$same_prefiling_feature_bbl[retain] &
    (filings$appbbl_future_appdate_used_for_linkage[left_rows[retain]] |
      filings$appbbl_future_appdate_used_for_linkage[right_rows[retain]]),
  same_archived_lot_history_group =
    .env$same_archived_lot_history_group[retain],
  same_pluto_owner = .env$same_pluto_owner[retain],
  same_dob_owner = .env$same_dob_owner[retain],
  explicit_job_reference = .env$explicit_job_reference[retain],
  same_project_code = .env$same_project_code[retain],
  within_nearby_distance =
    !is.na(.env$distance_meters[retain]) &
    .env$distance_meters[retain] <= nearby_meters,
  within_review_distance =
    !is.na(.env$distance_meters[retain]) &
    .env$distance_meters[retain] <= review_meters
) |>
  mutate(
    prefiling_owner_nearby = same_pluto_owner & within_nearby_distance,
    dob_owner_nearby = same_dob_owner & within_nearby_distance,
    strict_prefiling_owner_nearby =
      prefiling_owner_nearby &
      !appbbl_recovery_used_1 &
      !appbbl_recovery_used_2 &
      !appbbl_future_appdate_used_1 &
      !appbbl_future_appdate_used_2,
    current_crosswalk_prefiling_owner_candidate =
      prefiling_owner_nearby &
      (appbbl_recovery_used_1 | appbbl_recovery_used_2) &
      !appbbl_future_appdate_used_1 &
      !appbbl_future_appdate_used_2,
    post_filing_owner_candidate =
      prefiling_owner_nearby &
      (appbbl_future_appdate_used_1 | appbbl_future_appdate_used_2),
    strict_prefiling_lot_link =
      same_prefiling_feature_bbl &
      !feature_link_uses_current_appbbl_recovery &
      !feature_link_uses_post_filing_appbbl,
    current_crosswalk_prefiling_dated_lot_link =
      same_prefiling_feature_bbl &
      feature_link_uses_current_appbbl_recovery &
      !feature_link_uses_post_filing_appbbl,
    post_filing_lot_history_link =
      same_prefiling_feature_bbl & feature_link_uses_post_filing_appbbl,
    high_confidence_prefiling_signal =
      same_filing_bbl |
      strict_prefiling_lot_link |
      same_archived_lot_history_group |
      explicit_job_reference |
      same_project_code,
    owner_supported_candidate =
      (strict_prefiling_owner_nearby | dob_owner_nearby) &
      !high_confidence_prefiling_signal,
    prefiling_candidate_signal =
      high_confidence_prefiling_signal | owner_supported_candidate,
    proximity_only_review = within_review_distance &
      !prefiling_candidate_signal &
      !current_crosswalk_prefiling_dated_lot_link &
      !post_filing_lot_history_link &
      !dob_owner_nearby
  ) |>
  arrange(job_number_1, job_number_2)

if (
  nrow(candidate_pairs) == 0L ||
    anyDuplicated(candidate_pairs[c("job_number_1", "job_number_2")])
) {
  stop("Historical candidate-pair construction failed QC.")
}

summarize_grouping <- function(link_rows, definition) {
  component <- seq_len(nrow(filings))
  left_index <- match(link_rows$job_number_1, filings$job_number)
  right_index <- match(link_rows$job_number_2, filings$job_number)

  for (link_row in seq_len(nrow(link_rows))) {
    left_component <- component[left_index[link_row]]
    right_component <- component[right_index[link_row]]
    merged_component <- min(left_component, right_component)
    component[component %in% c(left_component, right_component)] <-
      merged_component
  }

  group_sizes <- tibble(component) |>
    count(component, name = "filings")

  tibble(
    definition,
    parent_groups = nrow(group_sizes),
    multi_filing_groups = sum(group_sizes$filings > 1L),
    filings_in_multi_filing_groups = sum(
      group_sizes$filings[group_sizes$filings > 1L]
    ),
    share_filings_in_multi_filing_groups =
      filings_in_multi_filing_groups / nrow(filings),
    groups_with_two_filings = sum(group_sizes$filings == 2L),
    groups_with_three_filings = sum(group_sizes$filings == 3L),
    groups_with_four_or_more_filings = sum(group_sizes$filings >= 4L),
    maximum_filings_in_group = max(group_sizes$filings)
  )
}

grouping_sensitivity <- bind_rows(
  summarize_grouping(
    candidate_pairs |>
      filter(same_filing_bbl),
    "same_filing_bbl_only"
  ),
  summarize_grouping(
    candidate_pairs |>
      filter(high_confidence_prefiling_signal),
    "high_confidence_prefiling_links"
  ),
  summarize_grouping(
    candidate_pairs |>
      filter(prefiling_candidate_signal),
    "high_confidence_plus_owner_review_candidates"
  )
)


signal_names <- c(
  "same_filing_bbl",
  "strict_prefiling_lot_link",
  "same_archived_lot_history_group",
  "prefiling_owner_nearby",
  "explicit_job_reference",
  "same_project_code",
  "current_crosswalk_prefiling_dated_lot_link",
  "post_filing_lot_history_link",
  "dob_owner_nearby",
  "strict_prefiling_owner_nearby",
  "current_crosswalk_prefiling_owner_candidate",
  "post_filing_owner_candidate",
  "high_confidence_prefiling_signal",
  "owner_supported_candidate",
  "prefiling_candidate_signal",
  "proximity_only_review"
)

link_signal_summary <- bind_rows(lapply(signal_names, function(signal_name) {
  signal_value <- coalesce(candidate_pairs[[signal_name]], FALSE)
  signal_pairs <- candidate_pairs[signal_value, ]
  tibble(
    signal = signal_name,
    candidate_pairs = nrow(signal_pairs),
    distinct_jobs = n_distinct(c(
      signal_pairs$job_number_1,
      signal_pairs$job_number_2
    )),
    evidence_timing = case_when(
      signal_name == "post_filing_lot_history_link" ~ "post_filing",
      signal_name == "post_filing_owner_candidate" ~ "post_filing",
      signal_name == "current_crosswalk_prefiling_dated_lot_link" ~
        "current_snapshot_with_prefiling_appdate",
      signal_name == "current_crosswalk_prefiling_owner_candidate" ~
        "current_snapshot_with_prefiling_appdate",
      signal_name == "prefiling_owner_nearby" ~ "mixed_timing_raw",
      signal_name == "proximity_only_review" ~ "review_only",
      TRUE ~ "available_by_filing"
    )
  )
}))

feasibility_summary <- tibble(
  evidence_dimension = c(
    "adjacent_lots",
    "shared_owners",
    "lot_mergers_and_subdivisions",
    "explicit_project_references"
  ),
  feasibility = c(
    "partial",
    "feasible_as_candidate_signal",
    "feasible_with_timing_split",
    "partial"
  ),
  usable_period = c(
    "exact geometry begins with the late-2018 release; coordinates cover 2010-2023",
    "PLUTO owner field 2010-2023; strict lot linkage varies; DOB owner 2021-2023",
    "archived APPBBL and APPDate 2010-2023; later transitions audit-only",
    "HDB description incomplete before 2021; DOB NOW 2021-2023"
  ),
  primary_limit = c(
    "centroid proximity does not prove shared parcel boundary before 2018",
    "tax-lot owner is not necessarily the developer or beneficial owner",
    "current or future APPBBL links can encode post-filing lot changes",
    "missing descriptions imply low historical recall"
  ),
  modeling_use = c(
    "exact adjacency only where prefiling geometry exists; otherwise review",
    "owner plus proximity defines review candidates, not automatic links",
    "use only archived prefiling links in the no-policy model",
    "high-specificity link when an existing companion job is named"
  )
)

link_feasibility_qc <- tibble(
  check = c(
    "training_filings",
    "unique_training_job_numbers",
    "required_pluto_releases",
    "pluto_releases_with_owner_field",
    "pluto_releases_with_xy_fields",
    "pluto_releases_with_appbbl_and_appdate",
    "pluto_releases_with_exact_geometry",
    "filings_using_current_appbbl_recovery",
    "filings_using_post_filing_appbbl_linkage",
    "candidate_pairs",
    "candidate_pairs_with_high_confidence_prefiling_signal",
    "candidate_pairs_with_owner_supported_signal"
  ),
  value = c(
    nrow(filings),
    n_distinct(filings$job_number),
    nrow(source_inventory),
    sum(source_inventory$has_owner_name),
    sum(source_inventory$has_xy_coordinates),
    sum(source_inventory$has_appbbl & source_inventory$has_appdate),
    sum(source_inventory$has_exact_geometry),
    sum(filings$appbbl_recovery_used),
    sum(filings$appbbl_future_appdate_used_for_linkage),
    nrow(candidate_pairs),
    sum(candidate_pairs$high_confidence_prefiling_signal),
    sum(candidate_pairs$owner_supported_candidate)
  )
)

if (
  nrow(source_inventory) == 0L ||
    anyDuplicated(source_inventory[c("source_id", "vintage")]) ||
    sum(filing_coverage_by_year$training_filings) != nrow(filings) ||
    any(
      as.integer(candidate_pairs$strict_prefiling_owner_nearby) +
        as.integer(
          candidate_pairs$current_crosswalk_prefiling_owner_candidate
        ) +
        as.integer(candidate_pairs$post_filing_owner_candidate) !=
        as.integer(candidate_pairs$prefiling_owner_nearby)
    ) ||
    nrow(grouping_sensitivity) != 3L ||
    nrow(feasibility_summary) != 4L
) {
  stop("Historical parent-link feasibility outputs failed final QC.")
}



write_parquet_if_changed(
  candidate_pairs,
  "../output/historical_parent_candidate_pairs.parquet"
)
write_csv_if_changed(
  link_signal_summary,
  "../output/historical_parent_link_signal_summary.csv"
)
write_csv_if_changed(
  grouping_sensitivity,
  "../output/historical_parent_grouping_sensitivity.csv"
)
write_csv_if_changed(
  feasibility_summary,
  "../output/historical_parent_feasibility_summary.csv"
)
write_csv_if_changed(
  link_feasibility_qc,
  "../output/historical_parent_link_feasibility_qc.csv"
)

cat("Wrote historical parent-link candidate pairs and feasibility summaries to ../output\n")

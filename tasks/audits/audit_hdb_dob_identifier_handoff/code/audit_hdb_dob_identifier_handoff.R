# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_dob_identifier_handoff/code")
# post_year <- 2025L
# min_units <- 6L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2L) {
  stop("Expected post year and minimum unit count.")
}

post_year <- as.integer(args[1])
min_units <- as.integer(args[2])

if (is.na(post_year) || is.na(min_units) || min_units < 1L) {
  stop("Identifier-audit arguments are not internally consistent.")
}

hdb <- read_parquet(
  "../input/hdb_mappluto_training_panel.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  filter(
    primary_leakage_safe_sample,
    classa_prop_integer,
    classa_prop >= min_units,
    !is.na(lotarea),
    lotarea > 0,
    filing_year == post_year
  ) |>
  transmute(
    hdb_root_job_id = str_squish(job_number),
    hdb_filing_date = as.Date(date_filed),
    hdb_units = as.integer(round(classa_prop)),
    hdb_bbl = normalize_bbl_field(bbl),
    hdb_bin = str_squish(as.character(bin)),
    hdb_address = str_to_upper(str_squish(address)),
    hdb_job_status = job_status
  ) |>
  arrange(hdb_filing_date, hdb_root_job_id)

dob <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    dob_root_job_id = str_squish(job_number),
    dob_filing_id = str_squish(job_filing_number),
    dob_filing_date = as.Date(filing_date),
    dob_units = as.integer(round(proposed_dwelling_units)),
    dob_bbl = normalize_bbl_field(bbl),
    dob_bin = str_squish(as.character(bin)),
    dob_address = str_to_upper(str_squish(address)),
    dob_filing_status = filing_status,
    dob_source_pull_date = parse_mixed_date(source_pull_date)
  ) |>
  arrange(dob_filing_date, dob_filing_id)

parent_crosswalk <- read_parquet(
  "../input/post_policy_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    hdb_root_job_id = str_squish(root_job_id),
    parent_crosswalk_filing_id = str_squish(job_number)
  )

if (
  nrow(hdb) == 0L ||
    nrow(dob) == 0L ||
    anyDuplicated(hdb$hdb_root_job_id) ||
    anyDuplicated(dob$dob_root_job_id) ||
    anyDuplicated(parent_crosswalk$hdb_root_job_id)
) {
  stop("An identifier-audit source failed uniqueness or nonempty QC.")
}

handoff <- hdb |>
  left_join(
    dob,
    by = c("hdb_root_job_id" = "dob_root_job_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    parent_crosswalk,
    by = "hdb_root_job_id",
    relationship = "one-to-one"
  )

missing_root_sites <- handoff |>
  filter(is.na(dob_filing_id)) |>
  select(
    hdb_root_job_id, hdb_filing_date, hdb_units,
    hdb_bbl, hdb_bin, hdb_address
  )

if (anyDuplicated(missing_root_sites[c("hdb_bbl", "hdb_bin")])) {
  stop("Root-unmatched HDB rows are not unique by BBL and BIN.")
}

later_same_site_candidates <- missing_root_sites |>
  inner_join(
    dob |>
      transmute(
        candidate_root_job_id = dob_root_job_id,
        candidate_filing_id = dob_filing_id,
        candidate_filing_date = dob_filing_date,
        candidate_units = dob_units,
        hdb_bbl = dob_bbl,
        hdb_bin = dob_bin,
        candidate_address = dob_address,
        candidate_filing_status = dob_filing_status,
        candidate_source_pull_date = dob_source_pull_date
      ),
    by = c("hdb_bbl", "hdb_bin"),
    relationship = "one-to-many"
  ) |>
  filter(
    candidate_root_job_id != hdb_root_job_id,
    candidate_filing_date >= hdb_filing_date
  ) |>
  mutate(
    filing_days_after_hdb = as.integer(
      candidate_filing_date - hdb_filing_date
    ),
    exact_address_match = hdb_address == candidate_address
  ) |>
  arrange(hdb_root_job_id, filing_days_after_hdb, candidate_filing_id)

nearest_later_same_site <- later_same_site_candidates |>
  group_by(hdb_root_job_id) |>
  slice_min(
    order_by = filing_days_after_hdb,
    n = 1L,
    with_ties = FALSE
  ) |>
  ungroup() |>
  select(
    hdb_root_job_id,
    later_same_site_root_job_id = candidate_root_job_id,
    later_same_site_filing_id = candidate_filing_id,
    later_same_site_filing_date = candidate_filing_date,
    later_same_site_units = candidate_units,
    later_same_site_filing_days_after_hdb = filing_days_after_hdb,
    later_same_site_exact_address_match = exact_address_match
  )

handoff <- handoff |>
  left_join(
    nearest_later_same_site,
    by = "hdb_root_job_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    exact_root_match = !is.na(dob_filing_id),
    parent_crosswalk_match = !is.na(parent_crosswalk_filing_id),
    hdb_dob_bbl_match = hdb_bbl == dob_bbl,
    hdb_dob_bin_match = hdb_bin == dob_bin,
    hdb_dob_address_match = hdb_address == dob_address,
    audit_status = case_when(
      parent_crosswalk_match ~ "exact_root_in_parent_crosswalk",
      exact_root_match & dob_units < min_units ~
        "exact_root_below_parent_min_units",
      exact_root_match ~ "exact_root_excluded_for_other_reason",
      !is.na(later_same_site_root_job_id) ~
        "no_exact_root_later_same_site_filing",
      TRUE ~ "no_exact_root_or_later_same_site_filing"
    )
  ) |>
  select(
    hdb_root_job_id, hdb_filing_date, hdb_units,
    hdb_bbl, hdb_bin, hdb_address, hdb_job_status,
    exact_root_match, parent_crosswalk_match, audit_status,
    parent_crosswalk_filing_id,
    dob_filing_id, dob_filing_date, dob_units,
    dob_bbl, dob_bin, dob_address, dob_filing_status,
    dob_source_pull_date,
    hdb_dob_bbl_match, hdb_dob_bin_match, hdb_dob_address_match,
    later_same_site_root_job_id, later_same_site_filing_id,
    later_same_site_filing_date, later_same_site_units,
    later_same_site_filing_days_after_hdb,
    later_same_site_exact_address_match
  ) |>
  arrange(hdb_filing_date, hdb_root_job_id)

if (
  nrow(handoff) != nrow(hdb) ||
    sum(handoff$parent_crosswalk_match) > sum(handoff$exact_root_match) ||
    any(
      handoff$parent_crosswalk_match &
        handoff$parent_crosswalk_filing_id != handoff$dob_filing_id,
      na.rm = TRUE
    )
) {
  stop("Identifier handoff failed row-count or nested-match QC.")
}

review <- handoff |>
  filter(!parent_crosswalk_match)

summary <- tibble(
  metric = c(
    "hdb_analysis_rows",
    "exact_root_matches_unfiltered_dob",
    "exact_root_match_rate_unfiltered_dob",
    "exact_root_matches_parent_crosswalk",
    "exact_root_match_rate_parent_crosswalk",
    "exact_root_matches_excluded_below_min_units",
    "exact_root_matches_excluded_other_reason",
    "no_exact_root_match",
    "no_exact_root_with_later_same_site_filing",
    "exact_root_filing_date_mismatches",
    "exact_root_bbl_mismatches",
    "exact_root_bin_mismatches",
    "exact_root_address_mismatches"
  ),
  value = c(
    nrow(handoff),
    sum(handoff$exact_root_match),
    mean(handoff$exact_root_match),
    sum(handoff$parent_crosswalk_match),
    mean(handoff$parent_crosswalk_match),
    sum(
      handoff$audit_status == "exact_root_below_parent_min_units"
    ),
    sum(
      handoff$audit_status == "exact_root_excluded_for_other_reason"
    ),
    sum(!handoff$exact_root_match),
    sum(
      handoff$audit_status ==
        "no_exact_root_later_same_site_filing"
    ),
    sum(
      handoff$exact_root_match &
        handoff$hdb_filing_date != handoff$dob_filing_date,
      na.rm = TRUE
    ),
    sum(
      handoff$exact_root_match & !handoff$hdb_dob_bbl_match,
      na.rm = TRUE
    ),
    sum(
      handoff$exact_root_match & !handoff$hdb_dob_bin_match,
      na.rm = TRUE
    ),
    sum(
      handoff$exact_root_match & !handoff$hdb_dob_address_match,
      na.rm = TRUE
    )
  )
)

write_csv_if_changed(
  later_same_site_candidates,
  "../output/hdb_dob_identifier_later_same_site_candidates.csv"
)
write_csv_if_changed(
  review,
  "../output/hdb_dob_identifier_review.csv"
)
write_csv_if_changed(
  summary,
  "../output/hdb_dob_identifier_summary.csv"
)
write_csv_if_changed(
  handoff,
  "../output/hdb_dob_identifier_handoff.csv"
)

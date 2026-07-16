# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_dob_unit_measurement/code")
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
  stop("Unit-measurement audit arguments are not internally consistent.")
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
    root_job_id = str_squish(job_number),
    hdb_filing_date = as.Date(date_filed),
    hdb_units = as.integer(round(classa_prop)),
    hdb_job_status = job_status,
    hdb_bbl = normalize_bbl_field(bbl),
    hdb_address = str_to_upper(str_squish(address))
  )

hdb_raw <- read_parquet(
  "../input/dcp_housing_database_project_level_raw_25q4.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    root_job_id = str_squish(job_number),
    hdb_raw_units = as.integer(round(classaprop)),
    hdb_hotel_units = as.integer(round(hotelprop)),
    hdb_other_class_b_units = as.integer(round(otherbprop)),
    hdb_proposed_floors = as.numeric(floorsprop),
    hdb_job_description = str_squish(job_desc),
    hdb_date_updated = as.Date(datelstupd),
    dcp_edited_fields = str_to_lower(str_squish(dcpedited))
  )

parent_crosswalk <- read_parquet(
  "../input/post_policy_filing_link_fields.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    root_job_id = str_squish(root_job_id),
    dob_i1_filing_id = str_squish(job_number),
    dob_i1_filing_date = as.Date(filing_date),
    dob_i1_filing_year = as.integer(format(dob_i1_filing_date, "%Y")),
    dob_i1_crosswalk_units = as.integer(round(units))
  )

dob_all <- read_parquet(
  "../input/dob_now_new_building_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble() |>
  transmute(
    root_job_id = str_squish(job_number),
    dob_filing_id = str_squish(job_filing_number),
    dob_filing_type = filing_type,
    dob_filing_date = as.Date(filing_date),
    dob_current_status_date = as.Date(current_status_date),
    dob_units = as.integer(round(proposed_dwelling_units)),
    dob_proposed_floors = as.numeric(proposed_stories),
    dob_filing_status = filing_status,
    dob_job_description = str_squish(job_description),
    dob_source_pull_date = parse_mixed_date(source_pull_date)
  )

if (
  nrow(hdb) == 0L ||
    anyDuplicated(hdb$root_job_id) ||
    anyDuplicated(hdb_raw$root_job_id) ||
    anyDuplicated(parent_crosswalk$root_job_id) ||
    anyDuplicated(
      dob_all |>
        filter(dob_filing_type == "I1") |>
        pull(dob_filing_id)
    )
) {
  stop("A unit-measurement source failed uniqueness or nonempty QC.")
}

comparison <- hdb |>
  inner_join(
    parent_crosswalk,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    hdb_raw,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    dob_all |>
      filter(dob_filing_type == "I1") |>
      transmute(
        dob_i1_filing_id = dob_filing_id,
        dob_i1_units = dob_units,
        dob_i1_proposed_floors = dob_proposed_floors,
        dob_i1_current_status_date = dob_current_status_date,
        dob_i1_filing_status = dob_filing_status,
        dob_i1_job_description = dob_job_description,
        dob_source_pull_date
      ),
    by = "dob_i1_filing_id",
    relationship = "one-to-one"
  )

if (
  any(is.na(comparison$dob_i1_units)) ||
    any(comparison$hdb_units != comparison$hdb_raw_units) ||
    any(comparison$dob_i1_crosswalk_units != comparison$dob_i1_units)
) {
  stop("HDB or DOB units changed unexpectedly across audit inputs.")
}

disagreement_roots <- comparison |>
  filter(hdb_units != dob_i1_units) |>
  select(root_job_id, hdb_units, dob_i1_filing_id)

disagreement_filings <- dob_all |>
  inner_join(
    disagreement_roots,
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    is_initial_filing = dob_filing_id == dob_i1_filing_id,
    filing_reports_hdb_units = dob_units == hdb_units
  ) |>
  arrange(root_job_id, dob_filing_date, dob_filing_id)

if (anyDuplicated(disagreement_filings$dob_filing_id)) {
  stop("A unit-disagreement DOB filing identifier is duplicated.")
}

filing_evidence <- disagreement_filings |>
  group_by(root_job_id) |>
  summarise(
    dob_filing_count = n(),
    dob_distinct_nonmissing_units = n_distinct(
      dob_units[!is.na(dob_units)]
    ),
    dob_units_seen = paste(
      sort(unique(dob_units[!is.na(dob_units)])),
      collapse = ";"
    ),
    another_filing_reports_hdb_units = any(
      !is_initial_filing & filing_reports_hdb_units,
      na.rm = TRUE
    ),
    filings_reporting_hdb_units = paste(
      dob_filing_id[filing_reports_hdb_units],
      collapse = ";"
    ),
    .groups = "drop"
  )

comparison <- comparison |>
  left_join(
    filing_evidence,
    by = "root_job_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    unit_match = hdb_units == dob_i1_units,
    unit_difference = hdb_units - dob_i1_units,
    absolute_unit_difference = abs(unit_difference),
    hdb_exact_99 = hdb_units == 99L,
    dob_i1_exact_99 = dob_i1_units == 99L,
    exact_99_classification_match = hdb_exact_99 == dob_i1_exact_99,
    dcp_class_a_edit = str_detect(
      coalesce(dcp_edited_fields, ""),
      "(^|/)classa_prop(/|$)"
    ),
    hdb_class_b_units = coalesce(hdb_hotel_units, 0L) +
      coalesce(hdb_other_class_b_units, 0L),
    hdb_plus_class_b_equals_dob_i1 =
      hdb_units + hdb_class_b_units == dob_i1_units,
    description_changed = str_to_upper(
      coalesce(hdb_job_description, "")
    ) != str_to_upper(coalesce(dob_i1_job_description, "")),
    proposed_floors_changed = hdb_proposed_floors !=
      dob_i1_proposed_floors,
    dob_record_postdates_hdb = dob_i1_current_status_date >
      hdb_date_updated,
    evidence_category = case_when(
      unit_match ~ "unit_agreement",
      dcp_class_a_edit ~ "dcp_class_a_edit",
      another_filing_reports_hdb_units ~ "filing_level_conflict",
      description_changed | proposed_floors_changed ~
        "cross_vintage_design_revision",
      TRUE ~ "unresolved_cross_vintage_unit_difference"
    ),
    measurement_implication = case_when(
      unit_match ~ "same unit count",
      dcp_class_a_edit ~
        "HDB explicitly edits the applicant count to Class A units",
      another_filing_reports_hdb_units ~
        "the same DOB root contains conflicting filing-level counts",
      description_changed | proposed_floors_changed ~
        "the HDB and current DOB records describe different design vintages",
      TRUE ~
        "the available snapshots do not reveal when or why the count changed"
    ),
    recommended_primary_units = hdb_units,
    recommended_sensitivity_units = dob_i1_units
  ) |>
  arrange(hdb_filing_date, root_job_id)

disagreements <- comparison |>
  filter(!unit_match) |>
  arrange(
    desc(hdb_exact_99 != dob_i1_exact_99),
    desc(absolute_unit_difference),
    root_job_id
  )

exact_99_disagreements <- disagreements |>
  filter(!exact_99_classification_match)

parent_2025_units <- parent_crosswalk |>
  filter(dob_i1_filing_year == post_year) |>
  left_join(
    hdb |>
      select(root_job_id, hdb_units),
    by = "root_job_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    hdb_priority_units = coalesce(hdb_units, dob_i1_crosswalk_units)
  )

category_counts <- disagreements |>
  count(evidence_category, name = "value") |>
  transmute(
    metric = paste0("disagreements_", evidence_category),
    value = as.numeric(value)
  )

summary <- bind_rows(
  tibble(
    metric = c(
      "hdb_analysis_rows",
      "exact_root_matched_rows",
      "unit_agreements",
      "unit_disagreements",
      "unit_disagreement_rate",
      "hdb_units_matched_total",
      "dob_i1_units_matched_total",
      "hdb_minus_dob_i1_units_matched_total",
      "hdb_units_lower_than_dob_i1",
      "hdb_units_higher_than_dob_i1",
      "median_absolute_unit_disagreement",
      "mean_absolute_unit_disagreement",
      "absolute_unit_disagreements_equal_1",
      "absolute_unit_disagreements_2_to_5",
      "absolute_unit_disagreements_6_to_15",
      "absolute_unit_disagreements_16_or_more",
      "hdb_exact_99_rows",
      "dob_i1_exact_99_rows",
      "exact_99_classification_disagreements",
      "dob_i1_exact_99_rows_full_parent_2025",
      "hdb_priority_exact_99_rows_full_parent_2025"
    ),
    value = c(
      nrow(hdb),
      nrow(comparison),
      sum(comparison$unit_match),
      nrow(disagreements),
      mean(!comparison$unit_match),
      sum(comparison$hdb_units),
      sum(comparison$dob_i1_units),
      sum(comparison$unit_difference),
      sum(disagreements$unit_difference < 0L),
      sum(disagreements$unit_difference > 0L),
      median(disagreements$absolute_unit_difference),
      mean(disagreements$absolute_unit_difference),
      sum(disagreements$absolute_unit_difference == 1L),
      sum(
        disagreements$absolute_unit_difference >= 2L &
          disagreements$absolute_unit_difference <= 5L
      ),
      sum(
        disagreements$absolute_unit_difference >= 6L &
          disagreements$absolute_unit_difference <= 15L
      ),
      sum(disagreements$absolute_unit_difference >= 16L),
      sum(comparison$hdb_exact_99),
      sum(comparison$dob_i1_exact_99),
      nrow(exact_99_disagreements),
      sum(parent_2025_units$dob_i1_crosswalk_units == 99L),
      sum(parent_2025_units$hdb_priority_units == 99L)
    )
  ),
  category_counts
)

write_csv_if_changed(
  disagreement_filings,
  "../output/hdb_dob_unit_disagreement_filings.csv"
)
write_csv_if_changed(
  exact_99_disagreements,
  "../output/hdb_dob_exact_99_disagreements.csv"
)
write_csv_if_changed(
  disagreements,
  "../output/hdb_dob_unit_disagreements.csv"
)
write_csv_if_changed(
  summary,
  "../output/hdb_dob_unit_measurement_summary.csv"
)
write_csv_if_changed(
  comparison,
  "../output/hdb_dob_unit_comparison.csv"
)

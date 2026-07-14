# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_dob_now_new_building_filings/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

file_manifest <- read_csv(
  "../input/dob_now_new_building_filing_files.csv",
  show_col_types = FALSE,
  na = c("", "NA")
)

if (
  nrow(file_manifest) != 2L ||
    !setequal(
      file_manifest$file_role,
      c("initial_new_building_filings_2016_2026", "new_building_amendments_2024_2026")
    ) ||
    any(!file.exists(file_manifest$raw_path))
) {
  stop("Expected available initial-filing and amendment DOB NOW extracts.")
}

raw_filings <- bind_rows(lapply(file_manifest$raw_path, function(path) {
  read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(.default = col_character()),
    na = c("", "NA")
  )
}))

required_columns <- c(
  "job_filing_number", "filing_status", "house_no", "street_name",
  "borough", "block", "lot", "bin", "initial_cost",
  "total_construction_floor_area", "existing_dwelling_units",
  "proposed_no_of_stories", "proposed_height", "proposed_dwelling_units",
  "filing_date", "job_type", "bbl"
)

missing_columns <- setdiff(required_columns, names(raw_filings))

if (length(missing_columns) > 0L) {
  stop("Raw DOB NOW extract is missing columns: ", paste(missing_columns, collapse = ", "))
}

duplicate_job_filing_numbers <- raw_filings |>
  count(job_filing_number, name = "rows") |>
  filter(rows > 1L)

staged_filings <- raw_filings |>
  transmute(
    source_row_number = row_number(),
    source_id = unique(file_manifest$source_id),
    source_pull_date = unique(file_manifest$pull_date),
    job_filing_number = str_squish(job_filing_number),
    job_number = str_remove(str_squish(job_filing_number), "-[A-Z][0-9]+$"),
    filing_type = str_extract(str_squish(job_filing_number), "(?<=-)[A-Z][0-9]+$"),
    filing_status = str_squish(filing_status),
    job_type = str_squish(job_type),
    filing_date = parse_mixed_date(filing_date),
    current_status_date = parse_mixed_date(current_status_date),
    first_permit_date = parse_mixed_date(first_permit_date),
    approved_date = parse_mixed_date(approved_date),
    signoff_date = parse_mixed_date(signoff_date),
    borough_code = standardize_borough_code(borough),
    borough_name = standardize_borough_name(borough),
    block = suppressWarnings(as.integer(block)),
    lot = suppressWarnings(as.integer(lot)),
    bbl_reported = normalize_bbl_field(bbl),
    bbl_built = build_bbl(borough, block, lot),
    bin = str_squish(bin),
    house_number = str_squish(house_no),
    street_name = str_squish(street_name),
    address = combine_address(house_no, street_name),
    community_district = standardize_community_district(borough, commmunity_board),
    council_district = standardize_council_district(council_district),
    nta = str_squish(nta),
    postcode = str_squish(postcode),
    latitude = suppressWarnings(as.numeric(latitude)),
    longitude = suppressWarnings(as.numeric(longitude)),
    filing_review_type = str_squish(filing_review_type),
    building_type = str_squish(building_type),
    existing_stories = parse_number(existing_stories),
    existing_height = parse_number(existing_height),
    existing_dwelling_units = parse_number(existing_dwelling_units),
    proposed_stories = parse_number(proposed_no_of_stories),
    proposed_height = parse_number(proposed_height),
    proposed_dwelling_units = parse_number(proposed_dwelling_units),
    initial_cost = parse_number(initial_cost),
    total_construction_floor_area = parse_number(total_construction_floor_area),
    applicant_professional_title = str_squish(applicant_professional_title),
    applicant_license = str_squish(applicant_license),
    applicant_first_name = str_squish(applicant_first_name),
    applicant_middle_initial = str_squish(applicants_middle_initial),
    applicant_last_name = str_squish(applicant_last_name),
    applicant_business_name = str_squish(applicant_business_name),
    owner_business_name = str_squish(owner_s_business_name),
    owner_first_name = str_squish(owner_first_name),
    owner_last_name = str_squish(owner_last_name),
    owner_type = str_squish(owner_type),
    job_description = str_squish(job_description)
  ) |>
  mutate(
    bbl = coalesce(bbl_reported, bbl_built),
    bbl_source = case_when(
      !is.na(bbl_reported) ~ "reported_bbl",
      !is.na(bbl_built) ~ "built_from_borough_block_lot",
      TRUE ~ "missing_bbl"
    )
  ) |>
  select(-bbl_reported, -bbl_built) |>
  arrange(filing_date, job_filing_number)

initial_filings <- staged_filings |>
  filter(filing_type == "I1")

duplicate_initial_job_numbers <- initial_filings |>
  count(job_number, name = "rows") |>
  filter(rows > 1L)

if (nrow(duplicate_initial_job_numbers) > 0L) {
  stop("DOB NOW initial job_number is not unique.")
}

staging_qc <- tibble(
  source_id = file_manifest$source_id[1],
  source_pull_date = file_manifest$pull_date[1],
  source_rows = nrow(raw_filings),
  staged_filing_rows = nrow(staged_filings),
  staged_initial_rows = nrow(initial_filings),
  duplicate_job_filing_numbers = nrow(duplicate_job_filing_numbers),
  duplicate_initial_job_numbers = nrow(duplicate_initial_job_numbers),
  missing_filing_date = sum(is.na(initial_filings$filing_date)),
  missing_or_nonpositive_proposed_units = sum(
    is.na(initial_filings$proposed_dwelling_units) |
      initial_filings$proposed_dwelling_units <= 0
  ),
  noninteger_proposed_units = sum(
    !is.na(initial_filings$proposed_dwelling_units) &
      abs(initial_filings$proposed_dwelling_units - round(initial_filings$proposed_dwelling_units)) > 1e-8
  ),
  missing_bbl = sum(is.na(initial_filings$bbl)),
  missing_bin = sum(is.na(initial_filings$bin) | initial_filings$bin == ""),
  missing_or_nonpositive_total_construction_floor_area = sum(
    is.na(initial_filings$total_construction_floor_area) |
      initial_filings$total_construction_floor_area <= 0
  ),
  first_filing_date = safe_min_date(initial_filings$filing_date),
  last_filing_date = safe_max_date(initial_filings$filing_date)
)

write_parquet_if_changed(
  staged_filings,
  "../output/dob_now_new_building_filings.parquet"
)

write_parquet_if_changed(
  initial_filings,
  "../output/dob_now_new_building_initial_filings.parquet"
)

write_csv_if_changed(
  staging_qc,
  "../output/dob_now_new_building_initial_filings_qc.csv"
)

cat("Wrote staged DOB NOW New Building filing history and initial filings to ../output\n")

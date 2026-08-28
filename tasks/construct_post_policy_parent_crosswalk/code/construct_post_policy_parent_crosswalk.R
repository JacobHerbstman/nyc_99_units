# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_post_policy_parent_crosswalk/code")
# start_year <- 2022L
# end_year <- 2026L
# min_units <- 6L
# max_units <- 1000L

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 4L) {
  stop(
    "Expected four arguments: start year, end year, minimum units, ",
    "and maximum units."
  )
}

start_year <- as.integer(args[1])
end_year <- as.integer(args[2])
min_units <- as.integer(args[3])
max_units <- as.integer(args[4])

if (
  any(is.na(c(start_year, end_year, min_units, max_units))) ||
    start_year > end_year ||
    min_units < 1L ||
    min_units > max_units
) {
  stop("Post-policy filing-link arguments are not internally consistent.")
}

dob_initial <- read_parquet(
  "../input/dob_now_new_building_initial_filings.parquet"
) |>
  as.data.frame() |>
  as_tibble()

appbbl_crosswalk <- read_csv(
  "../input/mappluto_appbbl_crosswalk.csv",
  show_col_types = FALSE,
  col_types = cols(
    current_bbl = col_character(),
    appbbl = col_character(),
    .default = col_guess()
  )
) |>
  mutate(
    current_bbl = normalize_bbl_field(current_bbl),
    appbbl = normalize_bbl_field(appbbl)
  )

if (anyDuplicated(appbbl_crosswalk$current_bbl)) {
  stop("APPBBL crosswalk is not unique by current BBL.")
}

filing_link_fields <- dob_initial |>
  mutate(
    filing_year = as.integer(format(filing_date, "%Y")),
    integer_units = !is.na(proposed_dwelling_units) &
      abs(proposed_dwelling_units - round(proposed_dwelling_units)) < 1e-8,
    filing_bbl = normalize_bbl_field(bbl),
    owner_business_clean = na_if(str_squish(owner_business_name), ""),
    owner_business_clean = if_else(
      str_to_upper(owner_business_clean) %in%
        c("N/A", "NA", "NONE", "NOT APPLICABLE"),
      NA_character_,
      owner_business_clean
    ),
    owner_name = coalesce(
      owner_business_clean,
      na_if(str_squish(paste(owner_first_name, owner_last_name)), "")
    ),
    owner_match_key = str_squish(
      str_replace_all(str_to_upper(owner_name), "[^A-Z0-9]+", " ")
    )
  ) |>
  filter(
    job_type == "New Building",
    filing_year >= start_year,
    filing_year <= end_year,
    integer_units,
    proposed_dwelling_units >= min_units,
    proposed_dwelling_units <= max_units
  ) |>
  transmute(
    root_job_id = str_squish(job_number),
    job_number = str_squish(job_filing_number),
    filing_date,
    filing_year,
    units = as.integer(round(proposed_dwelling_units)),
    filing_bbl,
    owner_match_key = na_if(owner_match_key, ""),
    description_referenced_job_id = str_remove(
      str_extract(
        str_to_upper(job_description),
        "(?<![A-Z0-9])(?:[BMQRSX][0-9]{8}|[1-5][0-9]{8})(?:-I[0-9]+)?"
      ),
      "-I[0-9]+$"
    ),
    description_project_code = str_remove_all(
      str_extract(str_to_upper(job_description), "MPP\\s*[0-9]+"),
      "\\s"
    )
  ) |>
  left_join(
    appbbl_crosswalk |>
      select(
        filing_bbl = current_bbl,
        historical_appbbl = appbbl,
        appbbl_date_min = appdate_min
      ),
    by = "filing_bbl",
    relationship = "many-to-one"
  ) |>
  mutate(
    lot_history_group_bbl = coalesce(historical_appbbl, filing_bbl),
    appbbl_change_after_filing =
      !is.na(appbbl_date_min) & appbbl_date_min > filing_date
  ) |>
  arrange(filing_date, root_job_id)

if (
  nrow(filing_link_fields) == 0L ||
    any(is.na(filing_link_fields$root_job_id)) ||
    anyDuplicated(filing_link_fields$root_job_id) ||
    anyDuplicated(filing_link_fields$job_number)
) {
  stop("Post-policy filing-link fields failed identifier QC.")
}

write_parquet_if_changed(
  filing_link_fields,
  "../output/post_policy_filing_link_fields.parquet"
)

cat("Wrote post-policy filing-link fields to ../output\n")

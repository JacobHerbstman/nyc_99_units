# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_parent_cohorts/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})
source("../../shared/code/source_pipeline_utils.R")
source("../../shared/code/write_data_report.R")

# The post-policy linkage universe: DOB NOW initial New Building filings from
# 2022 through 2026 proposing 6 to 1,000 units. 2022-2024 filings are padding,
# so companions of early 2025 filings can be found.
crosswalk <- read_csv("../input/mappluto_appbbl_crosswalk.csv", col_types = cols(current_bbl = col_character(),
  appbbl = col_character(), appdate = col_date(), same_boro_block = col_logical()))
stopifnot(!anyDuplicated(crosswalk$current_bbl))

owner_placeholders <- c("N/A", "NA", "NONE", "NOT APPLICABLE")
filings <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  mutate(filing_year = as.integer(format(filing_date, "%Y")),
    owner_business = na_if(str_squish(owner_business_name), ""),
    owner_business = if_else(str_to_upper(owner_business) %in% owner_placeholders, NA_character_, owner_business),
    owner_name = coalesce(owner_business, na_if(str_squish(paste(owner_first_name, owner_last_name)), ""))) |>
  filter(job_type == "New Building", filing_year >= 2022L, filing_year <= 2026L,
    abs(proposed_dwelling_units - round(proposed_dwelling_units)) < 1e-8,
    proposed_dwelling_units >= 6, proposed_dwelling_units <= 1000) |>
  transmute(root_job_id = str_squish(job_number), job_number = str_squish(job_filing_number), filing_date,
    filing_year, units = as.integer(round(proposed_dwelling_units)), filing_bbl = normalize_bbl_field(filing_bbl),
    site_linkage_bbl = coalesce(normalize_bbl_field(reported_bbl), filing_bbl),
    owner_match_key = na_if(str_squish(str_replace_all(str_to_upper(owner_name), "[^A-Z0-9]+", " ")), ""),
    description_referenced_job_id = str_remove(str_extract(str_to_upper(job_description),
      "(?<![A-Z0-9])(?:[BMQRSX][0-9]{8}|[1-5][0-9]{8})(?:-I[0-9]+)?"), "-I[0-9]+$"),
    description_project_code = str_remove_all(str_extract(str_to_upper(job_description), "MPP\\s*[0-9]+"), "\\s")) |>
  # The former lot recorded in PLUTO 25v4 groups lot histories; a lot change
  # recorded after the filing is flagged.
  left_join(crosswalk |> select(site_linkage_bbl = current_bbl, historical_appbbl = appbbl, appdate),
    by = "site_linkage_bbl", relationship = "many-to-one") |>
  mutate(lot_history_group_bbl = coalesce(historical_appbbl, site_linkage_bbl),
    appbbl_change_after_filing = coalesce(appdate > filing_date, FALSE)) |>
  select(-appdate) |>
  arrange(filing_date, root_job_id)
stopifnot(!anyNA(filings$root_job_id), !anyDuplicated(filings$root_job_id), !anyDuplicated(filings$job_number))

SaveData(filings, NULL, "../output/post_policy_filing_link_fields.parquet")

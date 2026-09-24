# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_companion_rules/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})
source("../../../shared/code/write_data_report.R")

# Every filing in parent membership, with the owner and applicant named on its
# own application. DOB NOW jobs (both periods) take these fields from the DOB NOW
# extract; older BIS jobs (historical filings through 2020) from the BIS
# application file. The same fields and normalization apply in both periods.
membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  filter(additive_component, units > 0) |>
  transmute(sample, parent_id, job_number, root_job_id, date_filed = as.Date(date_filed),
    units, filing_bbl)
stopifnot(!anyDuplicated(membership[c("sample", "job_number")]))

dob_now <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(root_job_id = job_number, owner_business = owner_business_name,
    owner_person = paste(owner_first_name, owner_last_name),
    applicant_license, dob_latitude = as.numeric(latitude), dob_longitude = as.numeric(longitude))
stopifnot(!anyDuplicated(dob_now$root_job_id))

# A BIS job appears once per dataset refresh; keep the earliest capture, closest
# to the filing. Owners agree across captures for more than 99 percent of jobs.
bis <- read_csv("../input/dob_bis_nb_initial_filings.csv", col_types = cols(.default = col_character())) |>
  arrange(job__, dobrundate) |>
  distinct(job__, .keep_all = TRUE) |>
  transmute(root_job_id = job__, owner_business = owner_s_business_name,
    owner_person = paste(owner_s_first_name, owner_s_last_name),
    applicant_license = applicant_license__,
    bis_latitude = as.numeric(gis_latitude), bis_longitude = as.numeric(gis_longitude))

# Housing Database coordinates come from one geocoder in both periods.
hdb <- bind_rows(
  read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet") |>
    transmute(sample = "historical", root_job_id = job_number,
      hdb_latitude = as.numeric(latitude), hdb_longitude = as.numeric(longitude)),
  read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
    transmute(sample = "post_policy", root_job_id = as.character(job_number),
      hdb_latitude = as.numeric(latitude), hdb_longitude = as.numeric(longitude))
)
stopifnot(!anyDuplicated(hdb[c("sample", "root_job_id")]))

normalize_owner <- function(x) {
  x <- str_to_upper(coalesce(x, ""))
  x <- str_replace_all(x, "[^A-Z0-9 ]", " ")
  x <- str_replace_all(x, "\\b(L L C|LLC|INC|INCORPORATED|CORP|CORPORATION|CO|COMPANY|LP|L P|LTD|THE)\\b", " ")
  na_if(str_squish(x), "")
}

# Placeholders and public agencies do not identify a developer: agencies sponsor
# many unrelated projects.
non_identifying <- "^(OWNER|OWNERS|NA|N A|NONE|PR|PRIVATE|NOT APPLICABLE|TBD|UNKNOWN|SAME|X)$"
public_agency <- paste0("HPD|HOUSING PRESERVATION|NYCHA|HOUSING AUTHORITY|SCHOOL CONSTRUCTION|",
  "DCAS|CITY OF NEW YORK|NYC DEPT|NYC DEPARTMENT|DEPARTMENT OF|NYCEDC|ECONOMIC DEVELOPMENT CORP|",
  "HOUSING DEVELOPMENT CORP|STATE OF NEW YORK|NYS |METROPOLITAN TRANSPORTATION|PORT AUTHORITY")

identity <- membership |>
  mutate(dob_now_job = str_detect(root_job_id, "^[A-Z][0-9]")) |>
  left_join(dob_now, by = "root_job_id", relationship = "many-to-one") |>
  left_join(bis |> rename_with(~ paste0(.x, "_bis"), c(owner_business, owner_person, applicant_license)),
    by = "root_job_id", relationship = "many-to-one") |>
  left_join(hdb, by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  mutate(
    identity_source = case_when(
      dob_now_job & !is.na(applicant_license) ~ "dob_now",
      !dob_now_job & !is.na(applicant_license_bis) ~ "bis",
      TRUE ~ "missing"),
    owner_business = if_else(dob_now_job, owner_business, owner_business_bis),
    owner_person = if_else(dob_now_job, owner_person, owner_person_bis),
    applicant_license = if_else(dob_now_job, applicant_license, applicant_license_bis),
    owner_key = normalize_owner(owner_business),
    owner_person_key = normalize_owner(owner_person),
    public_owner = coalesce(str_detect(owner_key, public_agency), FALSE),
    owner_key = if_else(public_owner | coalesce(str_detect(owner_key, non_identifying), FALSE),
      NA_character_, owner_key),
    owner_person_key = if_else(coalesce(str_detect(owner_person_key, non_identifying), FALSE) |
      coalesce(nchar(owner_person_key) < 5, TRUE), NA_character_, owner_person_key),
    applicant_license = na_if(str_remove(str_squish(applicant_license), "^0+"), ""),
    latitude = coalesce(hdb_latitude, dob_latitude, bis_latitude),
    longitude = coalesce(hdb_longitude, dob_longitude, bis_longitude),
    coordinate_source = case_when(!is.na(hdb_latitude) ~ "hdb", !is.na(dob_latitude) ~ "dob_now",
      !is.na(bis_latitude) ~ "bis", TRUE ~ "missing"),
    block = substr(filing_bbl, 1, 6)
  ) |>
  # People who sign as owner for a public agency are agency staff: their names
  # link unrelated city-sponsored sites, so they do not identify a developer.
  mutate(agency_signer = owner_person_key %in% owner_person_key[public_owner],
    owner_person_key = if_else(agency_signer, NA_character_, owner_person_key)) |>
  select(sample, parent_id, job_number, root_job_id, date_filed, units, filing_bbl, block,
    latitude, longitude, coordinate_source, identity_source, owner_key, owner_person_key,
    applicant_license, public_owner)

SaveData(identity, c("sample", "job_number"), "../output/filing_identity.parquet")

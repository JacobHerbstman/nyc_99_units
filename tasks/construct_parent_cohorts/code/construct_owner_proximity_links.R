# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/construct_parent_cohorts/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(purrr)
  library(readr)
  library(sf)
  library(stringr)
})
source("../../shared/code/write_data_report.R")

# Companion filings on separate, non-adjacent lots: the same owner, nearby, and
# filed within a year. Both periods use the owner named on each filing's own
# application: DOB NOW applications for DOB NOW jobs, and BIS applications for
# older jobs (historical filings through 2020). audit_companion_rules tests the
# rule and records a hand review of its links.
max_days <- 365L
max_metres <- 150
max_block_metres <- 200

filings <- bind_rows(
  read_parquet("../input/historical_parent_filing_link_fields.parquet") |>
    filter(filing_year >= 2010L, filing_year <= 2023L) |>
    transmute(sample = "historical", job_number, root_job_id = job_number,
      date_filed, filing_bbl),
  read_parquet("../output/post_policy_filing_link_fields.parquet") |>
    transmute(sample = "post_policy", job_number, root_job_id,
      date_filed = filing_date, filing_bbl)
)
stopifnot(!anyDuplicated(filings[c("sample", "job_number")]))

dob_now <- read_parquet("../input/dob_now_new_building_initial_filings.parquet") |>
  transmute(root_job_id = job_number, owner_business = owner_business_name,
    owner_person = paste(owner_first_name, owner_last_name),
    dob_latitude = as.numeric(latitude), dob_longitude = as.numeric(longitude))
stopifnot(!anyDuplicated(dob_now$root_job_id))

# A BIS job appears once per dataset refresh; keep the earliest capture, closest
# to the filing. Owners agree across captures for more than 99 percent of jobs.
bis <- read_csv("../input/dob_bis_nb_initial_filings.csv", col_types = cols(.default = col_character())) |>
  arrange(job__, dobrundate) |>
  distinct(job__, .keep_all = TRUE) |>
  transmute(root_job_id = job__, owner_business_bis = owner_s_business_name,
    owner_person_bis = paste(owner_s_first_name, owner_s_last_name))

# Housing Database coordinates come from one geocoder in both periods.
hdb <- bind_rows(
  read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet") |>
    transmute(sample = "historical", root_job_id = job_number,
      latitude = as.numeric(latitude), longitude = as.numeric(longitude)),
  read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
    transmute(sample = "post_policy", root_job_id = as.character(job_number),
      latitude = as.numeric(latitude), longitude = as.numeric(longitude))
)
stopifnot(!anyDuplicated(hdb[c("sample", "root_job_id")]))

normalize_owner <- function(x) {
  x <- str_to_upper(coalesce(x, ""))
  x <- str_replace_all(x, "[^A-Z0-9 ]", " ")
  x <- str_replace_all(x, "\\b(L L C|LLC|INC|INCORPORATED|CORP|CORPORATION|CO|COMPANY|LP|L P|LTD|THE)\\b", " ")
  na_if(str_squish(x), "")
}

# Placeholders and public agencies do not identify a developer; nor do people
# who sign as owner for an agency, whose names link unrelated city sites.
placeholder <- "^(OWNER|OWNERS|NA|N A|NONE|PR|PRIVATE|NOT APPLICABLE|TBD|UNKNOWN|SAME|X)$"
public_agency <- paste0("HPD|HOUSING PRESERVATION|NYCHA|HOUSING AUTHORITY|SCHOOL CONSTRUCTION|",
  "DCAS|CITY OF NEW YORK|NYC DEPT|NYC DEPARTMENT|DEPARTMENT OF|NYCEDC|ECONOMIC DEVELOPMENT CORP|",
  "HOUSING DEVELOPMENT CORP|STATE OF NEW YORK|NYS |METROPOLITAN TRANSPORTATION|PORT AUTHORITY")

identity <- filings |>
  mutate(dob_now_job = str_detect(root_job_id, "^[A-Z][0-9]")) |>
  left_join(dob_now, by = "root_job_id", relationship = "many-to-one") |>
  left_join(bis, by = "root_job_id", relationship = "many-to-one") |>
  left_join(hdb, by = c("sample", "root_job_id"), relationship = "one-to-one") |>
  mutate(
    owner_key = normalize_owner(if_else(dob_now_job, owner_business, owner_business_bis)),
    person_key = normalize_owner(if_else(dob_now_job, owner_person, owner_person_bis)),
    public_owner = coalesce(str_detect(owner_key, public_agency), FALSE),
    owner_key = if_else(public_owner | coalesce(str_detect(owner_key, placeholder), FALSE),
      NA_character_, owner_key),
    person_key = if_else(coalesce(str_detect(person_key, placeholder), FALSE) |
      coalesce(nchar(person_key) < 5, TRUE), NA_character_, person_key),
    latitude = coalesce(latitude, dob_latitude),
    longitude = coalesce(longitude, dob_longitude),
    block = substr(filing_bbl, 1, 6)
  ) |>
  mutate(person_key = if_else(person_key %in% person_key[public_owner], NA_character_, person_key)) |>
  filter(!is.na(latitude), !is.na(longitude), !is.na(owner_key) | !is.na(person_key))

# Pairs within 150 metres, or on the same tax block within 200 metres, filed
# within a year. The block limit keeps separate projects on very large blocks
# apart (for example Beitel's 261-315 Grand Concourse and 120 East 144th Street).
points <- identity |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
  st_transform(2263)
block_reach_feet <- max_block_metres / 0.3048
links <- map_dfr(split(points, points$sample), function(group) {
  near <- st_is_within_distance(group, group, dist = block_reach_feet)
  pairs <- tibble(i = rep(seq_along(near), lengths(near)), j = unlist(near)) |> filter(i < j)
  a <- st_drop_geometry(group)[pairs$i, ]
  b <- st_drop_geometry(group)[pairs$j, ]
  tibble(
    sample = a$sample, job_number_1 = a$job_number, job_number_2 = b$job_number,
    distance_metres = as.numeric(st_distance(group[pairs$i, ], group[pairs$j, ], by_element = TRUE)) * 0.3048,
    days_apart = abs(as.integer(a$date_filed - b$date_filed)),
    same_block = coalesce(a$block == b$block, FALSE),
    same_owner_business = coalesce(a$owner_key == b$owner_key, FALSE),
    same_owner_person = coalesce(a$person_key == b$person_key, FALSE)
  )
}) |>
  filter(same_owner_business | same_owner_person,
    distance_metres <= max_metres | (same_block & distance_metres <= max_block_metres),
    days_apart <= max_days)

SaveData(links, c("sample", "job_number_1", "job_number_2"), "../output/owner_proximity_links.parquet")

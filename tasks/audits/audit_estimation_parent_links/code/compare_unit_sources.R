# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_estimation_parent_links/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

parents <- read_parquet("../input/parent_opportunity_panel.parquet")
membership <- read_parquet("../input/symmetric_parent_membership.parquet")
dob <- read_parquet("../input/dob_now_new_building_initial_filings.parquet")
hdb_historical <- read_parquet("../input/dcp_housing_database_project_level_raw_23q4.parquet") |>
  select(job_number, addressnum, addressst, classaprop, datelstupd, floorsprop) |>
  mutate(across(c(classaprop, floorsprop), as.numeric),
    datelstupd = as.Date(datelstupd), sample = "historical", hdb_release = "23Q4")
hdb_post <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
  select(job_number, addressnum, addressst, classaprop, datelstupd, floorsprop) |>
  mutate(across(c(classaprop, floorsprop), as.numeric),
    datelstupd = as.Date(datelstupd), sample = "post_policy", hdb_release = "25Q4")
hdb <- bind_rows(hdb_historical, hdb_post)
stopifnot(!anyDuplicated(parents$parent_id),
  !anyDuplicated(membership[c("sample", "root_job_id")]),
  !anyDuplicated(dob$job_number), !anyDuplicated(hdb[c("sample", "job_number")]))

# Compare the same retained buildings, dates and classifications against sources.
filings <- membership |>
  filter(additive_component) |>
  inner_join(parents |> select(parent_id, included_ab, composition_eligible),
    by = "parent_id", relationship = "many-to-one") |>
  select(sample, parent_id, root_job_id, date_filed, original_filing_date,
    refiled, refiling_date, current_units = units, hdb_priority_units,
    unit_source, included_ab, composition_eligible) |>
  left_join(dob |> transmute(root_job_id = job_number, dob_address = address,
    dob_i1_units = proposed_dwelling_units, dob_status_date = current_status_date,
    dob_stories = proposed_stories, dob_floor_area = total_construction_floor_area),
    by = "root_job_id", relationship = "many-to-one") |>
  left_join(hdb |> transmute(sample, root_job_id = job_number, hdb_release,
    hdb_address = paste(addressnum, addressst), hdb_units = classaprop,
    hdb_update_date = datelstupd, hdb_stories = floorsprop),
    by = c("sample", "root_job_id"), relationship = "many-to-one") |>
  mutate(address = if_else(sample == "historical", hdb_address, coalesce(dob_address, hdb_address)),
    dob_available = !is.na(dob_i1_units),
    dob_change = dob_i1_units - current_units,
    # Explicit partial-coverage sensitivity, never labeled a DOB-only panel.
    available_dob_units = coalesce(dob_i1_units, as.numeric(current_units))) |>
  arrange(sample, parent_id, root_job_id)
stopifnot(all(filings$dob_i1_units[filings$dob_available] >= 0),
  all(filings$dob_available[filings$sample == "post_policy"]))

comparison <- filings |>
  group_by(sample, parent_id) |>
  summarise(current_total = sum(current_units),
    current_vector = paste(sort(current_units, decreasing = TRUE), collapse = "+"),
    n_components = n(), dob_components = sum(dob_available),
    dob_complete = all(dob_available),
    dob_total = sum(dob_i1_units),
    available_dob_total = sum(available_dob_units),
    available_dob_vector = paste(sort(available_dob_units, decreasing = TRUE), collapse = "+"),
    current_99x2 = n() == 2L && all(current_units == 99),
    available_dob_99x2 = n() == 2L && all(available_dob_units == 99),
    current_99x3 = n() == 3L && all(current_units == 99),
    available_dob_99x3 = n() == 3L && all(available_dob_units == 99),
    .groups = "drop") |>
  left_join(parents |> select(parent_id, parent_total_units, included_ab,
    composition_eligible, cohort_date, borough, component_addresses),
    by = "parent_id", relationship = "one-to-one") |>
  mutate(available_dob_change = available_dob_total - current_total) |>
  arrange(sample, parent_id)
stopifnot(nrow(comparison) == nrow(parents),
  all(comparison$current_total == comparison$parent_total_units),
  all(is.na(comparison$dob_total) == !comparison$dob_complete),
  sum(comparison$current_total) == sum(filings$current_units),
  sum(comparison$available_dob_total) == sum(filings$available_dob_units))
SaveData(filings, c("sample", "root_job_id"), "../output/dob_unit_filings.csv")
SaveData(comparison, c("sample", "parent_id"), "../output/dob_unit_parents.csv")

print(filings |> filter(included_ab) |> group_by(sample) |>
  summarise(filings = n(), matched = sum(dob_available),
    changed = sum(dob_change != 0, na.rm = TRUE),
    total_current_units = sum(current_units), dob_where_available = sum(available_dob_units),
    current_99 = sum(current_units == 99), dob_99 = sum(available_dob_units == 99),
    current_50_plus = sum(current_units >= 50), dob_50_plus = sum(available_dob_units >= 50)), width = 180)
print(comparison |> filter(included_ab) |> group_by(sample) |>
  summarise(parents = n(), complete = sum(dob_complete),
    changed = sum(available_dob_change != 0),
    current_50_plus = sum(current_total >= 50), dob_50_plus = sum(available_dob_total >= 50),
    current_99x2 = sum(current_99x2), dob_99x2 = sum(available_dob_99x2),
    current_99x3 = sum(current_99x3), dob_99x3 = sum(available_dob_99x3)), width = 180)

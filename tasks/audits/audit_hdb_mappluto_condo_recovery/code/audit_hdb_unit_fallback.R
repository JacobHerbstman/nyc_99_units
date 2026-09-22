# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
source("../../../shared/code/write_data_report.R")

constituents <- read_parquet("../input/constituent_filing_panel.parquet") |>
  filter(included_ab) |>
  select(sample, parent_id, root_job_id, address, date_filed, constituent_units,
    parent_total_units, exposure_status)
members <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  select(sample, parent_id, root_job_id, unit_source, dob_i1_units)
hdb <- read_parquet("../input/dcp_housing_database_project_level_raw_25q4.parquet") |>
  transmute(root_job_id = as.character(job_number), hdb_classa_units = classaprop,
    hdb_hotel_rooms = hotelprop, hdb_other_class_b = otherbprop,
    hdb_description = job_desc, hdb_status = job_status, hdb_version = version)

# A known HDB zero differs from an absent HDB record. Retain every matched
# fallback, including positive Class A counts, to expose source-priority gaps.
fallback <- constituents |>
  left_join(members, by = c("sample", "parent_id", "root_job_id"), relationship = "one-to-one") |>
  filter(unit_source == "dob_i1") |>
  inner_join(hdb, by = "root_job_id", relationship = "many-to-one") |>
  mutate(unit_difference = constituent_units - hdb_classa_units,
    zero_class_a = !is.na(hdb_classa_units) & hdb_classa_units == 0) |>
  arrange(sample, parent_id, root_job_id)

SaveData(fallback, c("sample", "parent_id", "root_job_id"), "../output/hdb_unit_fallback.csv")

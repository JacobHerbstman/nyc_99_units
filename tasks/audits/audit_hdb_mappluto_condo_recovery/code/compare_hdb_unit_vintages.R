# setwd("~/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")
library(arrow)
library(dplyr)
library(readr)
source("../../../shared/code/write_data_report.R")

# These are named members of DCP's complete 23Q4 archive. Keep inactive
# records visible: being absent from the active file does not mean zero units.
old_active <- read_csv(unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010.csv"),
  col_types = cols(.default = col_character()))
old_all <- read_csv(unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010_inactive_included.csv"),
  col_types = cols(.default = col_character()))
current <- read_parquet("../input/dcp_housing_database_project_level_25q4.parquet")
filings <- read_parquet("../input/constituent_filing_panel.parquet") |>
  filter(sample == "historical")
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  transmute(parent_id, weighting_sample = included_ab & parent_total_units >= 50 & composition_eligible)
stopifnot(!anyDuplicated(old_active$Job_Number), !anyDuplicated(old_all$Job_Number),
  !anyDuplicated(current$job_number), !anyDuplicated(filings$root_job_id),
  all(old_all$Version == "23Q4"), all(old_active$Job_Number %in% old_all$Job_Number),
  identical(old_active$ClassAProp, old_all$ClassAProp[match(old_active$Job_Number, old_all$Job_Number)]))

earlier <- old_all |>
  transmute(root_job_id = Job_Number, units_23q4 = as.numeric(ClassAProp),
    in_active_23q4 = Job_Number %in% old_active$Job_Number,
    bbl_23q4 = BBL, description_23q4 = Job_Desc, status_23q4 = Job_Status,
    date_filed_23q4 = DateFiled, date_updated_23q4 = DateLstUpd)
comparison <- filings |>
  select(parent_id, root_job_id, address, date_filed, constituent_units) |>
  left_join(earlier, by = "root_job_id", relationship = "one-to-one") |>
  left_join(current |> select(root_job_id = job_number, units_25q4 = classa_prop,
    bbl_25q4 = bbl, date_updated_25q4 = date_updated),
    by = "root_job_id", relationship = "one-to-one") |>
  left_join(parents, by = "parent_id", relationship = "many-to-one") |>
  mutate(change_23q4_to_panel = constituent_units - units_23q4,
    comparison_status = case_when(!root_job_id %in% old_all$Job_Number ~ "Absent from both 23Q4 files",
      is.na(units_23q4) ~ "Missing ClassAProp in 23Q4",
      !in_active_23q4 ~ "Present only in inactive-inclusive 23Q4",
      TRUE ~ "Present in active 23Q4"))
stopifnot(nrow(comparison) == nrow(filings), !anyNA(comparison$weighting_sample))
summary <- bind_rows(comparison |> mutate(universe = "All canonical historical filings"),
  comparison |> filter(weighting_sample) |> mutate(universe = "Current historical weighting sample")) |>
  group_by(universe) |>
  summarise(filings = n(), parents = n_distinct(parent_id),
    matched_active = sum(in_active_23q4, na.rm = TRUE),
    matched_inactive_inclusive = sum(!is.na(units_23q4)),
    changed_filings = sum(change_23q4_to_panel != 0, na.rm = TRUE),
    changed_parents = n_distinct(parent_id[!is.na(change_23q4_to_panel) & change_23q4_to_panel != 0]),
    current_exact99_filings = sum(constituent_units == 99),
    exact99_in_both = sum(constituent_units == 99 & units_23q4 == 99, na.rm = TRUE),
    changed_to99 = sum(constituent_units == 99 & units_23q4 != 99, na.rm = TRUE),
    .groups = "drop")
# These three jobs document the Livingston sequence. The 2024 job is absent
# from the earlier release. Dates below are source dates, not amendment dates.
livingston <- current |>
  filter(job_number %in% c("B00781447", "B00814498", "B01127732")) |>
  transmute(root_job_id = job_number, address, date_filed, units_25q4 = classa_prop,
    bbl_25q4 = bbl, date_updated_25q4 = date_updated) |>
  left_join(earlier, by = "root_job_id", relationship = "one-to-one")
SaveData(comparison, "root_job_id", "../output/historical_unit_vintage_comparison.csv")
SaveData(summary, "universe", "../output/historical_unit_vintage_summary.csv")
SaveData(livingston, "root_job_id", "../output/livingston_hdb_vintages.csv")

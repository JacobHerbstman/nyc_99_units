# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_site_boundaries/code")
suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})
source("../../../shared/code/write_data_report.R")

headers <- read_parquet("../input/dof_transaction_headers.parquet")
lot_actions <- read_parquet("../input/dof_lot_actions.parquet")
condo_actions <- read_parquet("../input/dof_condo_actions.parquet")
unit_actions <- read_parquet("../input/dof_condo_unit_actions.parquet")
condos <- read_parquet("../input/dof_current_condos.parquet")
units <- read_parquet("../input/dof_current_condo_units.parquet")

# DOF repeats the same transaction description on each header lot. The action
# table supplies the complete lot set, including lots absent from the header.
transactions <- headers |>
  transmute(transaction_id = TRANS_NUM, change_date = as.Date(Change_Date),
            change_time = as.POSIXct(Change_Date_N / 1000, origin = "1970-01-01", tz = "UTC"),
            change_type = Change_Type, authority = Auth_for_Change) |>
  distinct()
stopifnot(!anyDuplicated(transactions$transaction_id), !anyNA(transactions$change_date))

actions <- lot_actions |>
  transmute(transaction_id = TRANS_NUM, bbl = BBL, action = Lot_Action) |>
  distinct() |>
  left_join(transactions, by = "transaction_id", relationship = "many-to-one")
stopifnot(!anyNA(actions$change_date), all(str_detect(actions$bbl, "^[1-5][0-9]{9}$")))

# A transaction contains before/after SETS, not pairwise land allocations.
# Explicit New/Dropped actions also appear under DOF's generic editor and Block
# labels. Use those actions, rather than requiring a particular editor label.
events <- actions |>
  group_by(transaction_id, change_date, change_time, change_type, authority) |>
  summarise(
    old_bbls = list(sort(unique(bbl[action %in% c("Affected", "Dropped")]))),
    new_bbls = list(sort(unique(bbl[action %in% c("Affected", "New")]))),
    all_bbls = list(sort(unique(bbl))),
    ordinary_actions = all(action %in% c("Affected", "Dropped", "New")),
    new_or_dropped = any(action %in% c("Dropped", "New")),
    .groups = "drop"
  ) |>
  mutate(reversible = ordinary_actions &
           (new_or_dropped | change_type %in% c("Lot Merger", "Lot Apportionment", "Lot Reconfiguration")) &
           lengths(old_bbls) > 0L & lengths(new_bbls) > 0L) |>
  arrange(desc(change_date), desc(change_time), desc(transaction_id))

# PLUTO supplies the condominium number for billing lots whose condominium
# has since terminated. DOF supplies every base lot for that condominium.
pluto_condos <- read_csv(unz("../input/nyc_pluto_25v4_csv.zip", "pluto_25v4.csv"),
  col_select = c(bbl, condono), show_col_types = FALSE) |>
  transmute(filing_bbl = sprintf("%.0f", bbl),
            borough = substr(filing_bbl, 1, 1), condo_number = as.integer(condono)) |>
  filter(condo_number > 0, as.integer(substr(filing_bbl, 7, 10)) >= 7500)
stopifnot(!anyDuplicated(pluto_condos$filing_bbl))

condo_bases <- condo_actions |>
  transmute(borough = Borough, condo_number = as.integer(Condo_Number), base_bbl = BBL) |>
  distinct() |>
  group_by(borough, condo_number) |>
  summarise(base_bbls = list(sort(unique(base_bbl))), .groups = "drop")
historical_billing_links <- pluto_condos |>
  inner_join(condo_bases, by = c("borough", "condo_number"), relationship = "many-to-one") |>
  select(filing_bbl, base_bbls) |>
  tidyr::unnest_longer(base_bbls, values_to = "base_bbl") |>
  mutate(link_source = "pluto_condo_number_and_dof_history")

# Unit lots can have several base lots. Keep that set explicitly; never expand
# a filing-to-filing join across the separate source tables.
condo_links <- bind_rows(
  condos |> transmute(filing_bbl = CONDO_BILLING_BBL, base_bbl = CONDO_BASE_BBL,
                      link_source = "dof_current_billing"),
  units |> transmute(filing_bbl = UNIT_BBL, base_bbl = CONDO_BASE_BBL,
                     link_source = "dof_current_unit"),
  unit_actions |> transmute(
    filing_bbl = paste0(Borough, str_pad(Block, 5, pad = "0"),
                       str_pad(Condo_Unit, 4, pad = "0")),
    base_bbl = BBL, link_source = "dof_unit_history"),
  historical_billing_links
) |>
  filter(!is.na(filing_bbl), !is.na(base_bbl)) |>
  group_by(filing_bbl, base_bbl) |>
  summarise(link_sources = paste(sort(unique(link_source)), collapse = ";"), .groups = "drop") |>
  mutate(valid_bbl = str_detect(filing_bbl, "^[1-5][0-9]{9}$") &
                    str_detect(base_bbl, "^[1-5][0-9]{9}$")) |>
  arrange(filing_bbl, base_bbl)
# Keep malformed source identifiers in the report; they cannot match a filing.

SaveData(events, "transaction_id", "../output/dof_events.parquet")
SaveData(condo_links, c("filing_bbl", "base_bbl"), "../output/dof_condo_links.parquet")

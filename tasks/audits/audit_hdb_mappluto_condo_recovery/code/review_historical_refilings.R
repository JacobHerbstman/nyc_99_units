# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

source("../../../shared/code/write_data_report.R")
all_jobs <- read_csv(
  unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010_inactive_included.csv"),
  col_types = cols(.default = col_character())
)
active_jobs <- read_csv(
  unz("../input/nychousingdb_23q4_csv.zip", "HousingDB_post2010.csv"),
  col_types = cols(.default = col_character())
)

stopifnot(
  !anyDuplicated(all_jobs$Job_Number),
  !anyDuplicated(active_jobs$Job_Number),
  all(all_jobs$Version == "23Q4"),
  all(active_jobs$Version == "23Q4"),
  all(active_jobs$Job_Number %in% all_jobs$Job_Number),
  identical(
    active_jobs$ClassAProp,
    all_jobs$ClassAProp[match(active_jobs$Job_Number, all_jobs$Job_Number)]
  )
)

proposals <- all_jobs |>
  filter(
    Job_Type == "New Building",
    DateFiled >= "2019-01-01",
    DateFiled <= "2022-12-31",
    !is.na(ClassAProp),
    str_detect(ClassAProp, "^[0-9]+$"),
    as.integer(ClassAProp) >= 6L,
    str_detect(BIN, "^[1-5][0-9]{6}$")
  ) |>
  mutate(filing_date = as.Date(DateFiled))
withdrawn <- proposals |> filter(Job_Status == "9. Withdrawn")

# A source-only screen: each pair shares a valid building identifier and the
# later job is not withdrawn at the 23Q4 snapshot. No current DOB dates enter.
pairs <- bind_rows(lapply(seq_len(nrow(withdrawn)), function(i) {
  earlier <- withdrawn[i, ]
  later <- proposals |>
    filter(
      BIN == earlier$BIN,
      Job_Number != earlier$Job_Number,
      Job_Status != "9. Withdrawn",
      filing_date > earlier$filing_date,
      filing_date <= earlier$filing_date + 365L
    )
  if (nrow(later) == 0L) return(NULL)
  tibble(
    withdrawn_job = earlier$Job_Number,
    later_job = later$Job_Number,
    withdrawn_filed = earlier$DateFiled,
    later_filed = later$DateFiled,
    days_apart = as.integer(later$filing_date - earlier$filing_date),
    withdrawn_units = as.integer(earlier$ClassAProp),
    later_units = as.integer(later$ClassAProp),
    withdrawn_status_23q4 = earlier$Job_Status,
    later_status_23q4 = later$Job_Status,
    later_active_23q4 = later$Job_Number %in% active_jobs$Job_Number,
    bin_23q4 = earlier$BIN,
    withdrawn_bbl_23q4 = earlier$BBL,
    later_bbl_23q4 = later$BBL,
    withdrawn_address_23q4 = str_squish(paste(earlier$AddressNum, earlier$AddressSt)),
    later_address_23q4 = str_squish(paste(later$AddressNum, later$AddressSt)),
    withdrawn_last_updated_23q4 = earlier$DateLstUpd,
    later_last_updated_23q4 = later$DateLstUpd,
    withdrawn_description_23q4 = earlier$Job_Desc,
    later_description_23q4 = later$Job_Desc
  )
}))

stopifnot(nrow(pairs) > 0L, !anyDuplicated(pairs[c("withdrawn_job", "later_job")]))
later_predecessors <- pairs |>
  count(later_job, name = "withdrawn_predecessors")
pairs <- pairs |>
  left_join(later_predecessors, by = "later_job", relationship = "many-to-one") |>
  mutate(
    same_bbl = withdrawn_bbl_23q4 == later_bbl_23q4,
    same_address = withdrawn_address_23q4 == later_address_23q4,
    review_class = case_when(
      withdrawn_predecessors > 1L ~ "shared_successor_review",
      !same_bbl | !same_address ~ "address_or_lot_review",
      !later_active_23q4 ~ "inactive_successor_review",
      TRUE ~ "strict_same_building_alternative"
    )
  ) |>
  arrange(review_class, withdrawn_filed, withdrawn_job, later_job)

SaveData(pairs, c("withdrawn_job", "later_job"),
  "../output/historical_refiling_source_review_2026-09-22.csv")

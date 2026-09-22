# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_hdb_mappluto_condo_recovery/code")

library(dplyr)
library(jsonlite)
library(readr)
source("../../../shared/code/write_data_report.R")

header <- fromJSON("../input/dof_five_blocks_header.json")$features$attributes
lots <- fromJSON("../input/dof_five_blocks_lots_0.json")$features$attributes
applications <- fromJSON("../input/dof_tracker_five_blocks.json")$features$attributes
page_0 <- fromJSON("../input/dof_header_page_0.json")
page_7 <- fromJSON("../input/dof_header_page_7.json")
lot_count <- fromJSON("../input/dof_five_blocks_lots_count.json")$count

# The header repeats transaction metadata for individual lots. Only collapse
# rows whose date, type, and authority are identical within the transaction.
transactions <- header |>
  distinct(TRANS_NUM, Change_Date, Change_Type, Auth_for_Change)
stopifnot(!anyDuplicated(transactions$TRANS_NUM),
          !anyNA(transactions$TRANS_NUM),
          !anyDuplicated(lots[c("TRANS_NUM", "BBL", "Lot_Action")]),
          nrow(lots) == lot_count,
          all(lots$TRANS_NUM %in% transactions$TRANS_NUM))

# Querying the complete transaction retrieves participating lots outside the
# five requested blocks too. Retain them rather than truncating the event.
dof_lot_changes <- lots |>
  left_join(transactions, by = "TRANS_NUM", relationship = "many-to-one") |>
  transmute(
    transaction_id = TRANS_NUM,
    change_date = as.Date(Change_Date),
    change_type = Change_Type,
    borough = Borough_Name,
    block = as.integer(Block),
    lot = as.integer(Lot),
    bbl = BBL,
    lot_action = Lot_Action,
    authority = Auth_for_Change
  ) |>
  arrange(change_date, transaction_id, bbl, lot_action)
stopifnot(nrow(dof_lot_changes) == nrow(lots))

# These are application statuses, distinct from completed tax-map changes.
# Keep the other-lot text as recorded; it contains lists and number ranges.
dof_applications <- applications |>
  transmute(
    snapshot_object_id = OBJECTID,
    primary_bbl = sprintf("%.0f", Borough_Block_Lot),
    other_bbls_as_recorded = Multiple_BBLs,
    application_type = Application_Type,
    received = as.Date(as.POSIXct(Date_Received / 1000, origin = "1970-01-01", tz = "UTC")),
    accepted = as.Date(as.POSIXct(Accepted_Date / 1000, origin = "1970-01-01", tz = "UTC")),
    completed = as.Date(as.POSIXct(Completed_Date / 1000, origin = "1970-01-01", tz = "UTC")),
    status = Status,
    requested_lots = Number_Of_Lots_Requested,
    condo_number = Condo_Number
  ) |>
  arrange(received, snapshot_object_id)

# Test two small pages against the same ordered, unpaginated block query.
stopifnot(isTRUE(page_0$exceededTransferLimit),
          isTRUE(page_7$exceededTransferLimit),
          identical(c(page_0$features$attributes$OBJECTID,
                      page_7$features$attributes$OBJECTID), header$OBJECTID[1:14]))

SaveData(dof_lot_changes, c("transaction_id", "bbl", "lot_action"),
         "../output/dof_lot_changes.csv")
SaveData(dof_applications, "snapshot_object_id", "../output/dof_applications.csv")
cat(nrow(transactions), "transactions;", nrow(lots), "lot-action rows;",
    nrow(applications), "applications. Pagination and join checks passed.\n")

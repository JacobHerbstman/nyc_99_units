# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/source_registry/code")

source_catalog <- read.csv(
  "source_catalog.csv",
  na.strings = c("", "NA"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
manual_manifest <- read.csv(
  "manual_manifest.csv",
  na.strings = c("", "NA"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
archive_requests <- read.csv(
  "archive_requests.csv",
  na.strings = c("", "NA"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

required_source_cols <- c(
  "source_id", "source_name", "access_mode", "official_url", "raw_subdir",
  "expected_filename", "vintage", "unit", "geography_fields", "date_field",
  "start_date", "end_date", "checksum_sha256", "notes"
)
required_manual_cols <- c(
  "source_id", "expected_filename", "download_instructions", "login_required",
  "date_placed", "checksum_sha256", "notes"
)
required_archive_cols <- c(
  "request_id", "custodian", "portal_or_contact", "records_requested",
  "date_range", "submitted_date", "status", "returned_filename", "notes"
)

checks <- data.frame(
  table_name = c("source_catalog", "manual_manifest", "archive_requests"),
  required_columns_present = c(
    all(required_source_cols %in% names(source_catalog)),
    all(required_manual_cols %in% names(manual_manifest)),
    all(required_archive_cols %in% names(archive_requests))
  ),
  unique_primary_key = c(
    !anyDuplicated(source_catalog$source_id),
    !anyDuplicated(paste(manual_manifest$source_id, manual_manifest$expected_filename)),
    !anyDuplicated(archive_requests$request_id)
  ),
  referenced_source_ids_exist = c(
    TRUE,
    all(manual_manifest$source_id %in% source_catalog$source_id),
    TRUE
  ),
  known_access_mode = c(
    all(source_catalog$access_mode %in% c("public_script", "public_manual", "api_script", "agency_request", "archive_request")),
    TRUE,
    TRUE
  ),
  raw_subdir_style = c(
    all(startsWith(source_catalog$raw_subdir, "data_raw/") | startsWith(source_catalog$raw_subdir, "tasks/")),
    TRUE,
    TRUE
  ),
  row_count = c(nrow(source_catalog), nrow(manual_manifest), nrow(archive_requests))
)

write.csv(checks, "../output/source_registry_checks.csv", row.names = FALSE, na = "")

if (!all(checks$required_columns_present) ||
    !all(checks$unique_primary_key) ||
    !all(checks$referenced_source_ids_exist) ||
    !all(checks$known_access_mode) ||
    !all(checks$raw_subdir_style)) {
  stop("Source registry checks failed.")
}

cat("Wrote registry checks to ../output/source_registry_checks.csv\n")

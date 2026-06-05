# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_acris_deed_master/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(stringr)
  library(tibble)
})

source("../../_lib/source_pipeline_utils.R")

parse_acris_number <- function(x) {
  raw_value <- str_squish(as.character(x))
  raw_value[raw_value == ""] <- NA_character_
  parse_number(raw_value, na = c("", "NA", "N/A", "-"))
}

file_manifest <- read_csv("../input/acris_deed_master_files.csv", show_col_types = FALSE, na = c("", "NA"))

master_files <- file_manifest |>
  filter(file_role == "acris_master_deed_partition", row_count > 0, file.exists(raw_path)) |>
  arrange(part_number)

if (nrow(master_files) == 0) {
  stop("No ACRIS DEED master partition files are available to stage.")
}

deed_rows <- list()

for (i in seq_len(nrow(master_files))) {
  raw_rows <- read_csv(master_files$raw_path[i], show_col_types = FALSE, col_types = cols(.default = col_character()))
  names(raw_rows) <- normalize_names(names(raw_rows))

  required_columns <- c(
    "document_id", "record_type", "crfn", "recorded_borough", "doc_type",
    "document_date", "document_amt", "recorded_datetime", "modified_date",
    "percent_trans", "good_through_date"
  )

  missing_columns <- setdiff(required_columns, names(raw_rows))

  if (length(missing_columns) > 0) {
    stop("ACRIS DEED master partition is missing columns: ", paste(missing_columns, collapse = ", "))
  }

  deed_rows[[i]] <- raw_rows |>
    mutate(
      source_id = "dof_acris_real_property_master",
      source_raw_path = master_files$raw_path[i],
      source_row_number = row_number(),
      document_id = str_squish(as.character(document_id)),
      crfn = str_squish(as.character(crfn)),
      record_type = str_squish(as.character(record_type)),
      recorded_borough = standardize_borough_code(recorded_borough),
      doc_type = str_to_upper(str_squish(as.character(doc_type))),
      document_date = parse_mixed_date(document_date),
      document_amt = parse_acris_number(document_amt),
      recorded_datetime = as.POSIXct(parse_date_time(
        recorded_datetime,
        orders = c("ymd HMS", "ymd HM", "ymd", "mdy HMS", "mdy HM", "mdy"),
        tz = "America/New_York"
      )),
      modified_date = as.POSIXct(parse_date_time(
        modified_date,
        orders = c("ymd HMS", "ymd HM", "ymd", "mdy HMS", "mdy HM", "mdy"),
        tz = "America/New_York"
      )),
      percent_trans = parse_acris_number(percent_trans),
      good_through_date = parse_mixed_date(good_through_date),
      document_amt_key = as.character(round(document_amt)),
      document_date_key = format(document_date, "%Y-%m-%d"),
      acris_master_exact_key = paste(recorded_borough, document_date_key, document_amt_key, sep = "::")
    ) |>
    select(
      source_id, source_raw_path, source_row_number,
      document_id, crfn, record_type, recorded_borough, doc_type,
      document_date, document_date_key, document_amt, document_amt_key,
      recorded_datetime, modified_date, percent_trans, good_through_date,
      acris_master_exact_key
    )
}

deed_master_versions <- bind_rows(deed_rows) |>
  filter(doc_type == "DEED", !is.na(document_id), document_id != "") |>
  arrange(document_date, document_id)

if (nrow(deed_master_versions) == 0) {
  stop("No staged ACRIS DEED master rows remain after cleaning.")
}

document_version_counts <- deed_master_versions |>
  group_by(document_id) |>
  summarise(
    master_document_versions = n(),
    master_document_amount_versions = n_distinct(document_amt),
    master_document_latest_good_through_date = if (all(is.na(good_through_date))) as.Date(NA) else max(good_through_date, na.rm = TRUE),
    master_document_latest_modified_date = if (all(is.na(modified_date))) as.POSIXct(NA) else max(modified_date, na.rm = TRUE),
    .groups = "drop"
  )

deed_master <- deed_master_versions |>
  arrange(
    document_id,
    desc(coalesce(good_through_date, as.Date("1900-01-01"))),
    desc(coalesce(modified_date, as.POSIXct("1900-01-01", tz = "America/New_York"))),
    desc(coalesce(recorded_datetime, as.POSIXct("1900-01-01", tz = "America/New_York"))),
    desc(source_raw_path),
    desc(source_row_number)
  ) |>
  group_by(document_id) |>
  mutate(master_version_rank = row_number()) |>
  ungroup() |>
  filter(master_version_rank == 1L) |>
  left_join(document_version_counts, by = "document_id", relationship = "one-to-one") |>
  mutate(
    master_document_conflicting_amount = master_document_amount_versions > 1L,
    selected_master_version_rule = "latest_good_through_then_modified_then_recorded_then_source_row"
  ) |>
  select(
    source_id, source_raw_path, source_row_number, master_version_rank,
    master_document_versions, master_document_amount_versions,
    master_document_conflicting_amount, master_document_latest_good_through_date,
    master_document_latest_modified_date, selected_master_version_rule,
    document_id, crfn, record_type, recorded_borough, doc_type,
    document_date, document_date_key, document_amt, document_amt_key,
    recorded_datetime, modified_date, percent_trans, good_through_date,
    acris_master_exact_key
  ) |>
  arrange(document_date, document_id)

if (anyDuplicated(deed_master$document_id) > 0) {
  stop("Staged ACRIS DEED master document_id is not unique after version selection.")
}

if (sum(!is.na(deed_master$acris_master_exact_key)) == 0) {
  stop("No staged ACRIS DEED master rows have exact matching keys.")
}

write_parquet_if_changed(deed_master, "../output/acris_deed_master.parquet")
cat("Staged ACRIS DEED master to ../output\n")

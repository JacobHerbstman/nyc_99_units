# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_nys_ag_offering_plan_matches/code")
# batch_count <- 27L

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Expected the number of source-query batches.")
}

batch_count <- as.integer(args[1])

if (is.na(batch_count) || batch_count < 1L) {
  stop("Batch count is invalid.")
}

universe <- read_csv(
  "../input/parent_485x_exposure_universe.csv",
  show_col_types = FALSE,
  guess_max = Inf,
  na = c("", "NA"),
  col_types = cols(
    .default = col_guess(),
    parent_id = col_character(),
    root_job_id = col_character()
  )
)

search_batches <- lapply(seq_len(batch_count), function(batch_index) {
  read_csv(
    paste0(
      "../output/nys_ag_offering_plan_search_audit_batch_",
      sprintf("%02d", batch_index),
      ".csv"
    ),
    show_col_types = FALSE,
    guess_max = Inf,
    na = c("", "NA"),
    col_types = cols(
      .default = col_character()
    )
  )
})

match_batches <- lapply(seq_len(batch_count), function(batch_index) {
  read_csv(
    paste0(
      "../output/nys_ag_offering_plan_matches_batch_",
      sprintf("%02d", batch_index),
      ".csv"
    ),
    show_col_types = FALSE,
    guess_max = Inf,
    na = c("", "NA"),
    col_types = cols(
      .default = col_character()
    )
  )
})

search_audit <- bind_rows(search_batches) |>
  mutate(
    search_http_status = as.integer(search_http_status),
    returned_plan_count = as.integer(returned_plan_count)
  ) |>
  arrange(parent_id, root_job_id)

plan_matches <- bind_rows(match_batches) |>
  arrange(parent_id, root_job_id, plan_id)

expected_queries <- universe |>
  filter(!is.na(ag_search_query), ag_search_query != "") |>
  distinct(parent_id, root_job_id, ag_search_query)

if (
  nrow(search_audit) != nrow(expected_queries) ||
    anyDuplicated(search_audit[c("parent_id", "root_job_id")]) ||
    any(search_audit$search_http_status != 200L) ||
    anyDuplicated(plan_matches[c("parent_id", "root_job_id", "plan_id")])
) {
  stop("Combined Attorney General batches failed coverage or identifier QC.")
}

write_csv_if_changed(
  search_audit,
  "../output/nys_ag_offering_plan_search_audit.csv"
)
write_csv_if_changed(
  plan_matches,
  "../output/nys_ag_offering_plan_matches.csv"
)

cat(
  "Combined ",
  batch_count,
  " batches into ",
  nrow(search_audit),
  " address queries and ",
  nrow(plan_matches),
  " returned plans\n",
  sep = ""
)

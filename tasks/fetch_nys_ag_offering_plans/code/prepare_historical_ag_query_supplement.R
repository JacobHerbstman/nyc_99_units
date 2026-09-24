# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_nys_ag_offering_plan_matches/code")
# query_scope <- "broad"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
})

source("../../../shared/code/source_pipeline_utils.R")

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 1L)
  query_scope <- args[1]
}
stopifnot(query_scope %in% c("broad", "companions"))

hdb <- read_parquet("../input/dcp_housing_database_project_level_23q4.parquet")
saved_searches <- read_csv(
  "../../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)

stopifnot(
  !anyDuplicated(hdb$job_number),
  all(hdb$release == "23Q4")
)

if (query_scope == "broad") {
  # Include all contemporaneously recorded 2019-22 six-plus-unit proposals.
  queries <- hdb |>
    filter(
      job_type == "New Building",
      date_filed >= as.Date("2019-01-01"),
      date_filed <= as.Date("2022-12-31"),
      !is.na(classa_prop),
      classa_prop >= 6
    ) |>
    transmute(
      sample = "historical",
      root_job_id = job_number,
      search_query = str_squish(address),
      query_scope = "2019-22_23q4_new_building_six_plus"
    )
  manifest_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_manifest_2019_2022.csv"
  )
} else {
  membership <- read_parquet("../input/symmetric_parent_membership.parquet")
  stopifnot(!anyDuplicated(membership[c("sample", "job_number")]))

  # A 2023 filing can belong to a parent whose first filing was in 2019-22.
  companion_jobs <- membership |>
    filter(
      sample == "historical",
      cohort_date >= as.Date("2019-01-01"),
      cohort_date <= as.Date("2022-12-31"),
      full_window_observed,
      parent_observed_units >= 6,
      date_filed >= as.Date("2023-01-01"),
      date_filed <= as.Date("2023-12-31")
    ) |>
    distinct(job_number)

  if (nrow(anti_join(companion_jobs, hdb, by = "job_number")) > 0L) {
    stop("A 2023 historical companion is absent from the staged 23Q4 Housing Database.")
  }

  queries <- hdb |>
    semi_join(companion_jobs, by = "job_number") |>
    transmute(
      sample = "historical",
      root_job_id = job_number,
      search_query = str_squish(address),
      query_scope = "2023_companion_of_2019-22_parent"
    )
  manifest_path <- paste0(
    "../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/",
    "historical_ag_query_manifest_2023_companions.csv"
  )
}

queries <- queries |> distinct(sample, root_job_id, search_query, .keep_all = TRUE)

missing_addresses <- sum(is.na(queries$search_query) | queries$search_query == "")

saved_keys <- saved_searches |>
  mutate(sample = sub("__.*$", "", parent_id)) |>
  select(sample, root_job_id, search_query) |>
  distinct()

new_queries <- queries |>
  filter(!is.na(search_query), search_query != "") |>
  anti_join(saved_keys, by = c("sample", "root_job_id", "search_query")) |>
  arrange(root_job_id, search_query)

stopifnot(!anyDuplicated(new_queries[c("sample", "root_job_id", "search_query")]))

write_csv_atomic(new_queries, manifest_path)

cat(
  "Scope: ", query_scope,
  "; 23Q4 candidate filings: ", nrow(queries),
  "; missing addresses: ", missing_addresses,
  "; new job/address queries: ", nrow(new_queries), "\n",
  sep = ""
)

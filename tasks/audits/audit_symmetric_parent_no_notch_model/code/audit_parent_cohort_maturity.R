# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_symmetric_parent_no_notch_model/code")
# training_start_year <- 2019L
# training_end_year <- 2022L
# post_year <- 2025L
# maturity_days <- 180L
# maturity_horizons_text <- "0,30,60,90,100,120,180,270,365"

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(tibble)
})

source("../../../_lib/source_pipeline_utils.R")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5L) {
  stop(
    "Expected five arguments: training start and end years, post year, ",
    "maturity days, and comma-separated validation horizons."
  )
}

training_start_year <- as.integer(args[1])
training_end_year <- as.integer(args[2])
post_year <- as.integer(args[3])
maturity_days <- as.integer(args[4])
maturity_horizons_text <- args[5]
maturity_horizons <- as.integer(strsplit(
  maturity_horizons_text,
  ",",
  fixed = TRUE
)[[1]])

if (
  any(is.na(c(
    training_start_year, training_end_year, post_year, maturity_days,
    maturity_horizons
  ))) ||
    training_start_year > training_end_year ||
    post_year <= training_end_year ||
    maturity_days < 1L ||
    any(maturity_horizons < 0L) ||
    anyDuplicated(maturity_horizons) ||
    !all(c(0L, maturity_days, 365L) %in% maturity_horizons)
) {
  stop("Parent-cohort maturity arguments are not internally consistent.")
}

membership <- read_parquet(
  "../input/symmetric_parent_membership.parquet"
) |>
  as.data.frame() |>
  as_tibble()

if (
  nrow(membership) == 0L ||
    anyDuplicated(membership[c("sample", "job_number")]) ||
    any(membership$parent_span_days > 365L)
) {
  stop("The symmetric parent membership failed identifier or span QC.")
}

validation_members <- membership |>
  filter(
    (
      sample == "historical" &
        analysis_status == "historical_fully_observed" &
        cohort_year >= training_start_year &
        cohort_year <= training_end_year
    ) |
      (
        sample == "post_policy" &
          analysis_status == paste0("completed_", post_year, "_cohort") &
          cohort_year == post_year
      )
  ) |>
  mutate(
    sample_group = if_else(
      sample == "historical",
      paste0(
        "historical_", training_start_year, "_", training_end_year,
        "_complete"
      ),
      paste0("completed_", post_year)
    ),
    days_since_anchor = as.integer(date_filed - cohort_date)
  )

validation_parents <- validation_members |>
  distinct(
    sample_group, parent_id,
    final_units = parent_observed_units
  )

classification_rows <- vector("list", length(maturity_horizons))

for (horizon_row in seq_along(maturity_horizons)) {
  horizon_days <- maturity_horizons[horizon_row]

  provisional_parent_units <- validation_members |>
    filter(days_since_anchor <= horizon_days) |>
    group_by(sample_group, parent_id) |>
    summarise(
      provisional_units = sum(hdb_priority_units),
      .groups = "drop"
    )

  classification_rows[[horizon_row]] <- validation_parents |>
    left_join(
      provisional_parent_units,
      by = c("sample_group", "parent_id"),
      relationship = "one-to-one"
    ) |>
    mutate(
      horizon_days,
      provisional_exact_99_flag = provisional_units == 99L,
      final_exact_99_flag = final_units == 99L
    ) |>
    group_by(sample_group, horizon_days) |>
    summarise(
      parents = n(),
      provisional_exact_99 = sum(provisional_exact_99_flag),
      final_exact_99 = sum(final_exact_99_flag),
      false_positive_exact_99 = sum(
        provisional_exact_99_flag & !final_exact_99_flag
      ),
      false_negative_exact_99 = sum(
        !provisional_exact_99_flag & final_exact_99_flag
      ),
      exact_99_classification_disagreements = sum(
        provisional_exact_99_flag != final_exact_99_flag
      ),
      parents_total_changes_after_horizon = sum(
        provisional_units != final_units
      ),
      units_added_after_horizon = sum(final_units - provisional_units),
      .groups = "drop"
    )
}

classification <- bind_rows(classification_rows) |>
  arrange(sample_group, horizon_days)

post_parents <- membership |>
  filter(sample == "post_policy", cohort_year == post_year) |>
  distinct(
    parent_id, cohort_date, source_end_date,
    analysis_status, parent_observed_units
  ) |>
  mutate(
    observed_followup_days = as.integer(source_end_date - cohort_date),
    mature_cohort = observed_followup_days >= maturity_days
  )

maturity_validation <- classification |>
  filter(
    sample_group == paste0("completed_", post_year),
    horizon_days == maturity_days
  )

qc <- tibble(
  check = c(
    "maturity_days",
    "current_post_cohort_parents",
    "minimum_current_post_followup_days",
    "mature_post_cohort_parents",
    "mature_post_exact_99_parent_totals",
    "mature_post_right_censored_exact_99_parent_totals",
    "completed_validation_exact_99_disagreements_at_maturity",
    "completed_validation_parent_totals_changing_after_maturity",
    "completed_validation_units_added_after_maturity",
    "imputed_companions"
  ),
  value = c(
    maturity_days,
    nrow(post_parents),
    min(post_parents$observed_followup_days),
    sum(post_parents$mature_cohort),
    sum(
      post_parents$mature_cohort &
        post_parents$parent_observed_units == 99L
    ),
    sum(
      post_parents$mature_cohort &
        post_parents$analysis_status == paste0(
          "right_censored_", post_year, "_cohort"
        ) &
        post_parents$parent_observed_units == 99L
    ),
    maturity_validation$exact_99_classification_disagreements,
    maturity_validation$parents_total_changes_after_horizon,
    maturity_validation$units_added_after_horizon,
    0L
  )
)

if (
  nrow(validation_parents) == 0L ||
    nrow(maturity_validation) != 1L ||
    any(
      validation_members$days_since_anchor < 0L |
        validation_members$days_since_anchor > 365L
    ) ||
    anyDuplicated(post_parents$parent_id) ||
    anyDuplicated(classification[c("sample_group", "horizon_days")]) ||
    any(is.na(classification$parents)) ||
    any(classification$units_added_after_horizon < 0L) ||
    any(
      classification$horizon_days == 365L &
        classification$exact_99_classification_disagreements != 0L
    ) ||
    sum(post_parents$mature_cohort) == 0L
) {
  stop("Parent-cohort maturity outputs failed final QC.")
}

write_csv_if_changed(
  classification,
  "../output/parent_cohort_maturity_classification.csv"
)
write_csv_if_changed(
  qc,
  "../output/parent_cohort_maturity_qc.csv"
)

cat("Wrote parent-cohort maturity audit to ../output\n")

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_parent_485x_exposure/code")
library(dplyr)
library(readr)
source("../../../shared/code/source_pipeline_utils.R")
parent_exposure <- read_csv("../input/parent_485x_exposure.csv", show_col_types = FALSE)
exposure_summary <- parent_exposure |>
  count(sample, exposure_status, confidence, name = "parents") |>
  arrange(sample, exposure_status, confidence)

exposure_by_unit <- parent_exposure |>
  count(sample, parent_total_units, exposure_status, name = "parents") |>
  arrange(sample, parent_total_units, exposure_status)

review_queue <- parent_exposure |>
  mutate(
    review_priority = case_when(
      sample == "post_policy" & parent_total_units %in% 145L:155L ~
        "post_150_margin",
      sample == "post_policy" & parent_total_units >= 150L &
        exposure_status == "unresolved" ~ "post_150_unresolved",
      sample == "post_policy" & parent_total_units >= 150L &
        confidence != "high" ~ "post_150_low_or_medium",
      parent_total_units %in% 95L:106L ~ "99_margin",
      exposure_status == "unresolved" ~ "unresolved",
      confidence == "low" ~ "low_confidence",
      TRUE ~ NA_character_
    )
  ) |>
  filter(
    !is.na(review_priority)
  ) |>
  arrange(
    factor(
      review_priority,
      levels = c(
        "post_150_margin",
        "post_150_unresolved",
        "post_150_low_or_medium",
        "99_margin",
        "unresolved",
        "low_confidence"
      )
    ),
    sample,
    parent_total_units,
    parent_id
  )

write_csv_atomic(
  exposure_summary,
  "../output/parent_485x_exposure_summary.csv"
)
write_csv_atomic(
  exposure_by_unit,
  "../output/parent_485x_exposure_by_unit.csv"
)
write_csv_atomic(
  review_queue,
  "../output/parent_485x_exposure_review_queue.csv"
)

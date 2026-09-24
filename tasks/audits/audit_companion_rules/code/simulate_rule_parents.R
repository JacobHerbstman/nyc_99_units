# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_companion_rules/code")

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(purrr)
  library(readr)
  library(tidyr)
})
source("../../../shared/code/write_data_report.R")

# Re-form canonical parents under each companion rule and recompute the
# organization outcomes. Links apply only between parents in the canonical
# panel, a merged parent may span at most 365 days from first to last filing
# (the existing parent window), and manually rejected pairs never merge.
pairs <- read_parquet("../output/candidate_pairs.parquet") |> filter(!same_parent)
parents <- read_parquet("../input/parent_opportunity_panel.parquet") |>
  transmute(sample, parent_id, first_date = as.Date(cohort_date),
    last_date = as.Date(parent_last_filing_date), included_ab)
constituents <- read_parquet("../input/constituent_filing_panel.parquet") |>
  transmute(sample, parent_id, constituent_units)
rejected <- read_csv("../input/pair_decisions.csv", show_col_types = FALSE,
  col_types = cols(.default = col_character())) |>
  filter(review_decision == "reject")
membership <- read_parquet("../input/symmetric_parent_membership.parquet") |>
  select(sample, job_number, parent_id)
rejected_parents <- rejected |>
  left_join(membership |> select(sample, job_number_1 = job_number, parent_1 = parent_id),
    by = c("sample", "job_number_1"), relationship = "many-to-one") |>
  left_join(membership |> select(sample, job_number_2 = job_number, parent_2 = parent_id),
    by = c("sample", "job_number_2"), relationship = "many-to-one")

source("rule_definitions.R")

merge_parents <- function(links) {
  group <- setNames(parents$parent_id, parents$parent_id)
  first <- setNames(parents$first_date, parents$parent_id)
  last <- setNames(parents$last_date, parents$parent_id)
  blocked <- paste(rejected_parents$parent_1, rejected_parents$parent_2)
  find <- function(x) { while (group[[x]] != x) x <- group[[x]]; x }
  links <- links |> arrange(first_date, days_apart)
  for (k in seq_len(nrow(links))) {
    a <- find(links$parent_a[k]); b <- find(links$parent_b[k])
    if (a == b || paste(links$parent_a[k], links$parent_b[k]) %in% blocked ||
        paste(links$parent_b[k], links$parent_a[k]) %in% blocked) next
    span_first <- min(first[[a]], first[[b]]); span_last <- max(last[[a]], last[[b]])
    if (as.numeric(span_last - span_first) > 365) next
    group[[b]] <- a; first[[a]] <- span_first; last[[a]] <- span_last
  }
  tibble(parent_id = names(group), merged_id = vapply(names(group), find, character(1)))
}

outcomes <- function(assignment, rule_name) {
  merged <- constituents |>
    left_join(assignment, by = "parent_id", relationship = "many-to-one") |>
    left_join(parents |> select(parent_id, included_ab), by = "parent_id", relationship = "many-to-one") |>
    group_by(sample, merged_id) |>
    summarise(units = sum(constituent_units), buildings = n(),
      buildings_99 = sum(constituent_units == 99), included_ab = any(included_ab),
      source_parents = n_distinct(parent_id), .groups = "drop") |>
    filter(included_ab, units >= 50)
  merged |>
    group_by(sample) |>
    summarise(rule = rule_name, parents = n(), merged_parents = sum(source_parents > 1),
      multi_building_share = mean(buildings > 1), three_plus_share = mean(buildings >= 3),
      exact_99_share = mean(units == 99), exact_99x2 = sum(units == 198 & buildings_99 == 2 & buildings == 2),
      repeated_99 = sum(buildings_99 >= 2), exact_198_share = mean(units == 198), .groups = "drop")
}

baseline <- outcomes(tibble(parent_id = parents$parent_id, merged_id = parents$parent_id), "current links")
simulated <- map_dfr(seq_len(nrow(rules)), function(k) {
  r <- rules[k, ]
  links <- pairs |>
    filter(rule_links(pairs, r$identity_rule, r$space_rule, r$max_days),
      parent_a %in% parents$parent_id, parent_b %in% parents$parent_id)
  outcomes(merge_parents(links), paste(r$identity_rule, r$space_rule, r$max_days))
})

SaveData(bind_rows(baseline, simulated), c("rule", "sample"), "../output/rule_parent_outcomes.csv")

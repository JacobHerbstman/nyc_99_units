# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/analyze_borough_bunching/code")
suppressPackageStartupMessages({library(arrow); library(dplyr); library(readr)})
filings <- read_parquet("../output/geographic_filings.parquet")
parents <- filings |> distinct(sample, parent_id, borough_name, parent_total_units)
observations <- bind_rows(
  filings |> transmute(sample, borough_name, measure = "filings", units = constituent_units),
  parents |> transmute(sample, borough_name, measure = "parents", units = parent_total_units)
) |> filter(units >= 50)
summary <- observations |> group_by(measure, borough_name, sample) |>
  summarise(n_50_plus = n(), n_99 = sum(units == 99),
            n_100_149 = sum(units >= 100 & units <= 149), n_198 = sum(units == 198),
            share_99 = n_99 / n_50_plus, share_100_149 = n_100_149 / n_50_plus,
            share_198 = n_198 / n_50_plus, .groups = "drop") |>
  arrange(measure, borough_name, sample)
stopifnot(nrow(summary) == 20, !anyDuplicated(summary[c("measure", "borough_name", "sample")]))
write_csv(summary, "../output/borough_summary.csv")
print(summary, n = 20)

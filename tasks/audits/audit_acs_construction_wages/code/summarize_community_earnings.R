# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(readr); library(dplyr)})
data <- read_csv("../output/community_district_earnings.csv", col_types = cols(puma = col_character()))
tracts <- read_csv("../output/acs_construction_earnings.csv", show_col_types = FALSE) |> filter(geography == "tract")
independent <- data |> distinct(puma, table, .keep_all = TRUE)
lines <- c("# Community-district construction earnings", "",
  "The 59 community districts are represented by 55 directly published 2019-2023 ACS PUMA estimates. Tract medians were not averaged. District shapes come from the same official NYC source used by nyc_court_case, downloaded into this project's acquisition task.", "",
  "Four pairs share an estimate: Bronx 1+2 and 3+6; Manhattan 1+2 and 5+6. These are the 2020 PUMA definitions, not the older PUMA pairing. All district-to-PUMA assignments follow the official Census names. Boundaries are approximate, so the map assigns the named PUMA's value to each administrative district rather than claiming exact geographic identity.", "",
  "| Universe | Independent PUMAs | Numeric median with MOE | MOE > 50% | Tracts: numeric median with MOE | Tracts: MOE > 50% |",
  "|---|---:|---:|---:|---:|---:|")
for (worker_universe in unique(independent$universe)) {
  p <- independent |> filter(universe == worker_universe)
  t <- tracts |> filter(universe == worker_universe)
  lines <- c(lines, sprintf("| %s | %d | %d | %d | %d / %d | %d |", worker_universe, nrow(p),
                            sum(!is.na(p$earnings) & !is.na(p$moe)), sum(p$imprecise, na.rm = TRUE),
                            sum(!is.na(t$earnings) & !is.na(t$moe)), nrow(t), sum(t$relative_moe > .5, na.rm = TRUE)))
}
lines <- c(lines, "", "## All-employed medians (2023 dollars)", "",
           "| Borough | District(s) represented | Median | 90% MOE |", "|---|---|---:|---:|")
for (i in which(independent$table == "B24031")) {
  lines <- c(lines, sprintf("| %s | %s | $%s | +/- $%s |", independent$borough[i], independent$district_group[i],
                            format(independent$earnings[i], big.mark = ",", trim = TRUE),
                            format(independent$moe[i], big.mark = ",", trim = TRUE)))
}
lines <- c(lines, "", "These larger areas improve availability and precision substantially, but resident earnings still are not local project wages. Do not use paired districts as independent observations, infer an exact tract-to-district aggregation, or treat high-error rankings as precise. The map marks relative MOEs exceeding 50%; this threshold is descriptive.", "",
  "Definitions: https://data.cityofnewyork.us/City-Government/2020-Public-Use-Microdata-Areas-PUMAs-/pikk-p9nv",
  "", "Reproduce with make in tasks/audits/audit_acs_construction_wages/code/. The CSV contains both universes, source PUMA identifiers, paired-group labels, raw annotations, and uncertainty. The main bunching analysis is unchanged.")
writeLines(lines, "../report/community_district_findings.md")

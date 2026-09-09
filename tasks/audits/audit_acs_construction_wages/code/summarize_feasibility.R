# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(readr); library(dplyr)})
data <- read_csv("../output/acs_construction_earnings.csv", show_col_types = FALSE)
county <- data |> filter(geography == "county") |> arrange(universe, borough)
coverage <- data |> filter(geography == "tract") |> group_by(universe) |>
  summarise(tracts = n(), numeric_with_moe = sum(!is.na(earnings) & !is.na(moe)),
            unavailable = sum(estimate_status == "Unavailable"), bounded = sum(estimate_status == "Bounded median"),
            high_moe = sum(relative_moe > .5, na.rm = TRUE), .groups = "drop")
lines <- c("# ACS construction earnings: feasibility findings", "",
  "Tract data can be downloaded, but do not measure the pre-policy hourly cost of labor at a project site. The county medians fit the hypothesized geographic pattern of resident earnings; causal interpretation requires a better measure of employer labor costs.", "",
  "The extraction covers the 2019-2023 ACS five-year window, before 485-x's enactment. Amounts are annual earnings in 2023 dollars. The primary and full-time/year-round universes both describe residents, including all occupations within the construction industry.", "",
  "| Universe | Borough | Median annual earnings | 90% MOE |", "|---|---|---:|---:|")
for (i in seq_len(nrow(county))) {
  lines <- c(lines, sprintf("| %s | %s | $%s | +/- $%s |", county$universe[i], county$borough[i],
                             format(county$earnings[i], big.mark = ",", trim = TRUE),
                             format(county$moe[i], big.mark = ",", trim = TRUE)))
}
lines <- c(lines, "", "## Tract coverage", "",
  "| Universe | Tracts | Numeric median and MOE | Unavailable | Bounded median | MOE > 50% among numeric estimates |", "|---|---:|---:|---:|---:|---:|")
for (i in seq_len(nrow(coverage))) {
  lines <- c(lines, sprintf("| %s | %d | %d | %d | %d | %d (%.1f%%) |", coverage$universe[i], coverage$tracts[i],
                            coverage$numeric_with_moe[i], coverage$unavailable[i], coverage$bounded[i],
                            coverage$high_moe[i], 100 * coverage$high_moe[i] / coverage$numeric_with_moe[i]))
}
lines <- c(lines, "", "This is the first data-report baseline, not a comparison to an earlier extract. All geography/universe keys are unique. Source annotations and Census sentinel codes are retained; bounded/unavailable values are not treated as ordinary numeric medians. All five counties have numeric medians and margins of error for both universes.", "",
  "## What this can establish", "",
  "Lower baseline compensation could make a common required hourly rate more costly to cross. But resident earnings differ with commuting, occupation, hours, weeks, and self-employment. A lower residential-tract median does not establish lower wages on a construction site in that tract. Full-time/year-round earnings still are not hourly rates. Tract missingness and uncertainty make fine rankings particularly fragile.", "",
  "At 100 units the 485-x construction floor is citywide; the official 150+ requirements additionally differ across designated zones. The wage mechanism should therefore be described as a larger gap between baseline job-site compensation and the applicable requirement, not assumed borough differences in a legal prevailing-wage schedule.", "",
  "Public ACS/IPUMS USA microdata identify PUMAs rather than tracts. NHGIS can provide tract summary tables but cannot recover tract-level hourly wages from these public microdata. QCEW county/industry payroll is a possible employer-location benchmark; PUMS can examine individual occupations and hours at coarser geography. Neither alternative has been downloaded here.", "",
  "## Credentials", "",
  "Reused CENSUS_API_KEY through the existing home .Renviron mechanism (owner-only permissions). IPUMS_API_KEY is a separate credential and was not sent or used. No keys are saved in code, arguments, data, reports, or request logs. API request errors are redacted before they reach output.", "",
  "## Reproduce and inspect", "",
  "Run make in tasks/audits/audit_acs_construction_wages/code/. The saved CSV contains both county and tract estimates; filter geography explicitly. Construction earnings and tract precision PDFs show the comparisons. See the task README for definitions, limitations, and primary-source links.")
writeLines(lines, "../report/feasibility.md")

# ACS construction earnings: feasibility findings

Tract data can be downloaded, but do not measure the pre-policy hourly cost of labor at a project site. The county medians fit the hypothesized geographic pattern of resident earnings; causal interpretation requires a better measure of employer labor costs.

The extraction covers the 2019-2023 ACS five-year window, before 485-x's enactment. Amounts are annual earnings in 2023 dollars. The primary and full-time/year-round universes both describe residents, including all occupations within the construction industry.

| Universe | Borough | Median annual earnings | 90% MOE |
|---|---|---:|---:|
| All employed | Bronx | $45,659 | +/- $1,751 |
| All employed | Brooklyn | $46,850 | +/- $1,590 |
| All employed | Manhattan | $69,103 | +/- $8,809 |
| All employed | Queens | $49,614 | +/- $986 |
| All employed | Staten Island | $62,239 | +/- $4,911 |
| Full-time, year-round | Bronx | $50,158 | +/- $2,845 |
| Full-time, year-round | Brooklyn | $57,151 | +/- $2,994 |
| Full-time, year-round | Manhattan | $86,079 | +/- $12,793 |
| Full-time, year-round | Queens | $57,133 | +/- $1,738 |
| Full-time, year-round | Staten Island | $75,214 | +/- $9,616 |

## Tract coverage

| Universe | Tracts | Numeric median and MOE | Unavailable | Bounded median | MOE > 50% among numeric estimates |
|---|---:|---:|---:|---:|---:|
| All employed | 2327 | 1377 | 941 | 9 | 815 (59.2%) |
| Full-time, year-round | 2327 | 1061 | 1264 | 2 | 578 (54.5%) |

This is the first data-report baseline, not a comparison to an earlier extract. All geography/universe keys are unique. Source annotations and Census sentinel codes are retained; bounded/unavailable values are not treated as ordinary numeric medians. All five counties have numeric medians and margins of error for both universes.

## What this can establish

Lower baseline compensation could make a common required hourly rate more costly to cross. But resident earnings differ with commuting, occupation, hours, weeks, and self-employment. A lower residential-tract median does not establish lower wages on a construction site in that tract. Full-time/year-round earnings still are not hourly rates. Tract missingness and uncertainty make fine rankings particularly fragile.

At 100 units the 485-x construction floor is citywide; the official 150+ requirements additionally differ across designated zones. The wage mechanism should therefore be described as a larger gap between baseline job-site compensation and the applicable requirement, not assumed borough differences in a legal prevailing-wage schedule.

Public ACS/IPUMS USA microdata identify PUMAs rather than tracts. NHGIS can provide tract summary tables but cannot recover tract-level hourly wages from these public microdata. QCEW county/industry payroll is a possible employer-location benchmark; PUMS can examine individual occupations and hours at coarser geography. Neither alternative has been downloaded here.

## Credentials

Reused CENSUS_API_KEY through the existing home .Renviron mechanism (owner-only permissions). IPUMS_API_KEY is a separate credential and was not sent or used. No keys are saved in code, arguments, data, reports, or request logs. API request errors are redacted before they reach output.

## Reproduce and inspect

Run make in tasks/audits/audit_acs_construction_wages/code/. The saved CSV contains both county and tract estimates; filter geography explicitly. Construction earnings and tract precision PDFs show the comparisons. See the task README for definitions, limitations, and primary-source links.

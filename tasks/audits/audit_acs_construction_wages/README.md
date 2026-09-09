# Can tract ACS earnings explain geographic bunching?

This feasibility audit checks whether pre-policy construction earnings are
available finely enough to investigate geographic variation in 99-unit bunching.
It does not change the main sample, fit a causal model, or label residence-based
earnings as project labor costs. The hypothesis is that a common wage floor has
a larger cost effect where baseline job-site compensation was lower.

Inputs are the Census API's 2019–2023 ACS five-year construction-industry medians,
90% margins of error, and annotations for all NYC tracts and the five counties.
B24031 covers civilian employed residents age 16+; B24041 covers full-time,
year-round employed residents. The five-year window is entirely before 2024,
but includes a pandemic period and 2023 beyond our 2019–2022 filing comparison.

Run `make` in `code/`. The saved CSV is long by geography, GEOID, and worker
universe. Raw values/annotations survive cleaning. Bounded medians and unavailable
values are distinguished; negative Census sentinel codes never become earnings.
A relative margin of error greater than 50% is a transparent descriptive warning,
not an official Census suppression rule or a filter imposed on the main sample.
The borough plot uses directly published county medians, never an average of
tract medians. The tract coverage chart includes every returned tract, including
tracts where construction earnings cannot be estimated.

Main outputs: `acs_construction_earnings.csv`, `construction_earnings.pdf`,
`tract_precision.pdf`, and `report/feasibility.md`. The standard data report is
`report/acs_construction_earnings.txt`. Source acquisition and its reports live
in the sibling `fetch_acs_construction_earnings` audit task. The shared reporting
helper serves both tasks; existing audit Make infrastructure is retained.

## Interpretation and alternatives

Annual earnings vary with weeks/hours worked, occupation, and self-employment;
they are not a legal prevailing-wage schedule, hourly wages, or total benefits.
The full-time, year-round table narrows hours variation but does not eliminate it.
Residents can work in other boroughs, and construction-industry workers include
managers and office staff. Assigning the resident median to a nearby project
would not establish that project's baseline labor cost. Neither annual median
should be divided by 2,080 and presented as an observed hourly wage.

IPUMS USA/ACS public microdata allow construction-worker restrictions and
individual earnings/hours calculations, but identify PUMAs, not census tracts.
PUMAs contain at least 100,000 people. IPUMS NHGIS supplies tract summary tables,
not finer individual earnings records. The Census and IPUMS API keys are separate;
only the Census key is needed for this audit. Credential details are documented
in the source task without values.

A next step would be to compare pre-policy construction payroll by employer
location using QCEW county/industry data, and use PUMS to separate occupations and
hours at a coarser geography. QCEW establishment location also need not identify
the job site of a mobile construction crew. Neither alternative has been pulled
in this audit. Borough bunching by itself does not identify the wage mechanism.

## Sources checked September 8, 2026

- ACS B24031: https://api.census.gov/data/2023/acs/acs5/groups/B24031.html
- ACS B24041: https://api.census.gov/data/2023/acs/acs5/groups/B24041.html
- ACS variable annotations: https://www.census.gov/data/developers/data-sets/acs-1year/notes-on-acs-api-variable-types.html
- Earnings definition: https://www.census.gov/topics/employment/equal-employment-opportunity-tabulation/about/faq.html
- PUMAs: https://www.census.gov/programs-surveys/geography/guidance/geo-areas/pumas.html
- IPUMS NHGIS: https://developer.ipums.org/docs/v2/apiprogram/apis/nhgis/
- 485-x wage requirements: https://comptroller.nyc.gov/services/for-the-public/workers-rights/485-x/

- QCEW scope: https://www.bls.gov/cew/overview.htm

## Community-district map

Use directly published 2019–2023 PUMA medians for the Census approximations to
community districts, not averages of tract medians. NYC has 59 districts and
55 PUMAs; four district pairs share an estimate. The map shows administrative
district shapes assigned to the PUMA named for each district (an approximation,
not an exact boundary correspondence). The CSV retains the source PUMA and
paired-district label so it cannot be mistaken for 59 independent estimates.
The two-page PDF shows all employed and full-time/year-round earnings on a
common scale and flags imprecise estimates. The existing tract comparison stays
available. Source geography documentation: https://data.cityofnewyork.us/City-Government/2020-Public-Use-Microdata-Areas-PUMAs-/pikk-p9nv

The overlay map places post-period exact-99 constituent filings (January 2025–July 8, 2026) on the same earnings backgrounds. Circles indicate parents totaling 99; triangles indicate filings belonging to larger parents. Locations come from the existing geographic filing panel; missing coordinates remain excluded, and coincident points can overlap.

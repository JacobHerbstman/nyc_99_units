# Community-district construction earnings

The 59 community districts are represented by 55 directly published 2019-2023 ACS PUMA estimates. Tract medians were not averaged. District shapes come from the same official NYC source used by nyc_court_case, downloaded into this project's acquisition task.

Four pairs share an estimate: Bronx 1+2 and 3+6; Manhattan 1+2 and 5+6. These are the 2020 PUMA definitions, not the older PUMA pairing. All district-to-PUMA assignments follow the official Census names. Boundaries are approximate, so the map assigns the named PUMA's value to each administrative district rather than claiming exact geographic identity.

| Universe | Independent PUMAs | Numeric median with MOE | MOE > 50% | Tracts: numeric median with MOE | Tracts: MOE > 50% |
|---|---:|---:|---:|---:|---:|
| All employed | 55 | 55 | 5 | 1377 / 2327 | 815 |
| Full-time, year-round | 55 | 55 | 2 | 1061 / 2327 | 578 |

## All-employed medians (2023 dollars)

| Borough | District(s) represented | Median | 90% MOE |
|---|---|---:|---:|
| Manhattan | 1 & 2 | $107,750 | +/- $47,316 |
| Manhattan | 3 | $46,557 | +/- $10,052 |
| Manhattan | 4 | $122,535 | +/- $82,729 |
| Manhattan | 5 & 6 | $135,176 | +/- $46,347 |
| Manhattan | 7 | $106,768 | +/- $29,202 |
| Manhattan | 8 | $105,217 | +/- $70,352 |
| Manhattan | 9 | $54,080 | +/- $14,865 |
| Manhattan | 10 | $37,875 | +/- $13,033 |
| Manhattan | 11 | $50,133 | +/- $27,670 |
| Manhattan | 12 | $41,773 | +/- $10,665 |
| Bronx | 1 & 2 | $40,894 | +/- $7,909 |
| Bronx | 3 & 6 | $32,268 | +/- $9,107 |
| Bronx | 4 | $47,467 | +/- $6,793 |
| Bronx | 5 | $44,787 | +/- $8,947 |
| Bronx | 7 | $41,187 | +/- $6,372 |
| Bronx | 8 | $57,250 | +/- $20,606 |
| Bronx | 9 | $45,460 | +/- $5,570 |
| Bronx | 10 | $65,403 | +/- $9,847 |
| Bronx | 11 | $53,013 | +/- $6,422 |
| Bronx | 12 | $46,298 | +/- $3,528 |
| Brooklyn | 1 | $47,903 | +/- $6,203 |
| Brooklyn | 2 | $72,623 | +/- $4,546 |
| Brooklyn | 3 | $45,682 | +/- $17,303 |
| Brooklyn | 4 | $47,942 | +/- $12,126 |
| Brooklyn | 5 | $46,096 | +/- $4,631 |
| Brooklyn | 6 | $135,369 | +/- $37,422 |
| Brooklyn | 7 | $35,640 | +/- $2,791 |
| Brooklyn | 8 | $36,845 | +/- $32,314 |
| Brooklyn | 9 | $51,250 | +/- $31,189 |
| Brooklyn | 10 | $48,183 | +/- $6,662 |
| Brooklyn | 11 | $40,561 | +/- $3,822 |
| Brooklyn | 12 | $37,031 | +/- $5,809 |
| Brooklyn | 13 | $51,962 | +/- $10,509 |
| Brooklyn | 14 | $50,562 | +/- $7,673 |
| Brooklyn | 15 | $46,850 | +/- $6,725 |
| Brooklyn | 16 | $47,537 | +/- $7,403 |
| Brooklyn | 17 | $47,228 | +/- $11,960 |
| Brooklyn | 18 | $61,920 | +/- $8,310 |
| Queens | 1 | $58,585 | +/- $5,009 |
| Queens | 2 | $53,633 | +/- $8,901 |
| Queens | 3 | $44,743 | +/- $2,126 |
| Queens | 4 | $41,343 | +/- $1,144 |
| Queens | 5 | $58,093 | +/- $4,200 |
| Queens | 6 | $74,238 | +/- $19,336 |
| Queens | 7 | $48,840 | +/- $3,882 |
| Queens | 8 | $56,107 | +/- $6,200 |
| Queens | 9 | $50,951 | +/- $4,006 |
| Queens | 10 | $52,384 | +/- $12,381 |
| Queens | 11 | $60,716 | +/- $4,922 |
| Queens | 12 | $48,866 | +/- $3,451 |
| Queens | 13 | $64,807 | +/- $9,502 |
| Queens | 14 | $80,511 | +/- $14,548 |
| Staten Island | 1 | $57,509 | +/- $8,916 |
| Staten Island | 2 | $52,401 | +/- $8,922 |
| Staten Island | 3 | $79,555 | +/- $10,760 |

These larger areas improve availability and precision substantially, but resident earnings still are not local project wages. Do not use paired districts as independent observations, infer an exact tract-to-district aggregation, or treat high-error rankings as precise. The map marks relative MOEs exceeding 50%; this threshold is descriptive.

Definitions: https://data.cityofnewyork.us/City-Government/2020-Public-Use-Microdata-Areas-PUMAs-/pikk-p9nv

Reproduce with make in tasks/audits/audit_acs_construction_wages/code/. The CSV contains both universes, source PUMA identifiers, paired-group labels, raw annotations, and uncertainty. The main bunching analysis is unchanged.

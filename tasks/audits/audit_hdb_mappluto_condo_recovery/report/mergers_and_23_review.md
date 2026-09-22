# Five parent mergers and 23 land corrections — September 21, 2026

All five accepted parent mergers are implemented. Of the 23 documented land
corrections reviewed in this batch, **all 23 are applied** following the
September 22 approval. Flatbush, East 125th, St. James, Onderdonk, Jamaica, and
Kingsbrook use explicitly approved, flagged floor estimates or administrative
proxies; see [Flatbush](flatbush_floor_review.md)
and [the subsequent review](five_floor_decisions.md). The broader 126-flag inventory was held for later, apart from the
five explicitly requested merger groups that overlap it.

The production source is `tasks/parent_opportunities_manual/output/`.
`pair_decisions.csv` supplies the five accepted pairs; `site_lot_decisions.csv`
supplies the complete parcel allocations. The main code reads those sources
and the named frozen MapPLUTO releases. Later documents identify observed
ground and locate earlier buildings; they do not backdate ownership or zoning.

## Five implemented mergers

| Development | Canonical parent | Administrative units | Ground, square feet |
| --- | --- | ---: | ---: |
| Godwin/Kimberly | post_policy__X01201390-I1 | 99 + 65 = 164 | 18,441 |
| GO Broome | historical__121207292 | 378 + 117 = 495 | 32,395 |
| Woodside | historical__420665845 | 295 + 183 = 478 | 71,862 |
| Motto | historical__210180533 | 141 + 123 = 264 | 24,880 |
| Elara | post_policy__Q01254595-I1 | 330 + 99 = 429 | 39,003 |

Motto's June 2019 site plan includes the two building lots and ancillary lot 155.
The recorded easement names both exact DOB jobs. The included earlier floor
is 14,579 square feet after excluding 69,357 on retained lot 37. GO Broome's
merger and ground are settled; its separate dated floor-source conflict is
preserved below.

Sources: [Godwin and Elara](site_research_accepted_merger_covariates.md),
[GO Broome and Woodside](accepted_mergers_go_broome_woodside_land.md), and
[Motto](site_research_motto_2026-09-21.md).

## The frozen 23-case inventory

All areas are square feet. Earlier floor estimates and their assumptions are
recorded separately from the documented ground boundaries.

| Development | Previous production ground | Documented ground | Application |
| --- | ---: | ---: | --- |
| Ocean Parkway | 3,000.00 | 20,000.00 | Applied |
| North 8th Street | 12,450.00 | 7,237.85 | Applied |
| East 108th Street | 77,600.00 | 44,200.00 | Applied |
| East 178th Street | 7,696.00 | 7,287.00 | Applied |
| Beach 29/30 | 52,817.00 | 47,365.13 | Applied |
| 165th Street | 23,280.00 | 39,349.50 | Applied; earlier floor estimated |
| Van Cortlandt Park South | 56,560.00 | 56,048.00 | Applied |
| Orchard Street | 25,000.00 | 82,400.00 | Applied |
| 90 Flatbush | 1,198.00 | 12,603.00 | Applied; earlier floor estimated |
| Shell Road | 71,139.00 | 53,978.00 | Applied |
| 27-30 21st Street | 2,500.00 | 5,000.00 | Applied |
| South Street | 31,341.00 | 41,479.00 | Applied |
| Onderdonk | 13,218.00 | 9,310.00 | Applied; earlier floor estimated |
| East 125th Street | 10,092.00 | 42,540.00 | Applied; earlier floor estimated |
| 1440 Amsterdam | 12,490.00 | 24,990.00 | Applied |
| West 48th Street | 57,027.00 | 21,924.00 | Applied |
| 595 Dean | 62,475.00 | 116,535.00 | Applied |
| Casa Celina | 344,900.00 | 12,613.00 | Applied |
| DeKalb/LIU | 355,013.00 | 28,650.00 | Applied |
| 54 Crown | 38,070.00 | 55,385.00 | Applied |
| Penn South | 393,100.00 | 40,261.00 | Applied |
| St. James/Jerome | 46,563.00 | 17,775.00 | Applied; later administrative floor proxy |
| Kingsbrook/Schenectady | 70,562.00 | 105,382.00 | Applied; earlier gross floor estimated |

The evidence reviews retain exact identifiers, source vintages, source pages,
earlier floor areas, and zoning: [seven historical sites](historical_site_covariates_seven.md),
[West 48th](reviewed_west48_covariates.md), [six campus sites](site_research_campus_covariates_2026-09-21.md),
and [nine post-policy sites](site_research_post_correction_covariates.md).

## Judgment queue

All 23 land corrections are applied. The September 22 continuation resolves
the separate GO Broome source conflict below.

**GO Broome: earlier floor area.** The two-filings merger and 32,395-square-foot
whole-parcel ground are supported and applied. The common 19v2 archive records
4,600 square feet of prior floor on old lot 37; 20v1 repeats it. City Planning's
January 21, 2020 decision, page 4, says the synagogue remnants were completely
razed in June 2019, before the November 2019 reference snapshot. Its DEIS also
reports zero existing floor. Following Jacob's instruction on September 22,
production uses zero earlier floor and built FAR, preserving the 32,395 ground
and archived prior-use category. The source table labels the 4,600 deduction
as a documented archive correction. This resolves the dated source conflict.
[Sources and exact archive values](accepted_mergers_go_broome_woodside_land.md).

## Verification

The five-merger batch verification compares against the frozen pre-batch panels.
The subsequent Flatbush verification isolates its adopted correction and new
estimate flag; every other parent and all constituent rows remain unchanged. It checks
all constituent unit/date/refiling/source fields, all memberships outside the
five pairs, every parent outside the five mergers and 23 land targets, and each
adopted area's agreement with the source table. All constituent counts, source priorities, filing dates, and refiling fields
are unchanged. Only the five accepted pair memberships changed. The canonical
panels contain 1,811 historical and 907 post-policy parents, with the same
129,335 and 61,319 units as before. The weighting sample contains 554 historical
and 310 post-policy parents, down by three and two solely from the mergers.

The refreshed site audit marks all five merged developments supported.
Flags fall from 126/869 to 116/864 because ten flagged endpoints become five
supported parents. The five subsequent floor allocations change covariates
and preserve parent membership; their estimate flags remain separate from
this boundary screen.

Reproduce with root `make data`, `make`, `make dof-site-review`,
`make pure-notch-pilot`, and `make logbook`. The existing pilot remains a
provisional diagnostic; this batch changes its data, not its specification.

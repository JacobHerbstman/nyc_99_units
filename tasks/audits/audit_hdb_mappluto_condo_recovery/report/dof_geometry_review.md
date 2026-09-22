# Parcel coverage and changing lot identities

The [full-sample site-allocation follow-up](parent_site_scope_review.md) extends
these checks to all 877 weighting-eligible parents and reports the current
unresolved count. The 166-parent comparison below remains its original cohort.

The 1,198-square-foot input for **90 Flatbush Avenue** describes a small old
parcel, not the later 441-unit tower site. The city documents a replacement
12,603-square-foot tower parcel. DOB names three contributing original tax
lots whose earlier recorded areas sum to 16,531 square feet. The full shared
zoning site is larger still. These are different land definitions, not four
competing measurements of the same boundary.

This audit covers the 166 weighting-sample parents flagged by the DOF history
screen. Its corrected map comparison counts are:

| Map comparison | Historical | Post-policy | Total |
| --- | ---: | ---: | ---: |
| Whole earlier parcels align | 13 | 18 | 31 |
| Later site occupies part of earlier parcels | 102 | 15 | 117 |
| Incomplete later filing-parcel coverage | 0 | 13 | 13 |
| Earlier maps cover less than 98% of the later site | 3 | 0 | 3 |
| Parent spans two reference vintages | 2 | 0 | 2 |
| Total | 120 | 46 | 166 |

The comparison dataset has 168 rows: two mixed-vintage parents retain both
observations. Nine of the 31 whole-parcel matches have additional source/date
flags. Tightening the two-sided area tolerance from 2% to 1% or 0.5% leaves
25 matches, eight with additional flags. Map agreement does not certify a
complete development site or original ownership.

## Correction to the initial map lookup

The first pass reported 32 parents with missing later parcels. It replaced
condominium billing BBLs with physical base BBLs, then looked for those base
identifiers on the later map. MapPLUTO often draws the same land under the
condominium billing number. The code was therefore overlooking available
polygons. The corrected general rule first uses the filing BBL when mapped,
then a documented physical base, then a unique mapped condominium billing
alias for that base. Multiple aliases remain unresolved. All polygons are
counted once within each parent; no nearby parcel is substituted.

This recovers later mapped footprints for **all 19 historical parents** in
that group. Four become whole-parcel matches; fifteen become partial-parcel
comparisons. Thirteen post-policy parents still lack complete later-map
coverage. This changes the audit classification, not production inputs.

The [filing-date follow-up](dof_filing_map_review.md) preserves the original
32-parent physical-base diagnostic. All 19 parents with an archived base-ID
match have subsequent physical DOF transactions involving those identifiers.
A same-number match close to filing cannot establish the later boundary.

## Flatbush: the number 23 describes different parcels over time

DOB job 321595145 is the 441-unit filing in the historical panel. Its current
application page lists original tax lots **18, 23, and 24**, tentative lot 23,
and a zoning site comprising lots 1, 7, 10, 13, and 23. These fields can reflect
amendments; the original filing scan has not been inspected.

| Land definition | Recorded square feet | Evidence |
| --- | ---: | --- |
| Earlier small lot 23 alone | 1,198 | Reference MapPLUTO 18v2_1; current production input |
| Earlier lots 18 + 23 + 24 | 16,531 | DOB original-lot list joined to 18v2_1: 12,240 + 1,198 + 3,093 |
| Replacement tower tax lot 23 | 12,603 | NYCIDA May 2020 resolution; later MapPLUTO billing lot 7502 |
| Shared zoning site | 61,399 | Current DOB application zoning fields |

On **February 12, 2020**, DOF merger 88954 combines lots 9, 11, 13, 18, 23,
and 24 into lot 13; apportionment 88955 then divides lot 13 into lots 13 and
23. The second transaction creates a replacement lot 23 with a different
boundary. September 2021 condominium records connect the tower base lot to
the later condominium. The dated 2008 and 2020 tax maps visibly show this
change. Matching the old number 23 alone was misleading.

The corrected spatial overlap independently locates old lots 18, 23, and 24,
exactly matching DOB's original-tax-lot list. Their polygon union is about
17,980 square feet; the later tower polygon is about 12,802. Recorded tax-lot
areas remain separate from mapped polygon areas. The later tower occupies
about 71% of the earlier union, so assigning all three earlier lots also needs
a decision about the economic site and shared land.

[NYCIDA's May 12, 2020 minutes](https://publicmarkets.nyc/sites/default/files/2020-08/IDA%20Board%20of%20Directors%20Meeting%20Minutes%20May%2012%202020.pdf),
PDF page 41, distinguish the 12,603-square-foot tower site from a
26,981-square-foot school site; page 49 identifies tower lot 23 and school
lot 13. The larger zoning site therefore cannot automatically be assigned to
this one residential parent. The [source record](../../download_parent_review_documents/code/filing_sites_2026-09-16/README.md)
preserves the PDFs, URLs, transcription method, and original-scan access limit.

## What the remaining differences mean

For the 117 partial-parcel sites, the median share of the earlier parcel union
outside the later filing parcels is **45.5%**; 51 have more than half outside.
Summing every overlapping old lot can therefore add substantial land. Whether
that additional land belongs to the economic development must be established
from filing-site coverage and dated parcel changes.

At **46–10 70 Street**, the 305-square-foot production input is also much
smaller than the mapped later condominium parcel. DOB explicitly names
original lots 41, 44, and 50. The spatial overlap additionally includes part
of old lot 9, while the zoning list is broader still. The differing scopes
are retained for review, not collapsed into one replacement area.

At **Sackett**, the administrative anchor supplies later lot 47 alone. It
does not establish the full sale site or the zoning site. At **Noble/Oak**,
proposed lot 10 remains unmapped and the shoreline boundary differs between
releases. Their earlier documentary findings remain in
[dof_area_validation.md](dof_area_validation.md).

The separate DOB comparison uses a fixed capture of 17 filings representing
14 parents. It parses the original lot lists, joins them to their production
reference releases, counts each original parcel once per parent, and preserves
missing old lots. Shared zoning lists are flagged because separate parents
can use the same zoning site. The method is systematic; acquiring the displayed
BIS fields required a browser capture. It is a targeted diagnostic sample,
not a completed validation of every parent's development boundary.

## Reproduction and interpretation

Run `make dof-geometry-review`. The existing audit reads saved MapPLUTO 25v4
and seventeen earlier reference releases. Historical parents retain their
filing-specific reference vintage; post-policy parents retain 23v3_1. All
geometry uses the shoreline-clipped map in EPSG:2263, measured in square feet.
WKT retains 17-digit coordinates; geometry validity and pre/post-repair area
are saved. The nearest-map search separately uses all 23 usable 2018–2023
releases and the frozen September 15, 2026 DOF event snapshot.

The spatial comparison unions each parent's mapped later parcels and
intersects them with earlier parcels in batches by reference vintage.
Intersections above one square foot are retained. An overlap enters the
whole-parcel comparison when it covers at least 1% of either the earlier
parcel or the later site. Alignment allows at most 2% of each union outside
the other. Continuous shares remain available for sensitivity checks.

The outputs are `dof_geometry_lots.parquet`, `dof_geometry_overlaps.parquet`,
`dof_geometry_comparison.csv`, `dof_geometry_summary.csv`, the overview figure,
and a 168-page footprint atlas. `bis_filing_sites.csv` and
`bis_parent_site_comparison.csv` preserve the DOB field comparison. SaveData
writes deterministic data reports; logs and reports are not Make targets.

Production areas, constituent and parent panels, and calibration weights
remain unchanged. The remaining work is to reconstruct the full development
boundary consistently through dated changes and distinguish shared land from
land assigned to each residential parent. The 13 missing later-map cases are
not automatically an individual manual-research list.

## Verification of this update

The build completed, and an unchanged `make -j2 dof-geometry-review` ran no
scripts or downloads. All 99,299 saved parcel/vintage geometries have unique
keys and valid source polygons; WKT preserves their measured areas within
one millionth of a square foot. The comparison retains the same 166 parents.
The 32-parent base-ID cohort, nearest-release choices, subsequent transaction
flags, original-lot sums, shared zoning lists, and missing areas were checked.
Deleting the generated BIS parent comparison and rebuilding reproduced
identical CSV bytes and its SaveData report. A changed-input dry run reran
only the BIS comparison. A failed-download fixture preserved the prior source
file. All four source hashes and all seven baseline production/panel/calibration
hashes matched. The logbook compiled; its updated pages and the Flatbush map
were visually inspected. `git diff --check` passed. Original DOB site drawings
remain unverified because the document viewer did not expose the scan.

# Dated lot identities and full filing-site coverage

An archived map containing the requested lot numbers is not enough to verify
a development's land. The Flatbush investigation establishes why: old lot 23
was dropped and a larger lot 23 was created. The closest old map can therefore
contain the right number with the wrong boundary for the later development.

The corrected [geometry comparison](dof_geometry_review.md) now draws all
19 historical parents previously marked as missing later parcels. Their
polygons exist under condominium billing identifiers on MapPLUTO 25v4.
Thirteen post-policy parents still lack complete later-map coverage. The
32-parent table here is retained as a **physical-base identifier history
check**, not a list of 32 parents still missing current maps.

## The archived-map search

All 23 usable saved MapPLUTO releases from 2018 through 2023 are searched for
each requested physical/base BBL. Every requested lot must occur in one release;
map dates are never combined to make a complete footprint. The closest complete
release to first filing is selected, with an earlier release preferred in a
tie. Dates are internal archive-file dates from the release calendar, not
legal dates of parcel changes.

| Closest complete base-ID map | Historical | Post-policy | Total |
| --- | ---: | ---: | ---: |
| Within 180 days of filing | 18 | 0 | 18 |
| More than a year before filing | 0 | 1 | 1 |
| No complete map under those identifiers | 1 | 12 | 13 |
| Total | 19 | 13 | 32 |

The 18 close maps are 3–100 days from filing, with a median distance of 22.5
days. Twelve precede filing and six follow it. Village Lane's first complete
base-ID release is 38 days after filing. The post-policy match, 27–30 21
Street, is 648 days before filing. These facts describe availability only.

**All 19 parents with an archived base-ID match have later physical DOF
transactions involving those selected identifiers.** The match output retains
the transaction IDs and flags all 19 for dated tracing before interpreting the
old outlines as the later development. Transactions run from after the selected
map date through the frozen September 15, 2026 source snapshot. Some may postdate
MapPLUTO 25v4; the flag asks for tracing and does not assert which boundary each
release already incorporated. It also does not claim every transaction changed
every portion of the mapped site.

This corrects the earlier interpretation of seven apparently aligned maps as
boundary confirmation. Their numeric overlaps remain available, but identity
through time requires the DOF history. Flatbush's old 1,198-square-foot lot is
the clearest example. Its later tower site is independently documented at
12,603 square feet; the broader shared zoning site measures 61,399.

## What DOB's original-lot lists add

A saved browser capture covers **17 filings representing 14 historical
parents**. The script parses DOB's original tax lots being merged/reapportioned,
joins them to the same reference release used by production, and deduplicates
lots within each parent. Eleven parents have positive recorded areas for all
listed original lots: nine sums exceed the production input and two equal it.
The other three retain missing information. Seven parents' original lists
exactly match the material earlier lots identified by spatial overlap.
These are candidate site descriptions, not eleven certified replacement areas.

| Parent | Production area | Sum of listed original lots | Interpretation |
| --- | ---: | ---: | --- |
| 90 Flatbush Avenue | 1,198 | 16,531 | Old lots 18, 23, 24 also match the spatial overlaps; later tower parcel is 12,603 |
| 2686 Broadway | 3,531 | 10,789 | Three original lots match the later mapped footprint |
| 46–10 70 Street | 305 | 40,407 | DOB lists 41, 44, 50; spatial overlap also includes part of old lot 9 |
| 595 Dean Street | 62,475 | 116,535 | Original lots 50 and 100 span more land than the later filing parcel |
| 1018 Beach 20 Street | 6,550 | 54,873 | Three original lots match the material spatial lot set |
| 55 Suffolk / 64 Norfolk Street | 24,957 / 7,438 | 51,879 for the same original-lot set | Shared site cannot be assigned in full to both parents |

All areas are square feet. The Suffolk and Norfolk applications also display
the same 51,884-square-foot zoning area; that is a separate source from the
51,879 sum of earlier tax-lot records. The applications use different street
addresses from some Housing Database parent labels; job numbers carry the
link. Sharing a zoning list does not authorize merging economic parents.

At Snediker, two listed original lots are absent from the reference release.
Village Lane has three missing or nonpositive original-lot areas and an
original list spanning several phases. Bay Street's original-tax-lot field
is blank. Their original-area sums remain missing; a zoning total is not used
as a fallback. For the paired 45/46 Street filings, repeated original parcels
are counted once in the parent total.

The DOB pages show current application details and may include amendments.
The original filed diagrams have not been inspected. Their listed original
lots help identify land needing reconstruction, but may describe a larger
shared development or only portions of original parcels. The browser capture
is frozen and documented in the [source record](../../download_parent_review_documents/code/filing_sites_2026-09-16/README.md);
it is not represented as an automated DOB API download. Subsequent page
requests were denied, so original-plan review remains incomplete.

## Reproduction and remaining work

Run `make dof-geometry-review`. `read_dof_filing_maps.R` produces 704 dated
parcel geometries; `match_dof_filing_maps.R` produces 736 parent–release
comparisons, 32 parent results, and a 32-page footprint atlas. The retained
base-ID coverage columns keep this diagnostic cohort stable as the current
map lookup improves. `compare_bis_site_lots.R` produces the 17-row filing
table and 14-row parent comparison. SaveData writes their data reports.

Continue reconstruction by matching filing-site lot lists to dated DOF changes
and comparing the resulting boundaries. The model needs a consistent measure
of the parent's pre-existing site, including a treatment of land shared with
other filings or later phases. Neither a primary BBL, every historical ancestor
of that BBL, nor the full zoning area is automatically that measure.
Production areas, parent membership, unit counts, and weights remain unchanged.

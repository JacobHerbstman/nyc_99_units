# Rockaway Village III/IV: ground, prior structures, and zoning

Scope: historical economic parent `historical__420667488`, DOB jobs
420667558 (1626 Village Lane, 354 units), 420667488 (1605 Village Lane,
129 units), and 420667497 (1607 Village Lane, 55 units). The question is the
land and earlier conditions for these 538 units, not the full Rockaway Village
assemblage. No production value or link was changed in this follow-up.

## A measured 2020 site, with one remaining crosswalk

The July 29, 2020 NYS DEC Brownfield Cleanup Program (BCP) application for
*Far Rockaway Project—Phase 3 Development*, site C241245, defines a **124,574
square-foot** boundary on block 15537. Its attachment 1 (PDF p. 24) lists lots
46, 50, 51, 53–60, 112, 128, 130, and portions of 1 and 63. Figure 2 (PDF
p. 127, map dated April 27, 2020) draws that boundary, including the narrow
Redfern lots, a part of the central lot 1, and the lots toward Central Avenue.
The enclosed Montrose ALTA/NSPS survey (PDF p. 128, May 21, 2019, with
fieldwork effective May 9, 2019) independently tabulates the same 124,574
square feet, including **57,474** square feet from part of lot 1, **3,971**
from part of lot 63, **6,053** from lot 60, and **27,651** from lots 112/128/130.
The survey's metes-and-bounds description is also reproduced in Appendix A,
PDF pp. 492–493.

This is a plausible **combined-parent ground candidate**, not an adopted
number. The DEC project description (PDF p. 28) proposed three new buildings
with **545 units**, seven more than the three current DOB filings. The saved
BIS fields for all three jobs show the same **124,598-square-foot zoning area**,
just 24 square feet above the survey area, and assign original lots
112/128/130/part 1 to the two smaller filings. That close match is useful
corroboration of a common site; a zoning-area field does not independently
measure physical ground. Appendix B, PDF p. 2, labels the 2018 architectural
site plan “Phase 3” and places Buildings D, H3, and G around the phase site.
The master ground lease of June 12, 2018 (Appendix A, PDF p. 14) has a
different, earlier phase map (Exhibit 1.10, PDF p. 190). Phase names and
building membership therefore need a dated crosswalk, not a name match.

There is also a concrete overlap question. HDC's May 19, 2023 financing
notice (PDF p. 3) describes **Phase V** as including 1626 Village Lane and
**part of lot 60**, while the 2020 DEC survey includes all 6,053 square feet
of then-lot 60. The notice does not map the portion or prove that it overlaps
the exact 2020 survey polygon; it prevents treating 124,574 as a final
allocation to the 538-unit parent without reconciling later phase boundaries.
The broader 642,318-square-foot transaction envelope and the recorded
condominium's 28% ownership share are not substitutes for this crosswalk.

## Earlier buildings and zoning

The May 2019 survey's lot table (application PDF p. 128) records **9,792 square
feet of building footprint**, distributed over then-lots 1 (14), 51 (32), 53
(1,251), 54 (879), 56 (681), 57 (704), 58 (915), 60 (1,663), and 63 (3,653).
It is footprint, **not total building floor area**. At least one surveyed
building could have had more than one story; multiplying or substituting the
footprint would be an unsupported floor estimate. Nor is the whole 9,792
necessarily attributable to the final 538-unit parent if its boundary differs
from the 2020 BCP site.

The locally staged official DCP MapPLUTO **18v2.1** release gives a separate
earlier-floor measure. For the 14 survey lots that are included in full (all
listed lots other than 1 and 63), its `bldgarea` fields sum to **9,076 square
feet**. It records **78,750** on the *whole* earlier lot 1 and **4,500** on the
*whole* earlier lot 63. The survey includes only parts of those two lots, so
neither whole-lot value can be added automatically. The survey's included
footprints on parts of lots 1 and 63 are 14 and 3,653 square feet; they do not
provide a validated split of the MapPLUTO total floor. The 9,076 is a partial
source sum, not the final parent prior-floor covariate.

The DEC application is internally inconsistent about structures at submission.
Its project narrative (PDF p. 28) still mentions vacant houses and a
commercial building requiring demolition. Its later land-use attachment
(PDF p. 122) says operations ceased in early 2019 and **the last building was
demolished in September 2019**; the site-description attachment (PDF p. 37)
also says no structures remain. The dated survey is evidence of pre-demolition
buildings. The application is evidence of zero *standing* building floor at
the May 2020 filings, assuming no construction intervened; that is distinct
from a predevelopment-floor covariate based on the earlier built stock. A
numerical earlier total floor requires a dated DOF or DOB floor record for the
specific lots and a phase-boundary allocation.

The application calls the site **R7-1/C2-4** (PDF pp. 28 and 122), and says it
lies in Sub-District A of the Special Downtown Far Rockaway District (p. 122).
Its Figure 6 (PDF p. 131, dated April 28, 2020) is the accompanying zoning
map. DCP MapPLUTO 18v2.1 records `zonedist1=R7-1`, `overlay1=C2-4`,
`spdist1=DFR`, and **`residfar=3.44` for each of the 16 survey lots**. Thus
3.44 is a consistent contemporaneous *administrative residential-FAR field*
for this candidate site. The final covariate still depends on the III/IV
boundary and the project's rule for using DCP's field versus a separate
special-district calculation.

## Sources and reproduction

All new PDFs are preserved without modification in
`tasks/audits/download_parent_review_documents/code/rockaway_followup_sol_2026-09-22/`.
Physical PDF page numbers above are one-based. SHA-256 values identify the
downloaded bytes:

| File | Publisher, document date, exact URL | SHA-256 |
| --- | --- | --- |
| `dec_c241245_application_20200729.pdf` | NYS DEC, revised application July 29, 2020, [source](https://extapps.dec.ny.gov/data/DecDocs/C241245/Application.BCP.C241245.2020-07-29.complete.pdf) | `4441ba833bb2b79046c6497030b72c03a4d3f161cf7f6fabf0e78ac738cd27eb` |
| `dec_c241245_appendix_a_20200729.pdf` | NYS DEC, attached June 12, 2018 lease and site survey, [source](https://extapps.dec.ny.gov/data/DecDocs/C241245/Application.BCP.C241245.2020-07-29.Appendix_A.pdf) | `40eb29fbb0d9ea7e52e9a9894907a5d7135b6caaf17507567d16d95b230985aa` |
| `dec_c241245_appendix_b_20200729.pdf` | NYS DEC, attached architectural plan dated November 21, 2018, [source](https://extapps.dec.ny.gov/data/DecDocs/C241245/Application.BCP.C241245.2020-07-29.Appendix_B.pdf) | `fe24bb82dccb49c21133dbf6595303fe17e42a6bbe3d3cc57c502dbf4c023e81` |
| `hdc_tefra_20230519.pdf` | NYC HDC, May 19, 2023 hearing notice, [source](https://www.nychdc.com/sites/default/files/2023-05/Notice%20of%20TEFRA%20Hearing%20on%20May%2019%2C%202023%20%20%285.9.23%29.pdf) | `bfb974e4395690662b7a89a9fd22e93259b815ac567fcc32562997c107efba14` |

The DCP data used above are the existing staged file
`tasks/stage_mappluto_lots/output/dcp_mappluto_archive_18v2_1.parquet`, sourced
from DCP's [18v2.1 archive](https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_18v2_1_arc_shp.zip).
The project's `tasks/fetch_mappluto_archive/code/source_files.csv` identifies
that exact source and release. I filtered borough 4, block 15537, and the 16
survey lot numbers; there was one row per lot, and `residfar` was 3.44 in all
16. No staged file was edited.

The pre-existing recorded condo plans
`site_research_next10_2026-09-22/rockaway_condo_maps_2022051300461002.pdf`
(CRFN 2022000210978) fix Building D at 1626 Village Lane (PDF p. 5) and
its units 18/19/20 (pp. 57–58). Their first-floor and cellar areas are
building areas, not the development ground. The pre-existing deed
`rockaway_deed_2024051600214002.pdf` conveys those units but reports ownership
shares across a wider condominium. Both are linked in the prior
`next_ten_boundaries_2026-09-22.md` review.

**Decision for supervision:** retain the existing three-job economic parent;
keep physical land and predevelopment floor unresolved. The measured 124,574
square feet is the leading common-site candidate and 124,598 is a supporting
filed zoning area, but adoption requires overlaying the May 2019/April 2020
survey with the final III/IV and V ground-lease or approved site-plan
boundaries. Use a dated pre-demolition floor record for included structures,
and check the special-district FAR on the resulting geometry. MapPLUTO's
18v2.1 `residfar=3.44` is a documented zoning-field candidate, while its
9,076-square-foot whole-lot partial sum is not a complete earlier floor.

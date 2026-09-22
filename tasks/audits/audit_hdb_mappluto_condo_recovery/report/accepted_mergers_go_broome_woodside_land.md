# GO Broome and Woodside: production land inputs

This note records the original review of the two accepted economic-parent
mergers against primary documents and staged MapPLUTO archives.

**September 22 adopted update:** Both mergers and land boundaries are applied.
GO Broome uses **zero earlier floor**: the CPC records complete June 2019
demolition before the reference snapshot and first filing. The source table
explicitly deducts the stale 4,600 archive value as a documented correction;
its prior-use category remains unchanged. The proposed rows and recommendation
below describe the earlier review, not the current production choice. See the
[implementation and next ten reviews](next_ten_boundaries_2026-09-22.md).

## Proposed component order

| Surviving parent | Component jobs in filing order | Administrative units |
| --- | --- | ---: |
| `historical__121207292` | `121207292;121207522` | 378 + 117 = 495 |
| `historical__420665845` | `420665845;420665952` | 295 + 183 = 478 |

The first job in each row is the earlier filing and therefore the surviving
parent identifier. The filing dates remain March 6 and April 10, 2020 for GO
Broome and June 1 and June 14, 2019 for Woodside.

## GO Broome

The January 21, 2020 City Planning Commission decision for C 200061(A) ZSM,
physical PDF pp. 2–3, calls old Manhattan block 346 lots 37 and 75 the
development site for the two new mixed-use buildings. It distinguishes the
larger 51,884-square-foot zoning lot, which also contains retained Hong Ning
lot 1. The DEIS Chapter 1, physical PDF pp. 2–3 and Figure 1-2 on p. 13, assigns
the Suffolk Building, Norfolk Building, and linked courtyard to lots 37 and 75
and excludes retained lots 1 and 95. The agency's approximate lot areas are
7,443 and 24,958 square feet, totaling 32,401.

The common pre-first-filing **19v2** archive, dated November 22, 2019 in the
audit, supplies the exact administrative inputs:

| Reference BBL | Lot | Recorded area | Building area | Residential FAR | Broad FAR | Zone | Administrative prior use |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `1003460037` | 37 | 7,438 | 4,600 | 6.02 | 6.5 | R8 | public/transport/utility |
| `1003460075` | 75 | 24,957 | 0 | 6.02 | 6.5 | R8 | parking |
| **Group** |  | **32,395** | **4,600** | **6.02** | **6.5** | **R8** | **mixed prior use** |

Both parcels have identical area, building area, zoning, FAR, land-use, and
building-class fields in 20v1, the January 27, 2020 source vintage attached to
the later Norfolk filing. Using 19v2 for the accepted parent is therefore a
common pre-first-filing baseline, not an arbitrary later-vintage substitution.
The grouped row is valid because both source parcels have the same residential
and broad FAR. Its exact 32,395-square-foot administrative total is six square
feet below the DEIS approximation.

There is one source conflict that should remain explicit. The CPC decision,
physical p. 4, says the remnants of the former synagogue on lot 37 were
completely razed in June 2019. The DEIS existing-conditions table on physical
p. 3 reports zero existing gross square feet on lots 37 and 75, with a footnote
about the remnants. Those official statements predate the 19v2 reference date,
but both 19v2 and 20v1 retain 4,600 square feet of administrative `bldgarea` on
lot 37. **Recommendation: keep the frozen 4,600-square-foot administrative
floor value in production and place the agency-observed zero-floor conflict in
the judgment queue for Jacob.** Any later adoption of the agency-observed zero
should be an explicit source-error correction rather than use of
`excluded_building_area_sqft`, which currently means floor area retained
outside the development ground.

**Proposed row:**

| Field | Value |
| --- | --- |
| `sample` | `historical` |
| `parent_id` | `historical__121207292` |
| `expected_component_jobs` | `121207292;121207522` |
| `reference_vintage` | `19v2` |
| `reference_bbls` | `1003460037;1003460075` |
| `reference_recorded_area_sqft` | `32395` |
| `development_area_sqft` | `32395` |
| `excluded_building_area_sqft` | `0` |
| `prior_site_use` | blank; preserve computed mixed administrative use |
| `area_basis` | `archival_recorded_area_matching_official_development_boundary` |

With the administrative baseline, prior building floor is 4,600 square feet
and built FAR is `4,600 / 32,395 = 0.141997`. The documentary alternative is
zero, pending the explicit source-error decision above.

## Woodside

The executed NYSDEC Brownfield Cleanup Agreement, physical PDF pp. 1, 3, and
7, names both filing addresses, the common owner, and exactly six old Queens
block 2432 lots—8, 9, 21, 41, 44, and 50—to become two successor lots 8 and 9.
Its boundary excludes neighboring lots 1, 23, and 39. The November 2021 Site
Management Plan, physical PDF p. 14, describes the same 71,862-square-foot site
and the two-building redevelopment. The June 2020 Remedial Action Work Plan,
physical pp. 10 and 21 and Figure 2 on physical p. 137, corroborates the full
six-lot site, former structures, and redevelopment boundary.

Both component jobs use the common prefiling **18v2beta** archive dated January
17, 2019:

| Reference BBL | Lot | Recorded area | Building area | Residential FAR | Broad FAR | Zone | Administrative prior use |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `4024320008` | 8 | 305 | 0 | 5.0 | 5.0 | R7X | vacant land |
| `4024320009` | 9 | 29,050 | 0 | 5.0 | 5.0 | R7X | vacant land |
| `4024320021` | 21 | 2,100 | 0 | 5.0 | 5.0 | R7X | vacant land |
| `4024320041` | 41 | 3,782 | 2,240 | 5.0 | 5.0 | R7X | commercial/industrial |
| `4024320044` | 44 | 11,375 | 10,943 | 5.0 | 5.0 | R7X | commercial/industrial |
| `4024320050` | 50 | 25,250 | 10,943 | 5.0 | 5.0 | R7X | public/transport/utility |
| **Group** |  | **71,862** | **24,126** | **5.0** | **5.0** | **R7X** | **mixed prior use** |

The exact archive total equals the agency's stated site area. The RAWP says the
site was most recently occupied by a gas station, cultural center, warehouse,
and contractor's office/yard; its Figure 2 maps former buildings within the
same six-lot boundary. It does not provide an alternative floor-area total at
the January 2019 reference date. The identical 10,943-square-foot archive
entries on lots 44 and 50 correspond to distinct administrative records and
Figure 2 depicts more than one former structure across the southern lots. No
primary source establishes that either entry is a duplicate, so the frozen
administrative sum should be preserved.

**Proposed row:**

| Field | Value |
| --- | --- |
| `sample` | `historical` |
| `parent_id` | `historical__420665845` |
| `expected_component_jobs` | `420665845;420665952` |
| `reference_vintage` | `18v2beta` |
| `reference_bbls` | `4024320008;4024320009;4024320021;4024320041;4024320044;4024320050` |
| `reference_recorded_area_sqft` | `71862` |
| `development_area_sqft` | `71862` |
| `excluded_building_area_sqft` | `0` |
| `prior_site_use` | blank; preserve computed mixed administrative use |
| `area_basis` | `archival_recorded_area_matching_official_two_building_site` |

Prior building floor is 24,126 square feet and built FAR is
`24,126 / 71,862 = 0.335727`. All six parcels have the same two FAR measures,
so one grouped row preserves all six reference lots and their mixed use labels
without inventing an internal development-area allocation.

## Saved sources

GO Broome originals and hashes are in
`tasks/audits/download_parent_review_documents/code/site_research_followup_2026-09-20_broader/`.
The source URLs are the NYC Department of City Planning DEIS
`https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/go-broome/01-deis.pdf`
and CPC decision
`https://www.nyc.gov/assets/planning/download/pdf/about/cpc/200061a.pdf`.

Woodside originals, URLs, and hashes are in
`tasks/audits/download_parent_review_documents/code/site_research_followup_2026-09-20_six_historical/`
and `tasks/audits/download_parent_review_documents/code/site_research_followup_2026-09-20_woodside_sutphin/`.

## Paste-ready proposed rows

These rows follow the current `site_lot_decisions.csv` column order. They keep
GO Broome's frozen 4,600-square-foot administrative building-area value; the
documented zero-floor alternative remains the explicit judgment item above.

```csv
historical,historical__121207292,121207292;121207522,19v2,1003460037;1003460075,32395,32395,0,,archival_recorded_area_matching_official_development_boundary,https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/go-broome/01-deis.pdf;https://www.nyc.gov/assets/planning/download/pdf/about/cpc/200061a.pdf,"DEIS pp. 2-3 and plan p. 13 assign both buildings and courtyard to old lots 37 and 75 and exclude retained lots 1 and 95. CPC pp. 2-3 distinguishes the 51884-square-foot zoning lot from the two-lot development ground. Common pre-first-filing 19v2 areas total 32395; both lots have residential FAR 6.02 and broad FAR 6.5. CPC p. 4 and DEIS p. 3 document zero observed floor after June 2019 demolition, but this row preserves the frozen 4600 archive value pending an explicit source-error correction.",2026-09-21
historical,historical__420665845,420665845;420665952,18v2beta,4024320008;4024320009;4024320021;4024320041;4024320044;4024320050,71862,71862,0,,archival_recorded_area_matching_official_two_building_site,https://extapps.dec.ny.gov/data/DecDocs/C241235/Agreement.BCP.C241235.2019-10-11.Executed%20BCA.pdf;https://extapps.dec.ny.gov/data/DecDocs/C241235/Work%20Plan.BCP.C241235.2021-11-30.Site%20Management%20Plan%20%28SMP%29%20-%20Final.pdf,"Executed BCA pp. 1 3 and 7 names both addresses and the complete six-lot predecessor boundary. SMP p. 14 states 71862 square feet and identifies the two-building redevelopment. The six 18v2beta administrative areas sum exactly to 71862; recorded building area totals 24126. All six lots have residential and broad FAR 5.0. Preserve their mixed administrative use and all six source lots.",2026-09-21
```

## Applied original-filing crosswalks

The refreshed audit preserves both raw original-lot mismatches. GO Broome's
saved lists name lots 1/37/75; City Planning locates the new development on
37/75 and identifies lot 1 as retained Hong Ning ground. Woodside's saved
original list comes from job 420665952 and names only 41/44/50; that job's
zoning list names all six earlier parcels. The accepted two-building boundary
is established by the BCA and SMP. `reviewed_original_bbls` records these exact
observed lists. A changed list does not inherit the clearance automatically.

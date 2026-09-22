# Jamaica 165th Street: later recorded six-building boundary

This note supplies primary evidence for the 591-unit parent
`post_policy__Q01243880-I1`. It does not change production land, filing
membership, units, dates, or weights. The six July 11, 2025 DOB jobs remain
the administrative counts described in the
[large-parent review](site_research_large_parents.md) and
[supervisor review](site_research_supervised.md).

## What the new records establish

The NYC Department of Finance Property Information Portal for Queens block
9795 lot 99 revealed a package dated February 26, 2026 and recorded September
1, 2026. The [acquisition record and five raw ACRIS PDFs](../../download_parent_review_documents/code/site_research_followup_2026-09-20_jamaica/README.md)
preserve the source URLs, page counts, dates, and SHA-256 hashes. This package
was not present in the ACRIS index snapshot from the earlier review.

The [zoning-lot development declaration, document 2026051400252004](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252004)
defines a **Parcel A** for intended sale and construction of several mixed-use
buildings and a **Parcel B** for the MTA bus facility (PDF pp. 3–5). Exhibit A
(PDF pp. 34–36) describes Parcel A as tentative block 9795 lots **30, 85, 89,
94, 98, and 99**; Exhibit B (p. 37) describes Parcel B as tentative lot **65**.
The Exhibit C survey (p. 39) shows the five frontage lots and a sixth Parcel A
lot 30 at 89th Avenue. Exhibit E's printed development-rights chart (p. 45),
visually checked against the scan, records:

| 2026 parcel | Printed lot area (sq ft) | Role in declaration |
| --- | ---: | --- |
| Parcel A | **39,349.50** | intended mixed-use/residential development land |
| Parcel B | **72,982** | MTA bus facility land |
| Combined zoning lot | **112,331.50** | zoning envelope, not the residential ground |

The separate [vehicular easement declaration, document 2026051400252005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252005)
explicitly calls the portion intended for sale the **Residential Development
Site** and says it is for future development of **approximately six residential
buildings** (PDF p. 4, recital B). It says one residential building will be on
the **Burdened Property**, and that passageway easements over that property
will serve the retained **Benefited Property** for the MTA terminal (pp. 4–5).
Exhibits A-2 and A-3 (pp. 52–53) identify the MTA-benefited land as tentative
lot 65 and the burdened residential land as tentative lot 30. The parallel
[pedestrian easement declaration, document 2026051400252007](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252007)
repeats the approximately six residential buildings and the Residential
Development Site definition (p. 4). Thus lot 30's lack of direct 165th Street
frontage does not, by itself, exclude it from the six-building residential
project.

The [confirmatory zoning-lot declaration, document 2026051400252003](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252003)
confirms that current lots 30, 65, 85, 89, 94, 98, 99, and 130 comprise one
combined zoning lot (p. 4). It does **not** make the whole zoning lot
residential land. The [MTA memorandum of lease, document 2026051400252009](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252009)
describes a lease effective June 1, 2025 but executed February 26, 2026 (pp.
3–4). Its location line mentions tentative lot 65 and portions of tentative
lots 30 and 94; access and lease interests in those portions should not be
mistaken for an assignment of their entire ground to the bus terminal.

## Application to the audit

The 2026 instruments provide a much stronger candidate physical boundary than
the former commercial condominium: **Parcel A, 39,349.50 square feet, is the
later recorded development parcel that appears to correspond to the roughly
six-building residential site**, while the much larger Parcel B is the retained
MTA site. This identification combines the zoning declaration's six Parcel A
lots with the easement declarations' six-building recital; neither instrument
literally equates the term “Residential Development Site” with all of Parcel A.
The 39,349.50 figure is printed on a
recorded development-rights chart, not estimated from the broad eight-lot
assemblage or a construction-floor-area ratio. The whole 112,331.50-square-foot
2026 zoning lot is 791.50 square feet larger than the earlier review's
111,540-square-foot sum of eight 2023-reference PLUTO lot-area attributes;
those quantities are from different sources and dates and should not be
silently reconciled.

**Adjudication still required:** The instruments are dated after the six July
2025 DOB filings and do not list the DOB job IDs, their 99/96-unit counts, or
an explicit one-to-one address-to-tentative-lot crosswalk. All six jobs are
still in objections in the saved DOB NOW evidence; their original MPP 459 site
plan has not been recovered. The matching six-building count, block, common
development party, and residential/MTA partition support treating Parcel A as
the later documented boundary for this economic project, but do not prove the
2025 filing drawings used exactly the February 2026 parcel layout. The root
review should decide whether that chronological/crosswalk gap permits an audit
classification or whether the exact 2025 plan remains necessary. In either
case, the entire combined zoning lot and old commercial-condominium area are
not supported as six-building residential ground.

The saved September 16 [official DOB NOW exact-job response](../../download_parent_review_documents/code/site_research_large_parents_2026-09-16/dob_now_165_jobs_2026-09-16.json)
does strengthen the collective crosswalk: all six jobs name block 9795, owner
contact Ami Weinstock, architect Joseph Frankl, and `MPP 459` in otherwise
parallel 12-story mixed-use descriptions; five specify 99 dwellings and one
96. The audit's saved site-wide other-filing table matches only these six rows
to this parent and marks none as another live filing. This is a bounded screen,
not a complete assertion that no other phase exists. A September 20 requery of
the live DOB NOW API returned zero for even the known lead job and for the
whole block; [the raw empty responses and metadata](../../download_parent_review_documents/code/site_research_followup_2026-09-20_jamaica/README.md)
are preserved. Because the current feed has lost or omitted a known saved job,
its zero block result cannot independently rule out another residential phase.

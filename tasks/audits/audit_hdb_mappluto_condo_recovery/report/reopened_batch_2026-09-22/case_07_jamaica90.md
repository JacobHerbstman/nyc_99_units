# Reopened case 07: 159-29/159-31 90th Avenue, Jamaica

**Recommendation:** Mark the 2019 and 2025 new-building filings as successive
proposals for the same recorded lot and likely the same redevelopment ground,
not as two additive buildings or separate phases. Keep **both** existing
proposal parents in the study: `historical__420666256` with **203 HDB units**
and `post_policy__Q01233524-I1` with **213 HDB units**. Their distinct cohort
dates and weighting eligibility should remain intact. For the later parent,
retain the one-lot boundary `4097580047`, **24,238 sq ft**, with zero prior
building floor at its 2023 reference. For the earlier parent, retain its
filing-specific 2019 site covariates: the same 24,238-sq-ft lot and roughly
13,926 sq ft of existing building area in the pre-filing archived MapPLUTO
record. **Confidence: moderate** on the same-site alternative relationship;
the exact planned footprints cannot be proven without the original job plans.

## Evidence and interpretation

The [case packet](/private/tmp/nyc_reopened_batch_2026-09-22/case_07.json)
places old DOB BIS job `420666256` (filed **2019-09-16**, address **159-29 90
AVENUE**, 12-story mixed-use NB description, **203** 23Q4 HDB units, permitted
**2022-06-06**) and later DOB NOW job `Q01233524` / filing `Q01233524-I1`
(filed **2025-08-11**, address **159-31 90 AVENUE**, 14-story mixed-use NB
description, **213** 25Q4 HDB units) directly on **Queens block 9758 lot 47**.
The 2019 permit status identifies authorization for construction, not a
completed 203-unit building. The later filing has no permit or completion date
in the packet. The street-number difference does not establish two parcels.

The local [archived historical HDB–MapPLUTO panel](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_07/README.md)
links `420666256` to **18v2Beta** BBL `4097580047`: **24,238 sq ft** of land,
**13,926 sq ft** of existing building area, two buildings, maximum three
floors, zero residential floor, built FAR **0.57**, residential FAR **5.0**,
and class `M1` / land use `08`. Those are **pre-filing existing-site** fields,
not the proposed 12-story project's completed floor. The later panel links
`Q01233524` to **23v3** on the identical BBL and lot area, with building area
**0**, floors **0**, land use `11`, class `V1`, and residential FAR **5.0**.
The case packet's 2023-12-28 parcel-map reference likewise contains one whole
lot and 24,238 sq ft, with negligible polygon-edge discrepancy. The 2025
parent panel uses fixed reference vintage `23v3_1` and records prior building
floor **0**. This sequence supports removal of the preexisting church
structures and does not show a completed 2019 apartment building on the site.

The two project principals independently identify the same church property.
[Haussmann Development's current project page](https://www.haussmanndev.com/properties/the-tabernacle)
markets its development at **159-29 90th Avenue** and describes a church
ground lease plus a new worship facility. [GF55 Architects' 2025 project
statement](https://www.linkedin.com/posts/gf55-architects_permits-filed-for-159-31-90th-avenue-in-jamaica-activity-7366832169849090048-vGic)
describes its **159-31** design as a combined apartment/church building that
replaces the previous church on the site. A web search excerpt of an
[August 2025 NYC DOF tax bill for BBL 4097580047](https://a836-edms.nyc.gov/dctm-rest/repositories/dofedmspts/StatementSearch?bbl=4097580047&stmtDate=20250816&stmtType=SOA)
prints the church name and **159-29** address; the PDF itself could not be
opened here. These are stronger
evidence of address equivalence and redevelopment continuity than the address
labels alone, although they do not define the exact new-building footprint.
Developer/architect marketing counts of 258–265 units are outside comparisons,
not replacements for the archived HDB/DOB 203 and 213 units.

The [current parent-opportunity and constituent panels](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_07/README.md)
already carry both as separate single-component proposals, each with one
constituent filing and weight **1**, `included_ab=TRUE`, and
`included_ab_plus_d=TRUE`. The historical parent dates to **2019-09-16** and
has a full observed window; the post parent dates to **2025-08-11** and has
**331** observed follow-up days through **2026-07-08**, so its full-window flag
is false. Reclassifying physical overlap must not change either filing date,
window, weight, or sample inclusion. The 2026 administrative status of the
older job likewise is not a reason to erase its 2019 proposal.

## Proposed manual disposition and remaining check

For root adjudication, record a reviewed cross-period site relationship keyed
by `(historical__420666256, post_policy__Q01233524-I1)` and job pair
`(420666256, Q01233524-I1)`: `same_recorded_lot_successive_proposals`,
shared BBL `4097580047`, 24,238-sq-ft measured lot, **no additive 203+213
physical building**, and **no separate-phase evidence**. Keep both proposal
rows, their HDB unit sources, their distinct periods, and their existing
site-covariate reference vintages. This is an analytic physical relationship,
not a declaration that DOB legally withdrew or superseded job `420666256`.

The bounded unresolved item is a plan-to-plan footprint and existing-building
comparison: obtain original DOB document/plan sets for exact jobs
`420666256` and `Q01233524-I1`, especially the plot/site plans and zoning
exhibits, or a recorded ACRIS zoning-lot declaration or survey explicitly
linking the two designs. The official DOB exact-job API was inaccessible in
this environment, so no original plan was examined. The 2019 old permit does
not prove a separate physical building, and the 2023 vacant parcel row plus
architect/developer descriptions support treating it as an unbuilt predecessor
for **physical-site** purposes. Do not claim that these sources establish a
verified legal wage-assessment unit or the precise building footprint.

Source URLs, local hashes, and access limitations are preserved in the
[case source inventory](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_07/README.md).

## Supervisor adjudication — September 22, 2026

Root retrieved and inspected official BIS420666256 and NOWQ01233524 responses, preserved in the supervisor source folder. Applied the scoped same-ground alternative disposition; both dated proposals and their203/213 administrative units remain.

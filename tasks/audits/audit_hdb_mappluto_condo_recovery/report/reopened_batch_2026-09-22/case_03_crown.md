# Reopened case 03: 54 Crown Street

**Recommendation:** Treat DOB job `321042304` as an earlier, unbuilt
alternative plan on the same development ground, not an additive filing or a
separate completed building. Retain historical parent `historical__321593986`
as the exact archived additive job set `{321593986}` with **569 HDB units**.
Keep its reviewed development land at **55,385 sq ft**, reference lots
`3011900029;3011900045;3011900050` in `18v2beta`, zero prior building floor,
residential FAR 3.0, broad FAR 3.0, and vacant-land use. Do not add the
earlier 208 proposed units, allocate floor to it, or expand the land boundary.
Confidence is **high** that the 208-unit plan was not a separate completed
development; **moderate** about its formal DOB disposition, since the saved
filing still has a permit status rather than a withdrawal or sign-off.

## Why the new flag appears

The inactive-inclusive `23Q4` HDB search finds an additional, nonmember NB
record: job `321042304`, filed **2014-12-29**, permit **2015-06-09**,
**208 proposed units**, address `902 FRANKLIN AVENUE`, BBL `3011900029`.
It directly shares the later filing lot with job `321593986`, filed
**2019-06-26** at `54 CROWN STREET`, BBL `3011900029`, **569 units**.
The current scope has one other direct filing, no other estimation parent,
and no shared earlier reference lot with another parent. The old scope called
this parent supported; the present screen calls it “Shared earlier land or
other filing” solely because the newly surfaced historical job has no reviewed
disposition. The earlier job's address change does not signal a second site.

The saved [NYC DOB filing extract for 321042304](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_03/dob_job_321042304.json)
has distinct documents 01–05. Document 01 says seven proposed stories and
208 proposed dwelling units; its current `Q` status means partial permit,
and its latest action date is **2018-01-11**. Document 02 says foundation and
excavation, with an entire-work permit dated **2015-06-09**. The row has
`withdrawal_flag=0`; this is not evidence of an administrative withdrawal.
The [later DOB extract](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_03/dob_job_321593986.json)
shows document 01 on lot 29 with **569 proposed units** and the filing date
**2019-06-26**. These mutable DOB snapshots corroborate identity and dates,
but current job status alone cannot establish what stood in early 2019.

The stronger physical evidence is the [NYC Department of City Planning's June
8, 2018 revised EAS for Franklin Avenue Rezoning](https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/eas/17dcp067k_eas.pdf),
Attachment A p. A-1 (**physical PDF p. 25**, visually inspected). It identifies projected site 2 as **40 Crown Street,
block 1190 lots 29, 45, 50**, explicitly identifies `321042304` as its
**as-of-right, future No-Action** DOB plan, and says both applicant sites had
been excavated with one footing each but **remained vacant**. Thus a permit
and partial foundation work did not produce the proposed 208-unit building.
The project's 18v2beta archived lots 29, 45, and 50 have **zero recorded
building floor** at the 2019-01-17 reference date. The later [City Planning
FEIS Appendix 2](https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/960-franklin-ave/append2-feis.pdf),
printed p. 2 (**physical PDF p. 3**, visually inspected), again calls job
`321042304` the 2015 seven-story, 208-unit as-of-right **No-Action
scenario** for 40 Crown. Both agency PDFs are preserved and hashed in the
source inventory. The 2018 contemporaneous statement plus zero archived
floor is the basis for the noncompletion inference, rather than the 2021
scenario alone.

## Exact 569-unit ground remains supported

The preserved [ACRIS zoning declaration 2019091301137002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019091301137002),
PDF pp. **3–5** (visually rechecked), prints NB job **321593986** on p. 3
and defines tentative block 1190 lot 29 from old lots **29, 45, and part of
50**. Page 5 diagrams the 235-foot Crown frontage, Franklin frontage,
Montgomery Street notch, retained tentative lot 50, and out-parcels. The
[companion title certificate 2019091301137001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019091301137001),
PDF pp. **4–6**, repeats the courses and diagram. The [DOF tax map effective
2019-12-09](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30119020191209154141)
draws the resulting lot 29 separately from retained lot 50 and out-parcels.
The successor administrative lot area is **55,385 sq ft**. The three whole
old-lot records total **55,083 sq ft** (38,070 + 3,480 + 13,533), a
**302-sq-ft** gap; the recorded boundary uses only *part* of old lot 50.
Prior review concluded that the administrative successor area is the
appropriate exact-job measure, with no invented within-lot floor allocation.

This filing evidence does not change the adopted land row in
`tasks/parent_opportunities_manual/output/site_lot_decisions.csv` or the
recorded-boundary row in
`tasks/audits/audit_hdb_mappluto_condo_recovery/code/parent_site_document_review.csv`.
Both rows already identify exact job `321593986`, reference lots
`3011900029;3011900045;3011900050`, successor area **55,385**, and zero
excluded floor. The 208-unit alternative was associated with the overlapping
old lots before the successor configuration and does not create a second
physical land claim for the adopted 569-unit project.

## Rows for root adjudication

Add a reviewed **earlier-alternative filing disposition** keyed by historical
parent `historical__321593986` and other job `321042304`: `same_ground_prior_unbuilt_alternative`;
source BBL `3011900029`; earlier DOB filing date `2014-12-29`, permit date
`2015-06-09`, proposed units `208`; development parent component job
`321593986`; evidence EAS Attachment A p. A-1 and DOB documents 01–02;
no additive units, no separate land, no ancillary/nonresidential designation.
Preserve the older job's recorded permit status and `withdrawal_flag=0`; the
reviewed disposition describes the **physical and analytic relationship**,
not an asserted legal cancellation. No change is recommended to historical
filing roles, archived parent membership, source units, site-lot decisions,
or dates.

The only residual question is whether DOB later closed, superseded, or left
open job `321042304` administratively. That does not affect the observed
2019 parent membership or land allocation given the agency's vacant-site
statement, zero archived floor, and exact later job-linked boundary.

## Preserved-source checksums

| Source | SHA-256 |
| --- | --- |
| DOB job `321042304` JSON, 2026-09-22 | `0c2520a6945d39996001b162d57a2d87a1562c58232cc4f4f37c7e10ecf72913` |
| DOB job `321593986` JSON, 2026-09-22 | `7947a3708a63fd33697801618b46c67f445b400a6e8d47d4996392324d0f3544` |
| DCP revised EAS PDF, 2018-06-08 | `57e46b4e16a98642b2455808a44eabd32d5c9a6bee756d064c87f178e49e2fd0` |
| DCP FEIS Appendix 2 PDF, 2021 | `c1755f1ff0c3cc93b7f231e40131a0877e91f529de55e7e4317798b7b209de8a` |
| ACRIS `2019091301137002` PDF | `6089094a549ce9d811f96ab740264e82e7a8d7720c1586c90911fe72276319de` |
| ACRIS `2019091301137001` PDF | `cdb72152d5d806cfda88fc1e464ddbc16558a15fe969cbc1bcff8a62a6c0ed50` |
| DOF map `30119020191209154141` PDF | `fb8ab287934c7248fb9c4265906b08117998f9a7b1e353331302b349b105124f` |

The DOB JSON source URLs, PDF retrieval URLs, and acquisition details are
recorded in the [source inventory](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_03/README.md).

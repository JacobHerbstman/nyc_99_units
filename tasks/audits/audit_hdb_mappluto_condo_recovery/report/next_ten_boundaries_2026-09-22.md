# GO Broome and the next ten parent reviews

**Later September 22 follow-up:** the [queued-case review](queued_followup_2026-09-22.md)
applies Wallabout's allocation and confirms a historical source-vintage problem
at Livingston. The counts and unresolved descriptions below describe the
earlier batch result and are superseded by that follow-up where indicated.

September 22, 2026. GO Broome's earlier building floor is corrected to zero.
The next ten reviews support five additional production parcel corrections;
four of these ten have complete boundary decisions. Charles has a supported
land correction but retains a separate earlier-proposal question. The other
five require more boundary or filing-history evidence.

The ten were selected from the 116 unresolved weighting-sample parents at the
start of this batch, sorting by descending number of exact-99 constituents,
then constituent count, then parent units, and finally parent ID. Broome was
already boundary-supported and is separate from these ten. Reviewing ten is
not equivalent to resolving ten.

The refreshed audit confirms **112 unresolved and 752 supported among the same
864 parents**. Only Walton/Burnside, Willets Phase I, 261/315 Grand Concourse,
and Noble/Oak change from unresolved to supported. The remaining six from this
batch are still in the 112; the other 106 queued parents were not selected here.

## Applied production corrections

All areas below are square feet. Earlier floor means the building floor on the
land before the parent proposal, using the specified archived administrative
release and documented corrections. It is not proposed residential floor.

| Parent | Ground before | Ground adopted | Earlier floor before | Earlier floor adopted | Review status |
| --- | ---: | ---: | ---: | ---: | --- |
| GO Broome | 32,395 | 32,395 | 4,600 | 0 | Dated source conflict resolved |
| 21 Charles Place | 10,000 | 12,590 | 0 | 1,100 | Land applied; older proposal remains open |
| Walton/Burnside | 23,000 | 23,000 | 20,930 | 21,000 | Complete earlier parcel supported |
| Willets Point Phase I | 126,102 | 135,609 | 0 | 0 | Surveyed development boundary supported |
| 261/315 Grand Concourse | 26,304 | 37,661.3 | 30,603.02 | 46,463 | Surveyed development boundary supported |
| Noble/Oak | 252,780 | 173,834 | 2,527.8 | 1,500 | City development boundary supported |

Broome uses a documented demolition date. Walton and Noble use direct archived
building-area fields instead of reconstructing them from rounded built FAR.
The land corrections change derived density and development capacity. None
introduces a new estimated-floor flag; the six previously approved flagged
estimates remain the same six parents.

The production source is `tasks/parent_opportunities_manual/output/site_lot_decisions.csv`.
It now has 45 allocation rows for 39 parents. The existing linear parcel build
reads these rows, checks component jobs and archived areas, and applies them.
The only added archived input is 22v1 for Willets. Housing units, filing dates,
refiling histories, parent memberships, and sample definitions are unchanged.

## GO Broome

`historical__121207292`, jobs 121207292 and 121207522, 495 units.
The CPC decision C 200061(A) ZSM, physical p. 4, dates complete removal of the
synagogue remnants to June 2019. DEIS Chapter 1, p. 3, records zero existing
floor. Both precede the November 2019 reference release and March 2020 first
filing. The frozen 4,600 on old lot 37 is therefore a dated source error.
Apply zero floor on the supported 32,395-square-foot lots 37/75. Preserve the
archived prior-use category; correcting floor does not establish a new land-use
classification. The source-table deduction is explicitly labeled an archive
correction, not retained off-site floor.

Sources: [CPC decision](https://www.nyc.gov/assets/planning/download/pdf/about/cpc/200061a.pdf),
[DEIS Chapter 1](https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/go-broome/01-deis.pdf).
Saved unchanged in the acquisition task's `code/site_research_followup_2026-09-20_broader/`.

## The ten reviews

### 1. 370 Livingston Street — retain boundary and timing questions

`historical__B00781447`, 99 current administrative units, first filed September
28, 2022. The earlier lot 16 is shared with jobs B00814498 and B01127732, filed
in 2023 and 2024. DOF transaction 272940 partitions the earlier land in March
2025. The saved DOB description also names three buildings on a shared zoning
lot. Assigning the entire 13,937-square-foot old lot to this one parent is not
established by those records.

The newly saved declaration `2026010400010003`, pp. 2 and 13, identifies 370
Livingston and successor lot 22. Its p. 16 reproduces an April 28, 2025 HPD
application naming this exact DOB job, 99 units, and **485-x Option B**; p. 21
also assumes 485-x in the underwriting. This is direct evidence that the current
99-unit design seeks post-policy treatment despite its historical initial filing
date. It does not establish the original 2022 unit count or the amendment date.

**Remaining evidence:** the original/amended filing history and the physical
division of earlier land and floor among all three buildings. Preserve the
current sample in this boundary batch, but review this dated-outcome issue
before treating its current 99 as an untreated historical choice.
[Recorded declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026010400010003).

### 2. 21 Charles Place — apply land, retain older-proposal question

`post_policy__B01320823-I1`, 99 units. Agreement `2026030200076003`, pp. 2–6 and
25, assigns both complete earlier lots 7 and 71 to the development. Nearby lots
6/19/23 contribute rights, not physical ground. Their frozen 2023 land is
2,590 + 10,000 = **12,590**, with **1,100** earlier floor on lot 7 and zero on 71.
That physical correction is established independently of the filing-role issue.

The saved old ZD1 names job 321590541, 46 units, one building, and both lots.
The older permit record remains active through June 2026, while the new
application's November 2025 AI1 defers its ZD1. The new job received its first
permit July 9, 2026, after the panel cutoff. These facts suggest competing
proposals on the same site but do not establish a formal withdrawal or resolve
which older work the new filing retains.

**Remaining evidence:** the approved new zoning sheet and a filing-history
record connecting the two proposals. Land is implemented; no automatic merger,
withdrawal, or filing-date replacement is inferred.
[Recorded agreement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026030200076003).
Earlier ZD1 and permit evidence are in the acquisition task's
`code/site_research_followup_2026-09-20_charles/`.

### 3. 159 Broadway — retain proposal and earlier-floor questions

`post_policy__B01327363-I1`, 99 units. The December 2025 zoning sheet describes
the new 12-story proposal. Recorded easement `2025121500836001` distinguishes
the 9,262-square-foot development lot 34 from access rights on lot 28. The older
job 320911233 is a hotel proposal with a different design and active permits.
The new July 2026 S9 refers to selective demolition of an existing frame/slab.

The 2023 archive records **112,041** building square feet; the existing density
calculation yields 112,070.2 because it uses rounded FAR. Neither value proves
how much floor was physically standing in the unfinished structure at that
date. The obscured old-job text beneath the new zoning sheet is not affirmative
evidence of an approved amendment.

**Remaining evidence:** dated construction/floor plans and a documented
relationship between the two jobs. Preserve administrative unit priority and
the unresolved flag. Saved ZD1/S9 records are in the Charles follow-up packet;
the easement is in `code/site_research_supervisor_2026-09-16/`.

### 4. Rockaway Village III/IV — retain phase-ground allocation

`historical__420667488`, jobs 420667558/420667488/420667497, 354+129+55 = 538 units.
HDC distinguishes Phase III's 354 units at 1626 Village Lane and Phase IV's
184 at 1605/1607. The earlier 17-lot transaction envelope has 642,318 square
feet; that is a multi-phase envelope, not this parent's measured ground.
The current production lookup supplies only 17,568.

The June 2024 DOF map shows condominium 1349 crossing several underlying lots.
The newly saved April 2024 deed `2024051600214002`, pp. 3 and 6–8, conveys
condominium units 18/19/20 to Rockaway Village III. It assigns 11.61%, 12.27%,
and 4.12% undivided interests and then describes the broader condominium land,
including other Village Lane addresses. Those 28% ownership rights do not
measure Phase III's physical ground. The deed names the recorded condominium
plans, CRFN 2022000210978, as the source of the units' physical definitions.

**Remaining evidence:** those plans and the Phase IV recorded boundary, including
allocation of shared ground. Preserve the three-filings economic parent; phase
financing alone neither breaks the link nor assigns the whole envelope to it.
[Recorded deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2024051600214002).

### 5. Walton/Burnside — resolve and apply

`post_policy__X01250398-I1`, three filings, 255 units. December 2025 zoning
certificate `2025120500186002`, pp. 2–3, names tentative lots 1/3/5 as the
existing lot 1 and identifies all three filing addresses. Its p. 5 diagram
divides that complete earlier site among the three buildings. This supports
the whole old parcel once: **23,000 ground and 21,000 earlier floor** from
23v3_1. Do not replace the administrative land with rough diagram dimensions.
[Recorded certificate](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2025120500186002).

### 6. Wallabout/Union — retain allocation of earlier parcels

`historical__321595608`, 58 Union/269 Wallabout/34 Union, 174 units. The issuer's
2023 appraisal, pp. 289 and 320, distinguishes these sites from 251 Wallabout,
an earlier 2018 filing. Their completed ground is 9,643 + 20,000 + 9,680 =
**39,323**, while 251 Wallabout separately occupies 32,000. The 2021 DOF map
confirms the 20,000 and 32,000 rectangles on successor lots 41 and 37.

Production currently assigns 68,805 from a mixture of earlier references.
The common 18v2_1 old parcels have different residential FARs: 4, 4.2, and 6.
Old lot 41's 47,500 square feet crosses the later development division. Its
entire area cannot be assigned to 269 Wallabout without including part of the
older 251 project. Earlier recorded floor is zero, but the old zoning weights
still require spatial allocation.

**Remaining evidence/calculation:** overlay the documented later boundaries on
one common prefiling map and allocate each old parcel's area and FAR. The
39,323 ground total alone does not finish the parent covariates. New appraisal
and DOF map are checksum-pinned by `next_ten.make`.

### 7. Noble/Oak — resolve and apply

`post_policy__B01312761-I1`, two filings, 1,060 units. The June 2026 CB1 notice,
pp. 2–3, assigns the two-building site and tentative lots 1/10 approximately
**173,834** square feet, including waterfront access. The old tax lot includes
additional waterfront area. August 2025 confirmatory deed `2025082600703001`,
pp. 2–3, independently describes the street-centerline/bulkhead boundary.

For a reproducible check, start at (0,0), use course lengths
`30, 260, 709.09, 241.03, 30.43, 601.88` feet and mathematical headings
`0, -90, 180, 72.5958333333, 80.3191666667, 0` degrees. Cumulative x/y
increments and the polygon shoelace formula give **173,827.90455** square
feet and a **0.00819-foot** closure error. This agrees within 6.10 square feet
with the city's approximate figure. Adopt the city's 173,834 and preserve its
approximate status. The saved 2016 survey locates the earlier structures within
the boundary; retain the complete **1,500** recorded 2023 floor and frozen
2023 zoning. Later land/assessment boundaries do not define a second housing site.
[City notice](https://www.nyc.gov/assets/brooklyncb1/downloads/pdf/meeting-notices/2026/REVISED-Combined-Public-Hearing-and-Board-Meeting-Notice-06-09-26.pdf),
[recorded deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2025082600703001).

### 8. Willets Point Phase I — resolve and apply

`historical__Q08032504`, two filings, 881 units. The December 2023 DEC management
plan, pp. 8–9 and 15–17, identifies both housing buildings and site lots
120/130/135. Its recorded easement, pp. 116–117, measures **135,609** square feet.
Senior-housing lot 140 and the stadium on block 1823 are separate sites.

Use contributing old lots 103/111/120/141/143 from common prefiling release
22v1. Their recorded land totals 158,102, but the recorded development boundary
supplies the applicable 135,609. All five have zero recorded floor and identical
residential/broad FARs, so internal land allocation is unnecessary for these
covariates. Count all five contributing old parcels. Administrative housing
units and the two DOB jobs remain unchanged.
[DEC management plan](https://extapps.dec.ny.gov/data/DecDocs/C241146H/Work%20Plan.BCP.C241146H.2023-12-08.Final%20Site%20Management%20Plan.pdf).

### 9. 261/315 Grand Concourse — resolve and apply

`historical__X00561795`, two filings, 405 units. DOF transaction 190544 explicitly
names both NB jobs and combines/reconfigures old lots 1/11/27. The December 2025
DEC management plan, p. 16, confirms that genealogy and the two 14-story towers.
The completion certificate's legal description, pp. 6–7, and survey, p. 9,
give **37,661.3** square feet. Retained lot 17 is outside.

Use common pre-first-filing 20v8. Its three old parcels record 42,659 ground,
a source discrepancy against the survey. Preserve that discrepancy in the
source table and use surveyed development ground. All three earlier floor
records belong to this complete site: **20,480 + 15,800 + 10,183 = 46,463**.
Their FARs agree; no floor-share assumption is needed.
[DEC certificate and survey](https://extapps.dec.ny.gov/data/DecDocs/C203151/Certificate%20of%20Completion.BCP.C203151.2025-12-26.Copyrite_Plastic_Sheets_COC.pdf).

### 10. 310/322 Grand Concourse — retain earlier-floor allocation

`historical__220696851`, two filings, 301 units. The July 2020 DEC investigation,
pp. 6–7, establishes two later building lots of **15,692.22 and 13,917.38**, or
**29,609.6** square feet, including part of old lot 10 and old lots 28/31.
The separate 276 Grand Concourse proposal occupies retained old-lot-10 land.

Old 18v1_1 records 9,200 floor on lot 10, 4,133 on 28, and 3,950 on 31.
The report's p. 63 diagram and appended earlier assessment show structures
around the internal boundary but do not establish how much of lot 10's floor
belongs to 310/322. Production's 24,027 ground and 8,055.32 reconstructed floor
remain flagged; adopting 29,609.6 ground alone would leave an implicit, unproved
earlier-floor allocation.

**Remaining evidence:** a dated building-footprint/floor allocation across the
old lot 10 division. Do not merge the separate 215-unit neighbor by adjacency.
[DEC investigation](https://extapps.dec.ny.gov/data/DecDocs/C203121/Report.BCP.C203121.2020-07-01.Final%20Remedial%20Investigation%20Report.pdf).

## Consequences and reproduction

Comparison with the frozen pre-batch panels finds exactly six changed parents,
all listed in the applied table. Every constituent record is identical. The
parent panels retain 1,811 historical parents/129,335 units and 907 post-policy
parents/61,319 units. The weighting comparison retains 554 historical and 310
post-policy parents, with its existing formula. The weighted historical
exact-99 share moves from **1.3535331% to 1.3537427%**; mean parent units moves
from **151.4686235 to 151.3558985**. Maximum calibration moment error is
**6.50 × 10⁻¹⁰**. These small movements do not establish that future structural
estimates are insensitive to unresolved boundaries or filing timing.

Root `make` rebuilds production and descriptive exhibits; `make logbook`
refreshes the parcel reviews, weights, existing sensitivity checks, and logbook.
New unchanged sources, pages, API coverage, and checksums are documented in
`../../download_parent_review_documents/code/site_research_next10_2026-09-22/README.md`.
The ordinary build reaches their acquisition. No main data task consumes an
audit, and reports remain side effects rather than Make targets.

Verification checks exactly six changed parent rows and identical constituent
records against the frozen pre-batch panels. A fresh task build reproduces both
production parcel outputs field for field; unchanged builds, new-input
propagation, missing-output regeneration, and report absence alone behave as
specified on Make 3.81. Acquisition checks cover missing sources, unchanged
reuse, changed definitions, checksum mismatch, and failed transfers. Both
failure cases preserve the preceding snapshot. All 16 new source files match
their recorded fingerprints.

The full refresh also reruns the existing 20 floor-sensitivity scenarios.
Its existing 499-draw calibration bootstrap records 493 successful draws and
six calibration failures in `bootstrap_run_summary.csv`; those failed draws
are not presented as successful estimates.

Root `make` and `make logbook` complete successfully. The final unchanged
`make logbook` runs no data, figure, download, or document recipe. The refreshed
reweighted plot and the two-page logbook entry were visually inspected.

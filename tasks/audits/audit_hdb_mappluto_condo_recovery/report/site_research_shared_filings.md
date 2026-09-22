# Four parent sites with shared or predecessor filings

Current adjudications are in the [supervised review](site_research_supervised.md). The dated gathering rounds below preserve the evidence available at each stage.

This note reviews four post-policy parents flagged by the automated site-scope
screen. It asks a narrow question: what land was assigned to the economic
development represented by the observed 99-unit filing? A filing on the same
tax lot is not counted as another project merely because its old record still
shows a permit status. Conversely, a broad zoning lot, financing package, or
later tax-lot merger is not automatically the land allocated to the building.

These are source-gathering notes. The [supervisor review](site_research_supervised.md)
records the adopted boundary criterion and leaves all four cases open. A later
filed plan can establish the observed building boundary; prior ownership of an
identical boundary is not an additional requirement.

The DOB facts below come from the city's [DOB Job Application Filings
dataset](https://data.cityofnewyork.us/Housing-Development/DOB-NOW-Build-Job-Application-Filings/w9ak-ipjd)
and [DOB BIS Job Application Filings dataset](https://data.cityofnewyork.us/Housing-Development/DOB-Job-Application-Filings/ic3t-wcy2),
read September 16, 2026. DOF transaction dates, authority text, and parcel
geometry come from the project's frozen September 15, 2026 DOF history
snapshot. ACRIS links below identify the deeds named by DOF as the authority
for each map change.

## Results

| Parent | Relationship of the other filing | Land conclusion |
| --- | --- | --- |
| `post_policy__B01320823-I1`, 21 Charles Place | The 2020 46-unit filing has no recorded completion date and is a probable predecessor design on the same physical site. The record does not support adding its units or treating it as a second completed project. | **Unresolved between 10,000 and 12,590 square feet.** The reference parcel records 10,000; the later deed and merger add old lot 7. A development plan must establish whether the observed building uses the added land. |
| `post_policy__B01327363-I1`, 159 Broadway | Job 320911233 is a related predecessor filing on the same parcel. The city BIS row counts 256 proposed dwelling units in a 26-story R-1 hotel/residential building, while the Housing Database counts 21 Class A units. These fields have different definitions and neither should overwrite the other. A recorded 2025 easement includes the older hotel ground plan but does not state how much was constructed or whether the new filing legally replaces it. | **9,262 square feet is the supported physical parcel.** The recorded lot-28 relationship is an access/ramp easement between distinct buildings, not added building ground. An indexed copy of the new zoning drawing reports a broader 27,580.97-square-foot zoning lot, but remains an unverified lead. |
| `post_policy__X01201390-I1`, 3008 Godwin Terrace | X01201390 and X01202536 remain separate canonical parents pending adjudication. A July 2026 recorded agreement explicitly allocates a 99-unit building to lot 79 and a 65-unit building to lot 88 under one coordinated development agreement. | The two successor building lots total **18,441 square feet** (12,541 + 5,900). Godwin's allocated parcel is 12,541 and Kimberly's is 5,900. Retained lot 78 contains a separately identified existing commercial building and is not allocated to either new residential building. |
| `post_policy__X01252745-I1`, 623 East 178 Street | The July 70- and 60-unit filings expressly reference each other and were withdrawn; the August 99-unit filing is permitted on one of the same lots and is a replacement candidate. The recorded live zoning and development agreements define the Developer Parcel as old lots 88, 89, and 90 and omit old lot 87. | The recorded agreement states **7,292.40 square feet** for the Developer Parcel. The archival administrative areas sum to 7,287 square feet. Old lot 87 is excluded; separate lot 81 contributes development rights within the larger zoning lot but remains the Owner Parcel with its existing building. |

## 21 Charles Place, Brooklyn

DOB's 2020 filing, job 321590541, proposed a five-story, 46-unit building with
48,148 square feet of construction floor area. It was filed May 5, 2020,
approved March 10, 2021, and the current city row says "permit issued - entire
job/work," with July 25, 2025 as the fully permitted date. The ownership field
changed from Congregation Bais Chana in the older city rows to Yaakov Lefkowitz
and Lefko Capital Group in the September 15, 2026 row. There is no completion
date. Thus the status is evidence of continuing paperwork, not proof that a
separate 46-unit building was completed or coexists on the lot.

The new filing B01320823-I1 was filed November 20, 2025 by Lefko Capital Group.
It proposes an 11-story, 99-unit mixed-use building on the same BIN 3428696 and
lot 71; DOB issued the first permit July 9, 2026. Its much larger program and
the common physical site make the old filing a predecessor design. Unit counts
must not be added.

The land boundary changed around the new filing. MapPLUTO 23v3_1 records lot
71 at 10,000 square feet and neighboring old lot 7 at 2,590. DOF transaction
504542, applied January 29, 2026, merges lots 7 and 71 into lot 71. DOF cites a
deed dated November 25 and recorded December 16, 2025, CRFN 2025000341781,
document ID 2025121600440001. ACRIS Legals lists both lots 7 and 71; ACRIS
Parties names Congregation Bais Chana as party 1 and 21 Charles LLC as party 2
([ACRIS document](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025121600440001)).
The FY2026/27 final assessment then reports 12,590 square feet
([DOF assessment](https://a836-pts-access.nyc.gov/care/datalets/datalet.aspx?LMparent=20&UseSearch=no&jur=65&mode=asmt_fin_2027&pin=3031830071&taxyr=2027)).

The merger and deed show that 12,590 became one tax lot. A ZD1, survey, or
other development-boundary record must establish whether the observed building
uses the added old lot 7. The audit leaves that allocation open; the dates alone
do not require a 10,000-square-foot assignment.

## 159 Broadway, Brooklyn

The city's main BIS row for job 320911233 proposes a 130,151-square-foot,
26-story R-1 hotel/residential building with **256 proposed dwelling units**.
The Housing Database separately records 21 Class A units. A hotel-room count
or BIS dwelling-unit field is not an administrative override for the Housing
Database Class A measure. The job was filed February 21,
2018, approved February 21, 2019, and fully permitted January 14, 2020. Its
latest action date is October 24, 2025 and its raw withdrawal flag is 2. The
meaning of that code was not independently verified here, so it is preserved
without interpreting the job as withdrawn. The absence of a completion date
and continued permits do not establish a second completed project.

B01327363-I1 was filed December 11, 2025 for 99 units and says: "Please assign
to the dev hub to the same examiner as job #320911233." An indexed search
extract for a purported July-December 2025 zoning drawing
shows both `320911233-08` and `B01327363-I1`. The exact lead is
[ZD1_B01327363_2.pdf](https://www.pincusco.com/property-data/ZD1_B01327363_2.pdf),
but direct retrieval returned a payment-required response. It was not bypassed,
and the PDF was not read in this review. The verified same-parcel filings and
explicit examiner reference support a predecessor relationship; they do not
alone prove the extent to which an existing shell is reused.

The physical filing parcel, Brooklyn block 2457 lot 34, has a recorded 2023
area of 9,262 square feet and its mapped footprint is unchanged. The indexed
ZD1 text reports lots 28, 34, 39, 1001-1004, and 41 and 27,580.97 square feet,
but this remains unverified until the drawing is obtained from a public source.
Use 9,262 as the supported physical land. Keep 27,580.97 as a lead for a
broader zoning boundary, not an adopted measure.

A recorded 2025 instrument clarifies the adjacent-lot relationship without
expanding the building ground. ACRIS document **2025121500836001** is a
26-page Third Amended and Restated Easement Agreement between the owner of
**Parcel A, block 2457 lot 34 at 159 Broadway**, and the owner of **Parcel B,
lot 28 at 175 Broadway**. Page 2 calls the planned structure on Parcel A the
“Hotel Building” and the existing structure on Parcel B the “WS Building.”
Pages 3-8 grant and regulate access, ramp, landing, and enclosure easements
between the two separately described parcels. Exhibit A on page 15 gives the
lot-34 metes and bounds; Exhibit B on page 16 separately describes lot 28.
Exhibit D on page 20 is Stonehill Taylor drawing **A-101.01, “GROUND
CONSTRUCTION PLAN,”** for project **159 BROADWAY**, project number **21727**,
dated **05.31.2018**. Exhibits on pages 24-26 depict enclosure work linking the
two distinct buildings. No DOB job number appears in the recorded scan.

The agreement confirms recorded access rights across lot 28 and links its plan
to the older hotel-design period. It does not make lot 28 part of the Hotel
Building ground, nor does it state how much of job 320911233 was constructed
or whether B01327363-I1 legally replaces that filing. Together with the later
partial-demolition filing, it supports reuse of an existing project structure
as a question for the current zoning drawing rather than an area expansion.

## 3008 Godwin Terrace / 5517 Broadway, Bronx

X01201390-I1 and X01202536-I1 were both filed March 31, 2025. DOB identifies
the same owner (Westorchard Management / Andrea Gjini), architect and filing
representative. The first proposes 99 units and 72,137.6 square feet at 3008
Godwin Terrace, later lot 79. The second proposes 65 units and 68,815 square
feet at 220 Kimberly Place (also reported publicly as 5517 Broadway), later
lot 88. Both were approved February 19, 2026 and both subsequently received
full permits.

Contemporaneous reporting describes them together as a two-tower, 164-unit
development with 115,295 square feet of combined program
([April 4, 2025 filing report](https://www.newyorkyimby.com/2025/04/permits-filed-for-5517-broadway-in-kingsbridge-the-bronx.html)).
This is consistent with, but not a substitute for, the city records: same date,
team, and predecessor-lot transaction. Together these are evidence for treating
X01202536 as a candidate companion, but they do not resolve parent membership.

The canonical data currently retain them as two rental-eligible parents. Both
carry old application BBL 2057000078, but the application-BBL date is December
15, 2025, after their March filings. The strict lot-history link therefore does
not use that change. Neither filing explicitly names the other, and there is no
accepted edge in the manual link table. The evidence here exposes that coverage
gap; the recorded allocation evidence below should be reviewed before changing
parent membership.

A newly recovered primary record strengthens the common-site evidence without
settling that parent decision. ACRIS document 2025052300873001 is a **First
Modification to Zoning Lot Development and Easement Agreement**, dated May 19,
2025 and recorded June 6. Pages 3-4 identify block 5700 lot 99 at 5517 Broadway
as the "Owner Parcel" and lot 78 at 205 West 230 Street as the "Developer
Parcel." They state that a 2021 declaration combined the two into a single
zoning lot and that a 2021 zoning-lot development agreement created easements
between them. The modification is between 5517 Broadway Retail Owner LLC and
205 West 230th Owner LLC, both care of Procuratio LLC at the same address
([ACRIS record and scan](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025052300873001)).
This establishes a shared legal zoning site. It also shows why the broader
zoning lot cannot be assigned wholesale to the new residential buildings:
lot 99 is a distinct owner parcel, and the 99- and 65-unit building parcels
were later carved from developer lot 78.

The complete 13-page scan was subsequently exported from the public ACRIS
viewer by the supervising researcher as
`tasks/audits/download_parent_review_documents/code/site_research_supervisor_2026-09-16/godwin_agreement_2025052300873001.pdf`.
I inspected the recorded diagrams on scan pages 11 and 13 from that local
source. Page 11 is drawing **Z-006,
“LIGHT AND AIR EASEMENT,”** and its title block clearly carries job
**X01201390-I1**. It labels **“TENTATIVE LOT 78 / AREA - 8,864.23 SQ FT”** and
an existing **“ONE STORY MASONRY BUILDING / AREA - 8,936.30 SQ FT.”** The
second number is transcribed as printed even though it exceeds the stated lot
area. The same drawing labels **“TAX LOT 99 / AREA - 12,998.82 SQ FT”** and an
existing **“ONE STORY MASONRY BUILDING / AREA - 11,715.90 SQ FT.”** It also
marks lots 72, 86, 87, and 95 **“NOT IN SCOPE.”** Page 13 is drawing **Z-007,
“MIDWAY OF THROUGH LOT,”** and labels a **“Rear Yard Equivalent Area.”** Its
job-number line and the small labels inside the two outlined proposed-building
shapes are too degraded to transcribe reliably. I therefore cannot identify a
second DOB job from these drawings. The diagrams document tentative lot 78,
tax lot 99, and two building outlines, but their legible text does not assign
the retained lot or either outline to X01202536-I1.

A later recorded agreement supplies that allocation in text. ACRIS document
**2026071500691002**, dated July 9, 2026 and recorded July 17, is a 27-page
Declaration of Zoning Lot Development Agreement among North BX Associates LLC
in its separate capacities as owner of lots 78, 79, and 88. Page 4 says
historic tax lot 78 was apportioned into those three new lots. It defines lot
78 as land with an existing **“Lot 78 Owner Building,”** lot 79 as land on
which the **“Lot 79 Owner Building”** may be located, and lot 88 in the same
way for the **“Lot 88 Owner Building.”**

The development-right allocations match the two DOB programs exactly. Page 6
assigns the Lot 79 Owner Building **62,461.38 square feet of residential floor
area, 99 dwelling units, 1,768.21 square feet of commercial floor area, and
175.16 square feet of community-facility floor area**. Page 7 assigns the Lot
88 Owner Building **31,707.78 square feet of residential floor area and 65
dwelling units**. Page 6 separately identifies **8,967.30 square feet of
commercial floor area** used by the existing Lot 78 Owner Building. Exhibits A,
B, and C on pages 22-27 provide separate legal descriptions for lots 78, 79,
and 88. The scan does not print either DOB job number, but the dwelling-unit
allocations uniquely match X01201390-I1 and X01202536-I1.

The legal courses independently confirm the recorded parcel areas at their
stated precision. The ten lot-79 courses on page 25 imply approximately
12,539.9 square feet; their rounded lengths and one non-orthogonal West 230th
Street-parallel course explain the roughly 1.1-square-foot difference from the
recorded 12,541. Lot 88 on page 27 is an orthogonal step polygon whose area is
exactly `50 × 100 + 45 × 20 = 5,900` square feet. Lot 78's page-23 description
contains a curved boundary, so I do not derive a separate area from its rounded
courses.

This agreement establishes that the observed 99- and 65-unit buildings are
allocated to lots 79 and 88, respectively, while retained lot 78 contains a
separate existing commercial building. It is strong evidence of coordinated
development within the merged zoning lot. Whether the two DOB filings should
be one economic parent remains an adjudication question distinct from the
recorded land allocation.

DOF transaction 450942, applied November 19, 2025, apportions old lot 78 into
lots 78, 79, and 88. It cites a deed recorded June 10, 2025, CRFN
2025000154906, document ID 2025052900247002
([ACRIS document](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025052900247002)),
a May 21, 2025 survey, and SI job 220743024. The ACRIS master row dates the deed
May 20, 2025; Legals identifies old lot 78, and Parties names North BX
Associates LLC as party 2. Lot 79's final assessment area is
12,541 square feet and lot 88's is 5,900, so the two building parcels total
18,441. The reconstructed predecessor polygon is about 28,483 square feet,
whereas its old `LotArea` attribute is only 17,670. The attribute is therefore
not a sound total to allocate by overlap.

DOF's transaction rows identify only old lot 78 as **Affected** and lots 79
and 88 as **New**; no adjoining old parcel contributes land. The historical
old-lot-78 polygon measures about 28,482.53 square feet and covers essentially
all of both successor geometries. Thus the later allocated building ground
comes from old lot 78 spatially, but 18,441 square feet must not be described
as the historical parcel's recorded area. The archival 17,670 `LotArea`
attribute is internally inconsistent with both the historical polygon and the
later legal descriptions.

The evidence supports proposing these jobs for companion-parent review. If
that link is accepted, 18,441 square feet measures the land ultimately
allocated to the two buildings. Without that link, the recorded agreement and
later parcel evidence support 12,541 square feet for the Godwin 99-unit
building and 5,900 for the Kimberly 65-unit building. Retained lot 78 is part
of the broader coordinated zoning/development arrangement but is not allocated
to either new residential building in this agreement.

## 623 East 178 Street / Hughes Avenue, Bronx

The accepted filing-role decision is supported by city data. X01252745-I1
(70 units on old lot 87, filed July 8, 2025) and X01252502-I1 (60 units on old
lot 89, filed July 9) name Grun Group, Yonah Grunhut, and Nikolai Katz. Each
description asks for the same examiner as the other and says they are "one
zoning lot with the same owner and applicant." DOB records both as withdrawn.
X01273665-I1, filed August 20, proposes 99 units at lot 88 with the same owner,
applicant and architect; it was approved December 16 and first permitted March
9, 2026. These are alternative designs, so their units are not additive.

The boundary evidence is narrower than the economic relationship. At the
December 28, 2023 reference date, lots 87-90 totaled 10,124 recorded square
feet: 2,837 + 2,431 + 2,428 + 2,428. DOF transaction 464942, applied December
9, 2025, merged **lots 88, 89, and 90 only** into live lot 88. DOF cites deeds
dated November 10 and recorded November 17-18, 2025. ACRIS Legals assigns
document 2025111201097001 to lot 88
([lot 88](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025111201097001)),
2025111300218001 to lot 89
([lot 89](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025111300218001)),
and 2025111201087001 to lot 90
([lot 90](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025111201087001)).
The respective CRFNs are 2025000310325, 2025000312110, and 2025000310295;
ACRIS Parties names East 178 LLC as party 2 on all three deeds.
Those three predecessor areas total 7,287 square feet. Lot 87 was not part of
the merger and remains a distinct mapped parcel.

The two withdrawn filings establish a broader earlier zoning concept involving
lot 87, but the live job's tax-lot history and the subsequently reviewed live
zoning instrument assign only old lots 88-90 to new lot 88. Therefore 7,287
square feet is the archival administrative sum for the live 99-unit project's
three predecessor parcels. The recorded development agreement gives an exact
Developer Parcel area of 7,292.40 square feet. Old lot 87 belongs to the
withdrawn July design and is excluded from the live recorded diagram and
Developer Parcel.

## Remaining document requests

Two exact documents remain most useful: the initial ZD1/site plan for
B01320823-I1 and the public initial ZD1/site plan for B01327363-I1. DOB's legacy BIS
page returned an access-denied response during this review, so no restricted
viewer or access control was bypassed. The conclusions above use public city
open-data rows, frozen DOF history, and explicitly identified public documents.

## Round 2: additional source gathering

This pass sought the actual filing drawings and other primary records. It did
not change any adjudication. The ACRIS tab available in this agent session had
expired, but the supervising researcher later opened a fresh public viewer
session and exported the complete agreement scan. The page 11 and 13 findings
above come from that saved source. Public web searches and the DOB NOW portal's indexed surface did
not expose downloadable initial ZD1 or site-plan bytes for any of the four
jobs. Later recorded instruments supplied the Godwin/Kimberly allocation and
the East 178th live zoning diagram, as described below.

The full public DOB NOW filing family adds one material fact at 159 Broadway.
Filing **B01327363-S9**, filed July 1, 2026, describes “selective partial
demolition of existing slab on grade and non-bearing concrete columns/walls”
in conjunction with B01327363-I1. This official row supports physical work on
existing construction under the new filing. It does not by itself establish
how much of job 320911233 was built, whether that older filing should be
classified as replaced, or the land outside tax lot 34. The relationship and
broader zoning boundary therefore remain unresolved without the plans.

The other related-filing rows do not identify additional lots or site area.
For Charles Place, all 19 DOB NOW records in the filing family use block 3183,
lot 71; none lists old lot 7 or states a zoning-lot area. This does not resolve
whether the observed building boundary includes the 2,590-square-foot addition
merged into lot 71 after filing. For Godwin/Kimberly, the related rows remain
separate by later lots 79 and 88 and do not name one another. They add no
building-boundary evidence beyond the recorded zoning agreement already
described. For East 178th Street, the 15 DOB NOW records in the live filing
family all use later lot 88. A related legacy DOB BPP filing, job 240363959,
states a total lot frontage of 72 linear feet and explicitly says it was filed
with X01273665-I1. It does not list the predecessor lots or a site area, so it
could not decide whether old lot 87 remained appurtenant by itself. The later
recorded instruments reviewed below resolve that question.

The new raw files are `dob_now_all_related_filings.json` (60 rows) and
`dob_bis_x01273665_related.json` (one row). They are original city API bytes,
with query details and hashes in the source folder.

## Round 3: block-level recorded-instrument search

I searched the complete ACRIS Legals index for the relevant lots, then joined
the returned document IDs to official Master and Parties rows. These are index
findings, not claims about unread scan text. The original API responses, exact
queries, row counts, and hashes are preserved in the source folder. A fresh
attempt to create a public ACRIS viewer tab failed because this agent's browser
runtime was unavailable; the scan links below are provided for independent
inspection.

For Godwin/Kimberly, ACRIS agreement **2026071500691002**, dated July 9,
2026 and recorded July 17, indexes successor lots **78, 79, and 88**. All
listed parties are North BX Associates LLC. This is the strongest newly found
instrument for crosswalking the retained parcel and both building parcels
([ACRIS detail](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026071500691002)).
Easement **2025111701143001**, dated November 28, 2025 and recorded December
5, indexes lots **79 and 88**, again with North BX Associates LLC on both sides
([ACRIS detail](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025111701143001)).
Easement **2026071500691001** links lot 79 to commercial tax lot 99. These
indexes show recorded relationships among the parcels. The 27-page agreement
was subsequently reviewed and its explicit building allocations are reported
in the Godwin/Kimberly section above.

For Broadway, three easement recordings dated August 22, 2025 index lot 34 at
159 Broadway together with adjacent lot **28 at 175 Broadway**:
**2025101600646001**, **2025120200300001**, and **2025121500836001**. Their
listed parties are 159 Broadway Owner LLC and Driggs Broadway LLC. The latest
recording is available at the
[ACRIS detail page](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025121500836001).
This is new primary evidence that the project parcel participates in recorded
rights with an adjacent parcel. Review of the 26-page instrument establishes
that lot 28 supplies access/ramp easements between distinct buildings; it does
not support expanding the 9,262-square-foot lot-34 building boundary. The
B01327363-I1 zoning drawing remains necessary to classify the predecessor
filing relationship more precisely.

For East 178th Street, zoning document **2026020500129001**, dated January 29,
2026 and recorded February 5, indexes current lot 88 together with adjacent
lot **81 at 1997 Hughes Avenue**; East 178 LLC is the listed party
([ACRIS detail](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026020500129001)).
A declaration, agreement, and easement dated November 10, 2025—documents
**2025112100418002**, **2025112100418005**, and **2025112100418006**—index
lots **81, 88, 89, and 90** and list 1997 Realty LLC and East 178 LLC. None of
these index rows lists old lot 87.

The supervising researcher subsequently exported the six-page zoning
instrument to
`tasks/audits/download_parent_review_documents/code/site_research_supervisor_2026-09-16/east178_zoning_2026020500129001.pdf`.
Page 2 states that the zoning lot to which the applicant's permit or permits
pertain consists of **“New Lot 88 (Formerly Old Lots 90, 89, 88) and 81 in
Block 3068.”** The legal
descriptions on pages 2-4 cover old lots 90, 89, and 88 plus lot 81. Exhibit A
on page 6 draws the same three old lots as adjacent 24-foot-wide strips
fronting East 178th Street and connecting at their rear to lot 81. From west to
east, it gives depths of 101.25 feet for lot 90, 101.27 feet for lot 89, and
101.29 feet for lot 88; the eastern outside edge is 101.32 feet because the
rear line is slightly skewed. Their stated widths and depths imply about
7,291.44 square feet in total. Lot 81 is drawn behind them with a 184.12-foot
north edge, 184.27-foot south edge, and 150.48-foot Hughes Avenue edge.

Old lot 87 appears in neither the operative description nor Exhibit A. This
primary diagram therefore identifies the new-lot-88 ground as old lots 88-90
and excludes old lot 87 from the recorded zoning diagram. It also places that
ground in a larger zoning lot with lot 81. The latter relationship does not by
itself assign lot 81 to the observed building footprint.

The 30-page Zoning Lot Development and Easement Agreement,
**2025112100418005**, supplies the exact allocation. Page 4 defines lot 81,
with its existing **“Owner Building,”** as the Owner Parcel and old lots 88,
89, and 90 as the Developer Parcel on which the **“Developer Building”** may
be constructed. Page 6 assigns the Owner Parcel 62,322.10 square feet of
retained residential floor area, 75 dwelling units, and 12,464 square feet of
lot coverage; page 7 transfers excess rights for the new Developer Building.
The legal descriptions on pages 26-28 again include lot 81 and old lots 88-90,
with no old lot 87.

Most decisively, the development-right chart on page 29 states exact land
areas of **27,706.40 square feet for Owner lot 81** and **7,292.40 square feet
for Developer lots 88, 89, and 90**. It assigns 58,073.77 square feet of
residential floor area and density of 102.05 units to the Developer Parcel
after transfer. Page 30's Light and Air Easement Survey depicts the same
parcel relationship. The 7,292.40-square-foot recorded allocation is the
legal-instrument measure for the observed development ground; the 7,287-square-
foot archival administrative sum is a close comparison rather than the source
of that allocation.

### Reusable checks for other shared-site flags

The remaining shared-site rows suggest four factual checks that can be applied
before opening a bespoke document review. A direct same-lot predecessor new
building should be checked for a completion record, an explicit reference in
the current filing, and demolition or reuse shown in the current plan; a permit
or old status alone does not establish a live companion. An explicit master
plan project number establishes a common project but still requires the master
site schedule to allocate land among buildings and uses. A filing found only
inside a DOF transaction envelope should not enlarge the observed building
boundary without direct spatial overlap, a job cross-reference, or a recorded
zoning/easement instrument. Finally, contemporaneous sibling buildings can be
part of one economic project while occupying separately allocated parcels, so
the relationship and the land assignment should be recorded as separate facts.

Concrete examples are B01391270/B00878475 and X01346560/210179625 for the
same-lot predecessor check; Q01274555/Q01275341 for an explicit shared MPP
(`Project-000000254`) with distinct gaming-facility and parking-garage uses;
Q01359877/Q01385871 and X01298990/X01298988 for transaction-envelope-only
neighbors; and the Q01177691 Beach 30th Street group for multiple permitted
multifamily buildings followed by proposed two-family lots in the surrounding
transaction envelope. These checks classify the evidence source; they do not
adopt parent links or land allocations.

### Records still needed

- B01320823-I1 initial ZD1/site plan: needed to test whether old lot 7 belongs
  to the observed building boundary.
- B01327363-I1 initial ZD1/site plan and the relevant 320911233 plan/status
  documents: needed to verify the indexed broader zoning-lot claim and the
  predecessor construction relationship.
- X01201390-I1 and X01202536-I1 initial ZD1/site plans would provide building
  footprints, but the recorded 2026 agreement now connects the 99- and 65-unit
  programs to lots 79 and 88 and identifies retained lot 78 separately.

## Round four: comprehensive Bronx unresolved-parent screen

The supervisor requested a parent-level screen of all 48 Bronx rows marked
`unresolved == TRUE` in the frozen pre-round-three scope file
`/tmp/nyc_site_scope_before_round3.csv`. This table combines that frozen DOF
map comparison with the already saved DOB filing rows and the recorded
instruments reviewed above. The DOF-only rows are screening facts, not new
primary-document closures. Areas called “earlier” are the frozen audit's mapped
parcel areas and must not be substituted for an observed building boundary.

| Parent | Units | Concrete finding/evidence | Precise open item |
|---|---:|---|---|
| `historical__210182069` | 710 | Frozen DOF map comparison links the filing to earlier parcels 2023490038;2023490046;2023490047;2023490100: earlier area 225,839 sf, filing-lot area 29,200 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__220700873` | 562 | DOB records show legacy 220700873 (562 units) permitted on lot 1; later X00756455 proposes the same 562-unit, 19-story building on lot 1 and is withdrawn. | Verify from plans whether X00756455 was a refiling of 220700873 and allocate the 149,213-sf observed overlap within the 553,463-sf old lot. |
| `post_policy__X01298990-I1` | 510 | DOB identifies X01298988 as a college dormitory on lot 85 found only in the DOF envelope; the 510-unit parent directly overlaps lot 100. | Obtain a master/site plan before treating dormitory lot 85 as shared physical development land. |
| `historical__X00602987` | 483 | DOB shows later X00932163 (329 units) on the same lot 265 as X00602987 (483 units); both remain at objections and the later point is outside the historical-parent land test. | Compare actual plans/job references to decide replacement, redesign, or separate phase; status alone is insufficient. |
| `historical__X00561795` | 405 | DOB NOW descriptions reciprocally identify X00561795 (283 units) and X00673520 (122 units) as Buildings A/B of a two-tower project on one zoning lot. | Obtain the filed site schedule/drawing allocating ground between BBL 2344-1 and 2344-27. |
| `post_policy__X00945951-I1` | 347 | Frozen DOF map comparison links the filing to earlier parcels 2024200120;2024200150: earlier area 121,543 sf, filing-lot area 54,172 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00757318` | 340 | DOB identifies X00875055 as a school at 3850 Review Place found only in the DOF envelope; it does not directly match or overlap the parent filing land. | Do not enlarge the residence boundary for the school without a recorded master-site drawing; obtain the residential ZD1 for its two-old-lot allocation. |
| `post_policy__X00932163-I1` | 329 | DOB shows earlier X00602987 (483 units) on the same lot 265; both remain at objections. | Compare actual plans/job references to establish whether the 329-unit filing replaces the earlier 483-unit scheme. |
| `historical__210180828` | 326 | DOB/DOF screening places completed 326-unit 210180828 and permitted 244-unit 210180819 on separate current lots carved from shared earlier land. | Obtain the contemporaneous subdivision/site plan that allocates the old parcel between the two buildings. |
| `historical__220696851` | 301 | DOB records 310/322 Grand Concourse as two same-day components of this 301-unit parent; 276 Grand Concourse is a separate completed 215-unit parent in the transaction history. | Use the recorded site/easement plan to test whether lot 10 contributes ground or only rights to the 310/322 project. |
| `post_policy__X01265022-I1` | 298 | DOB NOW identifies a 91-unit building on lot 20 and later 207-unit sibling on lot 1 under the same parent. | Obtain the common master/site plan to distinguish each building footprint within the 145,120-sf earlier site. |
| `historical__210180105` | 265 | DOB/DOF screening finds later 79-unit X00702588 on a distinct lot within the earlier land associated with the 265-unit filing. | Obtain the subdivision/site plan allocating the former parcel between the 265- and 79-unit buildings. |
| `post_policy__X01250398-I1` | 255 | DOB NOW identifies three same-parent buildings on lots 1, 1/3, and 1/5 (77, 84, and 94 units), totaling 255 HDB units across listed filing lots. | Obtain the three-building site plan or recorded subdivision because the reference parcel map lacks later lots 3 and 5. |
| `historical__210180819` | 244 | DOB/DOF screening places permitted 244-unit 210180819 and completed 326-unit 210180828 on separate current lots carved from shared earlier land. | Obtain the contemporaneous subdivision/site plan that allocates the old parcel between the two buildings. |
| `historical__X00619862` | 218 | Frozen DOF map comparison links the filing to earlier parcels 2023690008;2023690009;2023690010;2023690048;2023690067;2023690068;2023690069;2023690070;2023690071: earlier area 36,854 sf, filing-lot area 2,625 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__220689921` | 215 | DOB records this completed 215-unit building on lot 10; the later 310/322 Grand Concourse parent lies elsewhere in the transaction envelope. | Use the recorded site/easement plan to distinguish common rights from physical ground. |
| `post_policy__X01350003-I1` | 214 | Frozen DOF map comparison links the filing to earlier parcels 2023640055;2023640056;2023640058;2023640060;2023640061: earlier area 14,388 sf, filing-lot area 6,644 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__210181079` | 205 | Frozen DOF map comparison links the filing to earlier parcels 2037300001: earlier area 344,900 sf, filing-lot area 344,900 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X08028724` | 195 | DOB NOW shows a later zero-dwelling-unit new-building filing X01384282 at 283 Walton on the same current lot as the 195-unit filing. | Inspect its use and site plan; zero dwelling units does not by itself prove a companion or replacement. |
| `historical__X00643959` | 177 | Frozen DOF map comparison links the filing to earlier parcels 2042390005: earlier area 61,278 sf, filing-lot area 61,278 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `post_policy__X01255412-I1` | 168 | DOB NOW identifies two 84-unit same-parent buildings on lots 40 and 40/42 at 112 and 120 East 167th. | Obtain the common site plan or later parcel map to allocate physical ground between the buildings. |
| `historical__X00587608` | 163 | Frozen DOF map comparison links the filing to earlier parcels 2023880061;2023880064;2023880067;2023880068;2023880069: earlier area 25,064 sf, filing-lot area 1,858 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__210179242` | 153 | Frozen DOF audit reports a source/reference-date disagreement: earlier area 21,378 sf, filing-lot area 13,337 sf. | Resolve the date/source mismatch with the recorded lot action and filed survey; do not choose an area mechanically. |
| `historical__210180533` | 141 | DOB shows 141-unit 2455 Third Avenue and 123-unit 227 East 134th filed the same day, permitted the same day, and completed separately on successor lots. | Obtain the subdivision/site plan allocating former lot 37 between both buildings. |
| `historical__X08043433` | 136 | DOB NOW shows X08043433 (136 units, filed 2022-12-15) withdrawn and X01376382 (135 units, filed 2026-03-26) active at the same address and lot. | Compare filed plans or explicit job-reference fields to establish replacement versus a changed project. |
| `historical__X00562360` | 134 | Frozen DOF map comparison links the filing to earlier parcels 2046570001;2046570004: earlier area 24,808 sf, filing-lot area 10,458 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__210180178` | 134 | Frozen DOF map comparison links the filing to earlier parcels 2029460001;2029460042: earlier area 39,740 sf, filing-lot area 2,740 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00695344` | 126 | Frozen DOF map comparison links the filing to earlier parcels 2026540001: earlier area 64,645 sf, filing-lot area 64,645 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__210180542` | 123 | DOB shows 123-unit 227 East 134th and 141-unit 2455 Third Avenue filed/permitted together and completed separately. | Obtain the subdivision/site plan allocating former lot 37 between both buildings. |
| `historical__210181382` | 117 | DOB places 117-, 42-, and 16-unit contemporaneous buildings on lots 50/30/40; later X01157279 proposes 213 units on lot 15 within the broad earlier union. | Obtain a master/subdivision plan separating the three original buildings and later lot 15; point containment alone cannot allocate land. |
| `historical__X00705496` | 111 | Frozen DOF map comparison links the filing to earlier parcels 2039630057: earlier area 22,790 sf, filing-lot area 22,790 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00682437` | 104 | DOB NOW shows X00682437 (104 units) permitted on lots 44/49 and later same-size X00888703 withdrawn on lot 44. | Inspect both site plans/job references to determine whether the withdrawn row was a duplicate refiling and which ground the permitted building occupies. |
| `historical__210181747` | 102 | Frozen DOF map comparison links the filing to earlier parcels 2031900001: earlier area 46,563 sf, filing-lot area 46,563 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00554868` | 101 | Frozen DOF map comparison links the filing to earlier parcels 2031250026;2031250027;2031250028;2031250034;2031250047;2031250048;2031250049: earlier area 12,727 sf, filing-lot area 1,686 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__210180604` | 101 | Frozen DOF map comparison links the filing to earlier parcels 2033100066: earlier area 44,717 sf, filing-lot area 44,717 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00696576` | 100 | DOB NOW description expressly says the 100-unit building merges lots 16, 17, 18, 19, 29, 40, and 42. | Obtain its ZD1/site plan to identify which of those lots are physical building ground rather than zoning-lot support. |
| `post_policy__X01201390-I1` | 99 | Recorded AGMT 2026071500691002 assigns the 99-unit building to new lot 79 (recorded 12,541 sf) and a separate 65-unit building to lot 88 (5,900 sf); retained lot 78 has the existing building. | No boundary document gap for physical lot 79; retain the sibling-parent membership question for supervisor adjudication. |
| `post_policy__X01252745-I1` | 99 | Recorded AGMT 2025112100418005 defines developer ground as old lots 88–90 (7,292.40 sf) and lot 81 as a distinct retained building/right-transfer parcel; old lot 87 is absent. | Apply the recorded developer parcel to the live 99-unit X01273665 only after supervisor confirms the filing-role replacement. |
| `post_policy__X01171565-I1` | 96 | DOB NOW has two same-day sibling jobs on lots 54 and 55: the HDB parent combines 96 units while one job is nonresidential/supportive housing and the other reports 69 dwelling units. | Obtain the common ZD1/site plan and preserve HDB unit priority while allocating the two physical lots. |
| `historical__X00702588` | 79 | DOB/DOF screening finds earlier 265-unit 210180105 on the companion portion of the earlier parcel union. | Obtain the subdivision/site plan allocating the former parcel between the two buildings. |
| `post_policy__X01346560-I1` | 70 | DOB shows permitted 36-unit legacy job 210179625 and proposed 70-unit X01346560 at the same address and lot. | Compare demolition, completion, and plans to determine whether the new job replaces, enlarges, or coexists with the legacy building. |
| `post_policy__X01202536-I1` | 65 | Recorded AGMT 2026071500691002 assigns the 65-unit building to new lot 88 (5,900 sf), separately from the 99-unit lot 79 building and retained lot 78. | No boundary document gap for physical lot 88; retain the sibling-parent membership question for supervisor adjudication. |
| `post_policy__X01238419-I1` | 64 | Frozen DOF map comparison links the filing to earlier parcels 2030340001: earlier area 9,024 sf, filing-lot area 9,024 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__220694700` | 59 | Frozen DOF map comparison links the filing to earlier parcels 2050690057: earlier area 15,040 sf, filing-lot area 15,040 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__X00687757` | 59 | Frozen DOF map comparison links the filing to earlier parcels 2029740030;2029740131;2029740132;2029740134: earlier area 11,842 sf, filing-lot area 2,500 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `post_policy__X01194154-I1` | 55 | Frozen DOF map comparison links the filing to earlier parcels 2045490019;2045490022: earlier area 10,842 sf, filing-lot area 7,300 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `post_policy__X01177042-I1` | 53 | Frozen DOF map comparison links the filing to earlier parcels 2032760027;2032760046: earlier area 10,973 sf, filing-lot area 6,523 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |
| `historical__220723741` | 52 | Frozen DOF map comparison links the filing to earlier parcels 2026230142: earlier area 10,709 sf, filing-lot area 10,709 sf. | Obtain a recorded subdivision survey or filed site plan allocating the building ground within the larger/partial earlier parcel. |

## Read-only implementation trace: Godwin/Kimberly membership

The existing manual pair-decision convention can represent the supported
economic-parent link, but a pair row alone cannot produce the supported land
area. The two current membership rows are additive components with 99 and 65
HDB-priority units, both filed March 31, 2025. Their filing BBLs are 2057000079
and 2057000088, their saved owner key is `WESTORCHARD MANAGEMENT`, and their
saved applicant is `KAO HWA LEE ARCHITECTS PC`. A reviewed `accept` edge between
`X01201390-I1` and `X01202536-I1` would therefore form a 164-unit parent. Because
the component constructor orders equal-date filings by job number, its expected
identifier is `post_policy__X01201390-I1`.

This fits the existing `pair_decisions.csv` convention. Existing accepted rows
use a documented common project that names distinct buildings/lots, including
the OER-supported Queens Building 2 case and the recorded multi-lot Bergen and
Astoria Cove cases. Agreement 2026071500691002 is at least as direct for the
membership fact: it places the 99-unit Lot 79 Building and 65-unit Lot 88
Building in one agreement under the same legal owner, while identifying the
existing Lot 78 building separately. A manual acceptance would establish an
economic development parent; it would not establish one legal wage-assessment
unit.

The automatic rule did not miss a valid prefiling signal through a coding
error. Both rows have `historical_appbbl = 2057000078` and
`lot_history_group_bbl = 2057000078`, but the first recorded APPBBL date is
December 15, 2025, after both filings. Consequently each row has
`appbbl_change_after_filing = TRUE`; the rule deliberately classifies the pair
as a `later_lot_history_candidate` and refuses `strict_lot_history_link`
(`construct_parent_cohorts.R`, lines 441–460). The filing BBLs and
`site_linkage_bbl`s differ, neither filing description contains the other job
number or a common parsed project code, and the fixed pre-policy parcel map
cannot supply an exact-touch edge for later lots 79 and 88. Matching owner is
only corroboration in the current rule, not an independent link (lines
461–491). There is therefore no existing “same old lot plus sponsor” automatic
acceptance rule; adding one broadly would undo the date safeguard that the
manual review system was designed to preserve.

The land result needs a separate production decision. The current site producer
maps X01201390 to 2023 feature BBL 2057000078 with 17,670 square feet and
X01202536 to feature BBL 2057000099 with 13,125 square feet. Once the jobs share
a parent, its present grouping code deduplicates only identical feature BBLs
and sums distinct ones (`build_parent_site_characteristics.R`, lines 209–231).
A membership-only rebuild would therefore report **30,795 square feet**, not
18,441. The recorded agreement instead assigns physical new-building ground of
12,541 square feet to lot 79 and 5,900 to lot 88, totaling **18,441 square
feet**, and leaves retained lot 78 outside both new-building allocations. Thus
the internally consistent implementation requires two conceptually separate
actions if the supervisor adopts them: the manual membership edge and a
documented site-boundary/area correction. The pair-decision source has no area
fields and cannot safely carry the second action.

## Read-only implementation trace: five Bronx relationship leads

| Lead | Current automatic treatment | Can an explicit source cross-reference close it mechanically? |
|---|---|---|
| X00561795 / X00673520 | Already one historical parent, `historical__X00561795`. The saved link reason is `explicit_job_reference`; the reciprocal DOB descriptions name Buildings A/B and the other job. Both remain additive, correctly totaling 405 units. | Yes; this is the existing successful example. It clears membership, while a drawing is still needed for land allocation. |
| X00696576 and its seven stated merger lots | One 100-unit filing, not a competing-filing pair. Its description establishes a zoning/site search set but does not identify another job. | No refiling or parent link is needed. A filed plan must distinguish physical ground from lots contributing only zoning area or rights. |
| 220700873 / X00756455-I1 | Separate historical and post-policy parents. The latter is withdrawn but the legacy filing is unavailable in the DOB NOW source used by the refiling matcher, and the matcher requires both rows in the same sample. | A direct job reference would support a reviewed relationship, but cannot by itself mark one filing nonadditive across samples. A filing-role decision and plan comparison remain necessary. |
| X08043433-I1 / X01376382-I1 | Separate post-policy parents despite the same BIN and BBL. The old job is withdrawn, but its source owner is the excluded placeholder `PR`; the applicant also differs, so the automatic refiling rule's exact BIN-owner-applicant test fails. | A direct plan/job reference could create a parent edge, but additive versus superseded status remains a filing-role decision. Same address and near-equal units are insufficient. |
| X00682437 / X00888703 | Separate parents. In the current DOB source X00682437 is permitted, while the later X00888703 is withdrawn; the automatic rule only starts from a withdrawn filing and searches for a later nonwithdrawn replacement with the same BIN, owner, and applicant. | No. The observed order is the reverse of the automatic replacement pattern. A cross-reference could establish relationship, but plans/status history must determine whether the withdrawn later job was a duplicate rather than a separate attempt. |

The automatic refiling rule is intentionally narrower than the parent-link
rule. It requires a withdrawn source filing, a unique later nonwithdrawn filing,
the same valid BIN, exact normalized owner and applicant, the same sample, and
an already shared component (`construct_parent_cohorts.R`, lines 729–779).
Explicit job references are automatic parent-link evidence, but they do not by
themselves change `filing_role` or prevent double counting. Of these five
leads, only the two-tower Grand Concourse relationship is already
deterministically closed by an explicit cross-reference; the others require
the distinct factual checks stated in the table.

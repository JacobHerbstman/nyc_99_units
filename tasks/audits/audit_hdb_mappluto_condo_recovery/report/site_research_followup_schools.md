# School parcels in two historical parent envelopes

This note examines only `historical__B00646589` (2971 Shell Road) and
`historical__X00757318` (160 Van Cortlandt Park South). It is source evidence
for parent-boundary review, not an edit to the parent table or unit counts.
The administrative residential counts remain 189 and 340, respectively.
Sources acquired on 2026-09-20, exact API URLs, and SHA-256 hashes are in
[`site_research_followup_2026-09-20_schools/sources.csv`](../../download_parent_review_documents/code/site_research_followup_2026-09-20_schools/sources.csv).

## 2971 Shell Road / 773 Neptune Avenue, Brooklyn block 7269

The historical residential parent `B00646589` is filed on lot 1. Its
2021-12-22 cohort date precedes the 2022-03-24 DOF partial-lot change and
the 2022-09-19 school filing `B00775071` on successor lot 50. The frozen
scope table places only lot 1 in the residential filing and describes lot 50
as a separate school filing in the transaction envelope, not a direct filing
overlap.

The City Register's ACRIS legal, master, and party rows provide a documented
post-split title allocation. Deed `2022052000328001` (document date
2022-05-12, recorded 2022-06-15) indexes **lot 50** and transfers it from
2957 Shell Road QOZ LLC to **773 Neptune Avenue QOZ LLC**. Separate deed
`2022052000544001` (same document date, recorded 2022-06-01) indexes **lot 1**
and transfers it from the same seller to **2971 Shell Road QOZ LLC**. The
later air-rights instrument `2022093000168001` and SAGE instrument
`2022093000197001` each index both lots and name the two ownership entities.
Those instruments establish a legal relationship between the lots; their
index rows alone do not establish that the school occupies residential
building ground or that the residential filing covers the school parcel.

The original [lot 50 deed
`2022052000328001`](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000328001)
confirms more than the index. Its PDF p. 1 conveys the entire school lot to
773 Neptune Avenue QOZ LLC. Schedule A on PDF p. 3 begins at the Neptune
Avenue / West 6th Street corner, runs 78.50 feet west along Neptune,
241.61 feet north, 73.94 feet east to West 6th Street, and 225.54 feet
south to the start. This pins the later school parcel to the southeast
corner of the former tract. The deed does not state parcel area; current
PLUTO gives 17,615 square feet. Its legal description is dated after the
residential cohort date.

The companion original [lot 1 deed
`2022052000544001`](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000544001)
conveys the entire residential lot to 2971 Shell Road QOZ LLC (PDF p. 1).
Its Schedule A (PDF p. 3) starts at Shell Road / Neptune Avenue, runs
284.57 feet north on Shell Road, 205.17 feet east, **241.61 feet south to
Neptune Avenue**, then 209.70 feet west to the start. The school deed's
Schedule A runs **241.61 feet north** from Neptune Avenue along the
adjoining western edge of lot 50. These opposite courses identify the
common legal boundary between the residential parcel to the west and the
school parcel on the Neptune / West 6th Street corner. Neither deed states
an area. Computing areas from their rounded courses independently gives
**53,978.07 square feet** for lot 1 and **17,615.93** for lot 50, agreeing
with current PLUTO's 53,978 and 17,615 to within one square foot; the
[acquisition note](../../download_parent_review_documents/code/site_research_followup_2026-09-20_schools/README.md)
shows the arithmetic. This is a geometry cross-check, not an override of
the 2021 historical lot area.

Current DCP PLUTO 26v2, queried 2026-09-20, lists lot 1 as 53,978 square
feet, owner 2971 Shell Road QOZ LLC, with 189 residential units and an
eight-story building. It lists lot 50 as 17,615 square feet, owner 773 Neptune
Avenue QOZ LLC, with zero residential units and zero recorded building area.
This is a later inventory snapshot, not a measurement of the 2021 filing
footprint or proof of the school's completion status. The two current areas
sum to 71,593 square feet, whereas the frozen 21v1 historical lot area is
71,139 square feet. The 454-square-foot difference is unresolved and should
not be silently reconciled.

**Boundary inference:** the recorded deeds describe complementary,
separately titled parcels after the partial-lot change. The residential
building and 189 units remain on lot 1 in current PLUTO, while school lot
50 is a separate southeastern parcel. This supports keeping school lot 50
outside the residential building's ground. The post-cohort deeds do not
establish the exact 2021 building outline or the legal effect of the shared
air-rights/SAGE instruments; a contemporaneous filed site plan would resolve
those narrower points.

## 160 Van Cortlandt Park South / 3850 Review Place, Bronx block 3271

The correct block is **3271**. Historical residential parent `X00757318` has
a 2022-07-21 cohort date and 340 units; the frozen parcel reconstruction
references old lots 150 and 175, with later lots 150 and 160 in the wider
transaction envelope. School filing `X00875055` at 3850 Review Place is
dated 2023-05-25 and matches only lot 160 in the frozen scope. The school
filing therefore postdates the residential cohort date.

The School Construction Authority's June 2022 [supplemental environmental
study](https://www.nyc.gov/assets/bronxcb8/pdf/2022/Proposed-PS_160-VCPS-BX-EAF-Supp-Report-rev-61622.pdf),
web-accessed on 2026-09-20 and rechecked on 2026-09-21 (physical PDF p. 32,
web text index `P31`; repeated on physical pp. 43 and 75, text indexes `P42`
and `P74`), describes the proposed school as the **western
21,810-square-foot portion of then-lot 150** along Review Place. It states
that the school site was paved parking and places the former church, parochial
school, and parsonage east of it on the remainder, where others would demolish
them and redevelop the land residentially. This independently establishes
that the western school carve removed no earlier building floor. Its
21,810-square-foot figure is a rounded
planning estimate; the later deed describes 21,809 square feet exactly.
The public PDF is readable through the web reader, but direct download
returned a 497-byte access-denied response. A clearly labeled web-access note,
not an asserted original PDF, is preserved as
`vancortlandt_sca_study_access_capture.txt` with its hash in `sources.csv`.

Original ACRIS deed `2022081800392002`, acquired from the City Register's
[document image viewer](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392002),
is much more precise. The document is dated 2022-08-16 and recorded
2022-08-25. PDF p. 1 indexes the **entire lot 160** as vacant land and
identifies the church as grantor and the **New York City School Construction
Authority** as grantee. PDF p. 2 calls lot 160 "formerly p/o Lot 150."
Schedule A on PDF p. 6 fixes the school's perimeter at Review Place, Van
Cortlandt Park South, and West 239th Street and states **21,809 square feet**.
This directly documents a land carve-out and separate public ownership, not
just two job numbers sharing a block.

The companion original [residential deed
`2022081800392001`](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392001)
has the same document and recording dates. PDF p. 1 conveys the entire new
lot 150 to 160 Van Cortlandt Park South Owner LLC. PDF p. 2 identifies new
lot 150 as formerly lot 175 and part of old lot 150. Its Schedule A on PDF
p. 7 states **56,048 square feet** and describes a western edge with
155.99-foot, 25.09-foot, and 85.00-foot segments that mirror the school
deed's eastern edge in reverse. The two conveyed parcel areas sum to
77,857 square feet. Thus the original deed legal schedules themselves
allocate the former site into complementary school and residential ground.

The contemporary residential [ZD1 drawing](https://www.pincusco.com/property-data/ZD1_X00757318_1.pdf)
is a three-page PDF created in September 2022 and signed by architect Ariel
Aufgang in October 2022; those plan dates are after the 2022-07-21 cohort
date. On PDF p. 1, a dashed tax-lot line divides the western **tax lot 160**,
labeled "PROPOSED FUTURE LOCATION OF SCHOOL PLAYGROUND," from eastern
**tax lot 150**, which contains the entire drawn eight-story residential
building footprint and parking. The title block identifies zoning lots 150
and 160; their shared zoning context does not merge the building ground.
PDF p. 3 gives 340 dwelling units for the residential proposal. The drawing
and the deed agree on the physical split.

ACRIS indexes agreement `2022081900245003` and easement
`2022081900245004`, both dated 2022-08-16 and recorded 2022-09-02,
index both lots and name that owner and the SCA. Those index rows show a
documented relationship, not a merged building footprint. Current PLUTO
26v2 separately lists lot 150 as 56,048 square feet, 340 residential units,
and an eight-story building; lot 160 is 21,809 square feet, SCA-owned,
with zero residential units. These areas match the deed legal schedules
and the SCA study's approximate former whole-block area, but do not
match the frozen old-lot area of 59,680 square feet because the historical
candidate-lot definition is different. These vintages must stay separate.

**Boundary inference:** the school parcel was carved out of old lot 150 and
conveyed to SCA as new lot 160; the 340-unit residential building is drawn
entirely on retained lot 150. Lot 160 is therefore separate building ground
within a broader former-church site and shared zoning context. This does
not establish a formal DOB cross-reference or withdrawal between the two
jobs, which is unnecessary to interpret the depicted land allocation.

## Source and cutoff discipline

The two school filings, recorded deeds, current PLUTO, and Bronx ZD1 all
postdate their corresponding residential cohort dates. They are useful
retrospective evidence for allocating later successor land, not grounds to
rewrite a 2021/2022 filing date or its administrative unit count. The
Brooklyn's and the Bronx's deed pairs directly establish later complementary
tax parcels. The Bronx architect drawing also assigns the residential
building to its parcel. A Brooklyn filed site plan remains the missing
direct depiction of the 2021 building outline, though current PLUTO assigns
all 189 residential units to retained lot 1.

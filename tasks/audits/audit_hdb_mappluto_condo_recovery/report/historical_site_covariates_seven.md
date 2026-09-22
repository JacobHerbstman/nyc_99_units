# Seven accepted historical sites: production covariates

This note checks only the seven accepted historical boundaries named in the
September 21 supervisor request. It combines the already saved primary pages
with the frozen staged MapPLUTO attributes and proposes production rows where
both ground and earlier floor placement are established. It does not edit the
central decision table or producer. Six paste-ready rows are saved as
`historical_site_covariates_seven_proposed.csv` beside this note for direct
supervisor review. East 125th Street remains in the judgment queue because the
saved source does not allocate the two earlier buildings across the partial-lot
boundary.

## Proposed results

| Parent | Frozen reference | Source BBLs | Reference area | Development area | Included prior floor | Residential FAR | Broad FAR | Prior use |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `historical__X00757318` | 21v3 | `2032710150;2032710175` | 59,680 | 56,048 | 17,040 | 3.44 | 4.8 | public/transport/utility |
| `historical__Q00528973` | 20v8 | `4002650001;4002650006;4002650013;4002650023` | 82,400 | 82,400 | 201,558 | 7.52 | 10.0 | commercial/industrial |
| `historical__B00646589` | 21v1 | `3072690001` | 71,139 | 53,978 | 0 | 2.43 | 4.8 | vacant land |
| `historical__M00558120` | 20v8 | `1002470001;1002470002` | 145,031 | 41,479 | 0 | 10.0 | 10.0 | parking |
| `historical__121207504` | 20v1 | `1017730020;1017730027` | 78,769 | 42,540 | unresolved | 6.02 | 6.5 | mixed prior use |
| `historical__321595403` | 18v2_1 | `3011290050;3011290100` | 116,535 | 116,535 | 0 | 0.0 | 2.4 | vacant land |
| `historical__321593986` | 18v2beta | `3011900029;3011900045;3011900050` | 55,083 | 55,385 | 0 | 3.0 | 3.0 | vacant land |

Each grouped source set has one residential FAR and one broad FAR. The current
producer can therefore preserve every reference lot and its lot count without
inventing an internal area split. Component order is the single listed job for
each parent.

## Floor-area and use checks

**Van Cortlandt Park South.** The 21v3 archive records old lot 150 at 56,560
square feet and 14,160 square feet of floor, and old lot 175 at 3,120 square
feet and 2,880 square feet of floor. Both are R7-1 with residential FAR 3.44,
broad FAR 4.8, and public/transport/utility use. Residential deed
`2022081800392001`, physical pp. 1–2 and 7, defines successor residential lot
150 at 56,048 square feet from old lot 175 and part of old lot 150. School deed
`2022081800392002`, pp. 2 and 6, separately conveys the western 21,809-square-
foot school parcel. The June 2022 SCA supplemental environmental study is more
explicit: physical p. 32 (web text index `P31`) calls the western
21,810-square-foot school site a
paved parking area and places the former church, parochial school, and parsonage
on the remainder; physical p. 75 (web text index `P74`) again places all three
buildings east of the school site. The exact-job ZD1 p. 1 places the residence entirely on successor
lot 150 and the school playground on lot 160. Together these establish that the
school carve did not remove either archived building from the residential
ground. Retain 14,160 + 2,880 = 17,040 square feet of prior floor. The old
59,680-square-foot administrative total understates the later complementary
deed areas and is used only as the required frozen reference check.

**Orchard Street.** The 20v8 four-lot areas are 37,400, 17,500, 25,000, and
2,500 square feet, totaling exactly 82,400. Their building areas are 140,348,
52,500, 3,710, and 5,000, totaling 201,558. Every parcel is M1-5/R9, with
residential FAR 7.52, broad FAR 10.0, and commercial/industrial use. The April
2022 NYSDEC remedial investigation, physical pp. 9–11, identifies the complete
old four-lot site, lists five existing buildings, and says the residential
tower and accessory two-story garage would replace them. The December 2024
site-management plan, physical pp. 13 and 41, locates both new structures
inside the same boundary. No retained parcel or retained earlier building
needs exclusion. The recorded environmental-easement schedule's 82,508.5
square feet remains a later survey comparison; the adopted boundary uses the
82,400 frozen administrative total.

**Shell Road.** The 21v1 old lot 1 is 71,139 square feet, has zero building
area, R6 residential FAR 2.43, broad FAR 4.8, and vacant-land use. Residential
deed `2022052000544001`, physical pp. 1 and 3, and school deed
`2022052000328001`, pp. 1 and 3, give complementary courses for the later
residential and school parcels. The residential legal dimensions reproduce
the successor administrative area of 53,978 square feet. Because the frozen
reference has no floor area, the unresolved 454-square-foot difference between
the old total and later two-lot sum does not affect prior density or zoning.

**South Street.** The 20v8 archive has old lot 1 at 113,690 square feet and
657,592 square feet of building floor, and old lot 2 at 31,341 square feet and
zero floor. Both have residential and broad FAR 10.0. The September 2021 OER
investigation, physical p. 8, calls lot 2 an asphalt parking lot with no
structures and says the 41,479-square-foot project expands it by 10,138 square
feet from lot 1. The final work plan, pp. 1, 8, 19, and Figure 2 on p. 58,
names exact job M00558120 and maps the enlarged site separately from lot 1's
residential buildings. The full 657,592 square feet is therefore retained
off-site floor and should be entered as `excluded_building_area_sqft`. The
observed development ground was parking, so the row explicitly overrides the
mixed whole-reference classification with `parking`.

**East 125th Street.** The 20v1 archive records old lot 20 at 68,677 square
feet and 64,363 square feet of floor, and old lot 27 at 10,092 square feet and
20,860 square feet of floor. Both are C4-4D, with residential FAR 6.02 and
broad FAR 6.5. The October 2021 OER work plan, physical pp. 6 and 24, says the
42,540-square-foot site came from portions of both old lots and had most
recently contained the Pathmark/Rainbow building and the USPS Triborough
Station. Those descriptions match the two archive floor entries, but they do
not assign either former building to the later boundary. Figure 2 on physical
p. 79 and the exact-job proposed plan on p. 91 show the site only after
demolition. The p. 91 label that residual western lot 20 is vacant therefore
cannot establish where the earlier Pathmark building stood. The contrary
archive geometry is material: old lot 20 reports a 420-foot building frontage
while the Figure 2 site has only 240 feet 6 inches of East 125th Street
frontage, making retention of all 64,363 square feet of old-lot-20 floor
unsupported. The work plan also says the site uses only the majority of old lot
27, so the 20,860-square-foot USPS entry cannot be treated as wholly included
without an earlier footprint or demolition/site plan. Ground (42,540),
homogeneous FARs (6.02 and 6.5), and mixed prior use are supported, but no
production row should be added until a primary existing-conditions plan
allocates the 85,223 square feet of earlier floor between the development and
retained land.

**595 Dean Street.** The 18v2_1 archive gives old lot 50 as 62,475 square feet
and old lot 100 as 54,060, totaling 116,535; both have zero floor, M1-1
residential FAR 0, broad FAR 2.4, and vacant-land use. Recorded cooperation
memorandum `2019021300759011`, physical pp. 4 and 10–11, defines the two legal
rectangles as the B13 and B12 premises. The filing-era DOF map and ESD's B12/B13
unit crosswalk tie both premises to the 798-unit, two-building parent. The
complete earlier premises can be grouped without a floor or use adjustment.

**54 Crown Street.** The 18v2beta archive records old lots 29, 45, and 50 at
38,070, 3,480, and 13,533 square feet, totaling 55,083. All have zero floor,
R6A residential and broad FAR 3.0, and vacant-land use. Recorded zoning
declaration `2019091301137002`, physical pp. 3–5, names exact job 321593986
and constructs tentative lot 29 from old lots 29 and 45 plus part of 50;
certificate `2019091301137001`, pp. 4–6, repeats the boundary. The successor
administrative lot is 55,385 square feet. Because all source parcels have
identical FARs and zero floor, the 302-square-foot administrative mismatch
does not require a fabricated partial-lot allocation.

## Paste-ready proposed rows

The following records use the current 13-column `site_lot_decisions.csv`
order. They preserve administrative units and dates and do not add ancillary
or school jobs as residential components.

```csv
historical,historical__X00757318,X00757318,21v3,2032710150;2032710175,59680,56048,0,,recorded_deed_area,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392001;https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392002;https://www.pincusco.com/property-data/ZD1_X00757318_1.pdf;https://www.nyc.gov/assets/bronxcb8/pdf/2022/Proposed-PS_160-VCPS-BX-EAF-Supp-Report-rev-61622.pdf,"Residential deed pp. 1-2 and 7 defines successor lot150 at 56048 square feet from old175 and part of old150; school deed pp. 2 and 6 conveys the complementary western lot160. SCA study physical pp. 32 and 75 (web text indexes P31 and P74) identifies the western school site as paved parking and places the former church, school and parsonage east on the remainder. Exact-job ZD1 p. 1 puts the residence on150 and school playground on160. Retain both homogeneous-FAR reference lots and all 17040 recorded prior floor on residential ground.",2026-09-21
historical,historical__Q00528973,Q00528973,20v8,4002650001;4002650006;4002650013;4002650023,82400,82400,0,,archival_recorded_area,https://extapps.dec.ny.gov/data/DecDocs/C241256/Report.BCP.C241256.2022-08-15.RIR.pdf;https://extapps.dec.ny.gov/data/DecDocs/C241256/Work%20Plan.BCP.C241256.2024-12-12.SMP.pdf,"RIR pp. 9-11 identifies the complete four-lot 82400-square-foot site, its five existing buildings, and the residential tower plus accessory garage. SMP pp. 13 and 41 locates both new structures within the same boundary. Preserve all four homogeneous-FAR source lots, commercial-industrial use and 201558 recorded prior floor; the later 82508.5 survey area is comparison evidence.",2026-09-21
historical,historical__B00646589,B00646589,21v1,3072690001,71139,53978,0,,successor_recorded_area_checked_against_legal_dimensions,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000544001;https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000328001,"Residential deed pp. 1 and 3 and school deed pp. 1 and 3 establish complementary successor parcels. The residential legal dimensions reproduce the 53978 successor administrative area. The frozen old lot has zero building floor, R6 residential FAR 2.43, broad FAR 4.8 and vacant-land use. Preserve the school as a separate site.",2026-09-21
historical,historical__M00558120,M00558120,20v8,1002470001;1002470002,145031,41479,657592,parking,agency_documented_lot_reconfiguration_area,https://a002-epic.nyc.gov/api/files/fe116c51-ed94-ec11-81c3-005056b05749/download,"Final OER work plan pp. 1 8 19 and 58 names exact job M00558120 and maps the 41479-square-foot expanded lot2 separately from retained lot1 buildings. The September 2021 investigation p. 8 says old lot2 was an asphalt parking lot with no structures and gained 10138 square feet from lot1. Exclude all 657592 recorded lot1 floor and classify the development ground as parking; both reference lots have residential and broad FAR 10.",2026-09-21
historical,historical__321595403,321595403,18v2_1,3011290050;3011290100,116535,116535,0,,archival_recorded_area,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019021300759011,"Recorded memorandum pp. 4 and 10-11 defines B13 old50 and B12 old100 as 245-by-255 and 212-by-255 rectangles, totaling116535. ESD identifies B12 and B13 together as the two 595 Dean buildings totaling the saved798 units. Both filing-era source lots have zero floor, residential FAR0, broad FAR2.4 and vacant-land use.",2026-09-21
historical,historical__321593986,321593986,18v2beta,3011900029;3011900045;3011900050,55083,55385,0,,successor_recorded_area_for_documented_exact_job_boundary,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019091301137002;https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019091301137001,"Zoning declaration pp. 3-5 names exact job321593986 and constructs successor29 from old29 and45 plus part of50; certificate pp. 4-6 repeats the boundary. Adopt successor administrative area55385. All three source lots have zero floor, residential and broad FAR3 and vacant-land use, so the 302-square-foot mismatch needs no invented internal allocation.",2026-09-21
```

## Judgment queue

Six cases have production-ready rows. Their dated limitations remain visible:
Van Cortlandt and Shell use post-filing deeds; Orchard's legal schedule is
108.5 square feet above the frozen administrative union; and Crown's successor
administrative area is 302 square feet above its reference sum. Those
differences affect provenance, not the homogeneous FAR, floor, or use
calculations proposed here.

East 125th Street remains queued. The exact missing fact is an
existing-conditions, demolition, survey, or comparable primary plan that shows
the former Pathmark/Rainbow and USPS building footprints against the later
42,540-square-foot development boundary. The available post-demolition figures
do not show how much, if any, of old lot 20's 64,363 square feet and old lot
27's 20,860 square feet remained outside that boundary.

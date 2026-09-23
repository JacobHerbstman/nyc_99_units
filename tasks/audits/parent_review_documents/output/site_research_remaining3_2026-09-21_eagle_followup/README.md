# Eagle Site D follow-up sources

This folder preserves the official records used to distinguish the observed 745-unit, three-building Eagle Site D phase from the broader 2018 Parcel D ownership and development-rights envelope. `sources.csv` records the URL, acquisition date, byte count, and SHA-256 for each file. The ACRIS PDFs are unmodified Save All exports from the public Document Image Viewer. The GeoJSON and geometry-comparison CSV files are bounded extracts from the project's already archived official MapPLUTO shapefiles; they are derived source excerpts rather than new source publications.

The decisive record is `eagle_self_deed_2022.pdf`. Pages 2–3 say the confirmatory deed covers a portion of the land conveyed under the two May 2018 deeds and was recorded to confirm the present metes and bounds of block 2472 lot 21. Pages 6–7 give the complete legal description and a survey area of **106,018 square feet (2.434 acres)**, prepared from Langan Final Survey FS101 dated October 5, 2018.

The two HPD amendments provide a first-party building-to-premises crosswalk. In `eagle_hpd_agreement_7011.pdf`, pages 2 and 6 define the premises as block 2472 lot 21 and page 9 identifies 221 West Street and 302 total units. In `eagle_hpd_agreement_7012.pdf`, pages 2 and 6 again define lot 21 and page 9 identifies 15 Eagle Street and 108 total units. Those historical street numbers differ from the DOB filing addresses 227 West Street and 27 Eagle Street, but the owner, lot, and exact unit counts match. The official DOB extract places all three jobs, including the 335-unit 1 Eagle Street filing, on that same owner and lot.

The 2018 Subparcel D agreement is intentionally retained as broader context. PDF pages 8–10 and 134–137 show that its `Parcel D Land` included old lots 2, 10, and 21, an Eagle Street strip, and a block 2494 strip, and contemplated separate development on lot 21 and lot 2. It therefore does not define the ground of the observed three-building phase. The filing-era March 4, 2019 DOF map and the later confirmatory deed isolate that phase to lot 21.

The historical-lot allocation is exact in the administrative areas and independently consistent with the official polygons:

- old lot 2: 64,068 minus retained lot 2 of 9,565 = **54,503 square feet**;
- old lot 21: 58,823 minus retained lot 3 of 7,308 = **51,515 square feet**;
- combined development ground: 54,503 + 51,515 = **106,018 square feet**.

The overlay places effectively all of retained lot 2 within old lot 2 and all of retained lot 3 within old lot 21. The 13.9-square-foot cross-boundary sliver for retained lot 2 is GIS boundary tolerance. MapPLUTO 19v1's lot-21 polygon area is 103,390.867 square feet, close to but less precise than the recorded survey. Its `LotArea` field of 160,511 is a lagged administrative value and is not used as ground area.

`dof_dtm_9_eagle_transactions.csv` and `dof_dtm_15_eagle_transactions.csv` preserve the filing-era apportionment rows from the project's already archived official DOF alteration books. Transaction 83289 is expressly `Step one of apportionment`: it drops old lot 2 into affected lot 21 and adds no outside lot. Transaction 83294 then creates retained lots 2 and 3 from affected lot 21 under the October 5, 2018 survey.

The two `dof_dtm_*_eagle_unusual_transactions.csv` files preserve the audit's actual flagged transactions. Transaction 84181, dated March 1, 2019, affects lots 21 and 3 and is explicitly a correction to their lot-face labels. Transaction 86750, dated October 3, 2019, affects lots 2 and 21 and is labeled `paper street removal`. Transaction 87034, dated October 15, 2019, affects the same two lots and is labeled `paper street correction`.

The four additional tax maps bracket those later actions: July 25, 2019 precedes both; October 4 follows the removal; October 15 follows the correction; and April 22, 2020 confirms the resulting map. Lot 21 keeps the same outer perimeter across all four. Official MapPLUTO lot-21 geometry is exactly equal in 19v1 and 20v1. The 19v1-to-20v5 symmetric difference is 0.055 square foot and the maximum boundary displacement is 0.00018 foot, which is coordinate precision rather than a parcel change. Page 6 of the 2022 confirmatory deed carries forward the 2018 survey's Eagle Street centerline course and confirms the same premises after the 2019 paper-street actions. The evidence establishes unchanged economic ground; it does not treat either 2019 action as effective on the March filing dates.

Original DOB site and zoning sheets were not publicly downloadable in this review. NYC DOB's current guidance directs requests for older BIS plans through an authenticated DOB NOW records request. This missing plan copy does not leave the boundary unidentified because the recorded legal description, HPD premises schedules, filing-era tax map, and DOB lot identifiers agree on lot 21.

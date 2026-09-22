# Historical campus-site covariates, 21 September 2026

This note evaluates fixed-vintage land, prior floor, zoning, and use for six historical parents whose development ground had already been adjudicated. It preserves the administrative filing counts and dates. The proposed CSV contains the four cases with exact floor reconciliation; The original review queued Flatbush and Jerome because the available sources did not allocate all earlier floor without an assumption. Flatbush was subsequently adopted with an explicitly approved estimate, documented below; Jerome remains queued. No central decision table, production data, or code is changed here.

The bounded archive extract is `tasks/audits/download_parent_review_documents/code/site_research_covariates_2026-09-21_campus/campus_covariate_crosswalk_rows.csv`. It retains the relevant rows from the official DCP MapPLUTO archives. `flatbush_geometry_overlap.csv` retains the already-built official geometry overlay for the queued Flatbush issue. The original deeds, leases, agency reports, maps, URLs, and hashes remain in the earlier acquisition folders cited below.

## Proposed cases

### 1440 Amsterdam Avenue, `historical__M00641741`, 490 units

Use the two 21v1 reference BBLs `1019840001;1019840028`, recorded area **547,265**, with development ground **24,990** and excluded prior floor **1,291,359**. NYCHA's October 17, 2022 first-party closing notice separates the transfer of **12,500 square feet of land** from 280,000 square feet of air rights. The transferred land became lots 10=10,000 and 30=2,500; these later merged with the already-private lot 28=12,490.

The floor allocation is exact and precedes the new building's recorded floor. In 21v1 the NYCHA campus lot 1 has 1,291,359 square feet of floor and private lot 28 has zero. In 22v1, after the ground split, retained lot 1 still has **1,291,359**, while lots 10, 28, and 30 all record zero. Thus no old campus floor transfers to the housing ground. The included parcels are a mixture of parking (lot 10) and vacant land (28 and 30), so use `mixed_prior_use`. Preserve the common R7-2 residential FAR 3.44, broad FAR 6.5, and 21v1 vintage.

### Casa Celina, `historical__210181079`, 205 units

Use 19v2 BBL `2037300001`, recorded area **344,900**, with development ground **12,613** and excluded prior floor **335,129**. The recorded June 24, 2021 lease memorandum bounds the corner project parcel, and the NYCHA board authorization describes approximately 12,614 square feet. The successor administrative area is 12,613.

The 21v3 split occurs before the new building enters MapPLUTO floor: retained lot 1 keeps the complete **335,129** square feet of old floor, while new lot 39 records **12,613 land and zero floor**. By 23v3_1 the new building appears on lot 39 with 136,032 square feet and 205 residential units. The later vacant-land code follows site preparation and must not be backdated. Leave the use override blank and preserve the 19v2 archive category because the reviewed primary documents do not divide the earlier open grass/parking uses within the leased parcel. Preserve R5 residential FAR 1.25 and broad FAR 2.0.

### 89 DeKalb Avenue, `historical__B00664860`, 324 units

Use 21v1 BBL `3020850001`, recorded area **355,013**, with development ground **28,650** and excluded prior floor **722,990**. The recorded LIU/RXR memorandum defines only lot 15 as the tower land; its companion construction-license memorandum prints 28,650.6 square feet, consistent with the 28,650 administrative area.

The old campus floor is accounted for outside the later tower ground. The 21v3 partition assigns **579,404** square feet to retained lot 1 and **143,586** to separate lot 100; these sum exactly to the 21v1 total of **722,990**. The later lot-15 parcel records zero floor before construction. The July 2023 agreement survey, PDF p. 9, also draws the project lot without an existing building inside it. This establishes zero included prior floor without treating post-demolition vacancy as proof. The old source lot's land-use code is 08, so leave the use override blank and preserve the production category `public_transport_utility`; the more specific historical open-campus use is not resolved by the administrative category. Preserve R6 residential FAR 2.43 and broad FAR 4.8.

### 335 Eighth Avenue, `historical__M00600672`, 188 units

Use 21v1 BBL `1007510001`, recorded area **393,100**, with development ground **40,261** and excluded prior floor **1,433,917**. The December 22, 2022 recorded ground-lease memorandum bounds a 247-by-163-foot rectangle, exactly 40,261 square feet, and excludes the retained Penn South campus.

The fixed-vintage floor allocation is exact. The old 21v1 campus row records **1,489,943** square feet. In 23v3_1, retained lot 1 has **1,433,917**, and project lot 20 has **56,026**; their sum is exactly 1,489,943. The parcel split and ground lease occur before the new residential building enters administrative floor, and Penn South's first-party annual report says the project replaced the all-commercial corner building. Use `commercial_industrial`, R8 residential FAR 6.02, broad FAR 6.5, and the 21v1 source vintage. The 2,057-square-foot difference between the old and successor administrative land sums remains an attribute revision and does not change the recorded 40,261-square-foot lease boundary.

## Follow-up decisions and remaining cases

### 90 Flatbush Avenue, `historical__321595145`, 441 units

The tower ground is 12,603 square feet. The 18v2_1 reference lots 18, 23, and 24 total 16,531 land and 53,670 earlier floor. Geometry assigns the tower all of old lots 23 and 24 and 61.3821169% of old lot 18. The initial review held the floor allocation because the exact building-space partition was unavailable.

**Adopted in the September 21 follow-up:** Jacob approved a flagged estimate assigning floor proportionally within old lot 18. Included floor is 2,450 + 15,640 + 35,580 × 0.613821169178864 = **39,929.757 square feet**, with built FAR **3.168274**. NYC ECF's 2018 DEIS Part 2 p. 118 describes the three-story building; Part 3 p. 1 photographs it. This supports an approximate uniform-density allocation but does not measure the partition. The source table and canonical panel explicitly flag the estimate. [Decision, limitations, and sensitivity](flatbush_floor_review.md).

### St. James Terrace, `historical__210181747`, 102 units

The accepted housing ground is 17,775 square feet, but prior floor remains unresolved. The 20v3 old lot 1 records **13,000** square feet of floor. After the split, 21v3 records 7,650 on retained church lot 1 and 3,650 on housing lot 10, totaling only **11,300**. The unexplained 1,700-square-foot revision cannot be assigned silently to either parcel. The recorded deed and lease establish the ground boundary but do not state the earlier floor allocation. The missing fact is an existing-condition/demolition schedule or a source explaining the 1,700-square-foot administrative correction. Preserve the 102-unit count and queue the covariates.

## Primary source locations

- Amsterdam: `site_research_followup_2026-09-20_four_large/amsterdam_nycha_2022_transfer.html` and the archived DOF rows/maps described in `site_research_followup_four_large.md`.
- Casa Celina: `site_research_followup_2026-09-20_bronx_four/casa_memorandum_lease_2021063001174002.pdf`; decisive legal-description page 9.
- DeKalb: `site_research_followup_2026-09-20_brooklyn_large/dekalb_memorandum_2023071200021002.pdf`, pp. 3, 7, and 9, and `dekalb_construction_license_2023071200021004.pdf`, p. 10.
- Penn South: `site_research_followup_2026-09-20_penn_jerome/penn_ground_lease_2022122800734016.pdf`, pp. 1, 3, and 7, plus the first-party Penn South 2023 annual report.
- Flatbush: NYC Planning `C 180216 ZMK` and the saved NYCIDA May 12, 2020 minutes; the official geometry values are preserved in `flatbush_geometry_overlap.csv`.
- Jerome: `site_research_followup_2026-09-20_penn_jerome/jerome_deed_2021070800201002.pdf` and `jerome_memorandum_lease_2021070800201004.pdf`.

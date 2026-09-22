# Nine accepted post-policy ground corrections: frozen covariates

This read-only diligence applies the frozen 2023 MapPLUTO covariates to nine
already accepted land boundaries in `23_targets.csv`. It does not revisit
membership, units, ground, filing dates, or the other case queue. The proposed
paste-ready rows are in
[`site_lot_decisions_post_corrections_proposed.csv`](site_lot_decisions_post_corrections_proposed.csv).
That file contains the six cases whose earlier floor allocation is supported.
165th Street, Onderdonk, and Kingsbrook are held because their ground is
settled but their earlier floor allocation is not.

The fixed-vintage rule is the same in every case: `23v3_1`. Building area below
is the fixed-vintage `BldgArea`; residential and broad FAR are fixed-vintage
parcel fields. A later plan is used to locate an earlier building only where it
draws or labels the retained structure. No floor area is prorated by land area.

| Parent | Exact additive job order | Frozen reference lots and fields | Supported result |
| --- | --- | --- | --- |
| Ocean, `post_policy__B01268544-I1` | `B01268544-I1` | `3072740025`: area 57,000; floor 10,200 across four recorded buildings; R6; residential FAR 2.43; broad FAR 4.8; use `public_transport_utility` | Development area 20,000; exclude floor 10,200; built FAR 0. Agreement p. 3 identifies the existing church on retained new lot 25, and survey p. 21 draws the existing church complex entirely within retained lot 25 while developer lot 30 is clear; declaration p. 6 gives developer lot 30 as 200 by 100 feet. The similarly numbered old lot 30 is a different retained location and is not a reference contributor. This plan locates every drawn pre-existing component, rather than inferring floor from the later ground alone. |
| North 8th, `post_policy__B01206874-I1` | `B01206874-I1` | `3023150033`: area 12,450; floor 11,800 across three recorded buildings at 275 North 8th; M1-2/R6 (`MX_slash`); residential FAR 2.43; broad FAR 4.8; use `public_transport_utility` | Development area 7,237.85; exclude floor 11,800; built FAR 0. Agreement pp. 4-5 separates retained lot 33 and developer lot 133; p. 48 supplies the courses. Survey p. 51 draws and labels the pre-existing two- and one-story brick components on retained tax lot 33 and the proposed 285 North 8th tower on 133. The later NB record has no full-demolition work. This is an address-and-plan location of the old improvements, not an inference from the split area. |
| East 108th, `post_policy__B01297622-I1` | `B01297622-I1;B01333932-I1` | `3082350342`: area 77,600; floor 33,350; one recorded one-story building; **R5; residential FAR 1.25; broad FAR 2**; use `public_transport_utility` | Development area 44,200; exclude floor 33,350; built FAR 0. Agreement p. 4 separates retained Parcel A from developer Parcel B, p. 35 gives the two developer rectangles, and parking/site plan p. 37 separates the retained one-story Parcel A building and parking area from proposed buildings on 340/341. The official FY2028 successor rows independently retain exactly 33,350 `GROSS_SQFT` on lot 342 and report no gross floor on developer lots 339/340/341, providing an exact administrative reconciliation rather than a floor-area proration. |
| East 178th, `post_policy__X01252745-I1` | `X01273665-I1` | `2030680088;2030680089;2030680090`: areas 2,431 + 2,428 + 2,428 = 7,287; floors 3,720 + 2,480 + 2,448 = 8,648; all R7-1, residential FAR 3.44, broad FAR 4.8, `existing_residential_units` | Count the complete three-lot archival union once, exclude no floor, built FAR **1.186771**. Agreement p. 4 and pp. 26-30 define the developer parcel; the January 2026 zoning diagram pp. 2/6 consolidates those same old lots. The 70- and 60-unit July jobs are nonadditive superseded alternatives. |
| Beach 29/30, `post_policy__Q01177691-I1` | `Q01177691-I1;Q01177738-I1;Q01222315-I1` | `4158210046;4158220044;4158220048`: total area 52,817; floor 0 on all; all R5, residential FAR 1.25, broad FAR 2, `vacant_land` | Development area 47,365.13; exclude no floor; built FAR 0. Easement pp. 5-10, 27, 29 and declaration pp. 3-4, 9, 11 partition the three apartment parcels from fifteen retained small-house parcels. Homogeneous FAR and zero floor make the partial partition exact for these covariates. |
| 165th Street, `post_policy__Q01243880-I1` | `Q01243880-I1;Q01243899-I1;Q01245408-I1;Q01245449-I1;Q01245454-I1;Q01245455-I1` | `4097950030;65;85;89;94;98;99;130`: total area 111,540; total floor 69,813 distributed across eight old parcels; all C4-5X, residential/broad FAR 5. Uses are one `mixed_res_commercial` row (65) and seven `commercial_industrial` rows. | **Hold floor allocation.** Accepted development ground remains 39,349.50. Declaration pp. 4, 34-39, 45 defines six-lot Parcel A and retained Parcel B. The later survey p. 39 labels the new strip lots vacant and the retained center as a one-story building/under construction, but it does not establish where every 2023 old-parcel building stood before possible demolition. Excluding all 69,813 is only a candidate and has been removed from the proposed CSV. Needed fact: exact pre/postpartition same-field `BldgArea` reconciliation or pre-demolition footprints locating all old buildings. Preserve `mixed_prior_use` if a later supported row groups all eight source lots. |
| 21st Street, `post_policy__Q01288509-I1` | `Q01288509-I1` | `4005390037;4005390038`: 2,500 area and 1,000 floor each; both R7X, residential/broad FAR 5, `public_transport_utility` | The 2023 and September 2025 DOF maps show the complete two-lot union becoming one 50-by-100-foot lot before filing. Development area 5,000; include all 2,000 earlier floor; built FAR **0.4**. |
| Onderdonk, `post_policy__Q01337462-I1` | `Q01337462-I1` | `4034660058`: area 13,218; floor 18,658; C4-3A; residential/broad FAR 3; `commercial_industrial` | **Hold floor allocation.** Ground 9,310 is supported: agreement p. 3 makes lot 30 Developer Land, p. 27 calls it the Development Site, and p. 29 prints 9,309.60 square feet; companion ZONE p. 3 separates residual lot 58 on Myrtle Avenue. The old parcel address and residual address suggest the K2 building stayed on residual 58, but the inspected originals do not draw the old building against the split or print successor pre-demolition floor. Excluding all 18,658 and assigning built FAR 0 is a plausible candidate, not yet a production-ready fact. Needed fact: a dated survey/site plan locating the old structure, or same-field successor `BldgArea` before demolition. |
| Kingsbrook, `post_policy__B01318629-I1` | `B01318629-I1` | `3046020001;3046020005`: areas 253,940 + 70,562 = 324,502; floors 291,398 + 297,200 = 588,598; both R6, residential FAR 2.43, broad FAR 4.8, `public_transport_utility` | **Hold floor allocation.** Accepted ground remains 105,382 (92,709 Phase I Parcel A plus 12,673 parking lot 2). Agreement pp. 4, 30-33, 37 and the DEC application identify the retained 195,658-square-foot Owner Land and the five existing Phase I structures. FY2028 DOF successor rows give retained lots 1/5 exactly 195,658 land and 407,582 `GROSS_SQFT`; subtracting that from frozen `BldgArea` would yield candidate included floor 181,016 and built FAR 1.717713. That subtraction is not adopted because field comparability and unchanged retained structures between 2023 and FY2028 are unverified. Needed fact: preconstruction/postpartition MapPLUTO `BldgArea` reconciliation or an original retained-building floor schedule. |

## Direct frozen-archive recheck

I re-read all 22 named parcel rows directly from
`dcp_mappluto_archive_23v3_1.parquet` on September 21 rather than copying the
earlier audit narrative. The aggregate checks are:

| Parent | Frozen area | Frozen floor | Recorded buildings | Zone | Residential FAR | Broad FAR | Use fields |
| --- | ---: | ---: | ---: | --- | ---: | ---: | --- |
| Ocean | 57,000 | 10,200 | 4 | R6 | 2.43 | 4.8 | 08 |
| North 8th | 12,450 | 11,800 | 3 | M1-2/R6 | 2.43 | 4.8 | 08 |
| East 108th | 77,600 | 33,350 | 1 | **R5** | **1.25** | **2** | 08 |
| East 178th | 7,287 | 8,648 | 3 | R7-1 | 3.44 | 4.8 | 01/02 |
| Beach | 52,817 | 0 | 0 | R5 | 1.25 | 2 | 11 |
| 165th | 111,540 | 69,813 | 8 | C4-5X | 5 | 5 | one 04; seven 05 |
| 21st | 5,000 | 2,000 | 2 | R7X | 5 | 5 | 07 |
| Onderdonk | 13,218 | 18,658 | 1 | C4-3A | 3 | 3 | 05 |
| Kingsbrook | 324,502 | 588,598 | 5 | R6 | 2.43 | 4.8 | 08 |

This recheck found two East 108th narrative errors: it had previously been
labeled R6/2.43/4.8 and its retained structure was called four-story. The
actual frozen row is R5/1.25/2 with one one-story building. The proposed CSV
and case row above now use the archive values and correct building description.
No other area, floor, building-count, zoning, FAR, or use discrepancy was found
in the nine cases.

## Source anchors

- Ocean: recorded [development agreement 2026080700950002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080700950002), PDF pp. 3 and 21; [declaration 2026080700950005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080700950005), p. 6.
- North 8th: recorded [development agreement 2026060300664002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026060300664002), PDF pp. 4-5, 48, 51.
- East 108th: recorded [agreement 2026022500765005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026022500765005), PDF pp. 4, 35, 37.
- Ocean, North 8th, and East 108th floor-location cross-check: official [FY2028 DOF daily parcel rows](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/18/query?where=PARID%20IN%20(%273072740025%27,%273072740030%27,%273023150033%27,%273023150133%27,%273082350339%27,%273082350340%27,%273082350341%27,%273082350342%27)&outFields=PARID%2CLAND_AREA%2CGROSS_SQFT%2CNUM_BLDGS%2CHOUSENUM%2CSTREET_NAME%2CBLDG_CLASS%2CTAXYR&returnGeometry=false&f=json), accessed September 21, 2026. Ocean old lot 25 remains 10,200 gross square feet at 2968 Ocean Parkway and North 8th old lot 33 remains 11,800 at 275 North 8th; the recorded surveys locate those addressed improvements on the retained sides of the legal splits. East 108th has the cleaner successor reconciliation: retained 342 is exactly 33,350 gross square feet and developer 339/340/341 report none.
- East 178th: recorded [agreement 2025112100418005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025112100418005), PDF pp. 4, 26-30; [live zoning diagram 2026020500129001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026020500129001), pp. 2, 6.
- Beach: recorded [easement 2025071800009001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025071800009001), PDF pp. 5-10, 27, 29; [declaration 2026061000055018](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026061000055018), pp. 3-4, 9, 11.
- 165th: recorded [development declaration 2026051400252004](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026051400252004), PDF pp. 4, 34-39, 45.
- 21st: official DOF maps [May 2023](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/40053920230504140802) and [September 2025](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/40053920250917153758), p. 1 each.
- Onderdonk: recorded [agreement 2026050800329001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329001), PDF pp. 3, 27, 29; [companion ZONE 2026050800329002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329002), p. 3.
- Kingsbrook: recorded [agreement 2026070900638021](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026070900638021), PDF pp. 4, 30-33, 37; [October 2025 DEC application](https://extapps.dec.ny.gov/data/DecDocs/C224448/Application.BCP.C224448.2025-10-29.Complete%20BCP%20Application.pdf), PDF p. 31. The FY2028 candidate check uses the official [DOF daily parcel endpoint](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/18/query?where=PARID%20IN%20(%273046020001%27,%273046020002%27,%273046020003%27,%273046020005%27)&outFields=*&returnGeometry=false&f=json), accessed September 21, 2026.

The component strings above reproduce the producer's ordering: filing date,
then job number. For East 178th the parent identifier remains the original
review root, while only live replacement `X01273665-I1` is additive.

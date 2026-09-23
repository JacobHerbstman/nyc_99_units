# Reopened case 06: 484 East 178 Street

Acquired 2026-09-22 for historical parent `historical__220212918`. This is a
case-specific research record, not a production source refresh. Original PDF
bytes are in `/private/tmp/reopened_06/downloads/`; the table extracts cited
below are the project's frozen snapshots.

| Source | Exact URL or local source | SHA-256 / identifying row |
| --- | --- | --- |
| DOF block 3043 map effective 2014-01-09, covering the 2022 filing date | https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20304320140109152807 | `1a0f21711e139ad31fa65ad1ecc6b7284ded3d2ee8b14e64c9e0c5d0b79cd0e8` |
| DOF block 3043 map effective 2025-05-07 | https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20304320250507162556 | `3f4fe831db0a7f1fe4f20e1dafff3594fb0f71d6fa946f6f14460825e4da3265` |
| DOF alteration book | `tasks/fetch_dof_tax_map_history/output/dtm_9.parquet`, transaction 304542 | Raw `dtm_9.zip`: `ecbd6947339c3e5047d68787571279d21ca021f28d49389a8bb9c5a61fb9467b` |
| DOF lot actions | `tasks/fetch_dof_tax_map_history/output/dtm_15.parquet`, transaction 304542 | Raw `dtm_15.zip`: `56cad8f380ad39d32c67a91abc35dded087b204345b4153ef02f71182baabc48` |
| DOF map index | `tasks/fetch_dof_tax_map_history/output/dtm_8.parquet`, block 3043 | Raw `dtm_8.zip`: `abcca240d72fe8a708754be61444af781578fd57c9c7b018be08e8faee12850f` |
| 22v1 MapPLUTO staged lot rows | `tasks/stage_mappluto_lots/output/dcp_mappluto_archive_22v1.parquet`, BBLs 2030430010/0016/0022/0023 | Raw `nyc_mappluto_22v1_arc_shp.zip`: `52974c12f498be1c33c2f8767b229148707457cd55c1958b40f36c6b4184c42a` |
| NYSDEC complete Brownfield Cleanup Program application, site C203182 (December 2024 posting; Attachment A dated October 2024) | https://extapps.dec.ny.gov/data/DecDocs/C203182/Application.BCP.C203182.2024-12-04.Complete%20BCP%20Application.pdf | `dd1465b43d22be60baa463369fb6ade196fe865e8ee761ea4a6db62176db568d` |
| NYSDEC February 2026 fact sheet, C203182 | https://extapps.dec.ny.gov/data/der/factsheet/c203182cupropeng.pdf | `a0fb7ef6f552a1ee3ba503c0f7de472ae2a39ed73d877bc42e634f533cb63663` |
| DOB-authored ZD1 diagram for job 220212918, scan ES443460578, dated 2026-03-10, third-party hosted copy | https://www.pincusco.com/wp-content/uploads/2026/04/ZD1-ES443460578-2026_03_31-10_49_35.pdf | `b7e8f7ae23949f4f4aea5e2c203fdaac05eb122b8669810531ff33da10749915` |
| ACRIS master, CRFN 2025000117343 | https://data.cityofnewyork.us/resource/bnx9-e6tj.json?%24where=crfn%3D%272025000117343%27&%24limit=100 | One row, `34b34bd66ecc874e5aaf6231fb41db9bb4442a8710df2f2ada1834ab873473fe` |
| ACRIS legal descriptions, document 2025042401044001 | https://data.cityofnewyork.us/resource/8h5j-fqxa.json?%24where=document_id%3D%272025042401044001%27&%24limit=100 | Four rows, `83ddf3d1d788cda0499ffe4daa0f4807ae2be2ee6297fd437473142e25ff1b22` |

DOF's public table service is
https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer .
The project's September 15, 2026 frozen ZIPs and exact query manifests are
documented by `tasks/fetch_dof_tax_map_history/README.md`; the staged Parquet
rows retain the original DOF fields. The 22v1 archive source is
https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_22v1_arc_shp.zip .

The ACRIS master row has document ID `2025042401044001`, CRFN
`2025000117343`, document type `CORRD`, document date 2025-04-15, and
recording date 2025-05-01. Its four ACRIS legal rows list Bronx Block 3043
Lots 10, 16, 22, and 23. This verifies the CRFN and four-lot legal indexing;
the `CORRD` code does not by itself prove a property conveyance.

## Supervisor preservation and application

The cited direct-download PDFs are now preserved in the acquisition task's `output/` directory under `reopened_XX_` names (replace XX with this case number). The shared `../reopened_batch_2026-09-22/sources.csv` and `sources.sha256` record their exact bytes; `../reopened_batch.make` supplies literal download recipes. Cases 08 and 10 also retain the cited mutable JSON/HTML responses in this source folder. Their temporary research paths are not required for replication. Original acquisition limitations above describe the initial research session.

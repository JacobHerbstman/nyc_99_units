# Four large Brooklyn parcel allocations, September 20, 2026

This folder preserves original public primary records for 595 Dean Street,
698 Atlantic Avenue, 89 De Kalb Avenue, and 54 Crown Street. No audit source
table or production value was edited here. `source_urls.csv` gives the exact
request URL and acquisition date for each of the 36 raw files;
`sources.sha256` hashes every preserved PDF, JSON, and HTML file. The ACRIS PDFs were exported through the
normal City Register viewer by the supervising agent and copied here byte for
byte. Direct City Register retrieval returned a 503 bandwidth notice.

## Recorded documents

| File | Official viewer URL | Document date; recorded date | Reviewed PDF pages |
| --- | --- | --- | --- |
| `dean_agreement_2019021300759011.pdf` | [ACRIS 2019021300759011](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2019021300759011) | 2019-02-13; 2019-02-14 | 4, 10–11: B12 premises are block 1129 lot 100, 212 by 255 feet; B13 premises are lot 50, 245 by 255 feet. The agreement separately names block 1120 B5–B7 premises. |
| `crown_zone_2019091301137002.pdf` | [ACRIS 2019091301137002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2019091301137002) | 2019-09-11; 2019-09-16 | 3–5: applicant's zoning description explicitly names NB job 321593986, tentative block 1190 lot 29 formed from old lots 29, 45, and part of 50; diagram labels retained tentative lot 50 and out-parcels. |
| `crown_certificate_2019091301137001.pdf` | [ACRIS 2019091301137001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2019091301137001) | 2019-08-12; 2019-09-16 | 4–6: title insurer's certification repeats the same tentative lot 29 metes and diagram as the ZONE instrument. No tract area is printed. The successor DOF map dated 2019-12-09 follows that outline and retains the Montgomery Street notch as other lots. |
| `dekalb_termination_2023071200021001.pdf` | [ACRIS 2023071200021001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2023071200021001) | 2023-07-07; 2023-07-27 | 2–3, 5–6: terminates an old LIU/Navy Street easement. It is indexed to lots 1 and 15 but does not describe 89 De Kalb's new-building ground. Retained as a negative scan check. |
| `dekalb_memorandum_2023071200021002.pdf` | [ACRIS 2023071200021002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2023071200021002) | 2023-07-07; 2023-07-27 | 3, 7, 9: LIU/RXR development memorandum defines the Land and Premises only as block 2085 lot 15 and states a mixed-use tower will be constructed on the Premises at the Phase II site. Exhibit A gives lot-15 metes; Exhibit B shows the development-site survey. No DOB job number is printed. |
| `dekalb_construction_license_2023071200021004.pdf` | [ACRIS 2023071200021004](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2023071200021004) | 2023-07-07; 2023-07-27 | 3, 7, 10: despite its DEVR index type, original is a LIU/RXR temporary construction-license memorandum. The broad protected “Project Premises” are lots 1 and 15; p. 7 excludes lot 15 from residual campus lot 1; p. 10 describes separate lot 15 as **28,650.6 sq ft**. No DOB job number is printed. |

The downloaded ACRIS [legal index](https://data.cityofnewyork.us/resource/8h5j-fqxa.json)
is preserved separately for Brooklyn blocks 1129, 1120, 1190, and 2085 as
`acris_legal_block*_2017plus.json`. Each query used
`borough='3' AND block='<block>' AND document_id>='2017010100000000'`,
`$limit=50000`. The [master index](https://data.cityofnewyork.us/resource/bnx9-e6tj.json)
is preserved in four `acris_master_chunk_*.json` responses. Each request used
`document_id in (...)` for up to 30 numeric document IDs from the target lots,
with `$limit=1000`; this retains the original API response rather than
rewriting a derived table. Indexes establish document type, dates, and indexed
lots, not the scanned document's physical allocation.

## DOF map vintages and current parcel attributes

`dof_map_library_brooklyn_blocks.json` preserves the [official DOF map-history
query](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/8/query)
with `BOROUGH='3' AND BLOCK IN (1129,1120,1190,2085)`, all fields, no
geometry, JSON. An initial block-only query is preserved as
`dof_map_library_four_blocks.json` but was not used because it also returned
same-numbered blocks outside Brooklyn. The map PDF URL for every file below is
`https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/`
followed by the ID in its filename. Each map is the original official PDF and
was visually inspected on physical page 1.

| Block | Preserved map IDs | Boundary purpose |
| --- | --- | --- |
| 1129 | `30112920190422074603`, `30112920191112095902`, `30112920230327115329` | Separate B13 lot 50 and B12 lot 100 at the October 2019 filing; later merger and condo recut. |
| 1120 | `30112020170222135621`, `30112020220816100301` | Broad old rail-yard lot 1 versus western 260-by-200-foot successor lot 1, distinct from lots 19 and 35. |
| 1190 | `30119020081204145036`, `30119020190923104410`, `30119020191209154141` | Old Crown/Montgomery lots 29, 45, 50 versus successor lot 29 and retained lot 50/out-parcels. |
| 2085 | `30208520190726103843`, `30208520210402104122`, `30208520230310120558` | LIU campus old lot 1 versus distinct new residential lot 15 on De Kalb Avenue. |

`dof_daily_target_lots.json` preserves the [current DOF property-description
query](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/18/query)
for listed BBLs 3011290050/0100/7503, 3011200001/0019/0028/0035,
3011900029/0045/0050, and 3020850001/0015, requesting all fields and no
geometry. The `LAND_AREA` field gives current recorded areas; it is not by
itself proof of the building ground at the historical filing date.
`geosearch_*.json` preserves [NYC Planning GeoSearch](https://geosearch.planninglabs.nyc/v2/search)
exact-address responses for the four literal addresses, using the `text`
parameter shown by each filename; 89 De Kalb did not return an exact first
feature, while the HDB current site uses 91 De Kalb / lot 15.

## Project-owner sources

- `esd_atlantic_workshop_2025-11-18.pdf`: [Empire State Development workshop](https://esd.ny.gov/sites/default/files/media/document/11182025-AY-PW-1-Presentation.pdf), physical p. 6 identifies B12 and B13 at 595 Dean as 419 and 379 units on block 1129 lot 50 (2025 labeling), collectively 798 units.
- `esd_atlantic_project_update_2024-04-18.pdf`: [ESD project update](https://www.esd.ny.gov/sites/default/files/media/document/41824-AYCDC-Project-Update.pdf), physical p. 5 confirms the same B12/B13 unit split and July 14, 2021 financing closing.
- `esd_atlantic_site_map_2024-12-03.pdf`: [ESD site map](https://esd.ny.gov/sites/default/files/media/document/12324-AYCDC-Project-Update.pdf), physical p. 4 distinguishes B5 at the west end of block 1120 from B6/B7 to the east; B12/B13 are distinct from the adjoining B11/B14 buildings.
- `liu_89_dekalb_breaking_ground.html`: [Long Island University project statement](https://headlines.liu.edu/breaking-ground-new-building-at-liu-brooklyn-to-transform-college-of-pharmacy-2/), which describes the 89 De Kalb development as 324 residences plus LIU academic space. It describes project use, not a land-area allocation.

The case interpretation is in
[`site_research_followup_brooklyn_large.md`](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_brooklyn_large.md).

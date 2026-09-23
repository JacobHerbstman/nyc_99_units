# Four source-ID parcel checks, September 20, 2026

This folder preserves unchanged official DOF tax-map PDFs, DOF ArcGIS JSON
responses, ACRIS Open Data index responses, NYC Planning GeoSearch address
responses, and four ACRIS document scans for four audit parents. The source
query URLs and SHA-256 hashes are recorded here and in `sources.sha256`.
Direct ACRIS page retrieval on this computer returned the City Register's
bandwidth notice; the four scans were exported through another agent's normal
ACRIS viewer session and copied here without alteration.

## DOF Digital Tax Maps

The official [DOF map-library index](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/8/query?where=BLOCK%20IN%20(1102%2C670%2C539%2C3466)&outFields=*&returnGeometry=false&f=json)
is saved as `dof_map_library_four_blocks.json`. `dof_map_library_block1192.json`
adds the Franklin address's actual Brooklyn block. The raw PDFs below came
from the DOF Property Information Portal, using the map IDs in that index:

| Case | Local PDF map IDs | Observed map history |
| --- | --- | --- |
| 964 Franklin | `30110220100125114638`, `30119220211230114221`, `30119220240522130656` | Brooklyn block 1102's current map has no lot 63; block 1192 maps show lot 63 on Franklin Avenue |
| 35-53 41 Street | `40067020081207122547` | Queens block 670 lots 4 and 47 are distinct adjacent lots |
| 27-30 21 Street | `40053920230504140802`, `40053920250917153758` | 2023 map has separate lots 37 and 38, each 25 by 100 feet; September 17, 2025 map replaces them with lot 37, 50 by 100 feet |
| 910 Onderdonk | `40346620081208065919`, `40346620260325150955` | March 5, 2026 successor map still shows distinct lots 30 and 58 |

For each ID, the stable public PDF URL is
`https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/` plus
the exact map ID. All PDFs were inspected visually; the lot labels, dimensions,
and dates were read from the originals.

## Parcel attributes and address crosswalk

- `dof_current_target_lots.json`: [DOF current polygon query](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/0/query?where=BBL%20IN%20(3011020063%2C3011920063%2C4006700004%2C4006700047%2C4005390037%2C4005390038%2C4034660030%2C4034660058)&outFields=*&returnGeometry=false&f=json). Polygon area is used only to confirm parcel existence, not as the adopted recorded land area.
- `dof_daily_target_lots.json`: [DOF current property-description query](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/18/query?where=PARID%20IN%20(%273011020063%27%2C%273011920063%27%2C%274006700004%27%2C%274006700047%27%2C%274005390037%27%2C%274005390038%27%2C%274034660030%27%2C%274034660058%27)&outFields=PARID%2CHOUSENUM%2CSTREET_NAME%2CLAND_AREA%2CLOT_FRT%2CLOT_DEP%2CTOTAL_UNITS%2COWNER%2CTAXYR&returnGeometry=false&f=json). The `LAND_AREA` field supplies the reported recorded areas.
- `geosearch_*.json`: [NYC Planning GeoSearch](https://geosearch.planninglabs.nyc/v2/search?text=964%20Franklin%20Avenue%20Brooklyn%20NY) results for the four literal filing addresses. The other three URLs substitute `35-53 41 Street Queens NY`, `27-30 21 Street Queens NY`, and `910 Onderdonk Avenue Queens NY` in the `text` parameter. The first exact-address feature gives PAD BBL and version 26c.
- `geosearch_2728_21.json`: [the Housing Database's alternate 27-28 21 Street address](https://geosearch.planninglabs.nyc/v2/search?text=27-28%2021%20Street%20Queens%20NY), which also resolves to successor lot 37.
- `dob_now_block539_current_empty.json`: the [September 20 current DOB NOW API block query](https://data.cityofnewyork.us/resource/w9ak-ipjd.json?%24where=borough%3D%27Queens%27%20AND%20block%3D%27539%27&%24limit=50000). It returned `[]`, as did a query for a known saved Jamaica filing. This is a current-feed coverage limitation, not evidence of no filings.

## Recorded-instrument index

`acris_four_legal_2024plus.json` is the [ACRIS legal-index query](https://data.cityofnewyork.us/resource/8h5j-fqxa.json)
for Brooklyn 1192/63 and Queens 670/4,47; 539/37,38; 3466/30,58,
restricted to document IDs from 2024 onward. `acris_four_master_2024plus.json`
and `acris_four_parties_2024plus.json` are the matching official
[master](https://data.cityofnewyork.us/resource/bnx9-e6tj.json) and
[party](https://data.cityofnewyork.us/resource/636b-3b5g.json) rows for the
legal-index document IDs. These indexes identify type, date, recorded lots and
parties; they do not reveal the scanned agreement's parcel allocation.

## Preserved ACRIS document scans

The PDFs below are the original ACRIS viewer exports acquired September 20,
2026. They are image-only. OCR was used to locate the cited text; decisive
pages (41 Street pp. 13 and 16, Onderdonk agreement pp. 3, 27 and 29,
Onderdonk ZONE p. 3, Franklin ZONE pp. 3 and 4) were also visually checked
against the PDF page number (first page is 1).

| Local PDF | Official viewer detail | Pages | Pages reviewed and finding |
| --- | --- | ---: | --- |
| `41st_declaration_2026082500424001.pdf` | [DECL 2026082500424001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026082500424001) | 27 | pp. 2–3, 13, 16: premises block 670 lots 47 and 4; HPD application p. 16 explicitly lists DOB Q01254595, 330 units, and both lots. |
| `onderdonk_easement_2026050800329001.pdf` | [zoning-lot development agreement 2026050800329001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329001) | 29 | pp. 3–4, 24–25, 27, 29: Developer Land is lot 30; architect calls it the Development Site; Exhibit D p. 29 prints lot 30 area 9,309.60 sq ft. The 44.60 density entry is a rights allocation subject to note 3, not an actual DOB count. |
| `onderdonk_zoning_2026050800329002.pdf` | [ZONE 2026050800329002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329002) | 5 | pp. 2–4: new lot 30 derives from old lot 58; residual new lot 58 derives from old lot 30 and lies on Myrtle Avenue. |
| `franklin_zoning_2025120900296002.pdf` | [ZONE 2025120900296002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025120900296002) | 5 | pp. 2–4: proposed new lot 63 takes most of old lot 66, retaining about 288 ft 5 in of the total Franklin frontage; proposed lot 66 retains about 58 ft. No proposed area is printed. |

The case interpretation and specific scan targets are in
[`site_research_followup_sourceids.md`](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_sourceids.md).

## City Planning project-package screen

Four bounded [City Planning ZAP API](https://zap-api-production.herokuapp.com/projects/)
`project_applicant_text` searches for `DOMAIN 41ST STREET`, `PROSPECTUS
ASTORIA`, `ONDERDONK SUITES`, and `FRANKLIN GARDENS II` returned zero project
rows on September 20. The exact raw responses are `zap_*.json`. These queries
do not establish that no DOB site plan or other City Planning record exists.

## Supervisor follow-up: Elara / 41st Street

`41st_joint_loan_2026082500424009.pdf` was exported through ACRIS Save / All
on September 20, 2026 from
https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424009.
Pages 1–4 identify both Site A and Site B borrowers and all three parcels.
Pages 31–32 describe their ground; pages 33–34 explicitly name both DOB jobs.
Page 35 records joint August 2025 financing predating both October filings.
The root inspected the recorded scan and accepts one 429-unit economic parent,
with 25,787 + 13,216 = 39,003 archival square feet. Membership and land are
pending a coherent production update; wage-assessment status is not inferred.

`elara_developer.html` archives https://thedomaincos.com/portfolio/elara/,
retrieved with curl on September 20. The developer identifies one 429-unit
project at 35th Avenue and 41st Street with S9 Architecture and common financing.
Both files are fingerprinted in `sources.sha256`.

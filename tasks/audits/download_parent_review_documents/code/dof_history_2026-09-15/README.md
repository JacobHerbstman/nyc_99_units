# DOF tax-map history: September 15, 2026 capture

These are frozen public-source extracts collected for the parcel-history feasibility review. They do not feed production data. `sources.csv` records all 50 exact request URLs, the retrieval date, byte counts, and SHA-256 hashes. JSON and the published data dictionary are retained here; the eleven map PDFs are preserved in this acquisition task's `output/`, at the relative paths recorded in the manifest. Raw response bytes are unchanged. No login or API key was used.

The JSON files are review inputs retained with the code. Ordinary audit builds read them without contacting the live service. Refreshing this capture is a separate source change: the public service is mutable and does not promise that its object IDs or historical records remain unchanged. The recorded URLs reproduce the requests, not necessarily the September 15 response bytes. The PDF URLs identify individual historical map versions.

## Sources and queries

The public [DTM service](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer) contains the following relevant tables:

| Layer | Table | Content |
| --- | --- | --- |
| 0 | TAX_LOT_POLYGON | Current lot attributes and geometry |
| 8 | MAPLIBRARY_MAP | Historical-map identifiers, effective/end dates, PDF links |
| 9 | DAB_BOOK_HEADER | Transaction metadata repeated for associated lots |
| 11 | DAB_BLOCK | Block actions |
| 12 | DAB_BOUNDARY | Boundary actions |
| 13 | DAB_CONDO | Condominium actions |
| 14 | DAB_CONDO_UNIT | Condominium-unit actions and associated base lots |
| 15 | DAB_LOT | Lot actions keyed to transaction numbers |

The initial query selected Brooklyn blocks 388 and 1306, Bronx blocks 2923 and 2260, and Queens block 9795. It returned 60 header rows representing 25 distinct transactions. The detail queries then requested **every row for those transaction numbers**, including rows outside the five blocks. They returned 71 lot actions, 14 condo actions, 20 condo-unit actions, zero block actions, and three boundary actions. The lot actions span six blocks. A separate direct lot-table query on the five blocks returned 60 rows and the same 25 transaction numbers.

The map-library query returned 31 versions. Eleven selected maps/insets were downloaded, including both Wyckoff layouts and the historical Third Avenue inset showing lot 135. All PDF transfers were validated with `pdfinfo`. Wyckoff's transaction and six lot-action rows were also checked in the public PIP interface.

All queried detail-table row counts agree with separate service count requests. No full-result response reports truncation. Two seven-row pages, ordered by `OBJECTID`, exactly reproduce the first fourteen rows of the full header query. The service advertises a 1,000-row response limit and supports pagination. These checks establish retrieval feasibility for this sample; they do not certify citywide history completeness.

The public [application tracker](https://nycdof.maps.arcgis.com/apps/dashboards/4c90c216b3064767805833ff147a7e2a) references the `TMU_Application_Points_Public` service, layer 3. Its five-block query used the primary numeric `Borough_Block_Lot` and returned ten records. It requested dates, status, type, requested lot count, and associated-lot text. It does not cover applications whose primary BBL is outside those blocks. Text in `Multiple_BBLs` includes lists, ranges, and escaped whitespace and is retained as recorded.

`opendata_metadata.json` preserves the link to DOF's relational dictionary. Its DAB tables use older names: `DAB_TAX_LOT` and `DAB_WIZARD_TRANSACTION`. The dictionary defines `TRANS_NUM` as the transaction identifier and distinguishes New, Affected, Dropped, numbering changes, and effective-tax-year changes. It describes the transaction authority as free text, which can cite ACRIS documents. The DAB tables are nonspatial; historical shapes require maps or spatial archives.

## Consumers

`audit_hdb_mappluto_condo_recovery/code/review_dof_history.R` produces the dated review's lot-change and application extracts, with SaveData reports. The substantive assessment is in that task's `report/dof_history_feasibility.md`. The Third Avenue predecessor correction also updates the existing five-parent parcel review in `fit_pure_notch_pilot`; production footprints and model estimates remain unchanged.

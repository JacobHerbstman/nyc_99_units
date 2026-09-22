# Ten-parent boundary review, September 22, 2026

These are unchanged source records used to review the next ten queued parents.
The research conclusions and individual page citations are in
`../../../audit_hdb_mappluto_condo_recovery/report/next_ten_boundaries_2026-09-22.md`.
Production consumes the committed manual decision table, not these audit files.

## Follow-up source-vintage and recorded-plan evidence

`queued_followup_sources.csv` records unchanged bytes, exact public URLs,
retrieval date, and SHA-256 for the additional sources:

- DCP's 23Q4 Housing Database bundle, downloaded by `../unit_vintages.make`
  from the official archive linked on the current Housing Database webpage.
  `HousingDB_post2010.csv` has 75,444 unique jobs and no missing ClassAProp;
  `HousingDB_post2010_inactive_included.csv` has 100,107 unique jobs, including
  29 missing ClassAProp. Both have Version 23Q4 throughout. The audit reads
  identifiers as strings and parses ClassAProp as numeric. The two files
  agree on ClassAProp for every active-file job. The zip preserves the city's
  dictionaries and other geographic summaries unchanged.
- `livingston_zone_2025021001245002.pdf`: four-page ACRIS Save All export.
  P2 names and draws all three Livingston buildings; p4 gives the earlier
  lots16/26 outer legal description. It does not supply earlier floor areas.
- `rockaway_condo_index.json`: public ACRIS master query for exact CRFNs
  2022000210977 and 2022000210978. Two rows, two unique document IDs; all
  returned fields are source strings and all fields are present. It identifies
  the declaration and plans, rather than retrieving their contents.
- `rockaway_condo_maps_2022051300461002.pdf`: complete 70-page ACRIS Save All
  export. Reviewed physical pp4–7 and 55–61, especially Building D's cellar
  and first-floor definitions on pp57–58. The remaining drawings are saved
  but are not claimed to have been individually reviewed. OCR/renderings used
  for inspection stay in system temporary storage; the PDF is unchanged.

The [follow-up review](../../../audit_hdb_mappluto_condo_recovery/report/queued_followup_2026-09-22.md)
records the historical-unit finding and the completed Wallabout calculation.
The DCP content API and obsolete archive paths inspected during discovery are
not used as dataset inputs. The actual acquired zip URL is in its Make recipe.

## Public downloads

`../next_ten.make` gives nine literal publisher URLs, temporary destinations,
checksum checks, and final filenames. Root `make dof-site-review` reaches it.
Ordinary builds reuse these snapshots. A changed publisher file fails the
recorded checksum rather than replacing the saved evidence.

| Output PDF | Publisher | Content used |
| --- | --- | --- |
| concourse_310_322_rir_2020.pdf | NYSDEC | July 2020 investigation, pp. 6–7, 63, 67; legal site includes part of old lot 10 |
| concourse_261_esa_2021.pdf | NYSDEC | Earlier site assessment reproduced in July 2023 investigation appendix |
| wallabout_appraisal_2023.pdf | Issuer filing on Tel Aviv Stock Exchange | Appraisal pp. 289, 320; separate completed development parcels |
| willets_phase1_smp_2023.pdf | NYSDEC | December 2023 management plan, pp. 8–9, 15–17, 116–117 |
| concourse_261_315_smp_2025.pdf | NYSDEC | December 2025 management plan, p. 16; old lots 1/11/27 and both towers |
| concourse_261_315_coc_2025.pdf | NYSDEC | December 2025 completion certificate, pp. 6–7, 9; recorded boundary and survey |
| wallabout_dof_2021.pdf | NYC DOF | Map 30224920210108124517, including separate lots 37/41 |
| rockaway_dof_2024.pdf | NYC DOF | Map 41553720240626105013; common condominium spans several phases |
| concourse_261_dof_2015.pdf | NYC DOF | Map 20234420151130181804, earlier block configuration |

The exchange filing is an owner-provided appraisal, not a city administrative
unit source. Its areas inform the unresolved boundary review; they do not
replace housing unit counts. The Willets URL contains `C241146H`, while the
downloaded plan identifies the housing site inside the document; interpretation
uses the document's actual boundary and recorded easement.

## Recorded documents saved through ACRIS

Open `https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=ID`,
choose Save, All, OK, and retain the downloaded PDF unchanged. These files were
exported on September 22, 2026; no credentials were needed.

| Local file | Document ID | Physical pages | Reviewed pages |
| --- | --- | ---: | --- |
| noble_deed_2025082600703001.pdf | 2025082600703001 | 8 | 2–3: confirmatory deed boundary |
| walton_zone_2025120500186002.pdf | 2025120500186002 | 5 | 2–3, 5: whole earlier lot and three successor addresses |
| livingston_decl_2026010400010003.pdf | 2026010400010003 | 25 | 2, 13, 16, 21: lot 22, 99 units, April 2025 HPD application, 485-x |
| rockaway_deed_2024051600214002.pdf | 2024051600214002 | 14 | 3, 6–8: units 18/19/20 and common condominium land |

Rockaway's units carry 11.61%, 12.27%, and 4.12% undivided interests. Those
percentages describe ownership of common elements, not each building's physical
ground. The deed therefore does not establish a Phase III ground allocation.

`sources.sha256` fingerprints the first three exports, the nine downloaded PDFs,
and the three JSON snapshots below. `rockaway.sha256` fingerprints the later
Rockaway export. Checksums describe received bytes, not semantic equivalence
between future ACRIS exports.

## Search extracts

These public API responses are frozen discovery evidence, not complete citywide
datasets. Their source fields remain unchanged and their hashes are recorded.

- `batch10_dof_map_library.json`: NYC DOF ArcGIS DTM_ETL_DAILY_view FeatureServer
  layer 8 `/query`, with `where=BLOCK IN (3178,167,2249,15537,2344,2341,3183,2457,2567,1833)`,
  `outFields=*`, `returnGeometry=false`, `f=json`. Endpoint base:
  `https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/8/query`.
  Received 124 features with 124 unique, nonmissing OBJECTID and ID values.
  OBJECTID and BLOCK are numeric; borough, dates, and map IDs are source strings.
  Blocks are requested across boroughs; the borough field must be used before
  selecting a map.
- `batch10_acris_legal.json`: NYC Open Data `8h5j-fqxa.json`, `$limit=50000`,
  `$where=((borough='2' AND block='3178') OR (borough='3' AND block in ('167','2567')) OR (borough='4' AND block='15537')) AND document_id>='2024010100000000'`.
  Received 1,106 legal rows. The string comparison also admits `FT_` legacy IDs;
  numeric 2024/2025/2026 IDs were selected for the follow-up. Rows are document–lot
  records, not documents. All returned fields are source strings. Document ID,
  record type, borough, block, and lot are nonmissing; unit is absent in 818 rows.
  The proposed document/type/borough/block/lot/unit key has 1,096 distinct values,
  so it is not unique. These source repetitions are preserved; the follow-up
  selects distinct document IDs before requesting master records.
- `batch10_acris_master.json`: NYC Open Data `bnx9-e6tj.json`, exact public query
  saved in `batch10_acris_master.json.url`. It requests the 108 selected document
  IDs. All 108 IDs are unique and nonmissing. The selection uses the target
  blocks above, narrowing Brooklyn block 167 to lots 16/22/24/26. This is a
  targeted index, not a complete chain of title. Good-through dates differ
  between source releases and remain in the responses.

Reproduction of a historical extract means using these saved bytes. Reissuing
the mutable APIs can return later records and requires a deliberate refresh.

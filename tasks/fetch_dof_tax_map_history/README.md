# DOF tax-map history

This task owns the September 15, 2026 citywide snapshot of the public NYC
Department of Finance tax-map service and its application tracker. It provides
the administrative records used by the parent-footprint audit. No credentials
are needed.

Run `make fetch_dof_tax_map_history` from the project root. Run
`make dof-parcel-audit` to prepare the main data and trace all parents meeting
the estimation size and policy-sample rules.

| Output table | DOF source | Rows in this snapshot |
| --- | --- | ---: |
| `dtm_0.parquet` | Current tax-lot polygon attributes, without geometry | 858,065 |
| `dtm_3.parquet` | Current condominium base and billing lots | 12,236 |
| `dtm_4.parquet` | Current condominium unit-to-base links | 307,762 |
| `dtm_8.parquet` | Dated block-map index and PDF links | 93,570 |
| `dtm_9.parquet` | Alteration-book transaction headers | 78,189 |
| `dtm_13.parquet` | Condominium actions | 10,168 |
| `dtm_14.parquet` | Condominium unit actions | 144,198 |
| `dtm_15.parquet` | Tax-lot actions | 78,108 |
| `applications.parquet` | Tax Map Unit application tracker | 7,549 |

The layer numbers identify tables in the
[DOF public service](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer).
The tracker has its own
[public source](https://services3.arcgis.com/aD88pT4hjL80xq0F/arcgis/rest/services/TMU_Application_Points_Public/FeatureServer/3).
The Makefile shows both URLs. The task's local input aliases downstream use
descriptive names such as `dof_lot_actions.parquet`.

## Acquisition and replication

`download_dof.py` calls `curl` because these APIs require pagination. It saves
the schema, all ordered pages, the full object-ID lists before and after
retrieval, and a manifest of exact query URLs and SHA-256 hashes. JSON response
bytes are unchanged inside the ZIP. It checks page lengths, duplicate IDs,
full coverage, HTTP errors, and ArcGIS errors returned inside HTTP 200 responses.
Object-ID consistency checks detect added or deleted records during retrieval;
they do not make the changing service an atomic historical database snapshot.

The nine original ZIPs are retained in
`data_raw/dof_tax_map/2026-09-15/`. **Include that directory in the replication
package.** Its total compressed size is about 55 MB. Git ignores raw data as
elsewhere in this project; `code/checksums.sha256` records the frozen bytes.
Ordinary builds verify and copy this snapshot, then stage the original fields
as Parquet. They do not contact the changing API when the snapshot is present.
SaveData writes the table reports as side effects.

If a raw ZIP is absent, Make requests it through the public API and requires
the recorded checksum before publishing it. DOF does not offer this historical
extract under an immutable download URL. A later API response may therefore
fail that check; restore the recorded ZIP from the replication package.
A deliberate refresh uses a new dated raw directory and recorded checksums,
with a comparison of the resulting reports. Editing a query or download script
does not redefine an already frozen raw snapshot.

Failed requests or checksum checks leave the previous snapshot intact.
`stage_dof.R` reads the pages in order and checks the source OBJECTID key.
These are source-table keys, not economic-parent or tax-lot uniqueness claims.
The audit resolves repeated transaction metadata and represents overlapping
condominium links as explicit parcel sets.

## Meaning of the records

The header contains 39,777 distinct transactions from May 2008 through September
2026. A transaction can include several old and new lots. Its action rows do
not allocate portions of old parcels to each new parcel and do not contain
historical polygons. The map index links to DOF's dated PDFs. An application
tracker entry records a proposed or processed request; its dates and status
are distinct from the completed tax-map transaction.

The first consumer is `audits/audit_parent_site_boundaries`. Its candidate
parcel sets and remaining review cases are audit outputs. Production parent
characteristics and weighting remain provisional while those cases are resolved.

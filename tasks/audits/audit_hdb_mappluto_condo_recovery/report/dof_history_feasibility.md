# DOF should be the first source for parcel history

September 15, 2026. This audit investigates whether recorded city tax-map changes can recover complete predecessor parcel sets before we implement a spatial reconstruction. It changes no production footprints, weights, membership, units, or structural estimates.

**Finding:** DOF provides publicly queryable transaction and lot-action tables. They directly resolve Wyckoff's missing predecessors, identify an additional Third Avenue strip, and recover Jamaica's condominium base-lot set. They should lead the next footprint audit, with spatial comparison checking coverage and handling partial sites. They cannot by themselves resolve every proposed development footprint.

## What the service provides

The [public DTM service](https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer) exposes `DAB_BOOK_HEADER` (layer 9), `DAB_LOT` (15), `DAB_CONDO` (13), `DAB_CONDO_UNIT` (14), and `MAPLIBRARY_MAP` (8). These are accessible without a login or API key. Transactions have dates, types, and an authority field that often cites a deed or survey. Lot rows identify New, Dropped, and Affected parcels. The same identifier can therefore survive a boundary change without appearing to be a new lot.

The citywide count queries returned 78,189 header rows, 78,108 lot-action rows, 10,168 condo-action rows, 144,198 condo-unit rows, and 93,570 map-library rows. Header rows are not unique transactions. The queried date range runs from May 20, 2008 through September 14, 2026, spanning our 2019–2022 historical period. This is observed source coverage, not proof that every change was entered correctly or promptly.

The service supports 1,000-row pages. Two seven-row test pages exactly matched the corresponding rows of the full ordered query. All five detail-table downloads matched their separate count requests. Bulk extraction is technically feasible; a citywide extraction and validation have not been completed.

## Five development cases

| Case | DOF evidence retrieved | Consequence |
| --- | --- | --- |
| Wyckoff/Bergen, Brooklyn 388 | Transaction 303740, May 7, 2025: lot 19 Affected; 42 and 51 Dropped; 20, 21, and 57 New. Tracker application received February 25, 2025, requesting four lots. | Directly recovers old 19/42/51 and new 19/20/21/57. Old PLUTO areas sum to 50,692 sq ft; production currently includes 46,692. |
| Third Avenue, Bronx 2923 | Transaction 474542, December 18, 2025: 27/31/35 Affected and 30/135 Dropped. Tracker received April 24, 2025, requesting three lots. Historical inset 1 shows lot 135 along Third Avenue. | The documented predecessor set is **27/30/31/35/135**. Lot 135 adds 108 sq ft in 2023 PLUTO. The five lots sum to **22,247 sq ft**, versus 19,555 in production and 22,139 in our September 14 review. |
| Jamaica/165th Street, Queens 9795 | Condo transaction 161321, August 30, 2024, and termination 426141, October 22, 2025, identify 30/65/85/89/94/130. Tracker also has a March 23, 2026 apportionment request encompassing these six plus 98/99, requesting seven lots, with status Returned. | Resolves the condo base-lot list and confirms a later application involving all eight associated parcels. The six residential filings' exact usable footprint remains unresolved. Do not substitute the full 111,540 sq ft automatically. |
| Sullivan/Empire, Brooklyn 1306 | Transaction 93082, July 19, 2021, merges 28/32/35 into 28. Retrieved current map retains lot 28; no later four-lot split for this site appears in the five-block history or tracker query. | Explains the older assembled lot. The four proposed filing lots still require proposal/survey evidence. Absence from the retrieved tracker is not proof no application exists. |
| Bruckner/Brook/East 132nd, Bronx 2260 | Retrieved current map remains the February 17, 2022 version and retains 1/34/38. No transaction or tracker application for their proposed reconfiguration was found in the block queries. | DOF does not yet replace the recorded 2026 zoning declaration and drawing as evidence of the proposed rearrangement. The same three numbers on two maps would not establish unchanged boundaries. |

The Third Avenue correction is supported by the [historical inset](https://propertyinformationportal.nyc.gov/pdf/home/index/map_inset/20292320180305155223_1), the [map effective December 18, 2025](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20292320251218115532), and the saved transaction rows. It updates the existing parcel-review source table and its outputs, but not production characteristics. The remaining four cases' parcel-review numerical results are unchanged.

## How to use this source

Start from all relevant filing and condo identifiers and query the lot/condo action tables. Retrieve complete transactions using `TRANS_NUM`, then follow changes back to the appropriate historical reference date. Keep date, source identifiers, and actions. Collect each predecessor parcel once per economic parent after determining the relevant site extent.

The header repeats metadata across lots. The audit checks that each transaction has one date/type/authority tuple before joining it many-to-one to the lot actions. Do not join the repeated headers directly to repeated lot rows. Do not limit detail retrieval to the first queried lot: the 25 selected transactions have 71 lot-action rows, eleven of them outside the five original blocks. Even the header does not necessarily enumerate every participant in a transaction.

New/Dropped/Affected actions describe an editing event, not a complete pairwise allocation of old land to each new lot. For a parent containing the whole resulting site, a merger or apportionment can identify the predecessor set directly. If a parent contains only part of the resulting site, taking every participant's entire old lot can overstate its land. Condominiums can contain retained uses or several projects; unit lots and billing lots require their own links. Generic corrections, REUC updates, numbering changes, and tax-year changes also require interpretation rather than blanket inclusion of all Affected parcels.

Use map overlays to check that the reconstructed old parcel set covers the intended land without adding unrelated land. Review plans and historical maps where the current tax map does not show proposed subdivisions or where an older parcel was only partly used. This narrows the manual work; it does not eliminate it.

Keep the clocks separate. For example, Wyckoff's DOF change date is May 7, 2025, the tracker completion date is May 9, and the saved PLUTO APPDate is July 18. These describe different administrative records. None alone dates the developer's economic decision, land acquisition, DOB filing, or construction start. Subsequent records can establish parcel lineage without making the resulting lot structure predetermined for the model.

## Reproduction and remaining work

The acquisition audit's `code/dof_history_2026-09-15/sources.csv` records 50 preserved responses with exact URLs and SHA-256 fingerprints. The public data dictionary confirms the transaction-key and lot-action definitions. Eleven historical map PDFs remain with the acquisition task. An ordinary audit build reuses the frozen JSON inputs:

```sh
make -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/dof_lot_changes.csv ../output/dof_applications.csv
```

This produces 71 keyed lot-action rows across 25 transactions and ten tracker applications, with deterministic data reports. Pagination, row-count, uniqueness, and metadata-consistency checks passed. A second unchanged build does no work. Source hashes were verified after preservation.

The next substantive step is a DOF-led review across all estimation parents, including stable BBLs, followed by spatial coverage checks and review of exceptions. Production footprints, weights, and pilot results remain provisional pending that work. No model estimation was run for this investigation.

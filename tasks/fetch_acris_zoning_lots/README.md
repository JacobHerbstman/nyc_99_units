# Fetch ACRIS zoning lots

Publishes the recorded zoning lot descriptions that list every tax lot of a
zoning lot, captured October 1, 2026 from the NYC Department of Finance's ACRIS
datasets on NYC Open Data:

| Output | Source | Rows |
|---|---|---|
| `acris_zoning_lots_20261001_zoning_lot_documents.csv` | Real Property Master ([`bnx9-e6tj`](https://data.cityofnewyork.us/City-Government/ACRIS-Real-Property-Master/bnx9-e6tj)): zoning lot descriptions (`ZONE`, 31,943) and development-rights transfers (`DEVR`, 790) dated from January 1, 2012 | 32,733 |
| `acris_zoning_lots_20261001_zoning_lot_parcels.csv` | Real Property Legals ([`8h5j-fqxa`](https://data.cityofnewyork.us/City-Government/ACRIS-Real-Property-Legals/8h5j-fqxa)): the lots listed by those documents | 55,025 |

A zoning lot description is recorded when a development's zoning lot is
declared, usually around its permit, and lists the tax lots it combines: lots
built on and, for a transfer of floor area, neighbouring lots whose buildings
remain. Condominium unit lots (1001–7500) can appear. A development-rights
transfer marks such a transfer. Every document has at least one listed lot.
Fifty-six document IDs repeat with different modification dates, and 215 lot
rows repeat exactly; consumers resolve them.

The API is mutable, so the capture in `data_raw/acris_zoning_lots/2026-10-01/`
is the source of record, with a manifest per table recording each request's URL,
row count and SHA-256. `download_acris.py` runs only when a capture is missing;
the lots are requested in batches of 150 document IDs from the saved documents
capture. `code/checksums.sha256` verifies the published copies.

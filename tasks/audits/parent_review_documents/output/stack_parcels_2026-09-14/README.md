# Five-parent parcel source capture

These small public-source snapshots are stored with the code and support the repeated-99 parcel
review in `fit_pure_notch_pilot`. They were received on September 14, 2026.
`sources.csv` records the exact public API queries and SHA-256 fingerprints.
The consumer reads these saved files; running the analysis does not refresh them.

- `pluto_26v2.json`: 87 PLUTO rows across the five tax blocks. Every row is
  release 26v2. The query requests parcel identifiers, dimensions, zoning
  districts, and apportionment fields. It does not contain zoning-lot IDs.
- `acris_legals.json`: 503 indexed parcel rows for specified old and filing lots.
  These are searched parcels, not necessarily every parcel named in a document.
  The query's document-ID lower bound also admits legacy letter-prefixed IDs;
  the consumer filters relevant document types by recorded date.
- `acris_master.json`: 201 returned metadata rows for the 196 distinct document
  IDs in the parcel query. Four literal queries are listed in `sources.csv`.
  Their JSON arrays were concatenated in request order. Five IDs have successive
  metadata versions; the consumer uses the latest modification and checks
  uniqueness before joining.

Each request used system curl with `--fail --location --max-time 40`, with TLS
verification enabled. Public APIs required no credential. Responses were parsed
as JSON and checked against the 10,000-row request limit before saving. The
PLUTO and legals files preserve response bytes. Master preserves all returned
records, including earlier versions, in one JSON array. A new source vintage
should be captured in a new dated folder and reviewed explicitly.

Recorded document images were read in ACRIS's public image viewer. The review
CSV and audit README identify the document IDs, pages, dates, and conclusions.
The index alone does not establish the meaning of a declaration. DEC and OER
site plans supply additional parcel lineage evidence, with exact URLs recorded
beside the reviewed old parcels. No documentary unit counts override the
canonical administrative panel.

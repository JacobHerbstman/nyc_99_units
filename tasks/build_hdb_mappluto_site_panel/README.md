# Build HDB–MapPLUTO site panel

This task attaches leakage-safe historical lot characteristics to DCP Housing
Database filings. It finds the latest release safely available before each
filing, then uses the preceding release to provide an additional lag. If that
lag is unavailable, it retains the earliest release with an explicit backfill
flag; those observations do not enter the primary leakage-safe sample.

The HDB filing BBL remains in `bbl`; the matched parcel is
`pluto_feature_bbl`. If the filing BBL is absent from the selected vintage, the
task may use a unique official same-block APPBBL feature lot. Shared recovered
feature BBLs remain visible through `pluto_feature_bbl_hdb_rows`.

This is a canonical site-matching panel used to construct historical parents
and predetermined parent characteristics. It does not estimate or score an
individual parcel unit-count model.

The same task validates the recorded parcel-release calendar and builds the official current APPBBL crosswalk. Both are intermediate inputs to site matching.

## Housing Database snapshots

`historical_hdb_mappluto_site_panel.parquet` uses the full 23Q4 HDB archive for filings through 2023. `hdb_mappluto_site_panel.parquet` uses 25Q4 for the post-policy route and current-source diagnostics. Both apply the same parcel-matching algorithm and record `hdb_release`; the historical output also records active-file membership. Historical units and filing identifiers come exclusively from 23Q4. Later dated parcel evidence can reconstruct earlier land and retains its recovery/timing flags.

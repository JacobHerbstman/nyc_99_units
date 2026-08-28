# Build HDB–MapPLUTO site panel

This task attaches leakage-safe historical lot characteristics to DCP Housing
Database filings. It uses the first MapPLUTO release that was safely available
before each filing where possible and records the earliest archived release as
an explicit backfill for earlier observations.

The HDB filing BBL remains in `bbl`; the matched parcel is
`pluto_feature_bbl`. If the filing BBL is absent from the selected vintage, the
task may use a unique official same-block APPBBL feature lot. Shared recovered
feature BBLs remain visible through `pluto_feature_bbl_hdb_rows`.

This is a canonical site-matching panel used to construct historical parents
and predetermined parent characteristics. It does not estimate or score an
individual parcel unit-count model.

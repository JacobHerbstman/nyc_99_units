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

The same task validates the recorded parcel-release calendar and builds the official current APPBBL crosswalk. These are intermediate inputs to site matching, with separate source files and output tables. They no longer require standalone task folders.

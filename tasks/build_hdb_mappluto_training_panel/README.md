# Build HDB MapPLUTO Training Panel

Builds the first 2016-2023 HDB-MapPLUTO panel for the unit-count prediction design.

This production task writes one canonical panel. It uses true one-release-lagged MapPLUTO where available and attaches the earliest documented archived release as an explicitly flagged backfill for earlier filings.

The HDB filing BBL remains in `bbl`. PLUTO features are joined through `pluto_feature_bbl`. When the filing BBL does not appear in the selected lagged MapPLUTO vintage, the task uses the production `mappluto_appbbl_crosswalk.csv` to recover official same-block APPBBL feature lots that appear uniquely in the lagged vintage. Shared recovered feature BBLs are included and flagged with `pluto_feature_bbl_hdb_rows`.

It does not estimate models, score the post-policy risk set, or write diagnostics. Matching audits live under `tasks/audits/`.

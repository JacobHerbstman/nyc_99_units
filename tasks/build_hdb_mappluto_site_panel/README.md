# Build HDB–MapPLUTO site panel

Attaches pre-filing parcel characteristics to each DCP Housing Database New
Building filing from 2010.

- `mappluto_release_calendar.csv`: the date each PLUTO or MapPLUTO release became
  available, from the committed table `code/mappluto_release_calendar_manual.csv`.
- `mappluto_appbbl_crosswalk.csv`: for each current tax lot in PLUTO 25v4, the
  former lot it replaced (APPBBL) and the date of that change.
- `historical_hdb_mappluto_site_panel.parquet` (23Q4 filings through 2023) and
  `hdb_mappluto_site_panel.parquet` (25Q4 filings through 2025): one row per
  filing.

Each filing uses the release one before the latest release available strictly
before its filing date, so its parcel attributes predate the filing. The filing
BBL stays in `bbl`; the matched lot is `pluto_feature_bbl`. When the filing's
own lot is missing from its release, a former lot from the crosswalk is used if
it is on the same block and appears exactly once in the release
(`appbbl_recovery_used`). `appbbl_future_appdate_used_for_linkage` marks a
crosswalk lot change recorded after the filing. A lot appearing twice in a
release is not matched. `exclusion_reason` records why a filing lacks usable
land, and `primary_leakage_safe_sample` marks filings with it.

Historical units and identifiers come only from 23Q4.

# Build MapPLUTO APPBBL Crosswalk

Builds a production APPBBL crosswalk from the current official PLUTO table staged by `fetch_mappluto_archive`.

The output maps the BBL reported in current PLUTO to its official `APPBBL`, the apportionment BBL used by PLUTO for lots created through merges, splits, or condominium conversions. This task only creates the crosswalk. It does not decide which HDB rows should use APPBBL features; that decision happens in `build_hdb_mappluto_training_panel`.

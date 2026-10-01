# Stage MapPLUTO lots

`stage_mappluto_lots.R` cleans each PLUTO (2009–18v1, CSV tables) and MapPLUTO
(18v1.1–23v3.1, shapefile attributes) release into one lot table with the same
fields, `output/dcp_pluto_archive_<release>.parquet` and
`output/dcp_mappluto_archive_<release>.parquet`. A valid recorded BBL is kept;
otherwise it is built from borough, block and lot. Each release has its own
Make target, and the 18v2 beta release is read from the 18v2 file.

Downstream tasks choose a release by date through the calendar in
`build_hdb_mappluto_site_panel`. Source acquisition is in
`fetch_mappluto_archive`.

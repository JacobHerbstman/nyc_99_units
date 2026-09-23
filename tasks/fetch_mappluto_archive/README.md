# Fetch MapPLUTO archive

Publishes the official DCP PLUTO and MapPLUTO releases used by the study in
`output/`, under DCP's filenames, and writes an inventory,
`output/mappluto_files.csv`. It does not clean lots or choose reference
releases.

| Files | Source |
|---|---|
| Borough MapPLUTO bundles, 2009–2017 (`mappluto_<release>.zip`) | Official archive, downloaded directly |
| Citywide MapPLUTO, 2018–2023 (`nyc_mappluto_<release>_arc_shp.zip`) | Official archive, downloaded directly |
| PLUTO CSV, 2009–2018 (`nyc_pluto_<release>.zip`) | Official archive, downloaded directly |
| Current 25v4 MapPLUTO, PLUTO and their documentation | Captures in `data_raw/dcp_mappluto_current/25v4/` and `data_raw/dcp_pluto_current/25v4/` |
| Archive index and release metadata JSON | Dated captures in `data_raw/`; the agency offers no historical query endpoint |

`code/checksums.sha256` records the bytes of all 67 published files and
`code/source_files.csv` records release, pull date and official URL. A file is
downloaded or copied only when it is missing from `output/`, and its checksum
is verified before it is published, so editing the Makefile never triggers a
download. The inventory rule re-verifies every file whenever the ledger
changes. To refresh a source, save the new capture under a new dated path and
update both ledgers. The full archive is about 11 GB.

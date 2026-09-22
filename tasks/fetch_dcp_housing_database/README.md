# Fetch DCP Housing Database

Publishes the DCP Housing Database project-level files used by the study in
`output/` and writes an inventory, `output/dcp_housing_database_files.csv`.
It does not clean or analyze the records.

| File | Source |
|---|---|
| 23Q4 project-level CSV ZIP | Official archive, downloaded directly. Contains `HousingDB_post2010.csv` and `HousingDB_post2010_inactive_included.csv`; internal files are dated April 2024 and every record identifies version 23Q4. |
| 25Q4 project-level CSV ZIP and data dictionary | Captures in `data_raw/dcp_housing_database_project_level/25Q4/`. |
| Release metadata (archive JSON, content-API JSON) | Dated captures in `data_raw/dcp_housing_database_project_level/20260501/`; the agency offers no historical query endpoint. |

`code/checksums.sha256` records the bytes of each published file and
`code/source_files.csv` records release, pull date and official URL. A file is
downloaded or copied only when it is missing from `output/`, and its checksum
is verified before it is published. The inventory rule re-verifies every file
whenever the ledger changes. A missing `data_raw/` capture fails the build
rather than being replaced with current data. To refresh a source, save the new
capture under a new dated path and update both ledgers.

The 25Q4 ZIP has since moved to `bytes/housing-database/housing-project-level/`
on the agency site; the file there has the same checksum as the capture.

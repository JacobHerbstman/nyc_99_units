# Fetch DCP Housing Database

Fetches the official DCP Housing Database project-level release metadata and files into `data_raw/dcp_housing_database_project_level/`.

The task writes a file inventory to `output/dcp_housing_database_files.csv`. It does not clean or analyze the project records.

## Recorded source vintage

`code/source_files.csv` records the exact source release used in this study. The Makefile owns each received file, checks its SHA-256, and exposes it through `output/`. Versioned public archives have direct download recipes. Mutable API responses and metadata require the original dated capture at the literal `data_raw/` prerequisite: the agency does not provide a historical query endpoint. A missing capture fails the build; it is never replaced silently with current data. Source refreshes require deliberately updating the capture, ledger, and checksum together. The original `raw_path` column remains provenance metadata; consumers read local input links.

The original 25Q4 URL returned 404 in the September 9, 2026 fresh-build check. NYC moved the ZIP under `bytes/housing-database/housing-project-level/`. The replacement in the Makefile was identified from the agency content API and downloaded successfully; its SHA-256 exactly matches the original capture (`76f16a63535ea661700afd2440f143e718f9ffa4e8685de6e166c4ea208cada2`). The ledger retains the URL recorded at acquisition, and the analysis still uses 25Q4.

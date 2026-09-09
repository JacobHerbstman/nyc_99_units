# Fetch DOB NOW initial New Building filings

This task downloads a frozen, source-level extract from the official DOB NOW
Build Job Application Filings dataset. The extract contains initial (`-I1`)
New Building filings dated 2016--2025 and the filing, site, unit-count, and
construction-area fields needed by the developer-response audit.

The raw CSV is stored under
`data_raw/dob_now_build_job_filings/<pull_date>/`. The task output is a manifest
that records the raw path, query URL, row count, and download status.

## Recorded source vintage

`code/source_files.csv` records the exact source release used in this study. The Makefile owns each received file, checks its SHA-256, and exposes it through `output/`. Versioned public archives have direct download recipes. Mutable API responses and metadata require the original dated capture at the literal `data_raw/` prerequisite: the agency does not provide a historical query endpoint. A missing capture fails the build; it is never replaced silently with current data. Source refreshes require deliberately updating the capture, ledger, and checksum together. The original `raw_path` column remains provenance metadata; consumers read local input links.

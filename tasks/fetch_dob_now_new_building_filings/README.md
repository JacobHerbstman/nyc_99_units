# Fetch DOB NOW initial New Building filings

This task downloads a frozen, source-level extract from the official DOB NOW
Build Job Application Filings dataset. The extract contains initial (`-I1`)
New Building filings dated 2016--2025 and the filing, site, unit-count, and
construction-area fields needed by the developer-response audit.

The raw CSV is stored under
`data_raw/dob_now_build_job_filings/<pull_date>/`. The task output is a manifest
that records the raw path, query URL, row count, and download status.

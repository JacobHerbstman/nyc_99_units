# Fetch DOB NOW New Building filings

Publishes a frozen extract of the DOB NOW Build Job Application Filings dataset,
pulled July 10, 2026:

- initial (`-I1`) New Building filings, 2016–2026 (9,193 rows);
- New Building amendments, 2024–2026 (28,681 rows).

Both are captures in `data_raw/dob_now_build_job_filings/20260710/`. The API is
mutable, so the capture is the source of record: a missing capture fails the
build. `code/checksums.sha256` records the bytes of each published file and
`code/source_files.csv` records row counts and query URLs. Files are copied
only when missing and verified before they are published.

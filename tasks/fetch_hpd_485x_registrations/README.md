# Fetch HPD 485-x registrations

This task downloads a dated snapshot of HPD's public 485-x prospective
applicant registration dataset and its Socrata metadata. Each source row is a
self-reported building registration, not a final application or an HPD
determination of the legal Eligible Site.

The raw files are stored under `data_raw/hpd_485x_registrations/<pull_date>/`.
The task output is a manifest containing the raw paths, source dates, row
count, query URLs, and checksums.

## Recorded source vintage

`code/source_files.csv` records the exact source release used in this study. The Makefile owns each received file, checks its SHA-256, and exposes it through `output/`. Versioned public archives have direct download recipes. Mutable API responses and metadata require the original dated capture at the literal `data_raw/` prerequisite: the agency does not provide a historical query endpoint. A missing capture fails the build; it is never replaced silently with current data. Source refreshes require deliberately updating the capture, ledger, and checksum together. The original `raw_path` column remains provenance metadata; consumers read local input links.

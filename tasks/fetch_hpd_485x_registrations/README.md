# Fetch HPD 485-x registrations

Publishes a snapshot of HPD's public 485-x prospective applicant registration
dataset and its Socrata metadata, pulled August 20, 2026. Each source row is a
self-reported building registration, not a final application or an HPD
determination of the legal Eligible Site.

The files are captures in `data_raw/hpd_485x_registrations/20260820/`. A missing
capture fails the build. `code/checksums.sha256` records the bytes of each
published file and `code/source_files.csv` records source dates, row counts and
URLs. Files are copied only when missing and verified before they are published.

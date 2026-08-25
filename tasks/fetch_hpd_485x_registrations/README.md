# Fetch HPD 485-x registrations

This task downloads a dated snapshot of HPD's public 485-x prospective
applicant registration dataset and its Socrata metadata. Each source row is a
self-reported building registration, not a final application or an HPD
determination of the legal Eligible Site.

The raw files are stored under `data_raw/hpd_485x_registrations/<pull_date>/`.
The task output is a manifest containing the raw paths, source dates, row
count, query URLs, and checksums.

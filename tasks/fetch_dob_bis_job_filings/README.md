# Fetch DOB BIS New Building applications

Publishes the initial (`doc__ = 01`) New Building applications from the DOB Job
Application Filings dataset on NYC Open Data
([`ic3t-wcy2`](https://data.cityofnewyork.us/Housing-Development/DOB-Job-Application-Filings/ic3t-wcy2)),
captured September 23, 2026: 136,595 rows for 83,570 jobs filed 2001–2020. BIS
stopped taking New Building applications at the end of 2020; later filings are in
DOB NOW (`fetch_dob_now_new_building_filings`).

The file supplies each application's owner business name, owner and applicant
names, applicant license, coordinates, neighbourhood and zoning-lot area. A job
can appear once per dataset refresh (`dobrundate`); consumers choose the row.

The API is mutable, so the capture in `data_raw/dob_bis_job_filings/2026-09-23/`
is the source of record, with `manifest.csv` recording each page's query URL,
row count and SHA-256. `download_bis.py` runs only when the capture is missing,
and `code/checksums.sha256` verifies the published copy.

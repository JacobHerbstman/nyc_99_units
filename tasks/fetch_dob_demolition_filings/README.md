# Fetch DOB demolition filings

Publishes the DOB full-demolition filings that show which lots of a zoning lot a
new development built on, captured October 1, 2026 from NYC Open Data:

| Output | Source | Rows |
|---|---|---|
| `dob_demolition_filings_20261001_bis_demolitions.csv` | BIS Job Application Filings ([`ic3t-wcy2`](https://data.cityofnewyork.us/Housing-Development/DOB-Job-Application-Filings/ic3t-wcy2)), `job_type = 'DM'`, 2000–2025 | 80,346 |
| `dob_demolition_filings_20261001_dob_now_demolitions.csv` | DOB NOW: Build Job Application Filings ([`w9ak-ipjd`](https://data.cityofnewyork.us/Housing-Development/DOB-NOW-Build-Job-Application-Filings/w9ak-ipjd)), `job_type = 'Full Demolition'` | 7,827 |

A BIS job can appear once per document and dataset refresh (`dobrundate`);
consumers choose the row. BIS dates are `MM/DD/YYYY`, DOB NOW dates ISO
timestamps.

The API is mutable, so the capture in `data_raw/dob_demolition_filings/2026-10-01/`
is the source of record, with a manifest per system recording each page's query
URL, row count and SHA-256. `download_demolitions.py` runs only when a capture is
missing, and `code/checksums.sha256` verifies the published copies.

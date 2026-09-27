# Fetch DOB work permits

Publishes the permits that name the contractor holding a building's work
permit, captured from NYC Open Data on September 27, 2026. The job filings in
`fetch_dob_bis_job_filings` and `fetch_dob_now_new_building_filings` name the
owner and the filing architect or engineer, not the builder.

- `dob_permit_issuance_20260927_nb_permits.csv`: DOB Permit Issuance
  ([`ipu4-2q9a`](https://data.cityofnewyork.us/Housing-Development/DOB-Permit-Issuance/ipu4-2q9a)),
  New Building permits (`permit_type = NB`) on BIS New Building jobs: 267,115
  rows for 95,524 jobs, including renewals. The permittee is usually a licensed
  general contractor (`permittee_s_license_type = GC`); business names are cut
  at 25 characters, so the license number is the better identifier.
- `dob_now_approved_permits_20260927_general_construction.csv`: DOB NOW: Build –
  Approved Permits
  ([`rbx6-tga4`](https://data.cityofnewyork.us/Housing-Development/DOB-NOW-Build-Approved-Permits/rbx6-tga4)),
  every General Construction work permit: 210,929 rows for 142,672 job
  filings of all job types, including renewals. On a permit the `applicant_*`
  fields are the permittee; select New Building jobs by `job_filing_number`
  from the DOB NOW job filings. License numbers carry no leading zero here, and
  do in BIS.

Permittee phone numbers and owners' personal names and addresses are not
requested. A permit is issued months after its job is filed, so recent jobs
are often not yet in either extract.

The API is mutable, so the capture in `data_raw/dob_permits/2026-09-27/` is the
source of record, with a manifest per extract recording each page's query URL,
row count and SHA-256. `download_permits.py` runs only when a capture is
missing, and `code/checksums.sha256` verifies the published copies.

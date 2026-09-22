# Pre-policy ACS construction earnings

Owns the 2019–2023 ACS five-year API snapshots for New York City's five counties
and their census tracts. This is the latest five-year window entirely before
485-x's 2024 enactment; it includes 2023, unlike the project's 2019–2022 filing
comparison. Amounts are in 2023 dollars. No post-policy earnings are pooled in.

B24031_005 is construction-industry median annual earnings for civilian employed
residents age 16+, and B24041_005 restricts that universe to full-time, year-round
workers. Fetch estimates, 90% margins of error, and both annotations. These are
residence-based earnings, including net self-employment earnings, not hourly
job-site wages. Industry includes all occupations in construction firms.

Run `make` in `code/`. The authenticated Census request needs CENSUS_API_KEY in
the process environment or the user's home ~/.Renviron. The existing local
credential file has owner-only permissions (0600); it also holds a distinct
IPUMS_API_KEY. Only the Census key is used, and only sent to api.census.gov over
HTTPS. The script loads credentials in memory, never puts them in shell arguments,
never prints request objects/URLs, and replaces request errors with a fixed
message. Do not copy keys into this repository. R's --vanilla disables automatic
.Renviron loading, so the script explicitly reads the home file if needed.

Sources:
- https://api.census.gov/data/2023/acs/acs5/groups/B24031.html
- https://api.census.gov/data/2023/acs/acs5/groups/B24041.html

Queries use state 36; counties 005,047,061,081,085. Raw response bytes are saved
unchanged only after JSON/schema/geography checks. An unchanged build reuses
this snapshot; refreshes are deliberate. Metadata is downloaded without a key.
This source task reports the raw data contents and fingerprints in report/.
The sibling audit task reports the cleaned estimates. Existing audit Make infrastructure is retained without a
shared-infrastructure migration.

The API query is defined entirely in `fetch_acs.R`, and the geography is encoded
in each output filename. Those source files depend on the query script;
changes to execution settings or report rules do not refresh Census data.
Refresh a recorded response deliberately with `make -B ../output/acs_2023_puma.json`
(or the corresponding tract/county target), then review its fingerprint and results.

## Community-district extension

The same ACS tables are requested for all New York State PUMAs; the map consumer
selects NYC's 55 using the official 2020 NYC PUMA boundaries (Open Data
pikk-p9nv). Community-district boundaries use 5crt-au7u, the source identified
in Desktop/nyc_court_case's build_dcp_boundaries task. Both geometries are dated
September 8, 2026 snapshots; source bytes remain unchanged. No cross-project
paths become build dependencies. Extending the API script rechecks the original
tract/county requests; compare their fingerprints to preserve the prior result.

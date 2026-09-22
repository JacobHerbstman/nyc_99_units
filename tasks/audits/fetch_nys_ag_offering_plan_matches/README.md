# Audit NYS Attorney General offering-plan matches

This audit queries the New York State Attorney General's public Real Estate
Finance Database for each component address in the full 6-plus-unit parent
exposure universe. It preserves both a one-row-per-query audit and one row per
returned offering plan, including the plan's submitted and accepted dates.

Queries run in deterministic Make-managed batches because the public search
service can time out during a full-universe pull. Completed batches remain
valid, while the combined outputs are written only after every address has a
successful response.

The results are evidence of condominium or cooperative tenure, not an automatic
parent match. The downstream exposure audit requires an address match and
checks the plan timing relative to the DOB proposal.

## Historical 23Q4 address supplement, September 22, 2026

Run `make historical-broad-supplement` from `code/` after staging the 23Q4
Housing Database. Its manifest includes every 23Q4 New Building proposal filed
in 2019–22 with at least six proposed Class A units. After historical parent
membership is built, run `make historical-companion-supplement` to search 2023
filings linked to fully observed 2019–22 parents with at least six observed
units. `make historical-supplement` requests both saved batches. Each manifest
excludes `(historical, job, address)` keys already searched in the saved August
26 AG snapshot. Parent IDs do not define a search key.

The script uses the public [NYS Attorney General Real Estate Finance Database](https://offeringplandatasearch.ag.ny.gov/REF/welcome.jsp):
`welcome.jsp` to establish a session, `search.action` with an address query,
and `planFormServlet` for each returned plan. No credential is required. The
two manifests and complete parsed response supplements are saved under
`data_raw/nys_ag_offering_plan_matches/2026-09-22/`; the August files remain
unchanged. Each supplement has a row for every query, including zero-result
searches, with the HTTP status, result count, source URLs, plan fields and
submission/acceptance dates. A zero-result search must contain the site's
explicit no-results message. Completed queries are checkpointed under
`tasks/audits/fetch_nys_ag_offering_plan_matches/temp/`; interrupted pulls
resume without repeating them. A failed search stops before publishing the
final supplement. The production exposure task may import these fixed files by
checksum, without depending on this audit task.

The September 22 pull completed 652 broad searches (101 returned plan rows,
572 explicit zero-result searches) and one 2023 companion search (zero
results). Every saved search returned HTTP 200; the `(sample, job, address)`
keys exactly match their manifests and have no overlap with the August source.
The SHA-256 hashes of the fixed response files are:

| File | SHA-256 |
| --- | --- |
| `historical_ag_query_manifest_2019_2022.csv` | `3df56374f57d1a97b53c75d5cff43693788e41b65060532d0fbf9b38dea318d5` |
| `historical_ag_query_manifest_2023_companions.csv` | `d04faba1aff80fdcf43b397aa5af1a4ca0b973453ff0e319a07592cc0c00569d` |
| `historical_ag_query_supplement_2019_2022.csv` | `0908af7cd2b41f2ba032d349b5c35a1e15c8f7e16dd0d866ea2019bfa091715f` |
| `historical_ag_query_supplement_2023_companions.csv` | `0c085614d7dcdb28564a0af4eb009af51c158c85495f08653cfc9b3e7dbe7e2d` |

These are 2026 observations of a live public database. Submitted and accepted
dates can establish whether a plan was recorded before the 23Q4 cutoff, but
the current search response is not an archived 2023 snapshot of the AG site.

# Fetch NYS Attorney General offering plans

Publishes the dated searches of the NYS Attorney General's public
[Real Estate Finance Database](https://offeringplandatasearch.ag.ny.gov/REF/welcome.jsp)
used to screen parents for condominium and cooperative tenure in
`classify_parent_485x_exposure`:

| Output | Capture in `data_raw/nys_ag_offering_plan_matches/` |
|---|---|
| `nys_ag_offering_plan_search_audit_20260826.csv` | `2026-08-26/`: one row per address query for the exposure universe |
| `nys_ag_offering_plan_matches_20260826.csv` | `2026-08-26/`: one row per returned offering plan, with submitted and accepted dates |
| `historical_ag_query_supplement_2019_2022_20260922.csv` | `2026-09-22/`: queries and plans for 2019–22 23Q4 proposals not searched in August |
| `historical_ag_query_supplement_2023_companions_20260922.csv` | `2026-09-22/`: the same for 2023 companions of 2019–22 parents |

The service is live and changes, so the captures are the source of record: a
missing capture fails the build, and `code/checksums.sha256` records the bytes
of each published file. A search result is tenure evidence, not a parent match;
the classification checks the address and plan timing.

## How the captures were made

The scripts in `code/` record the queries; the build does not run them. Each
opens a session at `welcome.jsp`, searches `search.action` by address and reads
`planFormServlet` for each returned plan.

- August 26, 2026: `fetch_nys_ag_offering_plan_matches.R 2026-08-26 <batch> 27`
  searched every component address of the then-current exposure universe in 27
  batches; `combine_nys_ag_offering_plan_match_batches.R 27` combined them.
- September 22, 2026: `prepare_historical_ag_query_supplement.R broad` and
  `companions` wrote the query manifests (saved beside the supplements), and
  `fetch_historical_ag_query_supplement.R broad` and `companions` ran them. A
  zero-result search had to show the site's explicit no-results message.

The scripts read the exposure universe, 23Q4 Housing Database and parent
membership that existed at the time. To refresh, run them into a new dated
folder under `data_raw/` and update the checksums.

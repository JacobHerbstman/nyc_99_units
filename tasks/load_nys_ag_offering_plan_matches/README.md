# Recorded Attorney General search evidence

Loads the retained 2026-08-26 search capture used by the current exposure screen. The source CSVs are parsed public Real Estate Finance Database responses, not raw HTML. Their historical query results cannot be recovered through a date-specific public API. Place the original capture in data_raw/nys_ag_offering_plan_matches/2026-08-26/ on a new checkout; retain it unchanged. The existing public-service query code remains in audits/fetch_nys_ag_offering_plan_matches for deliberate future refreshes. A refreshed search is a new data vintage, never an automatic replacement for this capture.

The search-audit file records which addresses were successfully searched and is required to distinguish no matches from failed queries. Both outputs feed classify_parent_485x_exposure. Make verifies the recorded checksums before copying. No credentials are involved.

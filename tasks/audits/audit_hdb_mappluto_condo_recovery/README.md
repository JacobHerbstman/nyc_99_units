# Audit HDB-MapPLUTO Condo Recovery

Audits whether HDB New Building rows that fail strict BBL matching can be recovered through official PLUTO/MapPLUTO apportionment fields.

This task is audit-only. It does not change the production HDB-MapPLUTO training panel and does not feed the prediction model directly.

The motivating issue is that many large HDB no-match rows have condo-like lot numbers, especially lots 7500 and above. PLUTO/MapPLUTO includes `APPBBL`, the originating BBL before a merge, split, or condominium conversion. This first-pass audit uses current official PLUTO `APPBBL` evidence to construct candidate base-lot links, then accepts only unique same-borough-block candidates that appear uniquely in the selected lagged MapPLUTO vintage and map to only one HDB row. Accepted matches are split into condo-like and non-condo-like HDB lot numbers.

Rows where several HDB jobs point to the same recovered base BBL are flagged as `duplicate_feature_bbl_across_hdb_rows`, not accepted. Those rows need deliberate aggregation or exclusion before any production modeling change.

Outputs are CSV diagnostics: unmatched-row audit, crosswalk candidates, match resolution, accepted matches, recovery summary, sample-comparison summaries, status summaries by modeling window/year/borough, duplicate recovered-base-BBL groups, and large unresolved examples.

# Companion linking rules

Tests symmetric rules for linking filings that belong to one development but
sit on different, non-adjacent lots, which the production linker misses.

`build_filing_identity.R` gives every filing in parent membership the owner
named on its own application, in both periods: DOB NOW applications from
`fetch_dob_now_new_building_filings`, and BIS applications (historical filings
through 2020) from `fetch_dob_bis_job_filings`. Owner business names and owner
person names are normalized. Placeholders (`PR`, `OWNER`, `NOT APPLICABLE`),
public agencies, and people who sign as owner for an agency do not identify a
developer. Coordinates come from the Housing Database (23Q4 historical, 25Q4
recent) with DOB fallback.

`evaluate_companion_rules.R` takes every pair of filings in different parents
within 250 m and 365 days and scores each rule in `rule_definitions.R`: new
links, links confirmed by a DOF lot merger or split involving both lots,
existing cross-lot links re-found, and expected chance links, estimated from
identity matches 1–2 km apart. `simulate_rule_parents.R` re-forms the canonical
parents under each rule, keeping the 365-day parent span and manual
rejections, and reports organization outcomes for A/B parents with 50+ units.

`code/companion_link_validation.csv` records a hand review of 111 links on
September 23, 2026: every recent link under the recommended rule, 40 random
historical ones, 20 at 150–250 m, and 20 matched only by architect. Each row
has a judgement (`companion`, `likely companion`, `uncertain`, `separate`) and
a reason.

The recommended rule links two filings when their owner business or owner
person matches and they are within 150 m or on the same tax block, filed
within 365 days. Run root `make companion-rules`.

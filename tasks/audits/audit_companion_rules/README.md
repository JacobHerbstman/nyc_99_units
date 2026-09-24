# Companion linking rules

Tests symmetric rules for linking filings that belong to one development but
sit on different, non-adjacent lots. The adopted rule is in production in
`construct_parent_cohorts`, so candidate pairs are measured against parents
that already include it.

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
September 23, 2026: every recent link under the proposed rule, 40 random
historical ones, 20 at 150–250 m, and 20 matched only by architect. Each row
has a judgement (`companion`, `likely companion`, `uncertain`, `separate`) and
a reason.

`strict_rule_sensitivity.R` checks the reweighted comparison under a stricter
rule: a link supported only by a shared owner counts when the filings are
within 60 m or filed within 30 days, where every reviewed link was a
companion. Production parents split where the remaining links no longer
connect their filings; each piece keeps its parent's site traits and
classification, and the historical weights are recalibrated. Filings that
production joined to parents anchored before the comparison window are not
recovered. `strict_rule_splits.csv` lists the split weighting-sample parents.

The adopted rule links two filings when their owner business or owner person
matches and they are within 150 m or on the same tax block within 200 m, filed
within 365 days. Run root `make companion-rules`.

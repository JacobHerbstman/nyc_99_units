# Audit parent condo tenure

This audit builds a source-based tenure-outcome dataset for every economic
parent proposal with at least six observed units in the stable 2011–2022
historical cohorts and the 2023-current DOB cohorts. The unit of observation is
the economic parent, so linked component filings are never counted as separate
projects.

The main private residential universe excludes records with affirmative
government/public ownership and projects whose filing description identifies a
hotel. Private and nonprofit owners remain included. Missing ownership is kept
as a separate unresolved universe status rather than silently included or
excluded.

DOB does not have a proposed-tenure field. The task therefore preserves a
narrow initial-filing text flag but does not infer rental tenure from the
absence of condo language. In the current source, three parents have condo
language in an initial owner entity name; none has an explicit proposed-tenure
field.

Condo evidence comes from the New York State Attorney General Real Estate
Finance Database. A candidate must have an exact address-phrase match, identify
new construction, and lie within the Makefile's two-year pre-filing and
five-year post-filing timing window. `CD` records are treated as condo offering
plans. `CP` records are retained separately as CPS-1 market tests and are not
treated as accepted offering plans. No-action-letter records are not condo
tenure evidence. When one plan is returned for multiple economic parents at the
same address, it is assigned to the parent with the closest cohort date and all
candidate assignments are written to a review file.

The panel distinguishes condo intent observable by the initial filing date,
condo offering plans submitted afterward, offering plans accepted afterward,
affirmative 485-x rental registrations, other homeownership evidence, and
unresolved tenure. It also supplies 190-, 365-, and 730-day fixed-follow-up
flags. The fixed-follow-up counts are the appropriate comparisons across
cohorts; the ever-observed count is descriptive and is right-censored for recent
projects.

Outputs:

- `parent_condo_tenure_panel.csv`: one row per economic parent with source and
  timing flags;
- `parent_condo_counts_by_cohort_year.csv`: private-universe counts and shares
  for all 6-plus-unit projects and separately for 6–99 and 100-plus parents;
- `parent_condo_counts_by_period.csv`: period totals, shares, and annualized
  counts for 2011–2022, 2019–2022, 2023–2024, and 2025-current; each fixed
  follow-up specification shortens the eligible cohort end date by the required
  follow-up interval;
- `condo_plan_parent_assignment_review.csv`: every timing-eligible AG plan with
  more than one candidate parent;
- `parent_condo_tenure_qc.csv`: source coverage and classification totals.

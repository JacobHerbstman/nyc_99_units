# Construct symmetric parent cohorts

Groups linked New Building filings into economic parent opportunities, applying
the same rules to historical and post-policy filings. Outputs:

- `symmetric_parent_membership.parquet`: one row per source filing, with its
  parent, role, units and dates.
- `symmetric_parent_links.parquet`: one row per accepted filing link, with its reason.
- `owner_proximity_links.parquet`: same-owner companion pairs on separate lots
  (below).
- `post_policy_filing_link_fields.parquet`: prepared DOB filing fields for the
  post-policy linkage, built first using the official APPBBL crosswalk from
  `build_hdb_mappluto_site_panel`.

Historical link evidence comes from `construct_historical_parent_links`;
post-policy links are built here from the DOB fields and the 23v3.1 MapPLUTO
shapefile.

## Parents

A parent is anchored on its first observed filing and may include linked filings
within 365 days. Links require the same explicit filing BBL, the same
site-linkage BBL, leakage-safe lot history, an explicit project reference, a
common project code, exact filing-lot adjacency corroborated by filing timing
or common ownership, or a same-owner companion filing. Later lot changes alone
do not link filings. The explicit filing BBL stays on each constituent.

`construct_owner_proximity_links.R` finds companion filings on separate lots:
the owner business or owner person on each filing's own application matches,
the filings are within 150 m or on the same tax block within 200 m, and they
were filed within 365 days. DOB NOW jobs use the DOB NOW owner; older BIS jobs
use the BIS application from `fetch_dob_bis_job_filings`. Placeholders, public
agencies and people who sign for an agency do not identify an owner.
Coordinates are Housing Database coordinates with DOB fallback.
`audits/audit_companion_rules` tests alternative rules and records a hand
review of the links.

Grouping applies accepted manual edges first, then candidate links in
filing-date order. A component cannot span more than 365 days from first to last
filing, so a chain of close filings cannot extend the window. Companion links
apply after the other links, and no link joins two components that a manual
rejection separates. Manual acceptances and rejections from `parent_opportunities_manual` are checked again
against the final components, so an indirect path cannot undo a rejection.
Every post-policy parent formed by a shared site-linkage BBL with different
filing BBLs has a manual review in `post_parent_reviews.csv`.

The historical linkage universe begins in 2010 and historical cohorts are
observed through 2023. The DOB universe begins in 2022 as padding, and recent
filings are observed through July 8, 2026. Both universes select filings with
at least six units on the count the parents use: Housing Database Class A
units, with DOB units only where HDB has none. Membership records whether each
cohort's full 365-day window is observable. No unobserved companion or unit
count is imputed.

## Units and filing roles

Selected `units` are the staged Housing Database Class A count, including a
recorded zero; DOB initial-filing units are used only when HDB is missing. Unit
selection does not depend on land availability, filing year or the six-unit
cutoff, and a final assertion checks that selected units equal
`hdb_priority_units`. Zero-Class-A records stay in membership with role
`zero_class_a` and contribute no units. `dob_i1_units` keeps the July 2026 DOB
count as a comparison. Documentary schedules in `unit_decisions.csv` never
override selected units.

A filing that belongs to a parent but describes a superseded design, or a
nonresidential filing, stays in membership as a source proposal without
entering additive units; `parent_observed_units` sums the additive filings.
Roles come from:

- **Manual decisions:** `post_parent_filing_roles.csv` and `historical_filing_roles.csv`.
  A reviewed superseded design is a refiling in both periods, with basis
  `reviewed_archived_alternative` or `reviewed_dob_alternative`.
- **Post-policy refilings (DOB):** a withdrawn filing with a valid seven-digit
  BIN and recorded owner or applicant, and a unique non-withdrawn replacement
  sharing the BIN and normalized owner or applicant, filed after both the
  original filing and its recorded withdrawal. Ambiguous or conflicting matches
  fail for review; they never create links.
- **Historical alternatives (23Q4):** earlier withdrawn versions sharing the
  archived BIN, lot and exact address with one later non-withdrawn application
  within 365 days. No historical withdrawal date is inferred.

Superseded designs get the role `superseded_refiling`.
Refiled records carry `refiled = TRUE`, `original_filing_date`, `refiling_date`
and `refiling_basis`. The parent anchor and cohort date are unchanged; only the
replacement contributes units.

Historical filing outcomes and link fields use the inactive-inclusive 23Q4
Housing Database, with each record's release, archived status and active-file
membership. A filing absent from 23Q4 is not filled from a later release.

Run `make` in `code/` against prepared inputs; use root `make data` after
upstream changes.

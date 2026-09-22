# Manual parent-opportunity decisions

Hand-researched source data, committed to Git. The CSVs in `output/` are not
generated: the Makefile only declares them, and a missing table must be restored
from version control. No script edits them. Each row records its evidence in
`review_basis` and `review_source` and the date of the review in `review_date`.
The research behind these decisions is summarized in the logbook.

| Table | Key | Records | Read by |
|---|---|---|---|
| `pair_decisions.csv` | `sample`, `job_number_1`, `job_number_2` | Whether two filings belong to one economic parent (`accept` / `reject`). Pair order follows the producer's filing-date and job ordering. | `construct_historical_parent_links`, `construct_parent_cohorts` |
| `post_parent_reviews.csv` | `reviewed_parent_id` | Post-policy shared-site reviews: `accept` / `reject` and a `configuration_action` (`keep_additive`, `split`, `exclude_superseded`, `split_and_exclude_superseded`). | `construct_parent_cohorts` |
| `post_parent_filing_roles.csv` | `job_number` | Post-policy filings that are `superseded_alternative`s of a named `replacement_job_number`. | `construct_parent_cohorts` |
| `historical_filing_roles.csv` | `job_number` | Historical 23Q4 filings that are `nonresidential_filing`s or `superseded_alternative`s. | `construct_parent_cohorts` |
| `unit_decisions.csv` | `sample`, `root_job_id` | Documentary unit counts (`documented_proposed_design`), kept as comparison evidence only. | `construct_parent_cohorts` |
| `site_lot_decisions.csv` | `sample`, `parent_id`, `reference_bbls` | Reviewed parcel allocations: earlier parcels, reference MapPLUTO release and recorded area, included ground, excluded earlier building floor, prior use, measurement basis, and `built_floor_area_estimated`. | `build_parent_site_characteristics` |

## Rules

- **Links.** Accepting a pair establishes a common economic development, not
  the city's legal wage-assessment unit or certification of units. Accepted
  historical endpoints stay in the linkage universe even if their land
  characteristics are missing. Automatic linking rules are otherwise unchanged.
  The parent producer checks that identifiers exist, that pairs are neither
  duplicated nor reversed, and that each accepted or rejected pair ends in the
  requested component relation.
- **Filing roles.** A superseded alternative or nonresidential filing stays in
  parent membership with its recorded units, status, original filing date and
  replacement date. It does not count toward additive residential units. No
  withdrawal date is inferred.
- **Units.** Selected units always follow the administrative priority: Housing
  Database Class A units, with DOB initial-filing units where HDB is missing.
  `unit_decisions.csv` never overrides them; disagreements stay visible.
- **Land.** Each `site_lot_decisions.csv` row lists the constituent jobs it
  covers in `expected_component_jobs`, and the producer checks them against
  current membership. A semicolon-separated `reference_bbls` combines earlier
  parcels only when they share both FAR measures. Retained neighboring buildings
  are excluded from earlier floor. Later records can reconstruct the development
  ground without establishing ownership at filing, and a later vacant parcel
  does not establish earlier vacancy; `area_basis` and `review_basis` state the
  measurement used. Rows with `built_floor_area_estimated = TRUE` use an
  explicitly approved floor estimate or later administrative proxy. FALSE means
  no such estimate was adopted, not that the other measurements are verified.

Downstream tasks link these files into their `input/` folders.

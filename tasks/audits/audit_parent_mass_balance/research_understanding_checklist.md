# Research Understanding Checklist

## Session goal

- [x] The object being balanced is a count of parent projects, not apartments.
- [x] The fixed-project interpretation requires excess exact-99 parents to be
  matched by missing parents at or above 100.
- [x] Restatement and quiz stages: `skipped_by_user` by prior request.

## Accounting to understand

- [x] Observed and predicted 2025 parent totals are fixed to the same number.
- [x] The conservation gap therefore equals expected minus observed mass below
  99.
- [x] The net below-99 shortage combines fewer 6--29 parents with more 50--98
  parents.
- [x] The 2025 local distribution has more 50--98 and exact-99 parents than any
  historical year in the training window.

## Data and construction

- [x] Unit of observation: preferred enhanced parent dated by first filing.
- [x] Historical sample: model-eligible 2019--2023 parents.
- [x] Post sample: model-eligible 2025 parents using HDB-primary unit totals.
- [x] Production scores join one-to-one on `observation_id`.
- [x] No parent, companion, or unit count is imputed.

## Interpretation

- [x] The conservative definition leaves all 27 exact-99 parents as singletons;
  a broader sensitivity absorbs eight and leaves 19 unlinked.
- [x] 2025 shifts toward the Bronx and R1--R5 zoning and away from Brooklyn.
- [x] No 2025 model prediction lies outside historical min-max support.
- [x] The 2021 placebo conservation gap exceeds the 2025 gap.
- [x] The exact-99 excess is the cleaner descriptive bunching moment, but it is
  not yet sufficient for a fixed-population cost interpretation.

## Open questions

- [x] A broader but less certain parent-link rule absorbs eight singleton
  exact-99 parents.
- [ ] Do commencement and eligibility data change the relevant 2025 cohort?

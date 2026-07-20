# Symmetric parent no-notch model audit

This audit rebuilds the no-notch estimation panel from the symmetric 365-day
parent membership. It does not delete linked exact-99 observations from the
old model scores. It first aggregates every linked historical and post-policy
filing to one parent opportunity and then refits the rounded, truncated log-unit
model.

The main comparison uses historical parents whose full 365-day window is
observed and 2025 parents whose full forward window is complete in the July 8,
2026 DOB snapshot. The historical linkage universe runs from 2018 through
2023: 2018 supplies the lookback for 2019 anchors, and the fully observed
training cohorts are 2019 through 2022. The 2023 cohorts remain boundary
exposed rather than borrowing potentially policy-exposed 2024 companions.
The all-2025 result is descriptive: later 2025 parents remain right-censored,
and no missing companion is imputed.

Historical covariates come from each filing's leakage-safe lagged MapPLUTO
record. Post-policy covariates use the fixed pre-policy 23v3.1 MapPLUTO
snapshot. HDB's resolved feature BBL is preferred when observed; otherwise the
DOB filing BBL is used. Parents with no observed pre-policy lot match are
reported and excluded from scoring.

## Main audit result

The fully observed comparison trains on 1,827 historical parents and scores
245 completed 2025 parents. It observes 10 exact-99 parents versus 0.38 under
the fitted no-notch distribution. The corresponding exact-99 excess is 9.62
parents. The model predicts 31.37 parents at 100 units or more and observes 24,
for missing upper-tail mass of 7.37. The conservation gap is therefore 2.25
parents, much smaller than the 13.49-parent gap in the calendar-year production
model. The exact-99 mass implies a frontier of 133.5 units and mean affected
counterfactual size of 114.9 units.

The descriptive all-2025 sample retains 567 scoreable parents but includes
right-censored late-2025 cohorts. Its conservation gap is 17.22 parents, so it
should not replace the completed-cohort result.

Run `make` from `code/`.

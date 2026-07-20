# Symmetric parent no-notch model audit

This audit extends the production symmetric-parent model across cohort and unit
definitions. It verifies the completed-2025 HDB result and compares it with
2025 cohorts observed for at least 180 days and with DOB initial-filing units.
It does not alter production parents or delete linked exact-99 observations.

The main comparison uses historical parents whose full 365-day window is
observed and 2025 parents whose full forward window is complete in the July 8,
2026 DOB snapshot. The historical linkage universe runs from 2018 through
2023: 2018 supplies the lookback for 2019 anchors, and the fully observed
training cohorts are 2019 through 2022. The 2023 cohorts remain boundary
exposed rather than borrowing potentially policy-exposed 2024 companions.
The parent definition continues to allow linked filings within 365 days. The
180-day rule only determines when a cohort enters the model sample; it does not
discard companions filed between days 181 and 365. Parents that have not yet
reached day 365 remain provisional, and no missing companion is imputed.

The audit reads the production model panels. Historical covariates come from
each filing's leakage-safe lagged MapPLUTO record; post-policy covariates use
the fixed pre-policy 23v3.1 MapPLUTO snapshot. Parents with no observed
pre-policy lot match remain excluded from scoring.

## Main audit result

The fully observed comparison trains on 1,827 historical parents and scores
245 completed 2025 parents. It observes 10 exact-99 parents versus 0.38 under
the fitted no-notch distribution. The corresponding exact-99 excess is 9.62
parents. The model predicts 31.37 parents at 100 units or more and observes 24,
for missing upper-tail mass of 7.37. The conservation gap is therefore 2.25
parents. The exact-99 mass implies a frontier of 133.5 units and mean affected
counterfactual size of 114.9 units.

The 180-day sample retains 567 scoreable parents. All 586 currently observed
2025 parent cohorts meet this rule because the youngest has 189 days of
follow-up. It observes 22 exact-99 parents versus 0.87 under the fitted
no-notch distribution, for excess mass of 21.13 parents. The exact-99 mass
implies a frontier of 130.5 units and mean affected counterfactual size of
113.8 units. Its conservation gap is 17.22 parents, so the larger sample does
not resolve the mass-balance problem.

## Maturity validation

The audit artificially censors the 252 completed 2025 parents at several
horizons and compares each provisional total with the final 365-day total. At
each horizon it uses only filings and links already observable by that date and
reconstructs the connected component containing the parent anchor. At day
zero, 15 parents appear to total exactly 99 units; five later acquire a linked
companion and cease to be exact-99 parents. Two remain misclassified at day 30,
one at days 60 and 90, and none at day 100 or later. The historical 2019--2022
validation sample has no exact-99 classification disagreement at any tested
horizon.

Exact-99 classification is therefore stable by 180 days in the completed
validation cohorts. Parent size is not fully settled: five of the 252 completed
2025 parents acquire 272 units after day 180. The 180-day result is informative
for the exact-99 bunching moment, but it remains a provisional-cohort result
until the full 365-day window is observed. No day-180 parent in either
validation sample contains an already observed filing that requires a later
bridge filing to connect it to the anchor.

Run `make` from `code/`.

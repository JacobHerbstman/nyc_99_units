# Research Understanding Checklist

## Session Goal
- [x] Estimate the pre-485-x building-level distribution
  \(F_0(n^0\mid X)\), not merely a 100+ ranking score.
- [x] Preserve uncertainty in preferred units for later structural integration.
- [ ] Mastery status: quizzes_skipped_by_user.

## Data And Sample
- [x] HDB supplies proposed permanent Class A units.
- [x] Lagged MapPLUTO supplies pre-filing parcel, zoning, capacity, existing-use,
  and assessed-land predictors.
- [x] The main sample begins at six units and does not select on proximity to 99.
- [x] The unit is one New Building filing; parent opportunities remain separate.

## Models And Validation
- [x] Every retained candidate model produces a complete conditional distribution.
- [x] Forward time splits are used instead of random train/test splits.
- [x] Held-out log score, Brier score, CDF calibration, and interval coverage
  evaluate distributions; RMSE alone is insufficient.
- [x] Exact-bin diagnostics near 99 are validation outputs, not training weights.
- [x] The simplest model remains preferred when predictive differences are small.

## Interpretation
- [x] \(\Pr(n^0\geq100\mid X)\) is exposure probability, not deterministic
  buncher status.
- [x] Building-level predictions cannot be summed mechanically within candidate
  split parents because building count may itself be policy-responsive.
- [x] The 2010--2023 pool spans different policy and market regimes; stability
  across windows is part of the result.

## Open Questions
- [x] Provisional baseline: simple linear lognormal; score 2025 under multiple
  recent training windows because time transport is imperfect.
- [ ] How should the parent-opportunity distribution be estimated symmetrically?
- [x] The 2022--2023 transport test is acceptable for aggregate 100-plus mass in
  some windows but has excess exact-99 mass; retain it as an explicit sensitivity.

## Residual-Diagnostics Stage
- [ ] Separate genuine unit-preference heterogeneity from building/site
  measurement mismatch.
- [ ] Determine how much squared prediction error comes from many filings linked
  to one MapPLUTO feature lot.
- [ ] Audit extreme underpredictions for incomplete zoning-lot or development-site
  coverage.
- [ ] Distinguish admissible pre-filing predictors from simultaneous design
  outcomes such as proposed floor area and stories.
- [ ] Compare the same models and time windows on the full sample and a clean
  building-to-parcel alignment sample.
- [ ] Mastery status: quizzes_skipped_by_user.

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-10 | All | User requested no quizzes | skipped_by_user | Revisit after empirical work |

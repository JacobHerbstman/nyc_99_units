# Parent-model inference and placebo audit

This audit tests the preferred symmetric 365-day parent model. The likelihood
uses rounded proposed units, a six-unit lower truncation, and the production
covariates. Training uses fully observed 2019--2022 first-filing cohorts. The
post sample is fixed to scoreable 2025 cohorts whose full 365-day companion
window is observable. No parent, companion, feature, or unit count is imputed.

The deterministic checks are:

1. expanding-window pseudo-policy cohorts from 2020 through 2022, each scored
   using only earlier fully observed cohorts;
2. candidate thresholds from 80 through 120 in the completed 2025 sample;
3. estimates after omitting each historical first-filing cohort in turn; and
4. training endpoints from 2020 through 2022.

The main bootstrap resamples and refits historical parents while holding the
observed completed-2025 population fixed. It measures estimation uncertainty
conditional on that realized cohort. A two-sample bootstrap also resamples the
2025 parents, adding uncertainty from treating them as a sample from a broader
post-policy population. The Makefile exposes the years, thresholds, bootstrap
repetitions, seed, and percentile interval.

## Findings

The production point estimate observes 10 exact-99 parents and predicts 0.38,
an excess of 9.62. It observes 24 parents at or above 100 and predicts 31.37,
leaving 7.37 missing. The resulting conservation gap is 2.25 parents. Mapping
the cleaner exact-99 excess into the no-notch distribution gives an affected
mean of 114.93 units and a frontier of 133.51.

Threshold 100 is sharply distinguished from its placebos. Across thresholds
80--120, its 9.62-parent excess is the largest; the next-largest excess is 1.71
at threshold 114. Pseudo-policy exact-mass excesses range from -0.55 to 2.09.
The missing-above-threshold moment is less well calibrated, especially in the
2021 pseudo-year, so exact bunching remains the preferred behavioral moment.

Leaving out one historical cohort at a time changes the exact-mass affected
mean only from 114.16 to 115.34 and the frontier from 131.67 to 134.56. Training
through 2021 or 2022 also gives nearly identical exact-mass mappings. Training
only through 2020 is too thin: its frontier rises to 166.51. This is evidence
for requiring at least three complete training cohorts, not for using the
shortest endpoint as a preferred specification.

Of 499 requested historical bootstrap refits, 498 succeed. Conditional on the
observed 2025 parents, the 95 percent percentile interval is 9.57--9.68 for the
exact-99 excess, 112.47--118.79 for its affected mean, and 127.52--143.31 for
its frontier. The conservation-gap interval, -4.94--8.95, contains zero.

The two-sample bootstrap is the more relevant warning for cost calibration.
Its exact-99 excess remains positive, with a 95 percent interval of 3.64--16.63,
but the affected mean interval widens to 104.90--133.66 and the frontier to
110.65--185.22. Missing 100-plus mass and the conservation gap both include
zero. The evidence therefore supports promoting the no-notch model and using
exact-99 excess as the bunching moment, while carrying post-cohort uncertainty
into any developer-cost estimate.

## Research understanding checklist

- [x] The estimation and scoring samples use the same first-filing 365-day
  parent rule.
- [x] Exact-99 excess is separated from missing 100-plus mass.
- [x] Threshold and pseudo-policy placebos isolate the policy cutoff.
- [x] Leave-one-cohort-out and endpoint checks distinguish stability from a
  too-short training window.
- [x] Conditional and two-sample bootstrap intervals answer different
  uncertainty questions.
- [ ] Dollar cost calibration still requires an explicit behavioral mapping
  and external cost inputs.

Researcher restatement: `skipped_by_user`
Mastery check: `skipped_by_user`

Run `make` from `code/` to reproduce all results.

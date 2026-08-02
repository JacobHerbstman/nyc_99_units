# Parent-model inference and placebo audit

This audit tests the preferred symmetric parent model. The likelihood
uses rounded proposed units, a six-unit lower truncation, and the production
covariates. Training uses fully observed 2019--2022 first-filing cohorts. The
post sample uses scoreable 2025 cohorts observed for at least 180 days, with a
complete 365-day pre-filing linkage window. Parent construction continues to
search for observed companions through day 365. No parent, companion, feature,
or unit count is imputed.

The deterministic checks are:

1. expanding-window pseudo-policy cohorts from 2020 through 2022, each scored
   using only earlier fully observed cohorts;
2. candidate thresholds from 80 through 120 in the mature 2025 sample;
3. estimates after omitting each historical first-filing cohort in turn; and
4. training endpoints from 2020 through 2022.

The main bootstrap resamples and refits historical parents while holding the
observed mature-2025 population fixed. It measures estimation uncertainty
conditional on that realized cohort. A two-sample bootstrap also resamples the
2025 parents, adding uncertainty from treating them as a sample from a broader
post-policy population. The Makefile exposes the years, thresholds, bootstrap
repetitions, seed, and percentile interval.

## Findings

The preferred point estimate scores 564 mature parents. It observes 22 exact-99
parents and predicts 0.86, an excess of 21.14. It observes 80 parents at or
above 100 and predicts 84.09, leaving 4.09 missing. The resulting conservation
gap is 17.05 parents. Mapping the cleaner exact-99 excess into the no-notch
distribution gives an affected mean of 113.93 units and a frontier of 130.83.

Threshold 100 is sharply distinguished from its placebos. Across thresholds
80--120, its 21.14-parent excess is the largest; the next-largest excess is 3.90
at threshold 87. Pseudo-policy exact-mass excesses range from -0.55 to 2.09.
The missing-above-threshold moment is less well calibrated, especially in the
2021 pseudo-year, so exact bunching remains the preferred behavioral moment.

Leaving out one historical cohort at a time changes the exact-mass affected
mean only from 113.22 to 114.20 and the frontier from 129.17 to 131.51. Training
through 2021 or 2022 also gives nearly identical exact-mass mappings. Training
only through 2020 is too thin: its frontier rises to 152.07. This is evidence
for requiring at least three complete training cohorts, not for using the
shortest endpoint as a preferred specification.

All 499 requested historical bootstrap refits succeed. Conditional on the
observed 2025 parents, the 95 percent percentile interval is 21.02--21.25 for
the exact-99 excess, 111.85--116.88 for its affected mean, and 125.94--138.09
for its frontier. The conservation-gap interval, -0.51--33.15, contains zero.

The two-sample bootstrap is the more relevant warning for cost calibration.
Its exact-99 excess remains positive, with a 95 percent interval of 13.09--30.12,
but the affected mean interval widens to 107.42--122.67 and the frontier to
116.04--152.66. Missing 100-plus mass and the conservation gap both include
zero. The evidence therefore supports promoting the no-notch model and using
exact-99 excess as the bunching moment, while carrying post-cohort uncertainty
into any developer-cost estimate.

## Research understanding checklist

- [x] The estimation and scoring samples use the same first-filing parent rule;
  the post cohort enters after 180 observed days while linkage continues to day
  365.
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

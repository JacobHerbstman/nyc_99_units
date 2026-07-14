# No-Notch Time-Adaptation Audit

This audit makes the final two small timing comparisons before choosing an
interim no-notch unit model. It keeps the two requested training floors, 6 and
11, and holds the simple right-hand side, rounded lower-truncated likelihood,
and one i.i.d. normal preferred-size shock fixed.

The six candidates cross each training floor with three timing rules:

- `expanding` uses every eligible filing from 2010 through the end of the
  training period;
- `rolling_5_year` re-estimates every coefficient and the common shock scale on
  the most recent five calendar years; and
- `recent_2_year_intercept` retains the expanding-sample slopes and shock scale
  but re-estimates one intercept shift on the latest two training years.

The recent-intercept specification is a deliberately small calibration check,
not a dynamic model. The rolling specification asks whether discarding older
projects improves transport enough to offset its loss of precision.

## Validation design

Seven non-overlapping forward tests cover calendar years 2016 through 2021 and
January 1 through June 15, 2022. For each test year, the expanding model trains
through the preceding year. Every fit uses only information available by its
training cutoff.

All candidates are evaluated on:

- the complete held-out six-plus filing universe; and
- one fixed near-threshold risk set, defined by the expanding floor-6 OLS
  model's prediction of 50--150 median units using held-out pre-filing
  characteristics.

The risk-set flag is computed once per window and held fixed across all six
candidates. It never uses held-out units. Floor-11 fits define an underlying
lognormal from the selected upper tail and transport it to the common six-plus
universe. Their probabilities for 6--10 units are therefore explicit
lower-tail extrapolations.

The interim choice minimizes average within-window rank across four metrics in
both evaluation samples:

1. exact rounded unit-count log score;
2. Brier score at 100 units;
3. CDF calibration RMSE from 80 through 120 units; and
4. absolute aggregate 100-plus count error.

Ranks avoid combining unlike metric scales. Each calendar test receives equal
weight; the output also records a row-weighted average rank. Point-prediction
metrics are reported but do not choose the structural distribution.

## Result

The expanding floor-6 rounded truncated-likelihood model is the interim
preferred full-distribution specification. It ranks first in both the complete
sample and the fixed near-threshold risk set, rather than winning only through
the pooled selection rule.

| Overall rank | Training floor | Timing rule | Mean rank | First-place cells |
|---:|---:|---|---:|---:|
| 1 | 6 | Expanding history | 3.02 | 12 |
| 2 | 6 | Recent two-year intercept | 3.27 | 11 |
| 3 | 11 | Rolling five years | 3.30 | 14 |
| 4 | 11 | Recent two-year intercept | 3.54 | 5 |
| 5 | 6 | Rolling five years | 3.93 | 7 |
| 6 | 11 | Expanding history | 3.95 | 7 |

The timing adaptations do not produce a broad improvement. Relative to the
expanding floor-6 model, updating only the recent intercept changes the
full-sample exact log score from 4.285 to 4.288 and the Brier score from 0.0860
to 0.0862. It slightly improves CDF RMSE and aggregate count error, but worsens
the proper scores. The rolling floor-6 model improves the risk-set exact log
score from 5.760 to 5.727, but worsens its Brier score, CDF calibration, and
aggregate count error. Those are tradeoffs, not a new preferred model.

The best floor-11 timing rule is the five-year rolling fit. It improves
full-sample aggregate threshold calibration, but it does not replace floor 6
as a complete distribution. In the 2019 test, 31 of 95 sites selected ex ante
into the near-threshold risk set actually realized 6--10 units. A model
estimated only on 11-plus outcomes assigns those realizations extremely low
transported probability, causing a poor exact log score. This is a real
limitation of using floor 11 as the universal distribution, not a reason to
discard it as a targeted robustness specification.

## Model stocktake

The earlier audits leave one clear interim model rather than several nearly
equivalent black boxes:

| Candidate | What the audit found | Current role |
|---|---|---|
| Expanding floor-6 rounded truncated normal | Best combined forward rank; complete six-plus distribution | Preferred |
| Rolling floor-11 rounded truncated normal | Best larger-project sample check; weak lower-tail transport | Required robustness |
| Sequential cutoff-11 logit | Better binary calibration at 100 | Diagnostic only; no full unit distribution |
| Enriched linear or GAM | Small full-sample gains, no stable local gain | Appendix audit |
| Student-t or negative binomial | No stable dominance; negative binomial fails key fits | Drop |
| Raw-unit OLS | Helps large-error RMSE but worsens typical and aggregate performance | Drop |
| X-targeted weights | Worsen near-threshold probability and point fit | Drop |
| Heteroskedastic shock | Small, unstable scoring gains and violates the requested i.i.d. baseline | Robustness only |

This ranking favors a model that can generate every latent no-notch unit count
needed by the later bunch-cross-split likelihood. A model that wins only the
binary 100-unit classification cannot replace that distribution.

## Interim decision

- **Preferred full distribution:** floor 6, expanding history, rounded
  lower-truncated maximum likelihood, simple linear mean, one i.i.d. normal
  shock.
- **Required sample robustness:** floor 11. Use its rolling five-year version
  when asking how a recent, larger-project training population changes the
  result.
- **Do not carry forward:** recent-intercept recalibration or rolling floor 6.
  Their gains are isolated and do not dominate across probability metrics.

The frozen 2010--2023 preferred fit uses 5,917 six-plus filings and estimates
the log-scale shock at 0.990. The 2019--2023 rolling floor-11 robustness uses
1,458 filings and estimates a shock scale of 0.765. These are latent preferred-
size shocks, not the dollar response shock in the bunch-cross-split model.

This decision is interim because the outcome is still an individual HDB filing
and the capacity variables are tax-lot proxies. The legal-site and parent-
opportunity crosswalk and a vintage-correct legal zoning cap remain the two
substantive future improvements. They should not be approximated silently in a
timing audit.

## Outputs

- `no_notch_time_adaptation_window_metrics.csv` reports every model-window-
  sample metric.
- `no_notch_time_adaptation_validation_summary.csv` reports validation means
  and ranges.
- `no_notch_time_adaptation_model_ranking.csv` records the prespecified ranking.
- `no_notch_time_adaptation_model_choice.csv` freezes the interim preferred
  specification.
- `no_notch_time_adaptation_interim_fit_parameters.csv` records the preferred
  expanding floor-6 fit on 2010--2023 and the required rolling floor-11 fit on
  2019--2023, including their common shock scales.
- `no_notch_time_adaptation_fit_qc.csv` records training support, convergence,
  shock scales, and intercept adjustments.
- `no_notch_time_adaptation_sample_qc.csv` shows the realized composition of
  each fixed risk set.
- `no_notch_time_adaptation_windows.csv` records the exact non-overlapping
  training and test dates.
- `no_notch_time_adaptation_out_of_time_predictions.parquet` retains one row
  per test filing and candidate model for timing and threshold placebos.

Run from `code/` with `make`.

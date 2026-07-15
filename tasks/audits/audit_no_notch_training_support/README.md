# No-Notch Training-Support Audit

This audit asks whether the simple no-notch unit model should be estimated on
every qualifying filing with at least six proposed units. [New York Real
Property Tax Law § 485-x](https://www.nysenate.gov/legislation/laws/RPT/485-X)
defines an Eligible Multiple Dwelling as containing at least six units and a
Small Rental Project as an eligible site with 6--10 residential units, subject
to additional tenure, location, zoning-capacity, and Option C conditions. [NYC
HPD's program summary](https://www.nyc.gov/site/hpd/services-and-information/tax-incentives-485-x.page)
likewise lists Option C for qualifying 6--10-unit Small Rental Projects.
Projects below 30 units also differ visibly from projects near the 100-unit
threshold. The estimation floor is therefore a substantive sample choice rather
than a mechanical tuning parameter.

The audit estimates the unchanged log-unit OLS specification at training floors
of 6, 10, 11, 20, 30, 40, and 50 units:

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

Every model uses the existing leakage-safe HDB--MapPLUTO sample, training-only
imputation and category pooling, and the ten pre-policy forward-validation
windows. The floor-11 specification excludes every 6--10-unit filing, whereas
floor 10 leaves exactly 10-unit filings in the training data. This is broader
than the statutory Small Rental Project definition because the audit does not
condition that screen on rental tenure, Manhattan exclusion, the 12,500-square-
foot zoning-lot cap, or an Option C election.

## Evaluation samples

The same three held-out samples are reported for every training floor:

- `all_units_at_least_6` contains the complete six-plus model universe. A model
  trained above six is extrapolating below its selected outcome support here.
- `actual_units_50_150_outcome_selected` contains held-out filings whose
  realized proposed units are 50--150. It is a useful local diagnostic, but it
  selects on the outcome being predicted and mechanically favors models trained
  on nearby realized outcomes.
- `floor_6_x_predicted_units_50_150_fixed_risk_set` first uses the floor-6 fit
  in each training window to select held-out sites with predicted median units
  between 50 and 150. The selected rows are then held fixed across all floors.
  This avoids selecting the risk set with held-out units, although it remains a
  model-dependent diagnostic rather than a final legal-site risk-set rule.

Log prediction metrics use the fitted linear predictor. Raw-unit means use the
maintained normal retransformation, `exp(X beta + residual_rms^2 / 2)`, and
raw-unit medians use `exp(X beta)`. Predictions are not clipped at a candidate
training floor: clipping would mechanically improve the higher-floor models on
their outcome-selected samples. AUC and hard classification at 100 evaluate
ranking and threshold separation without treating these OLS fits as calibrated
probability models.

## Main result

The floor-11 model is the strongest policy-directed challenger, but dropping
all projects below 30 is not supported as a general replacement. Across the ten
forward windows, floor 11 lowers mean log RMSE from 0.846 to 0.792 and median-unit
MAE from 72.8 to 67.0 in the fixed X-selected risk set. It also brings predicted
aggregate units from 0.912 to 1.02 times actual units and raises AUC at 100 from
0.675 to 0.765. Floor 10 performs almost identically, while floors of 20 or more
worsen X-selected log RMSE and aggregate calibration.

The outcome-selected 50--150-unit diagnostic gives a different answer: floor
30 minimizes mean log RMSE and floor 20 minimizes mean unit MAE. That apparent
local gain should not choose the baseline because the held-out sample itself is
defined with realized units. In the full six-plus universe, floor 6 wins log
RMSE in all ten windows, as expected when higher-floor models must extrapolate
to small outcomes.

The reference 2013--2020 training sample falls from 4,162 observations at floor
6 to 2,336 at floor 11 and 1,426 at floor 30. Its residual RMS falls from 0.760
to 0.693 and 0.608, respectively, while adjusted R-squared falls from 0.568 to
0.502 and 0.401. The smaller residual RMS is partly mechanical range
restriction; it is not evidence that the structural preferred-size shock is
smaller.

The practical recommendation is to carry floor 6 as the broad-universe model
and floor 11 as the institutionally motivated policy-risk challenger. Before a
higher-floor model supplies the simulation distribution, it needs a likelihood
that handles conditioning on the outcome floor explicitly. Fitting OLS after
selecting `units >= floor` and then conditioning its residual distribution at
the same floor can double-count truncation.

## Outputs

- `no_notch_training_support_window_metrics.csv` contains every
  floor-window-sample metric.
- `no_notch_training_support_validation_summary.csv` reports ten-window means,
  ranges, preferred directions, and window win counts.
- `no_notch_training_support_window_counts.csv` records training and evaluation
  counts, residual RMS, adjusted R-squared, and outcome centers.
- `no_notch_training_support_reference_sample_composition.csv` describes the
  unit bins in the 2013--2020 reference training sample.
- `no_notch_training_support_reference_predictions.parquet` contains all seven
  predictions for every reference held-out filing and both local-sample flags.
- `no_notch_training_support_reference_fit_summary.txt` records preprocessing
  constants, factor levels, and verbatim `summary(lm)` output for every floor.

Run from `code/` with `make`.

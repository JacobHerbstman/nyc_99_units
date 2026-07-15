# Research Understanding Checklist

## Session goal

- [x] Score 2025 HDB New Building filings with the frozen no-notch models.
- [x] Compare the observed 2025 unit distribution with the model-implied
  distribution absent the 100-unit notch.
- [x] Produce a row-level exact-99 exposure ledger without labeling projects as
  confirmed bunchers.

## Data and scope

- [x] Unit of observation: one HDB New Building filing.
- [x] Preferred model: expanding 2010--2023 floor-6 rounded truncated normal.
- [x] Required robustness: rolling 2019--2023 floor-11 model.
- [x] 2025 features use the one-release-lag 23v3 MapPLUTO vintage.
- [x] Exact-99 filings without a safe MapPLUTO match remain in the ledger with
  missing scores and an explicit reason.
- [x] All joins assert one-to-one or many-to-one cardinality.

## Interpretation

- [x] `probability_at_least_100` is an ex-ante no-notch exposure probability,
  not a posterior probability that the observed project bunched.
- [x] Summed model probabilities condition on the set of observed 2025 filing
  opportunities and do not recover an extensive-margin citywide counterfactual.
- [x] Floor-11 probabilities below 11 units are lower-tail extrapolations.
- [x] The legal site and parent opportunity remain unresolved without HPD and
  zoning-lot evidence.

Researcher restatement and quiz are `skipped_by_user`, following the standing
request while the framework is being built.

# Fit Candidate Prediction Models

Audits richer prediction models for large-project exposure among observed HDB New Building candidate filings.

This task is diagnostic. It does not create the production exposure score and does not score the post-policy land-value analysis sample.

The audit keeps the target narrow: among candidate filings with proposed Class A units above a threshold, predict whether proposed Class A units are at least 100. It compares simple complete-case-style features to richer leakage-safe MapPLUTO features already in the HDB-MapPLUTO training panel.

Candidate thresholds are 50+, 60+, and 70+. Validation windows are:

- pre-2018 training to 2018-2020 test;
- 2013-2020 training to 2021 through 2022-06-15 test;
- 2013-2020 training to post-2022-06-15 test, labeled as regime-transport evidence rather than ordinary validation.

Models include ordinary logit, ridge/elastic-net logit, weight-decay multinomial size-bin prediction, and penalized log-unit prediction. Glmnet models tune only inside the training period using filing-year folds. The multinomial diagnostic uses collapsed bins: 50-69, 70-99, 100-149, and 150+.

Outputs are CSV diagnostics only: fit summaries, reliability/capture bins, rank correlations, top-bin overlap, candidate sample summaries, size-bin counts, and feature missingness.

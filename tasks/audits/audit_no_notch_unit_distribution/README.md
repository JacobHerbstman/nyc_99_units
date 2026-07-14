# No-Notch Unit Distribution Audit

This audit estimates a building-level conditional distribution of proposed
permanent Class A units before 485-x. It does not classify legal eligible sites
or parent development opportunities, and it does not label individual 99-unit
filings as bunchers.

The training unit is one HDB New Building filing with at least six positive
integer Class A units and leakage-safe lagged MapPLUTO features. The audit fits
six transparent distribution models over the same forward time windows:

- unconditional lognormal benchmark;
- simple lognormal linear regression;
- enriched lognormal linear regression;
- enriched lognormal generalized additive model;
- simple linear regression with i.i.d. Student-t shocks; and
- simple truncated negative-binomial regression.

Model comparison emphasizes held-out probability scores, CDF calibration near
100 units, prediction-interval coverage, and stability across time windows.
Point-prediction metrics are secondary. A later task may use the selected model
to score post-policy buildings; parent-opportunity scale requires a separate,
symmetric grouping design.

The audit also refits the preferred simple lognormal model in a pairs bootstrap
that resamples training filings by BBL. It reports the bootstrap distribution of
held-out scores, CDF calibration, exact-99 mass, and predicted 100-plus mass for
every forward time window. The bootstrap measures training-sample uncertainty;
it does not replace the i.i.d. unit-preference shocks used in later simulation.

The reported unit-distribution shock scale describes residual variation in
preferred no-notch units. It is not the separate dollar-scale response-choice
shock in the later bunch/cross/split model.

`no_notch_predicted_actual_dashboard.pdf` and its PNG counterpart show
individual held-out predictions, probability calibration at 100 units, and
aggregate predicted-versus-actual 100-plus counts across every forward window.

Run from `code/` with `make`.

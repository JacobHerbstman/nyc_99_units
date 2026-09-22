# Historical holdout checks

Tests whether the reweighted historical benchmark in `audit_scale_shape_splitting`
reproduces pre-policy distributions it was not fit to. `audit_shape_counterfactual.R`
runs forward placebos (earlier historical years predicting later ones),
leave-one-pre-year-out estimates, historical-window sensitivity, and an
exploratory q–θ calculation, all on the benchmark sample of parents with 50–300
units and a pooled 301+ bin.

These are the pre-policy holdout checks cited in `framework_writeup.tex`. They
are evidence about the maintained counterfactual, not inputs to it. Build the
main panels and `audit_scale_shape_splitting` first, then run `make` in `code/`.

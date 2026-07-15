# No-notch timing and threshold placebo audit

This audit asks whether the fitted no-notch procedure creates artificial
bunching in years before 485-x or one unit below false thresholds. It uses
genuinely out-of-time predictions: every 2016--2022 test observation is scored
by a model trained only on earlier years. The 2022 window ends June 15 and is
shown but excluded from the full-year placebo summary.

The candidate thresholds are 90, 100, 110, and 120, corresponding to exact-bin
tests at 89, 99, 109, and 119. The preferred specification uses the six-unit
floor and expanding history. The required robustness uses the 11-unit floor
and rolling five-year history. Probabilities for both are evaluated in the
common six-plus-unit universe.

## Findings

The 2025 exact-99 excess is 51.95 filings in the preferred model and 51.83 in
the floor-11 robustness. Across the six full pre-policy placebo years, the
largest exact-99 excess is only 1.29 in the preferred model and 1.02 in the
robustness. At the false thresholds, the largest full-year excess ranges from
0.38 to 2.45. The partial 2022 exact-99 excess is 0.34 and 0.10.

The 2025 result is also localized at the actual threshold. In the preferred
model, the 2025 observed-minus-expected masses are 3.8 at 89, 52.0 at 99,
-0.9 at 109, and -0.8 at 119. The floor-11 results are nearly identical.

These placebos strongly reject the concern that the 99 spike is a generic
artifact of the prediction procedure or a tendency to create excess mass below
any round-number threshold. They do not fix the broader calibration error in
the total number of 100-plus filings, and they do not validate parent or legal
site definitions.

Run the task from `code/` with `make`. The Makefile exposes the common universe
floor, candidate thresholds, and post-policy year.

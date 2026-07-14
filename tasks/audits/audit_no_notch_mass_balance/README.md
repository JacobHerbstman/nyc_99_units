# No-notch mass-balance audit

This task asks whether a one-channel deterministic bunching model can reconcile
two post-policy moments:

1. excess filings at 99 relative to the no-notch prediction; and
2. missing filings at or above 100 relative to the no-notch prediction.

For each frozen no-notch model, the task sums the probability that latent
preferred scale lies between 100 and a candidate upper frontier. It separately
chooses the frontier that matches each observed moment. Under the local
constant-cost quadratic benchmark,

`frontier = 99 + sqrt(2 T / gamma)`, so the frontier also implies the
unit-squared ratio `T / gamma = (frontier - 99)^2 / 2`. Neither `T` nor `gamma`
is separately identified in dollars.

## Findings

Matching the preferred model's 51.95 excess exact-99 filings requires a latent
frontier of 179.1 units. Matching its 74.63 missing filings at or above 100
requires a frontier of 253.6 units. The first calibration predicts 72.68
filings above 100 rather than the 50 observed; the second predicts 75.68
exact-99 filings rather than 53.

The floor-11 robustness also requires a frontier near 177.9 units to match the
99 spike. Its missing-above-100 moment instead implies 164.7 units. The two
moments disagree by 5.24 filings, compared with 22.68 under the preferred
model.

These frontiers are far outside the domain in which the framework's quadratic
is intended to be local. They should not be interpreted as estimates that a
typical single building removed 79--155 units. The exercise is a failed-model
diagnostic: broad residual dispersion, individual-filing rather than parent
opportunities, unobserved extensive-margin projects, and response channels
other than one-for-one movement from 100+ to 99 can all break the calculation.

The result makes the parent-opportunity crosswalk economically important rather
than merely an institutional refinement. A 99-unit component of a 198--591-unit
parent should not be treated as a standalone project that locally shrank from a
very large latent unit count.

Run the task from `code/` with `make`. The only analytical arguments are the
sample floor used to condition probabilities and the 100-unit policy threshold.

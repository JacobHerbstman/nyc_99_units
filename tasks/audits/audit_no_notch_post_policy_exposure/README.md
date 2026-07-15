# Post-policy no-notch exposure audit

This task applies the two frozen no-notch unit-count models to 2025 New
Building filings. It asks how the observed 2025 unit distribution differs from
the distribution predicted for the same filing opportunities if the 100-unit
notch were absent.

The preferred model uses the six-unit estimation floor and expanding
2010--2023 history. The required robustness uses the 11-unit floor and a
rolling 2019--2023 window. Both use only MapPLUTO releases available before the
filing date. The scoring panel contains 626 filings. All use MapPLUTO 23v3,
which precedes the filing by 429--792 days.

## Main findings

Among the 626 scoreable filings, 53 have exactly 99 units and 50 have at least
100 units. The preferred model predicts 1.05 exact-99 filings and 124.63
filings at or above 100. It therefore implies an excess of 51.95 filings at 99
and a deficit of 74.63 filings at or above 100. The exact-99 excess is 69.6
percent of the missing mass above the threshold.

The floor-11 robustness predicts 1.17 exact-99 filings and 96.60 filings at or
above 100. It implies an excess of 51.83 filings at 99 and a deficit of 46.60
above the threshold. Here the exact-99 excess is larger than the missing mass
above 100. This failure of one-for-one mass conservation is a useful model
diagnostic, not evidence that more than one project moved for every missing
project.

For each observed exact-99 filing, the ledger reports the model-implied
probability that its latent no-notch unit count is at least 100. Under the
preferred model, the mean probability is 0.406, the median is 0.442, and 23 of
53 scored exact-99 filings have a probability of at least one half. These are
ex ante exposure measures conditional on observed site characteristics. They
are not posterior probabilities that a particular filing is a buncher.

There are 55 exact-99 filings in the full 2025 six-plus-unit HDB sample. Two
adjacent-lot filings cannot be matched to leakage-safe pre-filing MapPLUTO and
remain explicitly unscored in the ledger: Q01297222 on BBL 4159500030 and
Q01297223 on BBL 4159500031.

## Interpretation limits

The comparison conditions on the set of observed 2025 filing opportunities.
It does not recover projects that were never filed, validate legal 485-x sites,
or identify parent development opportunities. It therefore is not a citywide
extensive-margin counterfactual.

The exercise also does not convert bunching into dollars. With the quadratic
local profit approximation, the response can identify a unit-distance frontier
or a ratio such as threshold cost to profit curvature. A wage-cost ledger or
project financial data are still needed to separately anchor the dollar scale.

Run the task from `code/` with `make`. The Makefile exposes the policy year,
sample floor, threshold, plot range, category support rule, and exposure cutoffs
as scalar analytical choices.

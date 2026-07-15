# Parent-level no-notch model audit

## Question

This audit asks whether the historical no-notch model improves when the unit of
observation is a reconstructed economic parent rather than an individual DOB
filing. It keeps the preferred distributional specification fixed: the
conditional mean is linear in log units, observed units are rounded and
lower-truncated at six, and there is one normally distributed i.i.d. shock.

The audit separates three changes that should not be conflated:

1. aggregating filing-level predictions to a parent outcome;
2. shortening the training period from 2010--23 to 2019--23; and
3. re-estimating the model on parent outcomes.

## Parent construction

The enhanced parent is the common evaluation unit. It combines the
conservative pre-filing links from the historical feasibility audit with exact
MapPLUTO polygon adjacency when the adjacent filings are also corroborated by
a filing gap of at most 30 days or the same leakage-safe owner name. Exact
polygon adjacency is available only for 2019--23. No adjacency is imputed and
no inferred parent correction is applied before 2019. The model itself retains
the frozen filing specification's explicit missing-covariate handling.

The historical sample contains 5,917 filings, 5,805 conservative parents, and
5,775 enhanced parents. The enhanced construction has 106 multi-filing parents
containing 248 filings. In 2025, 626 scoreable filings become 590 enhanced
parents. Seven parents have repeated nonmissing BIN rows and are treated as
ambiguous rather than summed, leaving 583 common evaluation parents containing
609 filings.

## Model and comparison

Every fitted model uses

```text
log(units) = log(lot area) + ResidFAR + BuiltFAR
             + missing ResidFAR + filing year
             + borough + zoning group + prior site use.
```

Lot area is summed across unique pre-filing feature lots within a parent.
ResidFAR and BuiltFAR are lot-area weighted. Heterogeneous categorical values
are coded as mixed. The rounded, lower-truncated likelihood is otherwise the
same as in the frozen filing model.

Five models are compared on the same enhanced-parent outcomes in forward
validation years 2021, 2022, and 2023:

- filing model trained in 2010--23 or 2019--23, with independent filing shocks
  convolved to obtain the parent distribution;
- conservative-parent model trained in 2010--23 or 2019--23; and
- enhanced-parent model trained in 2019--23.

A parent spanning a validation boundary is excluded from that window. This
prevents a later companion filing from entering an earlier training or test
outcome.

## Findings

The enhanced-parent 2019--23 model has the best average rounded log score, CDF
RMSE over 80--120 units, and 100-plus share calibration. It ranks second on the
Brier score and on exact-99 share calibration. The gain is real but modest:

| Model | Rounded log score | Brier at 100 | CDF RMSE 80--120 |
|---|---:|---:|---:|
| Filing, 2010--23 | 4.57 | 0.0939 | 0.0241 |
| Filing, 2019--23 | 4.56 | 0.0917 | 0.0235 |
| Conservative parent, 2010--23 | 4.55 | 0.0916 | 0.0236 |
| Conservative parent, 2019--23 | 4.53 | 0.0888 | 0.0215 |
| Enhanced parent, 2019--23 | 4.53 | 0.0895 | 0.0212 |

The result is not uniform in every year. With only 2019--20 available for
training, the 2021 CDF RMSE is 0.0537 for the enhanced-parent model versus
0.0247 for the long-history filing model. In 2022 and 2023, the recent
parent-level models are substantially better on that metric. Thus the average
gain relies partly on the later validation windows and should not be described
as domination across all training lengths.

The 2025 counterfactual decomposition is more informative:

| Model and evaluation unit | Excess at 99 | Missing at 100+ | Absolute mass gap | Frontiers from the two moments |
|---|---:|---:|---:|---:|
| Filing 2010--23, individual filings | 52.0 | 74.6 | 22.7 | 179.1 / 253.6 |
| Filing 2010--23, enhanced parents | 34.1 | 48.5 | 14.4 | 153.0 / 191.3 |
| Filing 2019--23, enhanced parents | 34.2 | 23.0 | 11.1 | 164.9 / 136.9 |
| Conservative parent 2019--23 | 34.1 | 22.3 | 11.9 | 161.4 / 133.6 |
| Enhanced parent 2019--23 | 34.1 | 23.7 | 10.4 | 159.8 / 135.7 |

The parent model therefore looks much better than the original
individual-filing counterfactual, but most of that improvement does not come
from parent-level re-estimation alone. Aggregating the original filing model
closes a large part of the gap; restricting the training period to 2019--23
closes more; estimating the enhanced-parent model provides a smaller final
improvement. The enhanced-parent result is the best current same-data
specification, but its exact-99 moment still implies a high frontier of about
160 units and the two moments still disagree by about 24 units.

The earlier provisional frontier near 110 used a broader 2024--26 parent
crosswalk. This audit deliberately uses a symmetric, reproducible 2025-only
construction, so the two numbers are not directly comparable. The broader
crosswalk can absorb companion filings outside 2025, while this audit avoids
that look-ahead and accepts calendar-year right-censoring.

## Reproduction

Run `make` from `code/`. The Makefile links exact upstream files and builds the
parent panels, validation results, fitted parameters, 2025 score file,
counterfactual summary, unit distribution, and comparison figure. The scalar
choices for years, unit floor, filing window, adjacency corroboration window,
category floor, and distribution maximum are exposed at the top of the
Makefile.

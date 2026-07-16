# Preferred parent-model inference and placebo audit

This audit applies inference and falsification checks to the production
enhanced-parent model. It uses the same rounded, six-unit-truncated likelihood,
covariates, 2019--2023 historical parent panel, and HDB-primary 2025 parent
outcome as the preferred estimator.

The deterministic checks are:

1. expanding-window pseudo-policy years from 2020 through 2023, with each year
   scored only by earlier historical parents;
2. candidate thresholds from 80 through 120 in the fixed 2025 parent sample;
3. 2025 estimates after omitting every historical calendar year in turn; and
4. 2019--2022 versus 2019--2023 training endpoints.

A parent spanning a pseudo-policy boundary is not split across training and
test samples. Leave-one-year-out estimates remove any parent whose filing span
touches the omitted calendar year.

The main nonparametric bootstrap resamples and refits the 2019--2023 historical
parents while holding the observed 2025 parent population fixed. This measures
historical estimation uncertainty conditional on the realized 2025 cohort. A
parallel two-sample bootstrap also resamples 2025 parents, adding uncertainty
from viewing that cohort as a sample from a broader post-policy population.
Neither bootstrap imputes parents, companions, or unit counts.

The bootstrap reports percentile intervals for expected and excess exact-99
mass, expected and missing 100-plus mass, the conservation gap, the affected
mean counterfactual size, and the implied frontier. It retains both the
exact-99 and missing-100-plus mappings because the two empirical masses do not
currently balance.

Run `make` from `code/`. The Makefile exposes all sample years, threshold
bounds, bootstrap repetitions, seed, and interval probabilities.

## Findings

The preferred 2019--2023 model predicts 0.83 exact-99 parents in 2025, compared
with 27 observed. The estimated excess is therefore 26.17 parents. At and above
100 units, the model predicts 81.68 parents and observes 69, leaving 12.68
missing parents. Because excess exact-99 mass is larger than missing 100-plus
mass, the conservation gap is 13.49 parents. The exact-99 mapping implies an
affected-project mean counterfactual size of 118.97 units and a frontier of
143.00 units. The alternative missing-mass mapping gives 107.93 and 117.18
units, respectively.

The pre-policy pseudo-years do not reproduce the 2025 exact-99 excess. Their
estimated excesses range from -0.55 to 3.71 parents. Candidate thresholds from
80 through 120 also single out 100: excluding the actual threshold, the largest
exact-mass excess is 3.94 parents at 87 units. The missing-above-threshold moment
is less well calibrated in the pseudo-years, especially in 2021, when observed
100-plus mass exceeds its prediction by 21.2 parents. The exact-mass placebo is
therefore the cleaner falsification result.

Leaving out one historical calendar year at a time gives affected-project mean
counterfactual sizes from 117.9 to 119.7 units and frontiers from 140.3 to 144.9
units. The missing-100-plus estimate is more sensitive, ranging from 9.9 to
18.7 parents. Ending training in 2022 instead of 2023 produces the same pattern:
the exact-99 mapping changes little, while missing mass rises from 12.7 to 18.7.

All 499 historical bootstrap refits succeeded. Conditional on the observed
2025 parent cohort, the 95 percent percentile interval is 116.46--122.47 units
for the exact-99 affected mean and 136.81--152.11 for its frontier. The
corresponding interval for missing 100-plus mass is 0.45--25.42 parents, and the
conservation gap interval is 0.65--25.82. In the two-sample bootstrap, which also
resamples 2025 parents, uncertainty is substantially wider: the exact-99 mean
interval is 110.55--131.30, the frontier interval is 123.02--176.27, and the
conservation-gap interval includes zero at -5.60--31.20 parents. Thus the
roughly 119-unit mean is stable to historical-model estimation, but
population-level inference must acknowledge the small realized post-policy
cohort.

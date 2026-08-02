# Preferred parent-model mass-balance audit

This audit asks whether excess exact-99 parent mass can be accounted for by
missing parents at or above 100 units. It uses the production symmetric-parent
sample: fully observed 2019--2022 cohorts for training and 564 scoreable 2025
cohorts observed for at least 180 days, with complete pre-filing linkage
windows, for scoring.

Observed and predicted parents are divided into three mutually exclusive
regions: below 99, exactly 99, and at least 100 units. Because both
distributions contain the same 564 parents, excess exact-99 mass must equal
missing 100-plus mass plus missing below-99 mass. The task also reports broad
unit bins, annual local counts, observed parent structure, composition and
support checks, broad-link sensitivities, and pseudo-policy conservation gaps.

## Findings

The model predicts 479.05 parents below 99, 0.86 at 99, and 84.09 at or above
100. It observes 462, 22, and 80. The 21.14 exact-99 excess therefore divides
into 4.09 missing 100-plus parents and 17.05 missing below-99 parents. The
identity holds to numerical precision, but the large below-99 component rules
out treating all exact-99 excess as projects mechanically diverted from above
100 without an additional behavioral assumption.

The residual distribution is not a simple transfer across the cutoff. Relative
to the no-notch fit, the mature cohort has 13.13 excess parents with 50--79
units and 10.18 with 80--98, alongside a deficit of 8.61 at 100--119 and a
deficit of 37.30 at 6--29. Exact 99 is nevertheless exceptional: 22 parents are
observed versus at most three in any complete historical cohort.

All 22 production exact-99 parent totals are single-filing parents. Other
mature parents include seven linked repeated-99 parents and five linked
parents with one 99-unit component, but all have totals above 99. Under the
earlier broad parent sensitivity, 19 of the current 22 exact-99 parents remain
unlinked, two join parents with other filings, and one joins a
repeated-99 parent. These broad links are useful sensitivity evidence but are
not substituted for the leakage-safe production rule.

The 17.05-parent conservation gap is within the pre-policy experience: the
pseudo-policy gaps range from -2.56 to 22.54. By contrast, pseudo-policy exact
mass ranges only from -0.55 to 2.09. This reinforces the main interpretation:
exact-99 excess is the cleaner behavioral moment, while missing 100-plus mass
and the gap are useful accounting checks rather than independent cost moments.

The mature 2025 cohort contains no categorical level absent from the training
data. Its borough and zoning composition has shifted, especially toward the
Bronx and lower-density zones, but the exact-99 parents' fitted values remain
inside the historical prediction range. One exact-99 parent's built FAR lies
above the historical maximum. These checks support using the conditional model
while retaining composition and support diagnostics as robustness evidence.

The structure groups are defined by observed outcomes and are descriptive, not
separate causal effects. Run `make` from `code/`.

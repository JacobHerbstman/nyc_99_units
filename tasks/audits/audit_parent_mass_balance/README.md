# Preferred parent-model mass-balance audit

This audit asks whether excess exact-99 parent mass can be accounted for by
missing parents at or above 100 units. It uses the production symmetric-parent
sample: fully observed 2019--2022 cohorts for training and 245 scoreable 2025
cohorts with complete 365-day windows for scoring.

Observed and predicted parents are divided into three mutually exclusive
regions: below 99, exactly 99, and at least 100 units. Because both
distributions contain the same 245 parents, excess exact-99 mass must equal
missing 100-plus mass plus missing below-99 mass. The task also reports broad
unit bins, annual local counts, observed parent structure, composition and
support checks, broad-link sensitivities, and pseudo-policy conservation gaps.

## Findings

The model predicts 213.25 parents below 99, 0.38 at 99, and 31.37 at or above
100. It observes 211, 10, and 24. The 9.62 exact-99 excess therefore divides
into 7.37 missing 100-plus parents and 2.25 missing below-99 parents. The gap is
small and its identity holds to numerical precision, but it still cautions
against imposing literal one-for-one conservation as an assumption.

The residual distribution is economically coherent around the cutoff. Relative
to the no-notch fit, the completed cohort has 9.90 excess parents with 50--79
units and 3.22 with 80--98, alongside deficits of 4.29 at 100--119 and 2.39 at
120--149. Exact 99 is nevertheless exceptional: 10 parents are observed versus
at most three in any complete historical cohort.

All 10 production exact-99 parent totals are single-filing parents. Other
completed parents include three linked repeated-99 parents and two linked
parents with one 99-unit component, but all have totals above 99. Under the
earlier broad parent sensitivity, eight of the current 10 exact-99 parents
remain unlinked, one joins a parent with another filing, and one joins a
repeated-99 parent. These broad links are useful sensitivity evidence but are
not substituted for the leakage-safe production rule.

The 2.25-parent conservation gap is well within the pre-policy experience: the
pseudo-policy gaps range from -2.56 to 22.54. By contrast, pseudo-policy exact
mass ranges only from -0.55 to 2.09. This reinforces the main interpretation:
exact-99 excess is the cleaner behavioral moment, while missing 100-plus mass
and the gap are useful accounting checks rather than independent cost moments.

The structure groups are defined by observed outcomes and are descriptive, not
separate causal effects. Run `make` from `code/`.

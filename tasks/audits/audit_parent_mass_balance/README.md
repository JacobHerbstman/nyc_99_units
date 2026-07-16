# Preferred parent-model mass-balance audit

This audit asks why the preferred enhanced-parent model produces more excess
exact-99 parents than missing parents at or above 100 units. It uses the same
2019--2023 training parents, HDB-primary 2025 outcome, production no-notch
scores, and expanding-window pseudo-policy years as the preferred model and its
inference audit.

The accounting starts with three mutually exclusive regions: below 99, exactly
99, and at least 100 units. Because the observed and predicted distributions
each contain the same number of 2025 parents, the conservation gap must equal
the model's missing mass below 99. The audit then opens that identity up by:

1. reporting observed-minus-predicted mass in broad unit bins;
2. comparing annual parent counts around the threshold;
3. decomposing the two threshold moments by observed parent structure;
4. comparing borough, zoning, and prior-use composition;
5. checking continuous covariates and model predictions against historical
   support; and
6. placing the 2025 conservation gap beside the pre-policy pseudo-years.

The structure decomposition is descriptive because its groups are defined by
observed 2025 outcomes. It can reveal where the accounting discrepancy occurs,
but it does not estimate separate causal effects for singleton and multi-filing
parents.

## Findings

The preferred model predicts 485.49 parents below 99 units, 0.83 at exactly 99,
and 81.68 at or above 100. It observes 472, 27, and 69, respectively. The 26.17
excess exact-99 parents therefore divide arithmetically into 12.68 missing
100-plus parents and 13.49 missing below-99 parents. The conservation gap is the
second term; it is not unaccounted total parent mass.

The below-99 total conceals a broad composition shift. Relative to the no-notch
prediction, 2025 contains 41.98 fewer parents with 6--29 units, but 16.95 more
with 50--79 units and 10.89 more with 80--98 units. It also contains 9.10 fewer
parents with 100--119 units and 2.81 fewer with 120--149 units. Thus a literal
model in which every extra exact-99 parent came only from above 100 is too
restrictive for the observed distribution.

The annual counts tell a similar story. The 2025 cohort has 100 parents with
50--98 units, compared with a historical maximum of 75, and 27 exact-99 parents,
compared with a historical maximum of four. It has only 17 parents with
100--150 units, versus 23--39 in 2019--2022 and 13 in the smaller 2023 cohort.
There are 568 total 2025 parents, slightly above the historical maximum of 529.
This is consistent with a broader 2025 shift toward medium sub-threshold
projects; the current data cannot distinguish policy responses from entry,
timing, or unmodeled aggregate composition.

Under the conservative production parent definition, all 27 exact-99 parents
are single-filing parents. The 35 linked multi-filing parents contain no
exact-99 component filings. This means already-resolved multi-filing parents do
not generate the preferred exact-99 mass. It does not prove that the 27
singletons are economically independent: unresolved splits under broader link
rules remain a live measurement explanation. When those 27 parents are matched
to the earlier 365-day universal link sensitivity, 19 remain unlinked, three
belong to one repeated-99 broad parent, four have other companion filings, and
one is a multi-job DOB source-disagreement case. Broad links therefore absorb
eight preferred exact-99 parents, although that sensitivity is deliberately not
substituted for the conservative production definition.

Observed 2025 composition shifts toward the Bronx by 9.03 percentage points and
away from Brooklyn by 9.14 points. The R1--R5 zoning share rises by 7.56 points.
These covariates are already included in the no-notch model, and no 2025
prediction lies outside the historical prediction range. No categorical level
is new in 2025; only one parent lies outside the historical range of the three
continuous site variables. Lack of common support is therefore not the main
explanation, although omitted dimensions of composition remain possible.

Finally, conservation gaps are not specific to 2025. The 2021 pseudo-policy
year has a 22.54-parent gap, larger than the 13.49-parent post-policy gap, despite
having only 1.33 excess exact-99 parents. The exact-99 spike remains distinctive,
but the missing-100-plus and conservation-gap moments inherit meaningful
distributional misspecification. The exact-99 excess is therefore the cleaner
descriptive bunching moment, but interpreting all of it as projects shifted from
above 100 is not supported by the current accounting. That stronger cost
interpretation should wait for better parent links, commencement timing, and
cohort definition.

Run `make` from `code/`. The Makefile exposes the sample years, model floors,
policy threshold, unit bins, local comparison range, and support quantiles.

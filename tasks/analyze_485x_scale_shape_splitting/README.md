# 485-x scale, shape, and project-splitting checks

This task separates three empirical facts that should not be conflated:

1. **Market scale:** the annualized number of A/B rental opportunities.
2. **Distributional shape:** each unit bin's share of all parent opportunities
   with at least 50 units, retaining a pooled 301+ bin.
3. **Project composition:** whether a linked economic parent is filed as one or
   several constituent filings/buildings, including exact 99 x 2 and 99 x 3
   configurations.

The task does not replace or modify the existing counterfactual code. It
reconstructs the same parent universe and first verifies that the earlier
50-300 count and normalized-density series are reproduced exactly.

## Samples and timing

The descriptive sample contains all classified A/B rental opportunities with
at least six proposed units. The preferred shape sample contains all A/B parent
opportunities with at least 50 proposed units. Historical cohorts run from
January 1, 2019 through December 31, 2022. The post period runs from January 1,
2025 through July 8, 2026, or 1.51677 years.

Post-period parents are included without requiring a complete right-side
linkage window. The panel records observed follow-up days and whether each side
of the linkage window is observed, so results can later be restricted as a
sensitivity. This choice maximizes the current sample but means late post
cohorts remain provisional as new filings arrive.

## Parent and constituent construction

`construct_scale_shape_splitting_panels.R` produces one row per linked economic
parent and one row per constituent filing/building. It validates that the sum
of constituent units equals the parent total exactly. The parent panel records
sorted constituent sizes, component counts, exact 99 x 2 and 99 x 3 flags, and
mutually exclusive response categories A-G.

Splitting verification is intentionally conservative. Distinct HPD 485-x
registration units are coded as verified; distinct BBLs without that direct
evidence are suggestive; ambiguous cases remain unable to verify. No ambiguous
parent is converted into verified splitting by assumption.

## Composition-adjusted benchmark

The reweighted benchmark uses feature-complete 2019-2022 parents and positive
exponential calibration (`survey::calibrate(..., calfun = "raking")`) to match
the post sample on predetermined log lot area, residential FAR, built FAR,
multi-lot status, and borough. Project unit count and eventual 485-x option are
never used to construct weights.

The task retains capacity, slack, lot-count, zoning-family, and prior-use fields
in the analytical panel, but does not impose all of those moments in the main
calibration. The richer exact moment vector failed positive-weight
overlap/convergence. The code therefore reports the feasible prespecified
moment set and does not merge categories, switch estimators, or silently fall
back to a propensity score.

The primary reweighted histogram preserves exact historical heaping. It is not
smoothed. Local excess and cumulative-deficit calculations are reported at 99
and 198. Full-support normalized mass necessarily sums to one and is not
interpreted as behavioral mass recovery.

## Inference and diagnostics

The task reports balance, effective sample size, historical-year stability,
two forward pre-policy placebos, leave-one-pre-year-out estimates, and a
parent-level nonparametric bootstrap. Calibration weights are re-estimated in
every successful bootstrap replication. Failed positive-weight calibrations
are recorded rather than replaced by another method.

The exploratory q and theta outputs are discrete descriptive moments. They are
not estimates of structural adjustment costs, and the single-component results
condition on a post-policy choice margin.

Run the complete task from `code/` with:

```sh
make
```

The reader-facing compilation of all figures and their interpretations is
written to `output/pdf/scale_shape_splitting_figure_guide.pdf`. Its headline
values are generated from the current result tables before LaTeX compilation.

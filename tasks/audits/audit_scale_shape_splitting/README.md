# 485-x scale, shape, and project-splitting checks

This task separates three empirical facts that should not be conflated:

1. **Market scale:** the annualized number of A/B rental opportunities.
2. **Distributional shape:** each unit bin's share of all parent opportunities
   with at least 50 units, retaining a pooled 301+ bin.
3. **Project composition:** whether a linked economic parent is filed as one or
   several constituent filings/buildings, including exact 99 x 2 and 99 x 3
   configurations.

The task reads the canonical panels from `build_estimation_panels` and the
basic bunching figures from `plot_bunching`. It owns only the exploratory
reweighting, inference, decomposition, and their figure guide. Exact reproduction checks against those earlier series are maintained
in `tasks/audits/audit_scale_shape_counterfactual`.

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

`build_estimation_panels.R` in the main dataset task produces one row per linked economic
parent and one row per constituent filing/building. It validates that the sum
of constituent units equals the parent total exactly. The parent panel records
sorted constituent sizes, component counts, exact 99 x 2 and 99 x 3 flags, and
mutually exclusive response categories A-G.

Splitting verification is intentionally conservative. Distinct HPD 485-x
registration units are coded as verified; distinct BBLs without that direct
evidence are suggestive; ambiguous cases remain unable to verify. No ambiguous
parent is converted into verified splitting by assumption.

## Composition-adjusted benchmark

The reweighted benchmark selects rental parents with at least 50 units and
`composition_eligible = TRUE`: every source filing has a matched parcel with
positive area, and additive filings have distinct nonmissing building
identifiers. Building identifiers come from DOB initial filings with Housing
Database fallback. `output/calibration_summary.csv` records the selected sample
sizes and the composition-ineligible exclusions.

The benchmark uses the eligible 2019-2022 parents and positive
exponential calibration (`survey::calibrate(..., calfun = "raking")`) to match
the post sample on log lot area, residential FAR, built FAR, and borough.

The model takes each parent's total land footprint as given. The developer
chooses units and organization within it; the reweighted historical joint
distribution supplies ordinary size and organization, including ordinary
multiple-constituent parents. The parcel attributes used in weighting come
from archival releases, aggregated over the observed parent's linked lots.
Land area sums those lots; FAR measures use their area weights. Treating this
footprint as available under both policy regimes is a maintained assumption.

The primary reweighted histogram preserves exact historical heaping. It is not
smoothed. Local excess and cumulative-deficit calculations are reported at 99
and 198. Full-support normalized mass necessarily sums to one and is not
interpreted as behavioral mass recovery.

## Inference

The task reports calibration balance, effective sample size, and a parent-level
nonparametric bootstrap. Calibration weights are re-estimated in every
successful bootstrap replication. Failed positive-weight calibrations are
recorded rather than replaced by another method.

Forward pre-policy placebos, leave-one-pre-year-out estimates, historical-window
checks and exploratory q and theta moments live in
`tasks/audits/audit_scale_shape_counterfactual`.

Run the complete task from `code/` with:

```sh
make
```

The reader-facing compilation of all figures and their interpretations is
written to `output/pdf/scale_shape_splitting_figure_guide.pdf`. Its headline
values, which `framework_writeup.tex` also reads, are written from the result
tables to `output/figure_guide_values.tex`.

`output/pdf/meeting_packet.pdf` is the nine-page figures-only meeting packet:
annualized and normalized filing sizes, separate pre/post one-unit histograms
with common axes, 50+ and 6+ filing-size CDFs, normalized parent totals, the
composition-adjusted benchmark, and two views of repeated-99 configurations.

`plot_annual_split_shares.R` produces `output/annual_split_shares.csv` and
the annual chart in PDF and PNG. Each eligible 50-plus rental parent counts
once, in its original first-filing year. The two series show multiple
constituent filings and multiple matched archival tax lots. The tax-lot measure
does not date legal subdivision events. The chart leaves 2023–2024 outside
the comparison sample and identifies the partial 2026 cohort and shorter
post-period follow-up.

Refiling dates are separate from original proposal dates. In the constituent panel, `date_filed` is the original filing date, `record_filing_date` is the retained application's actual filing date, and `refiled`/`refiling_date` record an automatically detected replacement. Only the replacement's units are additive. The parent panel keeps the original `cohort_date`, sets `refiled` when any constituent refiled, and records the earliest qualifying refiling date across its constituents (missing otherwise). This correction uses observed replacement units and does not claim to recover the original design's unit choice.

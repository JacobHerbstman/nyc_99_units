# Pure-notch estimation pilot

The September 21 rerun uses the five parent mergers and 18 land
corrections, including the explicitly flagged Flatbush floor estimate. It contains 554 historical and 310 post-period parents. Five
reviewed land allocations and the broader boundary inventory remain unresolved,
so these results are provisional diagnostics at the existing specification.

The best separate-assessment baseline has `kappa = 0.11`, `sigma_org = 1.1`,
`tau = 0`, and fixed `lambda = 1`.

| Outcome | Post observed | Best baseline |
| --- | ---: | ---: |
| Parents with 99 units | 11.94% | 12.59% |
| Exactly two filings | 13.23% | 4.43% |
| Three or more filings | 3.55% | 12.28% |
| Parents organized as 99+99 | 2.90% | 0.19% |
| Mean proposed parent units | 136.58 | 149.89 |

The model implies 495 fewer units, including 487 among parents with
counterfactual sizes of 50–250. Allowing reorganization preserves 92 units
relative to holding historical constituent counts fixed. These are conditional
on the observed number of parents; entry, timing, and completed housing are
outside the model. The direct weighted-historical-minus-post difference is
4,620 units, including 4,263 in the 301+ bin. That distribution difference is
not an identified policy effect.

## Reproduction and inputs

Run `make pure-notch-pilot` from the repository root. Task-local `make` uses
prepared inputs. The current runtime is R 4.5.2 and GNU Make 3.81.

The two canonical panels in `build_estimation_panels/output/` supply parent
totals and additive constituents. Select
`included_ab & parent_total_units >= 50 & composition_eligible`: 2019–2022
versus January 1, 2025–July 8, 2026. Counts use unfiltered HDB Class A units,
including recorded zero, with DOB fallback when the HDB count is missing.
The model script reconstructs all parent totals and constituent counts from
the filing panel before fitting.

`audit_scale_shape_splitting/output/calibration_weights.csv` supplies positive
historical weights balancing log lot area, residential FAR, built FAR, and
borough. Historical weights are normalized to sum to one; post parents each
receive weight `1/310`. Effective historical sample size is 492.7. Multi-lot
status is absent from the adopted weighting formula. The separate multi-lot
sensitivity recalibrates that additional moment on the same sample.

Each historical parent supplies ordinary preferred total `x`, constituent
count `J0`, and its vector. The observed parent footprint is treated as given.
The current pilot allows `J = 1,...,6` for every parent, with a seven-choice
sensitivity; parcel counts do not constrain the menu.

## Model and fit

At `lambda = 1`, ordinary size loss is `((m-x)/99)^2`. Each separately assessed
constituent pays `kappa` at 100 or more units. Positive integer constituent
sizes and unrestricted layouts make the minimum burden zero when `m <= 99*J`
and `kappa` otherwise. A parent above that capacity compares shrinking to it
against retaining `x` and paying the charge. The solver also handles `x < J`.
There is no upper numerical size cap or choice restriction at the sample's
50-unit minimum.

Historical organization has zero ordinary disadvantage. Every other `J` has
an independent exponential disadvantage of mean `sigma_org`, constant across
its size/layout choices. Organization probabilities are integrated analytically.
Size solutions are cached across organization-cost scales. Ties retain size
closest to `x`, then the smaller total. Historical vectors are retained when
optimal; other minimizing layouts get representative vectors and uniqueness
flags. Those representatives do not identify an otherwise ambiguous layout.

The objective is the unweighted sum of squared share errors over 45 disjoint
cells: three organization groups (`J=1`, `J=2`, `J>=3`) crossed with:

`under 50; 50–89; 90–94; 95–98; 99; 100–104; 105–119; 120–149; 150–179; 180–197; 198; 199; 200–249; 250–300; 301+`.

The baseline search has 572 parameter combinations; joint assessment,
`lambda=.5`, `lambda=2`, and the seven-choice menu each have 180. Mean units,
exact constituent counts above two, and exact within-bin sizes are diagnostics.
The baseline objective is 0.006312. Joint assessment has objective 0.010947,
leaves historical organization unchanged, and does not identify an organization
cost. These are mechanical single-100 schedules; geographic 150-unit rules and
verified legal assessment units require further modeling.

Once enough filings make the project exempt, additional feasible filing counts
have the same policy cost. Independent organization draws of the same scale
therefore spread choices over large `J`. This helps explain the excess predicted
three-plus parents and shortage of pairs. Increasing costs per added filing and
linear/quadratic growing burdens remain the planned specification comparisons;
this rerun changes the administrative data, not the model.

## Outputs and checks

All products are in `output/`; SaveData reports and console logs are side effects.

- `analysis_parents.csv` and `input_provenance.csv`: observations, normalized
  weights, dates, flags, and input fingerprints.
- `best_fits.csv`, `fit_diagnostics.csv`, `parameter_grid.csv`, and
  `joint_cell_predictions.csv`: fitted parameters, diagnostic moments, and cells.
- `best_parent_contributions.parquet`: each historical parent's choice masses,
  representative vectors, and tie flags.
- `fit_overview.png` and `parameter_profiles.png` (also in `pdf/`): model fit
  and objective profiles. Shares include the upper tail in their denominator.
- `multilot_*`: the alternative calibration and its model/distribution comparison.
- `unit_gap_by_size.csv` and its figure: weighted historical counts and units,
  scaled to the post count, minus post observations within each size bin.
- `local_unit_effects.csv`: `310 * sum(mass * (x-m))` by counterfactual size.
  The 250 cutoff is an exploratory reporting boundary, not an identified limit.
- `bunching_unit_illustration.csv`: a separate uniform-origin illustration,
  distinct from a fitted estimate or bound.
- `tail_count_uncertainty.csv` and `historical_tail_by_year.csv`: distribution
  comparisons, without policy attribution. The bootstrap recalibrates weights
  within successful resamples; it does not incorporate linkage uncertainty.
- `numerical_checks.csv`, `synthetic_recovery.csv`, and
  `near_notch_sensitivity.csv`: exhaustive size/partition checks, analytic versus
  simulated probabilities, synthetic recovery, and leave-one-out sensitivity.
- `pilot_values.tex`: numerical text for the logbook.

Structural parameter uncertainty with estimated counterfactual weights remains
to be assessed. Economic parent links do not establish legal wage-assessment
units, and land corrections remain in the parcel audit until adopted coherently.

## Inspecting all eleven post parents with three or more filings

Ten of these eleven parents have every constituent below 100 units. Five contain
at least two exact 99s: Third Avenue (99+99+99), Bruckner/Brook/East 132nd
(99+99+99), Wyckoff/Bergen (99+99+99+70), Sullivan/Empire (99+99+99+99),
and 165th Street (99+99+99+99+99+96). Their totals are 297, 297, 367, 396,
and 591. The seven historical parents with at least three filings contain no
exact 99-unit constituents. These are small samples, but the observed post
organization patterns warrant retaining information about larger parents.

The full eleven-parent list is produced by `decompose_unit_gap.R` from the
saved pilot sample. Its vectors and totals match 38 unique additive filings
in the canonical constituent panel. The five repeated-99 parents all exceed
249 units; three remain above 300 despite having every constituent below 100.
Thus a 50–249-only objective would omit several conspicuous splitting patterns,
and a 50–300-only objective would still omit the quadruple and six-filing cases.
The recommendation is to retain these organization patterns when designing
a local fit. No fitting-window or model change has been adopted here.

These counts describe the pilot's mechanical threshold. They do not verify
legal exemption or identify units lost relative to each site's counterfactual.
The saved classification marks Wyckoff/Bergen as verified separate 485-x units,
Third Avenue, Bruckner, and Sullivan/Empire as suggestive, and 165th Street as
unable to verify. Existing administrative units and link decisions are retained.
The patterns support investigating policy-related splitting beyond 198; neither
their presence nor their absence would establish how much of the 301+ shortfall
is compression versus a change in the project mix.


The September 22 Jamaica correction adopts 39,349.5 square feet of residential
ground and 40,342.49 of flagged earlier floor, using six contributing old
parcels. The stack-parcel audit keeps the automatic filing matches and the
eight-parcel associated source extent as comparisons. Its equality check
against production applies to automatic sites; `site_feature_method` identifies
reviewed allocations. The recorded housing/MTA boundary does not establish a
separate legal wage assessment for each building.

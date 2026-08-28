# Research Understanding Checklist

## Session Goal

- [x] Research question: construct a model-based no-notch distribution for the
  fixed set of observed 2025 parent opportunities.
- [x] Initial scope: start with the strict invariant tail at 99 units.
- [x] Excluded initially: entry, non-filing, and splitting responses.
- [x] Transformation rule: do not use `log1p` or related zero-handling hacks.

## Stage 1: Why Transport Historical Projects?

- [x] A raw historical histogram may be a poor 2025 counterfactual when the
  historical and 2025 sites differ in predetermined development capacity.
- [x] Larger lots or greater zoning capacity can support larger buildings even
  without the 485-x notch.
- [x] Researcher restatement: using the raw historical distribution would be
  wrong if 2025 sites could accommodate larger buildings by default.
- [x] Understand how calibration weights change the historical comparison.
- [x] Historical site types that are underrepresented relative to the 2025
  target receive more weight; overrepresented types receive less weight.
- [x] Weights reflect target-site composition, not whether a historical
  project's observed unit count supports the desired result.
- [x] Unit count is an endogenous policy response; predetermined lot and
  zoning characteristics can define comparability without conditioning the
  weights on that response.
- [x] Researcher restatement: the exact unit count is the policy-sensitive
  decision margin, while membership in the 99-or-more tail is invariant under
  the maintained pure-notch model.
- [ ] Understand the identifying assumption that weighting cannot verify.
- [x] Mastery status: weighting intuition mastered; exact construction will be
  reviewed after the samples are audited.

## Stage 2: Data Provenance And Sample Construction

- [x] Understand the historical source: the current preferred experiment still
  uses fully observed 2017--2022 symmetric parent cohorts, and 2019--2022
  remains a benchmark. The parent-link build is being extended separately to
  2010 so that 2011 can be the first fully padded diagnostic cohort.
- [x] Earlier-window boundary: the raw leakage-safe feature panel contains
  eligible projects back to 2010. A 2010 linkage year supplies the left-side
  padding for 2011 parents; 2010 itself is not a complete cohort.
- [x] Older-linkage repair: official archived MapPLUTO geometry exists for the
  2009--2017 releases. The prior fetch step omitted those legacy borough
  bundles. They have now been restored and the production adjacency reader has
  been generalized to their older archive layouts.
- [x] Older-geometry caveat: GDAL autocorrects malformed ring ordering in the
  Queens shapefiles for 16v1, 16v2, 17v1, and 17v1.1. Selected filing lots pass
  post-read BBL-uniqueness and geometry-validity checks, but adjacency-supported
  links still require year-by-year and case-level audit.
- [x] Understand the target source: all usable 2025 symmetric parent cohorts
  with a complete pre-filing linkage window and at least 180 observed follow-up
  days; the realized minimum is 190 days.
- [x] Scope decision: retain the full 102-parent post-policy tail as the primary
  sample to maximize sample size.
- [x] Robustness decision: use the complete 365-day parent-linkage window as a
  later sensitivity rather than the primary restriction.
- [x] Unit of observation: one symmetric parent development opportunity,
  potentially composed of several linked filings.
- [x] Researcher restatement: two 99-unit filings should contribute one
  198-unit parent observation when they are components of the same development,
  rather than two observations at the notch.
- [x] Primary invariant-tail rule: observed or historical HDB-priority units
  are at least 99.
- [x] Linkage universe extended and verified: fully padded diagnostic cohorts
  now run from 2011 through 2022. The still-preferred 2017--2022 sample contains
  468 historical and 102 post-policy parents in the strict 99-or-more model sample;
  2017 and 2018 contribute 57 and 60 tail parents, respectively.
- [x] Potential sample gain: the common-specification comparison adds 302 usable
  99-or-more parents in 2011--2016, increasing the diagnostic 2011--2022 tail
  sample to 770 parents.
- [x] Legacy-geometry impact: restoring exact parcel adjacency raises the
  multi-filing-parent share from 0.6 to 3.6 percent in 2017 and from 0.8 to 2.8
  percent in 2018, bringing them into the broad 1.5--4.9 percent range observed
  across fully padded 2011--2022 cohorts.
- [x] Geometry-withholding audit: removing every adjacency-only edge changes
  the number of 99-or-more parents by no more than two in any cohort. It changes
  exact-99 mass for one of the 123 geometry-dependent parents: the confirmed
  35-plus-64-unit Fabric Astoria development. This is a
  sensitivity to the evidence channel, not a direct estimate of linkage error.
- [x] Tail-relevant case review: all 14 parents exposed by the repaired geometry
  were checked against project or permit evidence and retained. The audit now
  validates these decisions against every rebuild. Three separate mechanical
  false-positive edges were rejected and one missed Broadway Triangle edge was
  added through explicit reviewed overrides.
- [x] No future geometry borrowing: 57 filings assigned to MapPLUTO 18v1 lack
  polygon geometry because DCP did not publish that exact geometry vintage; the
  build does not substitute the later 18v1.1 release.
- [x] Identifier and required-covariate QC passed with no duplicate parent
  observations, no missing required covariates, and no below-cutoff rows.
- [x] Zeros were retained as levels plus separate zero indicators: historical
  capacity/slack zeros are 56/64; post-policy zeros are 5/9.
- [x] Every 2025 borough, prior-use, and zoning category appears historically;
  no post-only categorical support failure was found.
- [ ] Mastery status: implementation complete; researcher review pending.

## Stage 3: Positive Calibration Weights

- [x] Method: positive exponential calibration using
  `survey::calibrate(..., calfun = "raking")`.
- [x] The historical weights sum to the 102 post-policy parents.
- [x] The exact unit count is absent from the calibration formula.
- [x] Balance variables: log lot area; capacity and redevelopment slack in
  levels; residential and built FAR; multi-lot status; zero-capacity and
  zero-slack indicators; and existing borough, zoning, and prior-use groups.
- [x] All 29 balance-matrix columns are linearly independent, and all requested
  target totals are matched to numerical tolerance with strictly positive
  weights.
- [x] Updated preferred-specification weight diagnostics after reviewed linkage:
  effective sample size 166.2; maximum weight 2.88; largest 1/5/10 percent of
  historical parents carry 10.2/28.8/40.3 percent of total weight.
- [ ] Understand what the effective sample size and concentration diagnostics
  say about overlap.
- [ ] Mastery status: implementation complete; researcher review pending.

## Stage 4: Weighted No-Notch Point Estimate

- [x] Both observed and weighted no-notch c=99 distributions sum to 102 parent
  opportunities.
- [x] Observed mass at 99 is 22; updated weighted no-notch mass is 4.44;
  estimated excess mass is 17.56 parents. The confirmed 99-unit Fabric Astoria
  parent alone receives weight 2.88 and explains most of the revision.
- [x] The c=99 accounting identity holds: the estimated 17.56 excess at 99
  equals the total weighted no-notch deficit at 100 or more.
- [x] Structural allocation: counterfactual mass beginning at 100 reaches the
  99-unit excess after allocating 9.6 percent of the weighted mass at 120;
  the affected-project no-notch mean is 108.1 units.
- [x] Model-fit diagnostic: observed cumulative missing mass through 149 never
  reaches the 17.56 excess; it peaks at 17.54 and ends at 15.02. The remaining
  total deficit comes from the pooled 150+ category.
- [ ] Understand why the structural allocation frontier and observed
  missing-mass path answer different questions.
- [x] Researcher restatement: if a bin has counterfactual mass 2 and observed
  mass 3, its contribution to cumulative missing mass is `2 - 3 = -1`, even
  though cumulative counterfactual mass rises by 2.
- [x] Terminology correction: `A(m)` is cumulative counterfactual mass
  available between 100 and `m`, not cumulative empirically observed missing
  mass or an allocation that continues after the frontier is reached. The plot
  now labels this quantity directly rather than calling it an allocation.
- [x] Understand the blue line: it sums calibrated weights on historical
  parents with actual untreated counts from 100 through `m`; it is not a
  parent-specific unit-count regression for the 2025 sample.
- [x] Understand the orange line: it subtracts cumulative observed 2025 mass
  from cumulative no-notch mass and can fall when an exact count contains more
  observed than counterfactual projects.
- [x] Extended diagnostic: the unpooled cumulative deficit first crosses the
  20.38 excess at 154, driven by 5.59 weighted counterfactual projects at 154
  and no observed projects there. This lies beyond the clean primary range and
  is not used to set the structural frontier.
- [ ] Mastery status: point estimate complete; interpretation pending.

## Stage 5: Exact Parent-Unit Distribution Plot

- [x] Researcher instruction: the horizontal axis is total proposed units in
  the linked parent development, not average units across component filings.
- [x] Historical window: complete 2011--2022 parent cohorts. This is 12
  inclusive calendar years, despite the initial shorthand of an 11-year period.
- [x] Post window: January 1, 2025 through the DOB source end date of July 8,
  2026. Three left-boundary-exposed parents are excluded.
- [x] Exact-bin sample: 331 historical and 110 provisional post-period parents
  have 80--120 total proposed units. Exact 99 counts are 12 and 41.
- [x] Total plot: raw parent counts over unequal observation windows.
- [x] Annualized plot: historical counts divided by 12 and post counts divided
  by 554 observed days / 365.25 = 1.517 years.
- [x] Provisional-parent warning: later 2026 filings can still join current
  post-period parents, so the post histogram can change in future refreshes.
- [x] Post-99 support audit: 100--104 contain zero observations in the plotted
  parent sample, all parents including boundary-exposed cases, raw initial DOB
  NOW filings, and latest available filing versions. The next occupied
  parent-level bin is 105 with three single-filing projects.
- [x] Claim scope: this is established for proposals initially filed from
  January 1, 2025 through the July 8, 2026 source end date. It is not an
  immutable statement about later filings or final completed-unit counts.
- [ ] Mastery status: figures complete; researcher interpretation pending.

## Stage 6: Tenure And 485-x Status Of The Three 105-Unit Cases

- [x] Researcher hypothesis: an ordinary private rental project choosing
  485-x should have a strong incentive not to locate just above 99 units.
- [x] DOB filings alone do not identify whether a proposed building is rental,
  condominium, publicly financed affordable housing, or ultimately registered
  for 485-x.
- [x] The HPD prospective-registration file contains submissions through March
  31, 2026. It contains no registration with 100 or more reported units and no
  address or block match to any of the three 105-unit filings.
- [x] Registration absence is not yet dispositive: 485-x registration is tied
  to construction commencement rather than the DOB proposal date, and none of
  the three had a foundation permit in the July 2026 source extract.
- [x] 45-40 Pearson Street is privately developed by ZD Jasper, whose own
  portfolio classifies the project as a condominium; current market sources
  report 105 units. Current best classification: likely not a 485-x rental
  project, but not yet established by an offering plan or final HPD record.
- [x] 53-05 Beach Channel Drive is a NYCHA-sponsored, 100-percent affordable
  senior project awaiting financial closing. It is not an ordinary market-rate
  rental opportunity responding only to the 485-x notch; its eventual tax-
  benefit stack is not yet established in the public records reviewed.
- [x] 118 Tenth Avenue is a Toll Brothers City Living development and current
  project-market sources describe it as condominium development. Current best
  classification: likely not 485-x; a Manhattan homeownership project is not
  eligible for Option D, but final tenure documentation is not yet public.
- [x] Legal refinement: condominium and cooperative projects outside Manhattan
  can qualify for 485-x under Option D. They do not face the Option B-to-A
  affordability change at 100 units, but an eligible site with at least 100
  units is still subject to the 485-x construction-wage rule unless a statutory
  labor-agreement exclusion applies.
- [x] Public-affordable refinement: government grants, loans, and subsidies do
  not categorically bar 485-x. The statute anticipates subsidized applications
  but prohibits combining 485-x with another property-tax exemption or
  abatement. NYCHA-owned property that remains tax-exempt ordinarily has no
  property-tax liability for 485-x to reduce, while a disposition to a private
  entity can create a different tax-program choice.
- [x] Labor refinement: public or subsidized construction can already face
  prevailing-wage requirements, but coverage depends on ownership, funding,
  and contracting. This is not a reliable stand-alone exclusion rule.
- [x] Sample decision: use plausible taxable Option A/B rental opportunities as
  the main mechanism sample, classified symmetrically in both periods; examine
  A/B plus eligible outer-borough Option D opportunities separately.
- [x] Mastery status: case interpretation reviewed and sample scope chosen.

## Stage 7: Proposed Economic-Exposure Sample

- [x] Researcher concern: projects not exposed to the Option B-to-A rental
  choice can add observed mass above 99 and mechanically attenuate estimated
  missing mass. Applying exclusions only above 99 would be outcome-selective;
  the same classification must be applied at 99 and throughout both periods.
- [x] `Private development` is too broad for the rental-notch estimand because
  it includes condominium projects, and `public development` is too broad an
  exclusion because private and nonprofit subsidized rentals can use 485-x.
- [x] Recommended mechanism sample: taxable rental development opportunities
  that could plausibly choose Option A or B. Exclude confirmed condo/co-op
  projects, hotels, property that remains government-owned and tax-exempt, and
  projects established to use a mutually exclusive property-tax exemption.
- [x] Keep private or nonprofit subsidized rentals when their tax status leaves
  485-x available; subsidy alone is not an exclusion.
- [x] Do not use 485-x registration as the sole sample rule. Registration is
  filed after construction commencement, whereas the outcome is proposed units
  at filing. Restricting to eventual registrants would condition on a later
  implementation outcome and omit projects that never commence.
- [x] Use HPD registration as positive validation with case-level QC. The
  current public file is incomplete for recently proposed projects and contains
  apparent option/unit inconsistencies and duplicate project registrations.
- [x] Classify parents symmetrically using a documented evidence hierarchy:
  official HPD registration or financing records; government ownership and tax
  status; Attorney General offering-plan records; then developer/project
  documentation. Preserve unresolved cases with source, date, reason, and
  confidence rather than silently forcing a classification.
- [x] Keep a broad taxable-multifamily sample as a sensitivity because realized
  rental-versus-condo tenure may itself respond to the policy. A confirmed-only
  rental sample and transparent unresolved-case bounds can show how much the
  result depends on tenure classification.
- [x] Eligible-site grouping remains essential: one 485-x application may span
  multiple buildings or tax lots, so registration evidence must validate parent
  links rather than be joined one registration row to one DOB filing.
- [x] Researcher decision: the primary descriptive sample is the Option A/B
  rental opportunity sample; A/B plus Option D is a separate specification.
- [x] Mastery status: legal and measurement distinctions taught; first sample
  definitions approved.

## Stage 8: Implemented Exposure Classification And Descriptive Results

- [x] Every one of the 1,187 parent observations from 50 through 150 units has
  exactly one categorical status: `exposed_ab`, `exposed_option_d`,
  `not_exposed`, or `unresolved`, plus a reason, evidence source, review date,
  and confidence level.
- [x] Official NY Attorney General offering-plan searches were run for all 1,230
  component filings. Exact-address new-construction offering plans and CPS-1
  applications inform homeownership status. No-action letters are retained as
  financing-condominium evidence but do not by themselves establish that the
  residential units are for sale.
- [x] The expanded classification yields 815 historical and 243 post-policy
  A/B opportunities; adding Option D yields 849 and 244. The remaining parents
  are retained as 32 not exposed and 62 unresolved, not silently deleted from
  the audit data.
- [x] Evidence-strength limitation: 1,030 of the 1,058 A/B classifications are
  medium-confidence defaults based on a multifamily proposal with no contrary
  tenure or tax evidence. Direct HPD A/B registration validates 28 cases. This
  classification is a plausible opportunity screen, not observed 485-x take-up.
- [x] The three post-policy 105-unit parents separate as intended: Pearson
  Street is `exposed_option_d`; 118 Tenth Avenue is `not_exposed`; Beach Channel
  Drive is `unresolved`. The A/B sample therefore has zero post-policy parents
  from 100 through 105; the A/B-plus-D sample has one parent at 105.
- [x] New total and annualized one-unit-bin figures show both exposure samples
  while preserving the all-project figures as an audit benchmark.
- [x] Understand why excluding unresolved observations is transparent sample
  restriction rather than evidence that those observations are not exposed.
- [ ] Next implementation gate: extend the approved status system beyond 150
  units before recomputing a fully exposure-classified 99-or-more counterfactual.
- [x] Mastery status: classification edge-case logic mastered; full-tail
  extension remains the next implementation gate.

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-08-26 | Stage 8 exposure edge cases | Open-ended | Corrected and mastered | None |

## Stage 9: Full-Support And 50--150 Distribution Views

- [x] Full-support figures use all linked parents: 5,317 historical parents
  from 6 to 1,754 units and 913 post-policy parents from 6 to 1,060 units.
- [x] The full-support histogram uses 25-unit bins because one-unit bars are not
  readable over nearly 1,750 units; the full-support line retains exact
  one-unit counts.
- [x] Full-support figures are broad descriptive benchmarks, not exposure-
  restricted estimates. The classification has not been extended outside
  50--150 units.
- [x] The 50--150 histogram and line figures use exact one-unit bins and show
  both A/B-only and A/B-plus-Option-D samples.
- [x] Both total-count and annualized versions are produced. Annualization is
  necessary for rate comparisons because the pre period spans 12 years and the
  current post period spans 554 days.
- [x] Verified annualization: historical counts are divided by 12 and
  post-policy counts by 554/365.25 = 1.517 years. At 99 units in the A/B sample,
  the post-period value is 40/1.517 = 26.37 parents per year.
- [x] Understand why the total-count and annualized plots can look different
  without either being incorrectly calculated.
- [x] Mastery status: denominator distinction identified and corrected in the
  figure labels.

## Stage 10: Is Post-Policy Development Higher Throughout The Range?

- [x] It is not literally higher at every exact count below 99. In the A/B
  sample, the post annualized rate is higher in 41 of the 49 exact bins from
  50--98 and lower in eight.
- [x] Aggregated A/B counts from 50--98 are 568 historical and 171 post-policy,
  or 47.3 versus 112.7 parents per year after dividing by 12 and 1.517 years.
- [x] The broad all-parent 50--98 comparison is similar: 54.1 versus 116.0
  parents per year.
- [x] A/B counts from 100--149 are 233 historical and 32 post-policy, or 19.4
  versus 21.1 parents per year. Broad all-parent rates are 22.3 versus 23.7.
  Thus the aggregate annual rate above 99 is only slightly higher post-policy,
  unlike the large increase below 99.
- [x] The historical average masks trend: A/B 50--98 counts rose from 18 in
  2011 to 72 in 2022; the 2025 count is 98 and the partial 2026 count is 73.
  A/B 100--149 reached 36 in 2022, compared with 22 in 2025 and 10 through the
  current 2026 source end date.
- [ ] Interpretation gate: distinguish a descriptive post-period construction
  surge from a causal 485-x entry response or a source/composition difference.

## Stage 11: Does A Normal-Period Benchmark Reveal Missing Mass Above 99?

- [x] Treat “project mass” as the annual number of linked parent developments,
  not the sum of proposed units, and decompose the broad sample into 100--149
  and 150-plus parents.
- [x] Use 2017--2019 as the cleanest descriptive Affordable New York,
  pre-pandemic benchmark, while also reporting 2014--2019, 2017--2021, and
  2019--2021 so the benchmark is not selected after seeing the answer.
- [x] The broad post-policy rate at 100-plus is 138 / 1.517 = 91.0 parents per
  year. This exceeds 66.0 in 2017--2019, 66.7 in 2014--2019, 72.0 in
  2017--2021, and 81.3 in 2019--2021.
- [x] The apparent contradiction is resolved by the tail decomposition. The
  post-policy 100--149 rate is 23.7 per year, slightly below the 24.3--25.7
  rates in the main normal-period comparisons, but the 150-plus rate rises to
  67.2 from about 41--56 and more than offsets that decline.
- [x] The A/B-classified 100--149 sample gives the same local pattern: 21.1
  post-policy parents per year versus 21.3 in 2017--2019 and 22.0 in both
  2014--2019 and 2019--2021.
- [x] The 2022 cohort should not define normal conditions: the 421-a
  construction-commencement deadline was June 15, 2022 and official reporting
  documents a large pre-deadline permitting surge. A DOB filing date is also
  not the statutory construction-commencement date.
- [ ] Extend the exposure classification above 150 before interpreting the
  broad 150-plus increase as a change among 485-x-eligible rental projects.
- [x] Mastery check: a large spike at 99 can coexist with a higher observed
  count of 100-plus projects when the post period contains many more large
  developments; those inframarginal projects can raise the total above 99 even
  while marginal projects move to 99.

## Stage 12: Full Exposure Universe And The 150-Unit Threshold

- [x] Scope decision: extend the exposure ledger from 50--150 units to every
  linked parent with at least six units in the 2011--2022 historical and
  2025--2026 post-policy analysis windows.
- [x] Six units is the statutory minimum for Options B and D; a 6--10-unit
  rental project may also qualify for Option C outside Manhattan.
- [x] At 150 units, Option A affordability deepens from an 80% to a 60% AMI
  average. Zone A/B projects also face higher construction-wage schedules,
  and very large projects in those zones receive a forty-year benefit.
- [x] The expanded universe contains 6,230 parents and 6,601 component
  filings: 5,317 historical parents and 913 post-policy parents.
- [x] Data-quality rule: a parent cannot default to `exposed_ab` unless every
  component received a successful Attorney General homeownership screen;
  incomplete screens remain `unresolved`.
- [x] The linked economic parent and the statutory eligible site are distinct
  objects. Four post-policy 150-plus parents contain components registered by
  HPD under Option B, including 99+99 and 99+99+70 configurations. Preserve
  both levels rather than inferring Option A from the parent total.
- [x] Complete the full-universe Attorney General screen and rebuild final
  exposure statuses. All 6,601 component addresses returned successful search
  responses. The 6,230 parents classify as 5,360 `exposed_ab`, 573
  `exposed_option_d`, 110 `not_exposed`, and 187 `unresolved`.
- [x] The linked-parent 150-plus increase remains in the A/B sample: 33.7
  parents per year in 2017--2019 versus 61.3 in the post period. It is not a
  local pile-up at 150: post-period A/B counts at 150, 151, and 152 are all
  zero.
- [x] The increase is an aggregation phenomenon rather than a comparable rise
  in genuinely 150-plus filings. A/B component filings at 150-plus rise only
  from 34.0 to 38.9 per year, while A/B linked parents rise from 33.7 to 61.3.
  A/B single-filing parents at 150-plus are essentially flat at 30.3 per year
  in both periods; multi-filing parents rise from 3.3 to 31.0 per year.
- [x] Geography does not support the higher Zone A/B wage tier as the main
  direct explanation: 73 of the 93 post-period A/B parents totaling 150-plus
  are outside Zones A/B, and only 16 are wholly in Zone A or B.
- [x] The broad increase is not driven by government projects. Government
  150-plus parents fall from 6.7 to 5.3 per year; private-or-other parents rise
  from 29.7 to 53.4 and nonprofit parents from 5.3 to 7.9.
- [x] Among all 47 post-period multi-filing parents totaling 150-plus, 40 have
  no component filing at 150-plus and 24 contain an exact-99 component. This
  is consistent with a changed filing/linkage composition and potentially
  splitting, but does not alone establish a causal splitting response.
- [ ] Mastery check: explain why parent total units cannot automatically be
  treated as the unit count governing the project's registered 485-x option.

## Stage 13: Consistent 2023--2024 Timing Diagnostic

- [x] Rebuild 2023 and 2024 under the same recent-parent construction used for
  2025--2026. DOB NOW filings now begin in 2022 as linkage padding; 2023 and
  2024 both have complete symmetric 365-day windows.
- [x] The recent comparison cohorts use the same link evidence, fixed 23v3.1
  parcel geometry, HDB-priority/DOB fallback unit rule, and full A/B exposure
  classifier. They contain 226 parents in 2023 and 262 in 2024.
- [x] In the A/B rental-opportunity sample, multi-filing shares among parents
  totaling at least 150 units are 11.1 percent in 2023, 13.6 percent in 2024,
  48.3 percent in 2025, and 52.9 percent in partial 2026.
- [x] The corresponding multi-filing shares among all 6-plus A/B parents are
  only 6.8, 6.5, 10.4, and 7.5 percent. The 150-plus break therefore is not a
  generic increase in the linkage algorithm's propensity to combine filings.
- [x] No 2023 multi-filing 150-plus parent contains a 99-unit component. In
  2024, two of the three such parents were filed after 485-x enactment and are
  exactly 99+99 and 99+99+99. The pattern then expands to 16 such parents in
  2025 and eight in partial 2026.
- [x] Interpretation: the timing, threshold specificity, common DOB source,
  and actual Option B registrations make a 485-x-induced eligible-site
  splitting response a serious leading explanation. This remains suggestive,
  not a causal estimate, because development composition and other changes may
  coincide with enactment and the statutory eligible site is not fully observed.
- [ ] Mastery check: distinguish the evidence that makes the splitting story
  persuasive from the additional variation needed to call it causal.
- [x] Initial researcher restatement: distinction not yet known; teaching
  separates the observed policy-timed, threshold-specific pattern from the
  unobserved no-485-x counterfactual needed for a causal estimate.

## Open Questions

- [x] Historical-window extension: 2019--2022 was inherited from the existing
  preferred estimator, not required by the notch model. The linkage universe
  now begins in 2010 and supports fully padded 2011--2022 diagnostic cohorts.
  The reviewed common-specification comparison now covers 2011--2022,
  2014--2022, 2017--2022, and 2019--2022.
- [x] Case-review gate: repaired pre-filing geometry expanded the relevant set
  from the preliminary 10 to 14 parents. All 14 are documented and validated;
  weak non-tail edges remain a later audit layer.
- [ ] Decide which pre-2017 cohorts, if any, belong in the primary historical
  counterfactual after the 2010--2016 linkage audit.
- [ ] Which predetermined site characteristics should define comparability?
- [ ] Does the weighted historical sample have adequate overlap with 2025?
- [ ] Should the first implementation use entropy balancing or a simpler
  transparent benchmark?
- [x] Equal-weight descriptive benchmark checked for the expanded window:
  normalizing every historical parent to weight `102 / 469` gives 20.48 excess
  parents at 99, a partial-122 structural frontier (continuous value 122.83),
  and an affected-project mean of 110.74 units. The main bunching estimate is
  close to the calibrated result, but cumulative missing mass through 149 is
  smaller (13.58 rather than 15.15).

## Stage 14: Candidate Causal Comparison Design

- [x] Researcher restatement: proposed sites outside Zone A/B as the possible
  comparison group.
- [x] Correction: outside-Zone-A/B rental opportunities are not untreated at
  100 units. They still face the 6--99 versus 100-plus 485-x distinction;
  Zone A/B is useful as policy-intensity heterogeneity, especially around the
  additional 150-unit rules, rather than as the primary untreated comparison.
- [ ] Define ex ante exposure to crossing 100 using only predetermined lot,
  zoning, location, prior-use, ownership, and tax characteristics.
- [ ] Select the primary estimand: post-policy effect for sites with high
  predicted no-policy probability of reaching 100, or a continuous effect by
  predicted crossing probability.
- [ ] Establish common support and pre-trends before estimating a
  post-by-predicted-exposure contrast.
- [ ] Keep predetermined ineligible sites and non-99 thresholds as placebo or
  validation groups unless their comparability can be defended.
- [ ] Mastery check: explain why Zone A/B can reveal heterogeneous treatment
  intensity but does not provide an untreated group at the 100-unit threshold.

## Stage 15: Difference-In-Bunching Versus Exposure Event Study

- [x] Researcher restatement: earlier matched land-price event studies were
  noisy and depended on an exposure score that was difficult to predict; the
  preferred direction is a before/after comparison at the 100-unit threshold.
- [x] Design distinction: because proposed units are themselves manipulated,
  this is not a conventional regression discontinuity with an as-good-as-random
  running variable. The appropriate object is the post-policy change in excess
  density at 99 and missing density above 99 relative to the pre-policy unit
  distribution.
- [ ] Define the main normalization and exact local window before estimating
  the change in density.
- [ ] Separate parent-level downsizing from component-level exact-99 splitting.
- [ ] Treat the 2011--2022 historical comparison as the high-power baseline and
  the consistently constructed 2023--pre-enactment-2024 cohort as a lower-power
  same-source validation.
- [ ] Test pseudo thresholds, pseudo enactment dates, historical-year stability,
  linkage definitions, and sample classifications.
- [ ] Mastery check: explain why this design can identify a distributional
  response at 99 without identifying capitalization into land prices or entry.

## Stage 16: Absolute Tail Mass Versus Distributional Contraction

- [x] Researcher restatement: the annualized post line lies above much of the
  2011--2022 average even beyond 100 and 200, raising concern that early
  post-recession years depress the historical benchmark and conflict with a
  burdensome-notch interpretation.
- [x] The concern is valid for levels: the 2011--2014 and 2015--2018 A/B tails
  are much smaller than the later historical tail, so the full-period annual
  average is not a clean normal-market level benchmark.
- [x] Relative to 2019--2022, annual A/B mass at 50-plus rises from 141.0 to
  222.6, while 100-plus mass moves only from 78.5 to 83.1 and 199-plus mass is
  essentially unchanged at 36.2 versus 36.3.
- [x] Conditional on an observed A/B parent with at least 50 units, the
  100-plus share falls from 55.6 to 37.3 percent and the 199-plus share falls
  from 25.7 to 16.3 percent; exact 99 rises from 1.2 to 11.8 percent.
- [x] Parent mass at 198 is not evidence against avoidance: all ten post-period
  198-unit parents are linked 99+99 configurations, so economic-parent mass can
  remain above 100 while the component eligible sites avoid it.
- [ ] Main design implication: compare normalized local densities and mass
  balance, with late-pre and full-history windows shown separately; do not
  interpret raw annual count differences as the notch effect.
- [ ] Mastery check: explain how a 58-percent expansion in all 50-plus filings
  can leave absolute 100-plus mass flat while sharply reducing its share.

## Quiz Log

| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-08-25 | Why transport? | Open-ended | Correct | Teach weighting mechanics |
| 2026-08-25 | Weighting intuition | Open-ended | Correct with refinement | Distinguish representation from outcome prediction |
| 2026-08-25 | Endogenous outcome | Open-ended | Correct | Build and audit c=99 samples |
| 2026-08-25 | Tail invariance | Open-ended | Mastered | Review data provenance and parent construction |
| 2026-08-25 | Unit of observation | Open-ended | Mastered with terminology refinement | Review sample-window choices |
| 2026-08-25 | Post-policy follow-up | Researcher decision | Retain all 102 parents | Add 365-day sensitivity later |
| 2026-08-25 | Cumulative line arithmetic | Open-ended | Mastered | Explain weighted empirical histogram construction |
| 2026-08-26 | 105-unit 485-x status | Researcher hypothesis | Economically plausible with scope caveat | Separate private rentals from condo and public-affordable projects |
| 2026-08-26 | Exposure-sample definition | Researcher hypothesis | Correct attenuation concern; private/public rule needs refinement | Choose rental-notch estimand and apply symmetric classification |
| 2026-08-26 | 99 spike versus 100-plus mass | Open-ended | Mastered | Extend exposure coding to the full 6-plus universe and study the 150-unit threshold |
| 2026-08-26 | Persuasive versus causal splitting evidence | Open-ended | Not yet known; explanation provided | Restate the missing no-485-x counterfactual before choosing a design |
| 2026-08-26 | Candidate comparison geography | Open-ended | Reasonable intuition; corrected statutory scope | Distinguish untreated status from stronger policy intensity |
| 2026-08-27 | Exposure event study versus threshold design | Researcher decision | Prefers threshold design because exposure prediction and land-price estimates were noisy | Formalize a difference-in-bunching estimand and assumptions |
| 2026-08-27 | Tail levels versus bunching | Researcher concern | Valid level-comparison concern; relative tail contraction confirmed | Separate market scale from the normalized distributional response |

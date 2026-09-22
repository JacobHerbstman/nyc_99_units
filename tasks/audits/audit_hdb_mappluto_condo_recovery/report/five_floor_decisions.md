# Five adopted earlier-floor allocations

All five corrections are applied following Jacob's September 21–22 approvals,
with `built_floor_area_estimated = TRUE`. Their assumptions are stated below.
All constituent records, housing units, filing dates, parent memberships, and
the 554/310 weighting sample are unchanged. Exactly these five parent rows
changed relative to the start of this review.

| Parent | Supported ground, sq ft | Earlier floor, sq ft | Status |
| --- | ---: | ---: | --- |
| East 125th, historical__121207504, 614 units | 42,540 | **50,836.28** | Applied; parcel-specific proportional estimate |
| St. James, historical__210181747, 102 units | 17,775 | **3,650** | Applied; later administrative proxy |
| Onderdonk, post_policy__Q01337462-I1, 62 units | 9,310 | **13,141.62** | Applied; proportional estimate |
| Jamaica 165th, post_policy__Q01243880-I1, 591 units | 39,349.50 | **40,342.49** | Applied; plan-based allocation of frozen floor |
| Kingsbrook, post_policy__B01318629-I1, 402 units | 105,382 | **226,059.00** | Applied; documented gross floor plus estimated plant allocation |

The land boundaries are supported by recorded instruments and agency plans.
Earlier floor estimates require the assumptions below. All five decisions are
stored in the production-owned manual source table; the audit preserves their
calculations and evidence. Kingsbrook uses a documented gross-floor substitute
whose exact comparability with PLUTO remains unproved.

## East 125th

The [October 2021 OER work plan](../../download_parent_review_documents/code/site_research_followup_2026-09-20_four_large/east125_oer_rawp_2021.pdf),
physical pp. 6 and 24, identifies the new 42,540-square-foot site as parts of
old lots 20 and 27; p. 91 names DOB job 121207504 on its site plan. The
[2025 work plan](../../download_parent_review_documents/code/site_research_followup_2026-09-20_four_large/east125_final_rawp_2025.pdf),
p. 96, corroborates the boundary with a 42,540.1-square-foot survey.

Frozen 20v1 MapPLUTO records floor of 64,363 on old lot 20 and 20,860 on old
27. The saved old/new geometry comparison assigns approximately 49.19% and
91.94% of those old parcels to the development. Applying those respective
shares to recorded floor gives **50,836.28**, or built FAR **1.195023**.
The script uses full-precision polygon shares, not the rounded percentages.

**Assumption:** floor is spread uniformly within each old parcel. This is more
informative than assigning all 85,223 square feet or using only the old small
lot, but it is not a measured building partition. The OER narrative describes
a one-story supermarket/clothing-store building with rooftop parking and a
separate postal building. Different heights across the two old parcels are
handled separately; uneven floor distribution within each parcel is not.
The 2021 site was vacant. Neither that statement nor the 21v3 zero-floor
records establish the demolition date relative to the April 2020 filing or
the appropriate frozen reference, so zero is not adopted retrospectively.

## St. James / Jerome

The [recorded deed](../../download_parent_review_documents/code/site_research_followup_2026-09-20_penn_jerome/jerome_deed_2021070800201002.pdf)
and [lease memorandum](../../download_parent_review_documents/code/site_research_followup_2026-09-20_penn_jerome/jerome_memorandum_lease_2021070800201004.pdf)
define the housing parcel. Its administrative ground is 17,775 square feet;
the legal courses give 17,774.63.

The [archived parcel extract](../../download_parent_review_documents/code/site_research_covariates_2026-09-21_campus/campus_covariate_crosswalk_rows.csv)
shows 13,000 square feet of old floor in 20v3. In 21v3 and 22v1 the retained
church has 7,650 and the housing parcel has **3,650**. The new nine-story
building first appears in the inspected 23v3_1 row at 84,897. The adopted
3,650 parcel-specific earlier-improvement record is a flagged proxy, giving
built FAR **0.205345**.

**Remaining uncertainty:** 7,650 + 3,650 = 11,300, leaving a **1,700** discrepancy
with the frozen total. We do not know whether this is a correction or a
physical change. Subtracting retained church floor from the frozen total
would instead assign 5,350 to the housing site. The adopted measure uses the directly recorded housing-parcel value.

## Onderdonk

The [recorded agreement](../../download_parent_review_documents/code/site_research_followup_2026-09-20_sourceids/onderdonk_easement_2026050800329001.pdf),
pp. 3, 27, and 29, identifies developer lot 30 and 9,309.60 surveyed square
feet; the administrative value is 9,310. The companion ZONE separates residual
lot 58 on Myrtle Avenue. Frozen 2023 MapPLUTO records 18,658 floor on the
13,218-square-foot predecessor, with class K2 and two stories.

The [new DOF extract](../../download_parent_review_documents/output/onderdonk_floor_2026-09-21.json)
reports 9,310 gross floor on successor 30 and 3,908 on residual 58; both are
K1. This weakens the former candidate that all earlier floor stayed on
residual 58. It does not establish the old partition: total reported floor
has fallen by 5,440 and the extract says FY2028.

The adopted estimate is **18,658 × 9,310 / 13,218 = 13,141.62**,
preserving frozen floor and using the development's share of the old ground.
Built FAR is **1.411560**. The later floor shares happen to equal those land
shares, providing a location clue rather than proof about 2023.

**Remaining uncertainty:** the old two-story floor might have been concentrated
on one side. The later one-story records cannot locate the missing second
floor or establish when it disappeared. This is weaker than Flatbush's
uniform-height evidence. Choosing 9,310 would additionally replace frozen
floor with a much later amount.

## Jamaica 165th

The [2026 declaration](../../download_parent_review_documents/code/site_research_followup_2026-09-20_jamaica/zoning_development_2026051400252004.pdf),
physical pp. 34–39 and 45, separates residential Parcel A (39,349.50 square feet)
from the MTA terminal. The residential strip extends 62 feet behind the 165th
Street frontage and has a deeper return along 89th Avenue.

The [2024 condominium plans](../../download_parent_review_documents/code/site_research_supervisor_2026-09-16/jamaica_condo_maps_2024081600593002.pdf),
pp. 5–6 and 14–20, locate each earlier building and its floors. The two Merrick
Boulevard buildings are outside the residential boundary. At old lot 65,
the frontage ground floor partly enters the development, while the rear
second floor and roof stair lie outside. Old lots 30, 85, and 130 have
70-foot-deep storefronts cut by the 62-foot boundary. Their small mezzanines
are drawn at the rear; the bus-terminal office stays outside.

For each old parcel, the calculation divides the floor-plan area inside the
housing boundary by the building's total above-cellar plan area, then applies
that fraction to its frozen administrative BldgArea. Thus the plan locates
floor, while the source-specific administrative total is retained. Old lots
98 and 99 are outside the condo plan's coverage: their 70- and 80-foot
administrative building depths provide approximate frontage fractions.

| Old lot | Frozen floor | Estimated floor inside housing |
| --- | ---: | ---: |
| 30 | 6,800 | 5,974 |
| 65 | 21,637 | 14,058 |
| 85 | 7,875 | 6,499 |
| 89 | 6,720 | 0 |
| 94 | 10,500 | 0 |
| 98 | 6,580 | 5,828 |
| 99 | 4,451 | 3,450 |
| 130 | 5,250 | 4,534 |
| **Total** | **69,813** | **40,342.49** |

The [reproducible worksheet](../output/jamaica_floor_allocation.csv) uses full
precision; displayed component values are rounded. The implied built FAR is
about **1.02523**. The 102,470 condo total includes cellars and other coverage;
it is not substituted for the eight administrative parcel totals.

**Assumptions:** the nearly rectangular drawn footprints approximate the
partition; scaled mezzanine depths are about 34, 22, and 12.5 feet; the old
98/99 buildings face the street and have approximately uniform floor density
along their depth; the 2024 plans describe the earlier structures relevant to
the 2023 reference. Applying the above-cellar spatial fraction to PLUTO's total
also assumes any unmeasured floor has a similar spatial allocation. The old
lot 85 total does not reconcile exactly to the later plan; that discrepancy
is preserved through proportional allocation, not declared resolved.

Putting all three small mezzanines outside versus inside gives **39,678.62–
40,735.68**. This is a sensitivity to mezzanine placement only, not a confidence
interval or a bound on all errors. The two shops outside the condo coverage
and the administrative/plan differences remain reasons to flag the estimate.

## Kingsbrook / Schenectady

The [recorded agreement](../../download_parent_review_documents/code/site_research_followup_2026-09-20_atlantic_schenectady/schenectady_agmt_2026070900638021.pdf),
pp. 30–33 and 37, assigns 92,709 square feet to Phase I and 12,673 to its parking.
The adopted boundary excludes the 23,363-square-foot future phase and
195,658-square-foot retained hospital grounds.

HCR's [corrected 2018 floor plans](../../download_parent_review_documents/output/kingsbrook_hcr_floor_plans_2018.pdf),
physical p. 9, provide a building-by-building schedule. The [December 2018
addendum](../../download_parent_review_documents/output/kingsbrook_hcr_addendum_2018.pdf)
explicitly corrects the original RFP's Leviton and LeFrak areas.

| Building | Gross floor including basement | Basement | Floor excluding basement |
| --- | ---: | ---: | ---: |
| Leviton | 44,890 | 9,310 | 35,580 |
| Masin | 74,295 | 10,570 | 63,725 |
| Blumberg | 48,655 | 5,395 | 43,260 |
| LeFrak | 46,440 | 9,970 | 36,470 |
| **Four buildings** | **214,280** | **35,245** | **179,035** |

The [June 2025 ESA](../../download_parent_review_documents/output/kingsbrook_phase_I_esa_2025.pdf),
pp. 10, 12–13 and 37, identifies the old buildings, gives the entire power-plant
footprint as 11,600 square feet, and confirms a cellar. Its broader study
boundary is not the current Phase I boundary. The [June 2026 RAWP](../../download_parent_review_documents/output/kingsbrook_rawp_2026.pdf),
pp. 21–23 and 129–132, supplies the 2021 survey and Phase I legal courses.
The survey's west power-plant bay is labeled **one story and mezzanine**.
The report's simple one-story description is therefore insufficient on its own.

A documented tracing of the survey, scaled by its 460-foot Rutland frontage,
places **47.9165%** of the old power-plant footprint inside the recorded Phase I
boundary. The traced whole footprint is 11,766.90 square feet, close to the
ESA's rounded 11,600. Applying the traced fraction to the ESA footprint gives
**5,558.31** inside. The intersecting bay could accommodate up to **1,324.74**
additional mezzanine square feet if fully covered.

The adopted estimate is:

**214,280 + 5,558.31 ground floor + 5,558.31 cellar + 662.37 mezzanine =
226,059.00 square feet**, or built FAR about **2.14514**.

This uses HCR gross floor directly, including basements. The power-plant
cellar is assumed to follow its ground footprint, and half of the labeled
mezzanine bay is assigned floor. Half is an explicit midpoint imputation, not
a measured mezzanine coverage. The 2018 schedule is used for the same buildings
identified again in the 2025/2026 reports; no intervening floor change is proved.
The HCR cover also describes the drawings as approximate owner-provided plans.

Omitting versus filling the mezzanine bay gives **225,396.63–226,721.37**,
conditional on the cellar assumption. Excluding all cellars gives **185,255.69**
under the same mezzanine assumption. These distinguish the uncertainty about
floor definition from the much smaller mezzanine uncertainty. PLUTO's
BldgArea is an administrative gross-area estimate with source-dependent
basement treatment; its two frozen campus records use source code 2. The HCR
schedule is a documented measurement substitute, not an exact reconciliation
to the 588,598 frozen campus total. [DCP's definition](https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/bytes/PLUTODD.pdf), pp. 22–23.

The earlier 181,016 residual mixed the frozen campus total with later retained
DOF floor. The adopted estimate sums the named structures inside the
site. The [calculation](../output/remaining_floor_candidates.csv) and
[boundary illustration](../output/kingsbrook_floor_allocation.png) preserve
both definitions and the plant assumptions. The unknown mezzanine and cellar
extent remain measurement qualifications, not a claim of exactness.

## Weight sensitivity

Root `make five-floor-review` produces
[`five_floor_sensitivity.csv`](../output/five_floor_sensitivity.csv).
The sample stays at 554 historical and 310 post-policy parents. Each scenario
corrects one parent's ground and varies only its prior floor; other parents,
the calibration formula, residential FAR, and outcomes remain fixed.
Adopted estimates and two deliberately wide endpoints are compared with the
current data after all five approvals.
Neither endpoint is asserted to be physically plausible. Jamaica’s upper
endpoint uses 52,593 floor on the six contributing parcels, excluding the
wholly retained lots 89 and 94.

| Parent | Exact-99 counterfactual share: zero floor | Share: all old floor | Difference, percentage points |
| --- | ---: | ---: | ---: |
| East 125th | 1.353791% | 1.353296% | 0.000495 |
| St. James | 1.353679% | 1.353121% | 0.000558 |
| Jamaica 165th | 1.352963% | 1.353704% | 0.000740 |
| Onderdonk | 1.352746% | 1.353857% | 0.001111 |
| Kingsbrook | 1.352327% | 1.355357% | 0.003030 |

The current share is **1.353533%**, compared with **1.354308%** before the five
corrections. The weighted mean moves from **151.4872 to 151.4686 units**. These
are the combined effects of the five adopted corrections. The table instead
shows one-parent-at-a-time stress tests around the corrected data, not
confidence intervals, mathematical bounds over all intermediate values, or
joint bounds. Small effects on these summaries do not validate a particular
floor estimate or establish insensitivity of a future structural model.

The source table contains 40 rows for 34 reviewed parents; six parents carry
the floor-estimate flag, including the previously approved Flatbush estimate.
The 20 sensitivity scenarios all achieve calibration moment error below 8e-10.
All 23 reviewed land corrections are applied. The September 22
[continuation](next_ten_boundaries_2026-09-22.md) also applies GO Broome's
documented zero earlier floor. The continuation also reviews the next ten
parents from the broader inventory.

The root build and a row-by-row comparison verify the five changed parent
records and identical constituent data. The source table has unique reviewed
parcel assignments. Scratch Make 3.81 checks cover fresh parallel builds,
regeneration of a missing actual output, changed-input propagation, and an
unchanged second build; removing a report alone does not rebuild. A download
fixture verifies that a checksum mismatch fails while preserving the previous
snapshot.

Jamaica's housing land uses six contributing earlier parcels. Old lots 89 and
94, with 23,175 square feet of ground and 17,220 of floor, are wholly outside
the residential boundary. The audit retains all eight associated parcels to
show that exclusion; the production source counts six and starts from their
88,365 ground and 52,593 floor before applying the approved allocation.

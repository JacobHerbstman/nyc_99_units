# Reviewed parent allocations: September 21, 2026

The production pipeline applies the seven supported rows from the September 20 batch as three economic parents. Bedford Square's four filings form one 877-unit development; Starhill's two form one 570-unit development; Dupont retains its single 381-unit filing. Administrative unit counts and filing dates remain the source measurements.

| Parent | Earlier reference parcels | Development ground, sq ft | Earlier building floor area, sq ft | Existing floor area / ground |
| --- | --- | ---: | ---: | ---: |
| Dupont | 21v1: 3024940006 and 3024940010 | 20,901 | 0 | 0 |
| Bedford Square | 21v1: 3051330014 and 3051350053 | 177,520.79 | 14,946 | 0.084193 |
| Starhill | 19v2: 2028650134 and 2028650162 | 70,063 | 80,370 | 1.147110 |

## What the source table applies

The existing production task `parent_opportunities_manual` owns both the accepted pair decisions and the six-row `site_lot_decisions.csv`. Each parcel row names its parent and constituent jobs, earlier MapPLUTO vintage and recorded area, included development ground, excluded earlier building floor area, and source. The site-characteristics script validates those identifiers and source areas, replaces the complete parcel set for the reviewed parent, and aggregates the included earlier attributes. `site_feature_method = reviewed_parcel_allocation` carries the measurement basis into the canonical parent panel. Main tasks read no audit outputs.

**Dupont:** the recorded agreement assigns 9,011 square feet from old lot 6 and 11,890 from old lot 10, excluding the separate street strip. Both 21v1 parcels have zero building area and residential FAR 6.02. The OER notice identifies these two lots as the tower site. Earlier production used only the old lot-6 area, 12,194; corrected ground rises by 8,707 square feet.

**Bedford Square:** west housing ground is 43,413.10 + 73,457.69 = 116,870.79 square feet. The east buildings occupy the complete earlier lot at 60,650, counted once. Retained Sears land is excluded. Its entire 175,875 square feet of earlier building area remains on the retained parcel in current PLUTO, consistent with the DEC investigation, site plan, decision document, and recorded deed descriptions. The housing parent therefore retains only the east auto-center's 21v1 floor area of 14,946. Its earlier residential FAR is 2.43. Using later east areas instead would add 76 square feet; the adopted complete-reference-parcel convention keeps 60,650.

**Starhill:** the recorded declaration describes the combined development perimeter and expressly excludes retained lots 129 and 162. Later administrative phase areas sum to 70,063. The contribution from old lot 162 has legal dimensions 44.5 by 100 feet, or 4,450 square feet; the remainder is 65,613 from old lot 134. The 21v1 subdivision attributes all 33,750 square feet of the old lot-162 building to retained lot 162 and zero building area to its contributed strip. The parent retains old lot 134's 80,370 square feet. Earlier residential FAR is area weighted: (65,613 × 6.02 + 4,450 × 3.44) / 70,063 = 5.856133.

These are reconstructed development grounds. Later boundary evidence does not establish ownership at initial filing. Starhill's total is a later administrative measurement of its recorded boundary, not a February 2020 survey. A common economic parent is distinct from a legal wage-assessment unit.

## Panel verification

The canonical historical panel moves from 1,818 to 1,814 parents and retains exactly 129,335 units. The post-policy panel remains 909 parents with 61,319 units. Within the weighting sample, historical parents move from 561 to 557 and post-policy parents remain 312. The four removed IDs are the three Bedford companions and the Starhill companion now included in their joint parents.

Comparisons against saved pre-edit datasets verified that every constituent's administrative units, original filing date, record filing date, refiling indicator/date, address, and rental-sample inclusion are unchanged. The full membership source preserves those fields and filing roles. Every other parent's common panel columns are unchanged, and the complete post-policy site-characteristics dataset is identical. All three corrected parents remain composition eligible. Removing and regenerating the historical site-characteristics output through root `make data` reproduced its SHA-256 exactly.

The re-estimated weights remain positive, ranging from 0.1400 to 1.6830 and summing to 312. Effective sample size is 492.9, compared with 495.4 before these changes. The largest standardized balance error is below 6 × 10⁻¹². The weighting variables and fitting specification are unchanged; these are refreshed results from the corrected input data. Root `make -j2` rebuilds the main plots and maps; a second unchanged invocation runs no producer recipes.

The existing separate-assessment pilot selects the same parameters, κ = 0.115 and organization-cost scale = 1.2. Its modeled unit reduction changes from 546.18 to 542.54; this is a refresh of the exploratory fit, not a new adopted estimate. The bootstrap records 490 successful calibrations and nine failed calibrations out of 499 attempts; intervals use the successful draws and the run summary retains the failures.

Bedford's raw DOF screen also retains transaction 99999, a November 14, 2023 correction to lot 46's length. The inspected successor map and later recorded deed description resolve that exact change. The documentary table names the transaction; the audit checks its date and clears the physical-change question only when the reviewed transaction set exactly matches the observed set. Other source and membership questions remain independent.

The refreshed scope audit has 129 flagged parents out of 869 (98 historical and 31 post-policy), compared with 135 out of 873 before implementation. Bedford's four old rows and Starhill's two become two supported parents, reducing flags by six and the denominator by four. Dupont had already passed the documentary audit and now agrees in production. All other parents retain their previous pass/flag status. The remaining flagged rows should not be read as 129 completely unresearched cases; accepted decisions awaiting application remain separately identified.

## Remaining evidence questions

The other three sites in this batch remain open: Eagle/West needs the allocation of waterfront and shared-access ground; 355 Exterior needs its building-site boundary within a broader zoning lot; 1580 Story needs the building-specific allocation within the ownership parcel. Their source records remain unchanged. Other accepted audit decisions are tracked separately from unresolved evidence; this implementation covers Dupont, Bedford Square, and Starhill.

## Sources and reproduction

The [September 20 batch report](site_research_batch10_review.md) links the original records and precise pages. Additional density checks use the saved current PLUTO response for the Bedford lots and the saved 21v1 Starhill parcel attributes, checked against the original declaration and dated DOF maps. Transitional Starhill releases duplicate building attributes across a subdivision; the consistent later partition locates the old building on the retained parcel.

Run root `make` for panels, plots, and maps; `make dof-site-review` for refreshed scope flags; and `make logbook` to refresh the existing weights, pilot, and research record. The existing model specification and weighting moments remain fixed.

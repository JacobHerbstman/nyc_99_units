# Construct symmetric parent cohorts

This production task groups linked New Building filings into economic parent
opportunities. A parent is anchored on its first observed filing and may include
linked filings filed within 365 days. The same rule is applied to historical
and post-policy filings, including links that cross calendar years.

Recent links require the same explicit filing BBL, the same site-linkage BBL,
leakage-safe lot history, an explicit project reference, a common project code,
or exact filing-lot adjacency corroborated by filing timing or common
ownership. The common-site measure is kept only as a parent-link signal; the
explicit filing BBL is retained on each constituent for construction and
splitting analysis. Later lot changes alone are not used.

Every post-period parent created by a shared site-linkage BBL but different
filing BBLs is manually reviewed in `parent_opportunities_manual/output/post_parent_reviews.csv`. Pair
acceptances and rejections are listed in that source task's `pair_decisions.csv`. Filings that belong to the
same economic parent but describe a superseded, mutually exclusive design are
listed in that source task's `post_parent_filing_roles.csv`. They remain in the membership output
as source proposals but do not enter the additive filing count or parent unit
total. This keeps the two decisions separate: whether filings belong to one
economic opportunity, and whether their proposed units can be summed.

The completed review covers all 37 original shared-site parents. Thirty-five
groupings are accepted and two are rejected; no decision remains unresolved.
Three manually reviewed filings are retained as superseded alternatives. Automatic refiling detection additionally marks withdrawn predecessors as `superseded_refiling`. The output therefore
reports both additive `parent_observed_*` measures and `parent_source_*`
measures that describe every source filing before the supersession rule.

The historical linkage universe begins in 2010 so that 2011 cohorts have a
left-side window. Historical cohorts are observed through 2023. The DOB-based
linkage universe begins in 2022 as padding, producing fully observed 2023 and
2024 comparison cohorts under the same rules used for 2025 and 2026. Recent
filings are observed through July 8, 2026; the membership file records whether
each cohort's full 365-day window is observable. No unobserved companion filing
or unit count is imputed.

Run `make` from `code/`. The outputs are one row per filing with its parent
identifier and role, and one row per accepted filing link with its reason.

The manual task owns all committed review sources; this task reads input symlinks.
The seven September 2026 companion decisions overcome documented map-coverage
failures without broadening the automatic ownership/proximity rule. Three disputed
pair links are rejected; Wilson/Boston is now adjudicated separate in the baseline, with residual affiliation uncertainty recorded. Final
assertions check pair decisions against the resulting connected components, so
an indirect path cannot silently undo a rejection.

Selected `units` use the unfiltered staged Housing Database Class A count, including a recorded zero. DOB supplies units only when that HDB count is missing. Unit source selection is independent of land availability, filing-year restrictions, and the six-unit sample cutoff. Zero-Class-A source records remain in membership with role `zero_class_a`; they contribute neither units nor residential constituent counts. The original DOB count, parent connections, and filing/refiling dates remain available. Sample size restrictions are applied downstream.
Documented proposed-unit schedules in the manual task are comparison evidence;
they never override the selected administrative measure. A final assertion
requires selected units to equal `hdb_priority_units` for every record. Third
Avenue remains 99 per building and Boyland 86+28 because those are HDB counts.
Turnbull returns to 91; its externally documented 228 remains a separate field.
Parent observed totals and exact-99 counts use the selected administrative units.
The `dob_i1_units` field uses the July 2026 DOB source and is missing for
legacy filings without DOB coverage. For historical filings, it is a retrospective
comparison; it does not determine sample inclusion, selected units, or exposure.
Parent DOB totals are missing when
component coverage is incomplete. Neither administrative vintage reconstructs every design
at its original submission date.

Astoria Cove's four January 13, 2022 filings are joined by a documented manual
edge in both linkage routes. The December 2023 GEI report identifies them as one
Phase 1. The saved 576-unit program is unchanged; subsequent 731-unit plans are
a separate vintage. The Coney Island rejection separates LCOR's 1515 Surf/
2925 West 16th project from BFC's neighboring 1601 Surf/2938 West 16th project.

Post-policy automatic refiling detection uses the saved July 2026 DOB initial records. A withdrawn filing must have a valid seven-digit BIN and nonempty recorded owner/applicant; its unique non-withdrawn replacement must share the BIN and normalized owner/applicant and be filed strictly after both the original filing and recorded withdrawal. The rule scans the retained filing universe without using unit similarity or address proximity. Multiple candidates, multiple predecessors for one replacement, cross-parent matches, and conflicts with manual roles fail for review. They do not create new parent links.

Both source records remain, but only the replacement contributes units. Raw `date_filed` is unchanged in membership. Both records have `refiled = TRUE`, the original date in `original_filing_date`, and the replacement date in `refiling_date`. Other records have `refiled = FALSE` and a missing refiling date. This means no qualifying refiling observed in the saved source. The original parent anchor and cohort date remain unchanged. `refiling_basis` identifies the evidence supporting each replacement.

Recent DOB filing-field preparation is now the first producer in this task, using the official APPBBL crosswalk from `build_hdb_mappluto_site_panel`. It retains the existing years, unit restrictions, and link-field definitions.

## Historical source and alternatives

Historical filing outcomes and linkage fields use the inactive-inclusive 23Q4 Housing Database. Every record carries its release, archived status, and active-file membership. The source includes withdrawn and stalled proposals. Earlier withdrawn versions count as nonadditive when the same archived BIN, lot, and exact address identify one later nonwithdrawn application within the 365-day window. Several withdrawn versions may have the same successor. `refiling_basis` distinguishes this archived same-building rule from the dated DOB withdrawal rule for post-policy records; no historical withdrawal date is imputed.

`historical_filing_roles.csv` in the manual task records reviewed exceptions with their evidence. It marks 773 Neptune's institutional job as nonresidential and the withdrawn West 49th Street application as an alternative to the West 48th Street housing application. The latter has different BINs and addresses, so its replacement relationship requires documentary review. Source unit counts are retained; filing roles determine which counts enter the residential total.

Connected components cannot span more than 365 days from first to last filing. The grouping applies accepted manual edges first, then candidate links in filing-date order. A chain of individually close filings cannot extend the parent's window. Applicable manual acceptances and rejections are checked again against the final membership.

`pair_decision_coverage.csv` records which committed pair decisions have both endpoints in the selected source universe. A later-source filing absent from 23Q4 is not supplied by a later vintage. Applicable accept/reject decisions must survive component construction.

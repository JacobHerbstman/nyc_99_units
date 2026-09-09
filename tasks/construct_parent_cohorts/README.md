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
filing BBLs is manually reviewed in `post_parent_reviews.csv`. Rejected pair
links are listed in `post_parent_link_reviews.csv`. Filings that belong to the
same economic parent but describe a superseded, mutually exclusive design are
listed in `post_parent_filing_roles.csv`. They remain in the membership output
as source proposals but do not enter the additive filing count or parent unit
total. This keeps the two decisions separate: whether filings belong to one
economic opportunity, and whether their proposed units can be summed.

The completed review covers all 37 original shared-site parents. Thirty-five
groupings are accepted and two are rejected; no decision remains unresolved.
Three filings are retained as superseded alternatives. The output therefore
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

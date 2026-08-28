# Construct symmetric parent cohorts

This production task groups linked New Building filings into economic parent
opportunities. A parent is anchored on its first observed filing and may include
linked filings filed within 365 days. The same rule is applied to historical
and post-policy filings, including links that cross calendar years.

Links require same filing BBL, leakage-safe lot history, an explicit project
reference, a common project code, or exact parcel adjacency corroborated by
filing timing or common ownership. Later lot changes alone are not used.

The historical linkage universe begins in 2010 so that 2011 cohorts have a
left-side window. Historical cohorts are observed through 2023. The DOB-based
linkage universe begins in 2022 as padding, producing fully observed 2023 and
2024 comparison cohorts under the same rules used for 2025 and 2026. Recent
filings are observed through July 8, 2026; the membership file records whether
each cohort's full 365-day window is observable. No unobserved companion filing
or unit count is imputed.

Run `make` from `code/`. The outputs are one row per filing with its parent
identifier and one row per accepted filing link with its reason.

# Exact-99 exposure and physical-design audit

This task links the preferred no-notch exposure score to the DOB NOW physical
fields for each scoreable 2025 exact-99 filing. It asks whether 99-unit filings
that look more likely to cross 100 without the notch are physically small
projects or occupy larger gross building envelopes.

All 53 scoreable exact-99 filings match a positive DOB total construction area.
The task reports an application-level ledger, four exposure groups, descriptive
Spearman correlations, and a two-panel figure. Same-BBL repeated 99s are marked
but remain candidate clusters rather than legally validated splits.

## Findings

The relationship is positive, not negative. Median total construction area
rises from 68,225 square feet in the below-0.25 exposure group to 96,544 square
feet in the group with exposure of at least 0.75. Median gross construction
square feet per dwelling unit rises from 689 to 975. Across all 53 observations,
the Spearman correlations with exposure are 0.349 for total area and 0.355 for
gross square feet per unit. Proposed stories and height have correlations near
zero.

This is consistent with highly exposed 99s retaining a relatively large gross
building envelope while placing fewer dwellings inside it. It is not a causal
test of the notch. Exposure is partly predicted by lot size and zoning, so
larger gross buildings are mechanically more likely on higher-exposure sites.
The result also cannot distinguish larger apartments from common space,
mechanical space, parking, nonresidential uses, or amenities.

DOB NOW does not report apartment size, bedroom mix, amenity area, or proposed
residential-only floor area. Plans, Schedule A, HPD records, or developer
materials remain necessary to identify those margins.

Run the task from `code/` with `make`. The Makefile exposes the post year,
bunching count, and three exposure-group cutoffs as scalar analytical choices.

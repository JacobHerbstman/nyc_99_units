# Construct historical parent links

This task builds leakage-safe filing-pair evidence for historical parent
construction. The source universe begins in 2010 so a 365-day lookback can
determine whether a 2011 filing is a parent anchor. It extracts
owner, lot-history, coordinate, and explicit
project-reference fields from the historical MapPLUTO snapshot available at
each filing date. It then identifies filing pairs within one year and records
the conservative link signals used by the parent construction.

The task produces two analytical datasets: filing-level link fields and
candidate filing pairs.

Accepted historical endpoints from `parent_opportunities_manual/output/pair_decisions.csv`
remain in the filing universe even when land covariates fail their match. This
restores observed companions without inventing geometry or land area. All ordinary
filing-year and unit restrictions remain. The parent producer records which decisions have both endpoints in the selected
source; applicable manual edges do not depend on automatic candidate discovery.

This task also extracts exact filing-date parcel polygons and constructs adjacency pairs. The 2018 geometry provides the lookback for 2019 parent anchors. Adjacency is a link signal only under the documented corroboration rule; near-touch sensitivities remain in audits.

Historical units, filing BBLs, descriptions, and coordinates come from the complete 23Q4 Housing Database. Owner support comes from the archived parcel map selected before filing. Later DOB descriptions or owner fields do not supply historical mechanical links. Accepted manual companions can retain missing land covariates, but must still satisfy the historical source and residential-size conditions.

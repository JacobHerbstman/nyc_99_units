# Construct historical parent adjacency

This task reads the exact MapPLUTO polygon snapshot available at each
2018–2023 filing date and identifies pairs of distinct filing lots whose
polygons touch. An exact adjacency becomes a parent link only when the filings
are within 30 days or the link is corroborated by owner or conservative
historical evidence.

The 2018 rows provide the 365-day lookback needed to identify 2019 parent
anchors; estimation still begins in 2019. Near-touch and grouping-sensitivity
diagnostics remain in
`tasks/audits/audit_historical_exact_parcel_adjacency`.

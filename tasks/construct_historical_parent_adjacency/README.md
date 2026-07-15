# Construct historical parent adjacency

This task reads the exact MapPLUTO polygon snapshot available at each
2019–2023 filing date and identifies pairs of distinct filing lots whose
polygons touch. An exact adjacency becomes a parent link only when the filings
are within 30 days or the link is corroborated by owner or conservative
historical evidence.

No pre-2019 adjacency is imputed. Near-touch and grouping-sensitivity
diagnostics remain in
`tasks/audits/audit_historical_exact_parcel_adjacency`.

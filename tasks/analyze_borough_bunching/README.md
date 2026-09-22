# Bunching by borough

Compares constituent filing sizes and linked parent totals by borough in the
A/B rental-opportunity sample, 2019–2022 versus January 1, 2025–July 8, 2026. Each borough-period distribution is normalized over its own observations
with at least 50 units, including the entire upper tail in the denominator.
Plots display 50–300 units in one-unit bins. Parent eligibility uses parent total;
filing eligibility uses the constituent's own size. These are unweighted
descriptive comparisons, not estimates of a causal policy effect.

The canonical constituent panel supplies borough, proposed units, parent links,
and sample membership. All constituents within a parent must agree on borough;
their units must sum to the parent total. Borough is available for every filing,
so missing site characteristics do not exclude otherwise eligible projects.

Map coordinates come from DCP Housing Database 23Q4 for historical filings and
the staged DOB NOW initial-filing extract for post filings. These choices follow
the sources defining each cohort; there is no cross-source geocoding fallback.
The exact-99 map counts filings, distinguishing filings whose linked parent also
totals 99 from those belonging to a larger parent. It is a location map, not a
map of local bunching rates. Coincident points may overlap. Borough outlines are
the NYC Open Data September 8, 2026 snapshot. Coordinates are transformed from
WGS84 to New York State Plane (EPSG:2263) for plotting and spatial validation.
Any missing or out-of-borough coordinates are explicitly flagged in the saved
filing panel; valid mapped counts are shown on the map.

Run `make` in `code/`. `borough_bunching.pdf` collects all three figures. Individual outputs are `borough_filings.pdf`,
`borough_parents.pdf`, `exact_99_map.pdf`, and `borough_summary.csv`.
`geographic_filings.parquet` retains the map roster and source/status fields.
Both saved datasets have standard reports in `report/`.

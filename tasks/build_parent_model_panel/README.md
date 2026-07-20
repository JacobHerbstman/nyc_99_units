# Build parent-model panels

This task turns the symmetric 365-day parent membership into the historical
training panel and post-policy scoring panel. It sums proposed units within a
parent and aggregates site characteristics across unique pre-policy lots.

Historical features come from each filing's leakage-safe lagged MapPLUTO match.
Post-policy features use the fixed 23v3.1 MapPLUTO snapshot. The panel retains
the first-filing cohort date and the full-window status created upstream; the
estimation task makes the sample restriction.

Parents with incomplete lot features or repeated nonmissing BIN rows are
retained but marked ineligible. Nothing is corrected or imputed. Run `make`
from `code/` to build both panels.

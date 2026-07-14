# No-Notch Residual-Pattern Audit

This audit asks why the building-level no-notch unit model has large individual
prediction errors. It selects one latest-training out-of-time prediction per
filing, joins the prediction safely to the leakage-safe HDB-MapPLUTO panel, and
separates three possible sources of residual variation:

- multiple building filings linked to one parcel-scale MapPLUTO feature lot;
- incomplete or inappropriate parcel-capacity measurement; and
- remaining project-level heterogeneity among well-aligned singleton filings.

DOB NOW construction area, stories, owner, and applicant fields are used only
as diagnostics. They are simultaneous project-design outcomes or have limited
historical coverage and are not silently added to the no-notch baseline.

Run from `code/` with `make`.

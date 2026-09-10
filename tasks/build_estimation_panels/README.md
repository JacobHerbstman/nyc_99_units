# Estimation datasets

Produces the canonical constituent-filing and parent-opportunity panels from approved parent membership, exposure classifications, HPD registration links, and predetermined site characteristics. It preserves the existing administrative unit priority, manual membership decisions, refiling dates, and source coverage flags.

The comparison is 2019–2022 versus January 1, 2025–July 8, 2026. The panels contain classified parents with at least six units; `included_ab` identifies the adopted rental-opportunity sample. They do not estimate the joint model, impute unseen companion filings, or turn an economic parent into a verified legal wage-assessment unit.

Run `make` in `code/`. Outputs are `parent_opportunity_panel.parquet` (one row per parent) and `constituent_filing_panel.parquet` (one row per retained additive filing). Standard reports live in `report/`. The citywide plots, borough analysis, and relevant audits consume these same files.

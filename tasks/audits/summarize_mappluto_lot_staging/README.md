# Summarize MapPLUTO Lot Staging

Audits staged MapPLUTO lot files by release.

This task reports row counts, BBL coverage, duplicate BBL counts, and key predictor completeness. It is intentionally separate from `tasks/stage_mappluto_lots`, which only produces the canonical staged lot handoff.

The audit also records raw zip table-selection summaries and borough-level row counts so legacy PLUTO CSV/TXT vintages can be checked for file-selection, borough-coverage, and column-coverage problems without adding diagnostics to the production staging task.

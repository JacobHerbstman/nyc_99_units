# NYC 99 Units Project

This repository is the reproducible project scaffold for studying who pays for New York City's 485-x housing tax incentive, with attention to the 100-unit notch.

## Research Question

The paper asks whether the costs created by the 485-x threshold are capitalized into land prices or show up as developer avoidance. The key behavioral margins are bunching at 99 units, delays, larger units, and adjacent or related 99-unit filings that may split a larger feasible development.

The treatment object should not be observed post-policy unit count. The initial design is to build an ex ante notch-exposure measure from pre-485-x parcels and projects: use similar pre-2024 developments to simulate feasible unit counts for a parcel, then estimate whether parcels likely to fall just above 100 units experience lower land prices or avoidance after the policy.

## Principles

- Keep active tasks small, linear, and file-target driven.
- Run tasks from `tasks/<task>/code/`.
- Keep fixed task-local paths inside scripts, not Make arguments.
- Use Makefile scalar variables only for real analytical choices.
- Keep diagnostics, manual-review files, source integrity checks, and exploratory plots under `tasks/audits/`.
- Keep raw public and manual data under `data_raw/<source_id>/<vintage_or_pull_date>/`.
- Track all manual drops, agency requests, and non-scripted sources in `tasks/source_registry/code/`.

## Start Here

1. Run `make` in `tasks/setup_environment/code/` to install/check R packages and record versions.
2. Run `make` in `tasks/source_registry/code/` to validate source metadata.
3. Review `tasks/source_registry/code/source_catalog.csv`, `manual_manifest.csv`, and `archive_requests.csv`.
4. Add production source tasks only when they produce a real canonical handoff file.
5. Put all QC, coverage, source comparison, and exploratory outputs in `tasks/audits/<audit_name>/`.

## Initial Data Plan

- `DCP Housing Database`: project-level DOB-approved housing jobs since 2010, with units, permit dates, and completion status.
- `PLUTO` / `MapPLUTO`: parcel characteristics, zoning, lot area, built area, geography, and geometry for capacity prediction and adjacency.
- `DOB Open Data`: BIS and DOB NOW job filings as filing-side checks and applicant/owner/architect linkage inputs.
- `ACRIS`: real property master, legals, parties, and references for land transactions, ownership changes, and acquisition histories.
- `HPD 485-x materials`: program rules, registration forms, and any public or agency-provided project-level registration records.

## Planned Task Order

- `tasks/setup_environment`
- `tasks/source_registry`
- `tasks/fetch_dcp_housing_database`
- `tasks/load_dcp_housing_database_raw`
- `tasks/stage_dcp_housing_database`
- `tasks/fetch_pluto`
- `tasks/load_pluto_raw`
- `tasks/stage_pluto_lots`
- `tasks/fetch_dob_open_data`
- `tasks/load_dob_open_data_raw`
- `tasks/stage_dob_jobs`
- `tasks/fetch_acris`
- `tasks/load_acris_raw`
- `tasks/stage_acris_transactions`
- `tasks/build_parcel_project_panel`
- `tasks/build_notch_exposure`
- `tasks/estimate_land_price_incidence`
- `tasks/estimate_developer_avoidance`

## Active Tasks

- `tasks/setup_environment`
- `tasks/source_registry`
- `tasks/fetch_dcp_housing_database`
- `tasks/load_dcp_housing_database_raw`
- `tasks/stage_dcp_housing_database`
- `tasks/audits/summarize_dcp_hdb_unit_bunching`

The first active audit checks the proposed-unit distribution for DCP Housing Database new-building filings from 2010 through 2025. It uses `date_filed` and `classa_prop` as the main descriptive definition, compares annualized 2010-2023 counts to 2025, and keeps 2024 as a transition year around the April 20, 2024 statutory adoption date.

The remaining planned tasks should be created as the corresponding data and estimators become concrete.

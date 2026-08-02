# NYC 99 Units

This repository studies developer responses to the 100-unit threshold in New
York City's 485-x housing tax incentive. The current empirical goal is narrow:
measure bunching and splitting, reconstruct the parent development opportunity,
and estimate the no-notch distribution of proposed units. Developer costs and
broader welfare require additional cost data and are later stages.

## Workflow

- Run each task from its `code/` folder with `make`.
- Treat task Makefiles as the dependency graph.
- Keep fixed input and output paths inside scripts.
- Expose only genuine analytical choices as Make variables.
- Put diagnostics, model comparisons, placebos, and manual review under
  `tasks/audits/`.
- Do not edit generated outputs directly.

## Current production graph

The main bunching evidence is produced by:

```text
stage_dcp_housing_database
  -> summarize_hdb_unit_bunching

stage_dob_now_new_building_filings
  -> summarize_developer_responses
```

The preferred symmetric-parent model is produced by:

```text
HDB + historical MapPLUTO + DOB NOW
  -> build_hdb_mappluto_training_panel
  -> construct_historical_parent_links
  -> construct_historical_parent_adjacency
  -> construct_parent_cohorts
  -> build_parent_model_panel
  -> estimate_parent_no_notch_model
  -> prepare_developer_cost_calibration

DOB NOW + MapPLUTO APPBBL history
  -> construct_post_policy_parent_crosswalk
  -> construct_parent_cohorts
```

The preferred estimator uses one observation and one i.i.d. scale shock per
symmetric parent. It is estimated on fully observed 2019--2022 first-filing
cohorts. A 2025 cohort enters the main scoring sample after 180 observed days
if its full pre-filing linkage window is available; observed companions can
still join through day 365. The completed-365-day cohort and DOB initial-filing
units are sensitivities. No companion, feature, or unit count is imputed.
Filing-level models, placebos, inference, and alternative parent definitions
remain in audit tasks.

## Main outputs

- `tasks/summarize_hdb_unit_bunching/output/`: application and provisional
  parent bunching figures and exact counts.
- `tasks/summarize_developer_responses/output/`: construction-area,
  square-feet-per-unit, and provisional-site configuration figures.
- `tasks/estimate_parent_no_notch_model/output/`: fitted coefficients, 2025
  parent scores, observed and no-notch distributions, mass-balance moments,
  implied frontiers, and counterfactual figures for the preferred 180-day and
  completed-365-day specifications.
- `tasks/prepare_developer_cost_calibration/output/`: the preferred and
  completed-cohort exact-99 behavioral targets and affected counterfactual
  parent-size weights. These are inputs to future cost calibration, not dollar
  cost or welfare estimates.

## Deferred branches

The ACRIS and DOF tasks form a separate land-sales branch. They are retained
because they produce canonical source and event files, but they are not inputs
to the current developer-response results. They should not be added to the
paper build until the project returns to land-price incidence.

Raw public and manual data belong under `data_raw/<source>/<vintage>/` and are
never modified. Source metadata and requests are tracked in
`tasks/source_registry/code/`.

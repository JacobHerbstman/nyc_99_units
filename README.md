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

The preferred enhanced-parent model is produced by:

```text
HDB + historical MapPLUTO + DOB NOW
  -> build_hdb_mappluto_training_panel
  -> construct_historical_parent_links
  -> construct_historical_parent_adjacency
  -> build_parent_model_panel
  -> estimate_parent_no_notch_model

DOB NOW + MapPLUTO APPBBL history
  -> construct_post_policy_parent_crosswalk
  -> build_parent_model_panel
```

The preferred estimator uses one observation and one i.i.d. scale shock per
enhanced parent. It is estimated on 2019–2023 parents and scored on 2025
parents. The corresponding filing-level models, longer training periods,
alternative parent definitions, placebos, and validation windows remain in
audit tasks.

## Main outputs

- `tasks/summarize_hdb_unit_bunching/output/`: application and provisional
  parent bunching figures and exact counts.
- `tasks/summarize_developer_responses/output/`: construction-area,
  square-feet-per-unit, and provisional-site configuration figures.
- `tasks/estimate_parent_no_notch_model/output/`: fitted coefficients, 2025
  parent scores, observed and no-notch distributions, mass-balance moments,
  implied frontiers, and the primary counterfactual figure.

## Deferred branches

The ACRIS and DOF tasks form a separate land-sales branch. They are retained
because they produce canonical source and event files, but they are not inputs
to the current developer-response results. They should not be added to the
paper build until the project returns to land-price incidence.

Raw public and manual data belong under `data_raw/<source>/<vintage>/` and are
never modified. Source metadata and requests are tracked in
`tasks/source_registry/code/`.

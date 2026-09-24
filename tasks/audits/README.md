# Audit tasks

Audits hold validation, sensitivity analysis, and exploratory work that the
main pipeline does not depend on. Build the main pipeline with root `make`
before running an audit from its `code/` folder or through its root target.

| Audit | Purpose |
|---|---|
| `audit_scale_shape_splitting` | Reweighted historical benchmark, bootstrap, and the values used in `framework_writeup.tex` |
| `audit_scale_shape_counterfactual` | Pre-policy holdout checks of that benchmark |
| `audit_companion_rules` | Symmetric rules for linking companion filings across nearby lots, with a hand-validated sample |
| `audit_land_measurement_sensitivity` | Whether land-measurement choices move the reweighted comparison |
| `audit_parent_site_boundaries` | Automatic parcel-boundary screen and the calculations behind adopted land decisions |
| `audit_estimation_parent_links` | Evidence tables and casebook for reviewed parent links |
| `parent_review_documents` | Committed captures and checksum lists for the documents behind manual decisions |
| `fetch_nys_ag_offering_plan_matches` | Attorney General offering-plan queries used by the exposure classification |

The September pilot fit (`fit_pure_notch_pilot`) was replaced on September
24, 2026 by the production task `estimate_notch_model`; the logbook archive
keeps the pilot's outputs.

Adopted decisions live in production tasks: parent links, filing roles, and
land allocations in `parent_opportunities_manual`; exposure reviews in
`classify_parent_485x_exposure`. Earlier audits were removed from the tree;
tag `pre-cleanup-2026-09-22` preserves them.

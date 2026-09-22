# Audit tasks

Audits hold validation, sensitivity analysis, and exploratory work that the
main pipeline does not depend on. Build the main pipeline with root `make`
before running an audit from its `code/` folder or through its root target.

| Audit | Purpose |
|---|---|
| `audit_scale_shape_splitting` | Reweighted historical benchmark, bootstrap, and the values used in `framework_writeup.tex` |
| `audit_scale_shape_counterfactual` | Pre-policy holdout checks of that benchmark |
| `audit_land_measurement_sensitivity` | Whether land-measurement choices move the reweighted comparison |
| `fit_pure_notch_pilot` | Exploratory structural fit of the joint size-and-organization model |
| `audit_hdb_mappluto_condo_recovery` | Automatic parcel-boundary screen and the calculations behind adopted land decisions |
| `audit_estimation_parent_links` | Evidence tables and casebook for reviewed parent links |
| `download_parent_review_documents` | Checksummed copies of the documents behind manual decisions |
| `fetch_nys_ag_offering_plan_matches` | Attorney General offering-plan queries used by the exposure classification |

Adopted decisions live in production tasks: parent links, filing roles, and
land allocations in `parent_opportunities_manual`; exposure reviews in
`classify_parent_485x_exposure`. Earlier audits were removed from the tree;
tag `pre-cleanup-2026-09-22` preserves them.

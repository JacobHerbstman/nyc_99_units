# Audit tasks

Audit tasks contain validation, sensitivity analysis, manual-review ledgers,
and exploratory outcomes that are not headline production results. Each task
still has an explicit Makefile and should run from its `code/` folder, after
building the main pipeline with root `make`.

The retained audits cover:

- source and identifier checks for DCP HDB, DOB NOW, and MapPLUTO;
- historical and post-policy parent-linkage checks;
- exposure classification and threshold sensitivities;
- exploratory reweighting, decomposition, and bootstrap calculations;
- ACS, QCEW, and LODES wage comparisons;
- the right-censored condo-tenure branch.

No main task depends on an audit task. Adopted parent-link decisions live in
`parent_opportunities_manual`; exposure decisions live in
`classify_parent_485x_exposure/code/parent_exposure_manual_reviews.csv`.
HPD registration links and exposure classifications also have main tasks.

From `tasks/audits/<task>/code`, production outputs use paths like
`../../../<task>/output/<file>`. Sibling audit outputs use
`../../<task>/output/<file>`. Audit Makefiles include `../../../shared/code/generic.make`.

The older parcel-prediction, structural no-notch, ACRIS/DOF, and land-price
experiments were removed from the active tree. Git commit `1374dda` preserves
their final pre-cleanup state.

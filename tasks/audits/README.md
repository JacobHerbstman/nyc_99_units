# Audit tasks

Audit tasks contain validation, sensitivity analysis, manual-review ledgers,
and exploratory outcomes that are not headline production results. Each task
still has an explicit Makefile and should run from its `code/` folder.

The retained audits fall into four groups:

- source and identifier checks for DCP HDB, DOB NOW, and MapPLUTO;
- historical and post-policy parent-linkage checks;
- exposure classification and threshold sensitivities;
- the right-censored condo-tenure branch.

An audit output may feed a production task only when the judgment itself is
part of the research design. The parent exposure classification is the current
example: its manual review file is authoritative and remains visible here.
Canonical mechanical links, such as HPD registrations to DOB jobs, belong in a
top-level production task.

From `tasks/audits/<task>/code`, production outputs use paths like
`../../../<task>/output/<file>`. Sibling audit outputs use
`../../<task>/output/<file>`. Audit Makefiles include `../../generic.make`.

The older parcel-prediction, structural no-notch, ACRIS/DOF, and land-price
experiments were removed from the active tree. Git commit `1374dda` preserves
their final pre-cleanup state.

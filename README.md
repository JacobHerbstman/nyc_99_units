# NYC 99 Units

This repository studies developer responses to the 100-unit threshold in New
York City's 485-x housing tax incentive. The current empirical work measures
the distribution of proposed project sizes in a plausible rental-opportunity
sample and tests whether linked economic parents are split across multiple
filings or buildings. The unit of observation is the linked parent proposal,
not an individual filing.

The current analysis is descriptive and design-based. It does not treat an
individual parcel-size prediction, a structural cost estimate, a land-price
event study, or the condo-tenure panel as a headline result.

## Current framework

[`framework_writeup.pdf`](framework_writeup.pdf), built from
[`framework_writeup.tex`](framework_writeup.tex), contains the September 2026
note *Project Size and Splitting under New York City's 485-x Program*.
It asks how the threshold changes total proposed units when developers can
also divide a parent into separately assessed constituents. The comparison
retains historical size and organization together. A direct mean comparison
measures proposed-unit differences conditional on filing; the joint model
explains design responses under explicit assumptions about regulatory and
organization costs.

The note's empirical facts are linked to the current generated analysis
values through Make. It uses observed historical organization directly,
without a separate historical propensity model. The distribution of unobserved
organization costs remains a choice for structural estimation, which is not
yet implemented. The framework changes are recorded in
[`logbook/entries/2026-09-07-framework.tex`](logbook/entries/2026-09-07-framework.tex).

## Next research priority

The next step is estimating the joint size-and-splitting model in the framework.
The current code produces descriptive distributions, a composition-adjusted
historical benchmark, and bootstrap inference; it does not estimate structural
policy or organization costs. Implementation needs an integer size/partition
solver, an explicit specification for cost heterogeneity and feasible designs,
and estimation against joint size and organization outcomes. Parameter recovery
and identification checks should precede interpretation of fitted costs.

ACS, QCEW, and LODES wage comparisons remain exploratory tasks under
`tasks/audits/`. Further wage-data acquisition, including a NYDOL inquiry, is
deferred while model estimation takes priority.

## Current workflow

Run `make` from a task's `code/` folder. Task Makefiles are the dependency
graph; generated inputs are symlinks to named upstream outputs.

The graph below is generated from the concrete input prerequisites in the task
Makefiles. Arrows show task dependencies; redundant transitive links are omitted
from the display. The Makefiles retain every concrete file prerequisite.

![Production task dependencies](task_graph.svg)

Shared code and Make settings live in `tasks/shared/code/`. Upstream checks
run before consumers compare timestamps. A missing companion output reruns its
producer, including under GNU Make 3.81. Each producing task also builds a
standard report from its saved datasets.

The main empirical compilation is
`tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf`.
The underlying count and normalized-density figures are produced by
`tasks/analyze_parent_unit_distribution/`.

## Production tasks

Top-level tasks are limited to source acquisition/staging, canonical linkage
and parent datasets, predetermined site characteristics, and the current
analysis tasks. In particular:

- `construct_parent_cohorts` defines historical and post-policy economic
  parents and preserves reviewed linkage decisions.
- `build_parent_485x_exposure_universe` assembles the parent-level information
  used for the rental-opportunity screen.
- `link_hpd_485x_registrations` produces the canonical HPD-to-DOB link without
  depending on a unit-count prediction model.
- `build_parent_site_characteristics` aggregates predetermined parcel traits
  used for composition adjustment; it does not predict project unit counts.
- `analyze_parent_unit_distribution` produces the raw, annualized, and
  normalized parent-size distributions.
- `analyze_485x_scale_shape_splitting` produces the current scale, shape,
  reweighting, and multi-filing results.

## Audits

`tasks/audits/` contains validation, case listings, sensitivity analysis, and
exploratory wage and condo comparisons. The adopted exposure classification and
its committed manual-review ledger live in `classify_parent_485x_exposure`.
Its review queue remains in audits. `load_nys_ag_offering_plan_matches` supplies
the recorded Attorney General evidence; the live search remains an audit tool
for deliberate future refreshes.

Earlier parcel-prediction, structural no-notch, cost-calibration, land-price,
and ACRIS/DOF exploration was removed from the active tree during the August
2026 cleanup. It remains recoverable from Git history at commit `1374dda`.

## Builds

- `make` builds the current framework PDF and empirical figure guide.
- `make paper` compiles the draft paper separately. The draft is not the
  dependency root for the current empirical outputs yet.
- `make source-registry` validates source metadata.
- `make -C logbook` compiles the research logbook.

Acquisition tasks own received files in their `output/` directories. The
recorded releases and checksums are explicit. Historical responses from mutable
APIs require the dated original captures under `data_raw/<source>/<vintage>/`;
they cannot be silently replaced with a current query. Source task READMEs
explain that replication boundary. Raw bytes and generated results must not be
edited directly.

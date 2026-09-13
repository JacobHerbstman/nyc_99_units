# NYC 99 Units

This project studies bunching below the 100-unit threshold in New York City's
485-x program and whether developers divide larger projects into constituent
filings. The current production pipeline prepares the parent and constituent
data and produces citywide bunching plots, filing CDFs, borough comparisons,
and a map of exact-99 filings. It does not estimate the joint size-and-organization model.

## Build and outputs

Run `make` at the repository root to build the current plots and maps and
follow their dataset dependencies. `make data` requests just the two final
panels and their reports. The root Makefile orders the tasks; each task's
Makefile decides which files are stale. Individual tasks run from their `code/`
folders using the inputs already prepared. After upstream changes, run Make
from the root.

- Data: `tasks/build_estimation_panels/output/parent_opportunity_panel.parquet`
  and `constituent_filing_panel.parquet`.
- Citywide plots: `tasks/plot_bunching/output/pdf/main_project_plots.pdf`.
- Borough plots and map: `tasks/analyze_borough_bunching/output/borough_bunching.pdf`.

The comparison is 2019–2022 versus January 1, 2025–July 8, 2026. Housing Database
units take priority, with DOB fallback. Outside documentary counts remain
comparison evidence and cannot replace administrative counts. The committed
manual decisions in `parent_opportunities_manual` govern reviewed parent links
and filing roles. The panels retain missingness, refiling dates, and follow-up
coverage; those limitations must be resolved or addressed before estimation.

## Main tasks

There are 18 data-and-figure tasks, plus `setup_environment` for replication.
Their responsibilities are:

| Work | Tasks |
|---|---|
| Acquire the recorded HDB, DOB, HPD, parcel, and borough sources | Five `fetch_*` tasks |
| Load and normalize administrative records and parcel vintages | Three `stage_*` tasks |
| Attach parcel histories and construct parent membership | `build_hdb_mappluto_site_panel`, `construct_historical_parent_links`, `construct_parent_cohorts` |
| Retain reviewed links and source evidence; link registrations and classify exposure | `parent_opportunities_manual`, `link_hpd_485x_registrations`, `classify_parent_485x_exposure` |
| Prepare parent characteristics and final panels | `build_parent_site_characteristics`, `build_estimation_panels` |
| Produce citywide and geographic exhibits | `plot_bunching`, `analyze_borough_bunching` |

Raw loading and staging share folders. Release-calendar and APPBBL preparation
belong to parcel matching; adjacency belongs to historical link construction;
recent filing-field preparation belongs to parent construction; exposure
assembly belongs to classification. Their intermediate files remain traceable
through concrete Make prerequisites.

![Production task dependencies](task_graph.svg)

Shared execution rules and reusable functions live in `tasks/shared/code/`.
The supported Make runtime is GNU Make 3.81. Producers write standard data
reports through `SaveData` when saving datasets. Make targets are the actual
outputs; data reports and execution logs are written during production.
Unchanged builds reuse the recorded source vintage. No main task
depends on an audit task.

## Framework and audits

The joint model is described in `framework_writeup.tex`. `make framework-writeup`
rebuilds the note and its existing empirical illustrations explicitly; those
illustrations use the exploratory scale-and-shape audit and are not part of
the default data-and-plots build. `make paper` and `make logbook` first build the main pipeline, then compile those
documents through their own Makefiles. The logbook command also refreshes the
existing audit outputs cited by its entries.

`tasks/audits/` retains parent-link investigations, wage comparisons, the older
2011–2022 distribution analysis, source-registry checks, and exploratory
reweighting, decomposition, and bootstrap calculations. These remain runnable
research evidence, not prerequisites for the current bunching plots. Build the
main pipeline from the root before running an individual audit against it.

The research decisions and remaining data questions are recorded in `logbook/`.
The structural model has not yet been estimated.

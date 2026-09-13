# NYC 99 Units

Apply the personal research skills: `readable-research-code` for coding style, `research-workflow` for integrity and completion, and `remove-ai-slop` for cleanup. This file adds project facts and build instructions; it does not define an alternative coding standard.

## Research and data

The project studies bunching below the 100-unit threshold under 485-x and the joint decision over parent size and organization into constituent filings. The main pipeline prepares data and descriptive exhibits; it does not yet estimate the joint model. See [README.md](README.md) and `framework_writeup.tex` for the research context.

The canonical panels are produced by `tasks/build_estimation_panels`. Its [README](tasks/build_estimation_panels/README.md) and Makefile define the comparison periods, minimum size, and adopted sample. Preserve those definitions during cleanup.

Housing Database units take priority with DOB fallback. Outside documentary counts are comparison evidence, not administrative overrides. Committed decisions in `tasks/parent_opportunities_manual` govern reviewed links and filing roles. An economic parent is not automatically a verified legal wage-assessment unit. Preserve refiling dates and coverage flags.

Do not use many-to-many joins in active code or suppress cardinality warnings. Resolve duplicate keys upstream using documented source priority or aggregation. Do not use `log1p` or arcsinh in place of logs; exclude zero observations from a logged specification unless explicitly instructed otherwise.

## Build entry points

- Root `make` builds the main plots and maps. `make data`, `make plots`, and `make maps` request narrower products and their dependencies.
- Task-local `make` runs from `code/` against prepared inputs; it does not execute upstream tasks. Use the root entry point after upstream changes.
- Root `make paper`, `make logbook`, and `make framework-writeup` prepare their inputs and compile the documents. Document-local Makefiles use prepared inputs. Do not invoke `latexmk` directly.
- No main data/figure task depends on an audit. Build the main inputs before running an audit; the logbook and framework explicitly consume selected audit results.

Read [shared build behavior](tasks/shared/code/README.md) when changing Make rules. It records the runtime and output dependency conventions; keep the root task graph consistent with concrete task prerequisites. Older audit machinery is not a template for new code.

Use `tasks/setup_environment/code/` for setup; its [README](tasks/setup_environment/README.md) records the verified runtime and required tools. Source snapshots and access procedures belong to their acquisition tasks. Research decisions and unresolved questions belong in `logbook/`.

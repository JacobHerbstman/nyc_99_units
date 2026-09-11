# NYC 99 Units Project Guidelines

## Code Quality Standard
- Working code is not enough. In this repo, clarity, traceability, and simplicity are part of correctness.
- A reader should be able to start from the final paper/report output, follow concrete Makefile prerequisites backward through the pipeline, and understand how each table, figure, dataset, or result is produced without hidden defaults, orchestration scripts, side outputs, or exploratory clutter.
- Prefer boring, linear, explicit code over clever abstractions.
- The Makefile dependency graph is the source of truth. Final documents or reports should depend on task outputs through Make, not manual copying.
- Expose real analytical choices as scalar Make variables: years, samples, bandwidths, outcomes, cutoffs, fixed effects, controls, clustering, and thresholds.
- Fixed task-local file paths belong directly in scripts at the read/write call site, not as command-line arguments.
- Active scripts should run top-to-bottom from the task `code/` folder.
- Production tasks should produce the primary output they exist to produce. Put audits, diagnostics, QC files, logs, manifests, exploratory tables, and diagnostic plots in dedicated audit tasks unless they are actual final outputs.
- Keep output filenames stable, informative, and tied to real specifications. Do not rename outputs casually.
- Before committing a meaningful change, run `make` from each changed task's `code/` folder, confirm incrementality with `make -n`, rebuild the final document/report through its Makefile, run `git diff --check`, review the diff for scope, and commit with a short literal message.

## Data Analysis workflow
- This project uses a task-based workflow. Every task in the paper has a dedicated folder in `tasks/` with its own `code/`, `input/`, and `output/` subfolders.
- Each task should have its own makefile. Each makefile should be as clean and simple as possible to make them readable.
- In makefiles, limit comments and additional targets such as ``clean''. Typical makefiles should only have a default ``all'' target and a ``link-inputs'' target.
- Tasks that run many regression specifications, for example, should call only true specification arguments from the Makefile and use loops in the Makefile to create target filenames for each specification.
  Then the R script should read in those specification arguments from the command line and produce the corresponding output file, named according to the arguments in the Makefile.
  Do not pass fixed task-local input/output file paths as command-line arguments.
- Tasks that use output from ``upstream`` tasks should use symlinking and makefiles to connect them together.
  It should be easy to trace the path out via makefiles from the `data_raw/` folder to final outputs.
- This project follows the logbook/Dingel task workflow: task-local Makefiles declare concrete files, and the root Makefile orders the main tasks. See `tasks/shared/code/README.md`.
- Use root `make paper` for data plus the paper. `make` in `paper/` compiles the paper from the prepared task outputs.

  ## Project Structure
- `paper/` - LaTeX paper and sections
- `slides/` - Presentation slides
- `data_raw/` - Raw data files (not to be modified)
- `tasks/` - Analysis tasks, each with `code/`, `input/`, and `output/` subfolders
- R scripts in `tasks/*/code/` generate outputs (tables, figures) used by the paper

## Compiling the Paper
- Always use `make` in the `paper/` folder to compile LaTeX
- Use version control (e.g., Git) to track changes in both code and paper, leave clear and simple commit messages
- Always execute tasks by running `make` from the `code` folder within any task and make sure all paths are relative
- Do NOT use `latexmk` directly

## Workflow
- When modifying tables/figures, edit the R script that generates them, not the output files directly
- After running R scripts that update outputs, recompile the paper with `make` in `paper/`

## Modeling Guardrails
- Do NOT use `log1p`, inverse-hyperbolic-sine (arcsinh), or similar "zero-handling hacks" in place of log transforms.
- If a logged outcome has zeros, handle them by dropping zero observations for the logged specification unless explicitly instructed otherwise.

## Join Safety Standard
- Never use many-to-many joins in active task code.
- Before joining, validate that the join keys are unique on the side that should be unique, or collapse duplicate keys upstream with explicit source-priority or aggregation logic and QC output.
- Do not silence dplyr many-to-many warnings with `relationship = "many-to-many"`. If `relationship` is used, use it to assert the expected one-to-one, many-to-one, or one-to-many contract.
- If a join would be many-to-many, fix the producer/root data issue first instead of expanding rows downstream.

## Make workflow
- Root `make` checks the main tasks in dependency order. Root `make data` requests the final datasets; `make plots` and `make maps` request those exhibits.
- Task-local `make` builds that task from its declared input files. It does not run upstream tasks. After changing an upstream source or script, build from the root.
- Keep the root task dependencies consistent with the concrete input prerequisites. The generated task graph checks that agreement.
- Main task Makefiles contain the shared execution include, scalar settings, `all`, output rules, input-link rules, `link-inputs`, and the generic include last.
- In `all`, list local intermediate producers before consumers, with reports before their data. Verify missing intermediate reports as well as missing final files.
- Use ordinary explicit or pattern rules for coherent output sets. Shared `.NOTPARALLEL` prevents concurrent writers within a task. Verify missing members, changed inputs, and unchanged second builds on GNU Make 3.81.
- Do not add `check-*` blocks, empty upstream-file rules, `RECOVER`, recursive task builds, stamps, or guarded `readlink` recipes to main task Makefiles.
- Use plain `ln -sf $< $@` with each link depending on its real upstream file. Make compares the referenced file's timestamp, so unchanged builds do not relink it.
- List actual files explicitly. Use release/specification lists and ordinary patterns for real repeated families. Do not introduce generic task runners or Make metaprogramming.
- Generate standard reports in the data producer, using the shared report function on the saved data. A separate report-only script is appropriate for externally acquired source files.
- Never implement Make's incrementality again inside R or Python.

## Makefile Path Style
- Write file paths directly in targets and recipes.
- Do not use path indirection blocks like `*_IN`, `*_UP`, `*_OUT`, `INPUT`, `OUTPUTS`, or similar path alias variables.
- Keep only scalar/config variables in Makefiles (dates, thresholds, flags, spec lists, tool executables).
- Do not pass fixed task-local file paths from Make to R/Python scripts. A fixed input such as `../input/foo.csv` or fixed output such as `../output/bar.csv` should be written directly in the script.
- Makefile command-line arguments are reserved for real analytical variation: specifications, outcomes, fixed-effect choices, clustering choices, samples, periods, control sets, thresholds, or other scalar/config values.
- If a task has no real analytical variation, its Make recipe should usually call the script with no arguments, for example `$(R) $<`.

## RStudio Interactive Block Standard
- For every active R script that accepts CLI arguments, include a top-of-file commented interactive block.
- That block must include:
  - a commented `setwd(...)` line to the task `code/` folder
  - one commented named assignment line per example CLI argument, in CLI order, using the exact variable names used by the script's interactive fallback or CLI unpacking
- Scripts with no CLI arguments should usually include only the commented `setwd(...)` line.
- Do not include a commented `Rscript ...` line in the interactive block.
- Do not include bundled commented argument vectors/lists (for example, no `args <- c(...)` block).
- Do not include placeholder paths such as `tasks/"task"/code`.
- Interactive examples must mirror current Makefile defaults/paths and run end-to-end when uncommented from the task `code/` directory.
- CLI parsing remains canonical for non-interactive runs; interactive blocks are for readability/debugging only.
- For interactive runs, scripts may either unpack CLI args into named variables once near the top or rebuild `args`/`cli_args` from the uncommented named variables before validation.
- Do not use executable `!exists(...)` checks as the bridge between interactive runs and CLI runs; use direct positional-arg validation plus one named unpacking block instead.

## Script Path Style (R + Python)
- Fixed task-local file paths belong directly in active scripts, not in Makefile arguments.
- Avoid path alias variables for simple I/O handoff when direct use is clear.
- Prefer direct call-site reads/writes (`read_csv("../input/foo.csv")`, `write_csv_atomic(df, "../output/bar.csv")`, and R equivalents).
- Keep path handling explicit and local to each read/write call unless reuse materially improves clarity.
- For CLI scripts, use arguments only for real specification/configuration values, not fixed file paths.
- For CLI scripts, keep positional `args[i]` or `cli_args[i]` as the canonical Make interface for those specification/configuration values, then introduce one short top-of-script unpacking block to named variables when that makes interactive execution clearer.
- Do not create `in_*`, `out_*`, or similar path variables solely to shuttle fixed task-local paths from the top of the script to the read/write call. Use direct paths at the call site unless the same path is reused enough that a local variable materially improves readability.
- Do not use `normalizePath()` in active task scripts for standard Make-managed inputs/outputs; keep task paths relative and direct.
- Do not use `dir.create()` in active task scripts for standard task `input/`, `output/`, or `temp/` directories; Make should own directory creation.

## Linear Active Script Standard
- For non-archived active tasks, prefer scripts that run top-to-bottom in a linear, readable sequence once the user is in the task `code/` folder.
- Inline one-off cleaning, merge, transformation, modeling, and export steps instead of wrapping them in local helper functions.
- Use functions in active scripts only when logic is clearly reused within that same script and duplication would materially hurt readability.
- Do not leave the main active script as a thin wrapper around one large helper pipeline.
- Put genuinely reusable cross-task helpers in `tasks/shared/code`.
- Allow a task-family helper file only when multiple active sibling scripts share substantial logic and moving it to `tasks/shared/code` would be less clear.
- When refactoring for readability, preserve current methods and outputs unless fixing a confirmed bug.

## Root-Cause First (No Shortcuts)
- Do not bypass missing dependencies with wildcard hacks, dummy targets, or optionalized prerequisite checks.
- Do not use forwarding wrappers (for example, an R script that only calls `python3 some_script.py`).
- Do not add placeholder smoke targets.
- No silent fallback branches. If a secondary source is required, make source-priority logic explicit with row-level reason codes and deterministic unresolved/manual-review outputs.
- Fix producer/root data issues upstream rather than suppressing validation downstream.

## Environment Setup Conventions
- Keep `tasks/setup_environment/code/` as the bootstrap entry point.
- Keep package bootstrap scripts (R/Stata) current and log installed package versions.
- Reuse `run.sbatch` where SLURM execution is needed; symlink it only in tasks that actually require it.

## Terse/Clear Code Preference
- Prefer simpler argument parsing and fewer helper abstractions when they do not improve clarity.
- Keep scripts short, direct, and clearly mapped to Makefile arguments and outputs.
- Avoid unnecessary indirection so readers can trace input -> transform -> output quickly.

## Collaboration Preferences
- Keep commit messages clear and minimal.
- When changing a figure/table, edit the generating script and rerun the relevant task.
- Prefer incremental, testable changes over large rewrites.

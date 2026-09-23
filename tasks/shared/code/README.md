# Shared code

Task scripts own the data transformations. This directory contains reused cleaning functions, data saving and reporting, execution settings, and directory rules.

Root `make` checks the main tasks in dependency order. Each task runs once per root invocation, and its own Makefile decides which files need rebuilding. Use `make data`, `make plots`, or `make maps` for a narrower end-to-end build. Task-local `make` uses the declared inputs as they stand; it does not inspect another task's scripts. After upstream edits, run the root build.

A main task Makefile contains the execution include, `all` listing actual outputs, the generic include, output recipes, and plain `ln -sf $< $@` input links. Scripts, data, sourced helpers, and the task Makefile are concrete prerequisites. Release lists and patterns represent real file families. `generic.make` supplies directory rules and `OOPR`, the standard order-only prerequisites.

A producer declares its actual output files in one ordinary rule. `.NOTPARALLEL` prevents concurrent writers within each task on GNU Make 3.81, including when the root is invoked with `-j`. Within a task, `all` lists local intermediate producers before their consumers. Check fresh builds, changed inputs, and missing actual outputs when changing these rules. Cross-task execution belongs to the root Makefile; audits follow the same conventions.

`SaveData(data, keys, output_file)` in `write_data_report.R` writes CSV or Parquet data and its deterministic summary in `../report/`. It retains row order, file representation, saved-file fingerprints, and the declared key checks. The shared `copy_data.R` copies received CSV files byte for byte and writes their reports; borough acquisition validates and publishes its received GeoJSON. Data reports are side effects of producing these files and are not Make targets or prerequisites. To recreate a deleted report, explicitly rerun its data producer.

`shell_functions.make` and `shell_functions.sh` provide `$(R)`. Local R execution writes the script's latest console log to `code/<script>.log`, ignored by Git, and propagates failures through the logging pipe. SLURM execution uses the scheduler's logs. Execution logs are side effects, not Make targets.

`SaveData` checks the saved data and writes its report before publishing the completed temporary dataset by renaming it. Downloads publish only after transfer and checksum verification. The source snapshots are fixed; a source refresh requires an explicit vintage and checksum change.

Fixed specifications are written directly in the tracked recipes. Change the recipe to change a specification at the same output filename. Specifications encoded in filenames, such as parcel releases and plot measures, have separate targets. After changing shared execution settings, use `make -B` on the affected derived tasks; scientific helpers are ordinary tracked prerequisites.

The date parser's upper validity bound is September 9, 2027, preserving the earlier rule without dependence on the computer clock. Review that explicit bound when refreshing sources.

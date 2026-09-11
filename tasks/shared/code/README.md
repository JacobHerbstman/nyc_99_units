# Shared code

Task scripts own the data transformations. This directory contains reused cleaning functions, atomic writers, the standard data report, execution settings, and directory rules.

Root `make` checks the main tasks in dependency order. Each task runs once per root invocation, and its own Makefile decides which files need rebuilding. Use `make data`, `make plots`, or `make maps` for a narrower end-to-end build. Task-local `make` uses the declared inputs as they stand; it does not inspect another task's scripts. After upstream edits, run the root build.

A main task Makefile starts with the execution include, then settings and `all`, output rules, input-link rules, `link-inputs`, and the generic include last. Inputs use plain `ln -sf $< $@`. Unchanged inputs do not run that recipe. Actual datasets and sourced helpers remain concrete prerequisites. Release lists expand real vintages; they do not replace file dependencies with task-wide gates.

A coherent producer declares all its files in one ordinary rule and writes its standard reports from the saved datasets. Real sample or release families use ordinary pattern rules. `.NOTPARALLEL` prevents concurrent writers within each task on GNU Make 3.81, including when the root is invoked with `-j`. Check fresh builds, changed inputs, and missing outputs when changing these rules. Within a task, `all` lists local intermediate producers before their consumers, with each producer's report before its data file. This makes a missing report rebuild the producer before a downstream timestamp is cached by Make 3.81. There are no recursive checks or recovery commands in main task Makefiles. Older audit Makefiles retain their existing conventions; `RECOVER` remains available only for those consumers.

The atomic writers publish completed temporary files by renaming them. They do not decide whether an output is stale. Downloads likewise publish only after transfer and checksum verification. The source snapshots are fixed; a source refresh requires an explicit vintage and checksum change.

Settings for fixed-name outputs belong in the tracked task Makefile. Command-line overrides are rejected because Make cannot otherwise distinguish a previous specification at the same filename. Specifications encoded in filenames, such as parcel releases and plot measures, have separate targets. After changing shared execution settings, use `make -B` on the affected derived tasks; scientific helpers are ordinary tracked prerequisites.

The date parser's upper validity bound is September 9, 2027, preserving the earlier rule without dependence on the computer clock. Review that explicit bound when refreshing sources.

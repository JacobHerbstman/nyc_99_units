SHELL := bash

all: ../output/simple_logit_time_window_specs.csv \
	../output/simple_logit_time_window_status.csv \
	../output/simple_logit_time_split_summary.csv \
	../output/simple_logit_time_split_tiers.csv \
	../output/simple_logit_time_split_contrast.csv \
	../output/simple_logit_time_split_examples.csv \
	../output/simple_logit_reference_coefficients.csv

../output/simple_logit_time_window_specs.csv: audit_simple_logit_time_splits.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $<

../output/simple_logit_time_window_status.csv ../output/simple_logit_time_split_summary.csv ../output/simple_logit_time_split_tiers.csv ../output/simple_logit_time_split_contrast.csv ../output/simple_logit_time_split_examples.csv ../output/simple_logit_reference_coefficients.csv: ../output/simple_logit_time_window_specs.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet

include ../../generic.make

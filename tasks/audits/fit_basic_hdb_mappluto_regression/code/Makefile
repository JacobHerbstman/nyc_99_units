SHELL := bash

all: ../output/basic_logit_coefficients.csv \
	../output/basic_log_units_coefficients.csv \
	../output/basic_units_coefficients.csv \
	../output/basic_regression_fit_summary.csv \
	../output/basic_regression_sample_by_year.csv \
	../output/basic_regression_feature_summary.csv

../output/basic_logit_coefficients.csv: fit_basic_hdb_mappluto_regression.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $<

../output/basic_log_units_coefficients.csv ../output/basic_units_coefficients.csv ../output/basic_regression_fit_summary.csv ../output/basic_regression_sample_by_year.csv ../output/basic_regression_feature_summary.csv: ../output/basic_logit_coefficients.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet

include ../../generic.make

SHELL := bash

all: ../output/hdb_mappluto_training_panel_counts_by_year.csv \
	../output/hdb_mappluto_training_panel_exclusion_reasons.csv \
	../output/hdb_mappluto_training_panel_vintage_use.csv \
	../output/hdb_mappluto_training_panel_feature_missingness.csv \
	../output/hdb_mappluto_training_panel_duplicate_bbl_jobs.csv \
	../output/hdb_mappluto_training_panel_2023_comparison.csv \
	../output/hdb_mappluto_training_panel_latest_vs_lag1.csv

../output/hdb_mappluto_training_panel_counts_by_year.csv: summarize_hdb_mappluto_training_panel.R ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_lot_files.csv | ../output
	$(R) $<

../output/hdb_mappluto_training_panel_exclusion_reasons.csv ../output/hdb_mappluto_training_panel_vintage_use.csv ../output/hdb_mappluto_training_panel_feature_missingness.csv ../output/hdb_mappluto_training_panel_duplicate_bbl_jobs.csv ../output/hdb_mappluto_training_panel_2023_comparison.csv ../output/hdb_mappluto_training_panel_latest_vs_lag1.csv: ../output/hdb_mappluto_training_panel_counts_by_year.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_lot_files.csv

include ../../generic.make

SHELL := bash

all: ../output/condo_recovery_summary.csv \
	../output/unmatched_hdb_condo_audit.csv \
	../output/condo_crosswalk_candidates.csv \
	../output/condo_match_resolution.csv \
	../output/accepted_condo_matches.csv \
	../output/condo_recovered_sample_comparison.csv \
	../output/condo_recovery_status_by_window.csv \
	../output/condo_recovery_status_by_year.csv \
	../output/condo_recovery_status_by_borough.csv \
	../output/duplicate_feature_bbl_groups.csv \
	../output/large_unresolved_no_match_examples.csv

../output/condo_recovery_summary.csv: audit_hdb_mappluto_condo_recovery.R ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_lot_files.csv ../input/mappluto_files.csv | ../output
	$(R) $<

../output/unmatched_hdb_condo_audit.csv ../output/condo_crosswalk_candidates.csv ../output/condo_match_resolution.csv ../output/accepted_condo_matches.csv ../output/condo_recovered_sample_comparison.csv ../output/condo_recovery_status_by_window.csv ../output/condo_recovery_status_by_year.csv ../output/condo_recovery_status_by_borough.csv ../output/duplicate_feature_bbl_groups.csv ../output/large_unresolved_no_match_examples.csv: ../output/condo_recovery_summary.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/mappluto_lot_files.csv ../input/mappluto_files.csv

include ../../generic.make

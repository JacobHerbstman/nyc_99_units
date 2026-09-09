include ../../../shared/code/shell_functions.make

all: ../output/condo_recovery_status_by_borough.csv ../output/condo_recovery_summary.csv \
	../output/unmatched_hdb_condo_audit.csv \
	../output/condo_crosswalk_candidates.csv \
	../output/condo_match_resolution.csv \
	../output/accepted_condo_matches.csv \
	../output/condo_recovered_sample_comparison.csv \
	../output/condo_recovery_status_by_window.csv \
	../output/condo_recovery_status_by_year.csv \
	\
	../output/duplicate_feature_bbl_groups.csv \
	../output/large_unresolved_no_match_examples.csv

../output/condo_recovery_status_by_borough.csv: audit_hdb_mappluto_condo_recovery.R \
	../../../shared/code/source_pipeline_utils.R ../input/hdb_mappluto_site_panel.parquet \
	../input/mappluto_lot_files.csv ../input/mappluto_files.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/condo_recovery_summary.csv \
	../output/unmatched_hdb_condo_audit.csv \
	../output/condo_crosswalk_candidates.csv \
	../output/condo_match_resolution.csv \
	../output/accepted_condo_matches.csv \
	../output/condo_recovered_sample_comparison.csv \
	../output/condo_recovery_status_by_window.csv \
	../output/condo_recovery_status_by_year.csv \
	../output/duplicate_feature_bbl_groups.csv \
	../output/large_unresolved_no_match_examples.csv: ../output/condo_recovery_status_by_borough.csv
	$(MAKE) -W audit_hdb_mappluto_condo_recovery.R all

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_site_panel.parquet ../input/mappluto_lot_files.csv ../input/mappluto_files.csv

../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../../../stage_mappluto_lots/output/mappluto_lot_files.csv: check-stage_mappluto_lots ;

.PHONY: check-stage_mappluto_lots

check-stage_mappluto_lots:
	$(MAKE) -C ../../../stage_mappluto_lots/code all ../output/mappluto_lot_files.csv

../../../fetch_mappluto_archive/output/mappluto_files.csv: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../../fetch_mappluto_archive/code all ../output/mappluto_files.csv

include ../../../shared/code/generic.make

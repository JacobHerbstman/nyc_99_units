include ../../../shared/code/shell_functions.make

all: ../output/numerical_checks.csv ../output/input_provenance.csv ../output/analysis_parents.csv \
	../output/observed_double_crossers.csv ../output/parameter_grid.csv ../output/joint_cell_predictions.csv \
	../output/best_fits.csv ../output/best_parent_contributions.parquet ../output/fit_diagnostics.csv ../output/synthetic_recovery.csv \
	../output/near_notch_sensitivity.csv ../output/pilot_values.tex ../output/fit_overview.png ../output/pdf/fit_overview.pdf \
	../output/parameter_profiles.png ../output/pdf/parameter_profiles.pdf \
	../output/multilot_weight_comparison.csv ../output/multilot_parameter_grid.csv \
	../output/multilot_distribution_comparison.csv ../output/multilot_fit_comparison.csv \
	../output/unit_gap_by_size.csv ../output/unit_gap_by_size.png ../output/pdf/unit_gap_by_size.pdf \
	../output/post_three_plus_parents.csv ../output/local_unit_effects.csv \
	../output/bunching_unit_illustration.csv ../output/tail_count_uncertainty.csv ../output/historical_tail_by_year.csv

all: ../output/stack_parcel_filings.csv ../output/stack_reviewed_lots.csv \
	../output/stack_parcel_summary.csv ../output/stack_acris_documents.csv

include ../../../shared/code/generic.make

../output/numerical_checks.csv: test_pure_notch.R ../../../shared/code/pure_notch_model.R \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/input_provenance.csv ../output/analysis_parents.csv ../output/observed_double_crossers.csv \
	../output/parameter_grid.csv ../output/joint_cell_predictions.csv ../output/best_fits.csv \
	../output/best_parent_contributions.parquet ../output/synthetic_recovery.csv \
	../output/near_notch_sensitivity.csv ../output/fit_diagnostics.csv ../output/pilot_values.tex: \
	fit_pilot.R ../../../shared/code/pure_notch_model.R \
	../../../shared/code/write_data_report.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet ../input/calibration_weights.csv \
	../input/calibration_summary.csv ../output/numerical_checks.csv Makefile | $(OOPR)
	$(R) $<

../output/fit_overview.png ../output/pdf/fit_overview.pdf ../output/parameter_profiles.png \
	../output/pdf/parameter_profiles.pdf: plot_pilot.R ../output/analysis_parents.csv \
	../output/parameter_grid.csv ../output/joint_cell_predictions.csv ../output/best_fits.csv \
	../output/best_parent_contributions.parquet Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/multilot_weight_comparison.csv ../output/multilot_parameter_grid.csv \
	../output/multilot_distribution_comparison.csv ../output/multilot_fit_comparison.csv: \
	compare_multilot_weights.R ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/pure_notch_model.R ../../../shared/code/write_data_report.R \
	../input/parent_opportunity_panel.parquet ../output/analysis_parents.csv \
	../output/parameter_grid.csv ../output/fit_diagnostics.csv Makefile | $(OOPR)
	$(R) $<

../output/unit_gap_by_size.csv ../output/unit_gap_by_size.png ../output/pdf/unit_gap_by_size.pdf \
	../output/post_three_plus_parents.csv: \
	decompose_unit_gap.R ../../../shared/code/write_data_report.R ../output/analysis_parents.csv Makefile | $(OOPR) ../output/pdf
	$(R) $<

../output/local_unit_effects.csv ../output/bunching_unit_illustration.csv \
	../output/tail_count_uncertainty.csv ../output/historical_tail_by_year.csv: \
	summarize_local_effects.R ../../../shared/code/write_data_report.R ../output/analysis_parents.csv \
	../output/best_fits.csv ../output/best_parent_contributions.parquet \
	../input/bootstrap_intervals.csv ../input/bootstrap_run_summary.csv Makefile | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet ../input/constituent_filing_panel.parquet: \
	../input/%: ../../../build_estimation_panels/output/% | ../input
	ln -sf $< $@

../input/calibration_weights.csv ../input/calibration_summary.csv \
	../input/bootstrap_intervals.csv ../input/bootstrap_run_summary.csv: \
	../input/%: ../../audit_scale_shape_splitting/output/% | ../input
	ln -sf $< $@

../output/stack_parcel_filings.csv ../output/stack_reviewed_lots.csv \
	../output/stack_parcel_summary.csv ../output/stack_acris_documents.csv: \
	review_stack_parcels.R stack_source_lots.csv stack_case_review.csv \
	../../../shared/code/write_data_report.R ../output/post_three_plus_parents.csv \
	../input/parent_opportunity_panel.parquet ../input/constituent_filing_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet ../input/pluto_26v2.json \
	../input/acris_legals.json ../input/acris_master.json Makefile | $(OOPR)
	$(R) $<

../input/dob_now_new_building_initial_filings.parquet: \
	../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/hdb_mappluto_site_panel.parquet: \
	../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_mappluto_archive_23v3_1.parquet: \
	../../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	ln -sf $< $@

../input/pluto_26v2.json ../input/acris_legals.json ../input/acris_master.json: \
	../input/%: ../../download_parent_review_documents/code/stack_parcels_2026-09-14/% | ../input
	ln -sf $< $@

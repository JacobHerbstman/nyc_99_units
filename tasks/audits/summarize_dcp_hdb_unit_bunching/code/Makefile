include ../../../shared/code/shell_functions.make

all: ../output/dcp_hdb_unit_bunching_year_summary.csv \
	../output/dcp_hdb_unit_bunching_period_summary.csv \
	../output/dcp_hdb_unit_bunching_exact_counts.csv \
	../output/dcp_hdb_unit_bunching_sample_qc.csv \
	../output/dcp_hdb_unit_bunching_pre_post_exact_comparison.csv \
	../output/dcp_hdb_unit_bunching_top_spikes.csv \
	../output/dcp_hdb_unit_bunching_near_threshold_by_year.csv \
	../output/dcp_hdb_unit_bunching_date_basis_sensitivity.csv \
	../output/dcp_hdb_unit_bunching_status_sensitivity.csv \
	../output/dcp_hdb_unit_bunching_pre_period_sensitivity.csv \
	../output/dcp_hdb_unit_bunching_pre_period_cut_plot_counts.csv \
	../output/dcp_hdb_unit_bunching_2024_2025_monthly_99.csv \
	../output/dcp_hdb_unit_bunching_2025_99_applications.csv \
	../output/dcp_hdb_unit_bunching_2025_99_geography.csv \
	../output/dcp_hdb_unit_bunching_duplicate_site_qc.csv \
	../output/dcp_hdb_unit_bunching_pre_post_exact.pdf \
	../output/dcp_hdb_unit_bunching_pre_post_histogram.pdf \
	../output/dcp_hdb_unit_bunching_pre_period_cut_exact.pdf \
	../output/dcp_hdb_unit_bunching_pre_period_cut_histogram.pdf \
	../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf \
	../output/dcp_hdb_unit_bunching_year_start.pdf

../output/dcp_hdb_unit_bunching_year_summary.csv: summarize_dcp_hdb_unit_bunching.R \
	../../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet Makefile \
	| ../output \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh
	$(R) $<

../output/dcp_hdb_unit_bunching_period_summary.csv ../output/dcp_hdb_unit_bunching_exact_counts.csv ../output/dcp_hdb_unit_bunching_sample_qc.csv ../output/dcp_hdb_unit_bunching_pre_post_exact_comparison.csv ../output/dcp_hdb_unit_bunching_top_spikes.csv ../output/dcp_hdb_unit_bunching_near_threshold_by_year.csv ../output/dcp_hdb_unit_bunching_date_basis_sensitivity.csv ../output/dcp_hdb_unit_bunching_status_sensitivity.csv ../output/dcp_hdb_unit_bunching_pre_period_sensitivity.csv ../output/dcp_hdb_unit_bunching_pre_period_cut_plot_counts.csv ../output/dcp_hdb_unit_bunching_2024_2025_monthly_99.csv ../output/dcp_hdb_unit_bunching_2025_99_applications.csv ../output/dcp_hdb_unit_bunching_2025_99_geography.csv ../output/dcp_hdb_unit_bunching_duplicate_site_qc.csv ../output/dcp_hdb_unit_bunching_pre_post_exact.pdf ../output/dcp_hdb_unit_bunching_pre_post_histogram.pdf ../output/dcp_hdb_unit_bunching_pre_period_cut_exact.pdf ../output/dcp_hdb_unit_bunching_pre_period_cut_histogram.pdf ../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf ../output/dcp_hdb_unit_bunching_year_start.pdf: ../output/dcp_hdb_unit_bunching_year_summary.csv
	$(RECOVER) -W summarize_dcp_hdb_unit_bunching.R all

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet

../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_25q4.parquet

include ../../../shared/code/generic.make

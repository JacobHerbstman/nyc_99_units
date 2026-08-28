SHELL := bash
include ../../shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
POST_START_DATE := 2025-01-01
MIN_UNITS := 80
MAX_UNITS := 120
ZOOM_MIN_UNITS := 50
ZOOM_MAX_UNITS := 150
WIDE_MAX_UNITS := 300
FULL_BIN_WIDTH := 25

all: ../output/parent_unit_distribution_80_120.csv \
	../output/parent_unit_distribution_sample_summary.csv \
	../output/post_99_next_observed_unit_audit.csv \
	../output/post_105_parent_cases.csv \
	../output/parent_unit_distribution_total_80_120.png \
	../output/parent_unit_distribution_annualized_80_120.png \
	../output/parent_unit_distribution_exposure_80_120.csv \
	../output/parent_unit_distribution_exposure_sample_summary.csv \
	../output/parent_unit_distribution_exposure_total_80_120.png \
	../output/parent_unit_distribution_exposure_annualized_80_120.png \
	../output/parent_unit_distribution_full.csv \
	../output/parent_unit_distribution_full_histogram_bins.csv \
	../output/parent_unit_distribution_exposure_50_150.csv \
	../output/parent_unit_distribution_annualized_50_300.csv \
	../output/parent_unit_distribution_normalized_density_50_300_ab.csv \
	../output/parent_unit_distribution_full_histogram_total.png \
	../output/parent_unit_distribution_full_histogram_annualized.png \
	../output/parent_unit_distribution_full_line_total.png \
	../output/parent_unit_distribution_full_line_annualized.png \
	../output/parent_unit_distribution_exposure_histogram_total_50_150.png \
	../output/parent_unit_distribution_exposure_histogram_annualized_50_150.png \
	../output/parent_unit_distribution_exposure_line_total_50_150.png \
	../output/parent_unit_distribution_exposure_line_annualized_50_150.png \
	../output/pdf/parent_unit_distribution_annualized_50_300.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_all.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2014.pdf \
	../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2011_2022.pdf \
	../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2019_2022.pdf \
	../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2019_2022.pdf

../output/parent_unit_distribution_80_120.csv: plot_parent_unit_distribution.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/dob_now_new_building_filings.parquet \
	../input/parent_485x_exposure.csv | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS) $(MAX_UNITS)

../output/parent_unit_distribution_sample_summary.csv \
../output/post_99_next_observed_unit_audit.csv \
../output/post_105_parent_cases.csv \
../output/parent_unit_distribution_total_80_120.png \
../output/parent_unit_distribution_annualized_80_120.png \
../output/parent_unit_distribution_exposure_80_120.csv \
../output/parent_unit_distribution_exposure_sample_summary.csv \
../output/parent_unit_distribution_exposure_total_80_120.png \
../output/parent_unit_distribution_exposure_annualized_80_120.png: ../output/parent_unit_distribution_80_120.csv
	@test -s "$@"

../output/parent_unit_distribution_full.csv: plot_parent_unit_distribution_views.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/parent_485x_exposure.csv | ../output ../output/pdf
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(ZOOM_MIN_UNITS) $(ZOOM_MAX_UNITS) $(WIDE_MAX_UNITS) \
		$(FULL_BIN_WIDTH)

../output/parent_unit_distribution_full_histogram_bins.csv \
../output/parent_unit_distribution_exposure_50_150.csv \
../output/parent_unit_distribution_annualized_50_300.csv \
../output/parent_unit_distribution_normalized_density_50_300_ab.csv \
../output/parent_unit_distribution_full_histogram_total.png \
../output/parent_unit_distribution_full_histogram_annualized.png \
../output/parent_unit_distribution_full_line_total.png \
../output/parent_unit_distribution_full_line_annualized.png \
../output/parent_unit_distribution_exposure_histogram_total_50_150.png \
../output/parent_unit_distribution_exposure_histogram_annualized_50_150.png \
../output/parent_unit_distribution_exposure_line_total_50_150.png \
../output/parent_unit_distribution_exposure_line_annualized_50_150.png \
../output/pdf/parent_unit_distribution_annualized_50_300.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_all.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_ab.pdf \
../output/pdf/parent_unit_distribution_normalized_density_50_300_ab.pdf \
../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2022.pdf \
../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2011_2014.pdf \
../output/pdf/parent_unit_distribution_normalized_density_50_300_ab_post_vs_2019_2022.pdf \
../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2011_2022.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2011_2022.pdf \
../output/pdf/parent_unit_distribution_total_50_300_ab_post_vs_2019_2022.pdf \
../output/pdf/parent_unit_distribution_annualized_50_300_ab_post_vs_2019_2022.pdf: ../output/parent_unit_distribution_full.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure.csv: ../../audits/audit_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/dob_now_new_building_filings.parquet \
	../input/parent_485x_exposure.csv

../output/pdf:
	mkdir -p $@

include ../../generic.make

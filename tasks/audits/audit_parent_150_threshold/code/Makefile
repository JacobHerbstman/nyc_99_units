SHELL := bash
include ../../../shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
NORMAL_START_YEAR := 2017
NORMAL_END_YEAR := 2019
POST_START_DATE := 2025-01-01
THRESHOLD_UNITS := 150
PLOT_MIN_UNITS := 100
PLOT_MAX_UNITS := 250

all: ../output/parent_150_period_summary.csv \
	../output/parent_150_exact_distribution.csv \
	../output/parent_150_component_exact_distribution.csv \
	../output/parent_150_parent_component_comparison.csv \
	../output/parent_150_post_composition.csv \
	../output/parent_150_borough_comparison.csv \
	../output/parent_150_ownership_comparison.csv \
	../output/parent_150_post_parent_cases.csv \
	../output/parent_150_hpd_registration_qc.csv \
	../output/parent_150_linkage_qc.csv \
	../output/parent_150_yearly_linkage_diagnostic.csv \
	../output/parent_150_exact_distribution_annualized.png \
	../output/parent_150_component_exact_distribution_annualized.png \
	../output/parent_150_borough_comparison_annualized.png \
	../output/parent_150_yearly_multi_filing_share.png

../output/parent_150_period_summary.csv: audit_parent_150_threshold.R \
	Makefile \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv \
	../input/hpd_485x_registration_dob_links.csv \
	../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(NORMAL_START_YEAR) \
		$(NORMAL_END_YEAR) $(POST_START_DATE) $(THRESHOLD_UNITS) \
		$(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS)

../output/parent_150_exact_distribution.csv \
../output/parent_150_component_exact_distribution.csv \
../output/parent_150_parent_component_comparison.csv \
../output/parent_150_post_composition.csv \
../output/parent_150_borough_comparison.csv \
../output/parent_150_ownership_comparison.csv \
../output/parent_150_post_parent_cases.csv \
../output/parent_150_hpd_registration_qc.csv \
../output/parent_150_linkage_qc.csv \
../output/parent_150_yearly_linkage_diagnostic.csv \
../output/parent_150_exact_distribution_annualized.png \
../output/parent_150_component_exact_distribution_annualized.png \
../output/parent_150_borough_comparison_annualized.png \
../output/parent_150_yearly_multi_filing_share.png: ../output/parent_150_period_summary.csv
	@test -s "$@"

../input/parent_485x_exposure.csv: ../../audit_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure_universe.csv: ../../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../audit_hpd_485x_registration_linkage/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv \
	../input/hpd_485x_registration_dob_links.csv \
	../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make

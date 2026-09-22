include ../../../shared/code/shell_functions.make

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

../output/parent_150_period_summary.csv: audit_parent_150_threshold.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv ../input/hpd_485x_registration_dob_links.csv \
	../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
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
	$(RECOVER) -W audit_parent_150_threshold.R all

../input/parent_485x_exposure.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure_universe.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
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

../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure.csv

../../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

../../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv: check-link_hpd_485x_registrations ;

.PHONY: check-link_hpd_485x_registrations

check-link_hpd_485x_registrations:
	$(MAKE) -C ../../../link_hpd_485x_registrations/code all ../output/hpd_485x_registration_dob_links.csv

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

include ../../../shared/code/generic.make

include ../../shared/code/shell_functions.make

PRE_START_DATE := 2019-01-01

PRE_END_DATE := 2022-12-31

POST_START_DATE := 2025-01-01

POST_END_DATE := 2026-07-08

MINIMUM_UNITS := 6

NEAR_99_MINIMUM := 95

ifneq ($(filter command,$(origin PRE_START_DATE) $(origin PRE_END_DATE) $(origin POST_START_DATE) $(origin POST_END_DATE) $(origin MINIMUM_UNITS) $(origin NEAR_99_MINIMUM)),)

$(error These fixed-name outputs use the settings in this Makefile; edit them here so Make tracks the change)

endif

all: ../output/parent_opportunity_panel.parquet ../output/constituent_filing_panel.parquet \
	../report/parent_opportunity_panel.txt ../report/constituent_filing_panel.txt

../output/parent_opportunity_panel.parquet: construct_scale_shape_splitting_panels.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/parent_485x_exposure.csv ../input/parent_485x_exposure_universe.csv \
	../input/hpd_485x_registration_dob_links.csv ../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PRE_START_DATE) $(PRE_END_DATE) $(POST_START_DATE) \
		$(POST_END_DATE) $(MINIMUM_UNITS) $(NEAR_99_MINIMUM)

../output/constituent_filing_panel.parquet: ../output/parent_opportunity_panel.parquet
	$(RECOVER) -W construct_scale_shape_splitting_panels.R all

../report/parent_opportunity_panel.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/parent_opportunity_panel.parquet Makefile | ../report
	$(R) $< parent_opportunity_panel

../report/constituent_filing_panel.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/constituent_filing_panel.parquet Makefile | ../report
	$(R) $< constituent_filing_panel

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure.csv: ../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure_universe.csv: \
	../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: \
	../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_site_characteristics.parquet: \
	../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_parent_site_characteristics.parquet: \
	../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure.csv

.PHONY: check-link_hpd_485x_registrations

check-link_hpd_485x_registrations:
	$(MAKE) -C ../../link_hpd_485x_registrations/code all ../output/hpd_485x_registration_dob_links.csv

.PHONY: check-build_parent_site_characteristics

check-build_parent_site_characteristics:
	$(MAKE) -C ../../build_parent_site_characteristics/code all \
	../output/historical_parent_site_characteristics.parquet ../output/post_policy_parent_site_characteristics.parquet

../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

../../classify_parent_485x_exposure/output/parent_485x_exposure.csv \
	../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv: check-classify_parent_485x_exposure ;

../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv: check-link_hpd_485x_registrations ;

../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet \
	../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet: check-build_parent_site_characteristics ;

link-inputs: ../input/symmetric_parent_membership.parquet ../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv ../input/hpd_485x_registration_dob_links.csv \
	../input/historical_parent_site_characteristics.parquet ../input/post_policy_parent_site_characteristics.parquet

include ../../shared/code/generic.make

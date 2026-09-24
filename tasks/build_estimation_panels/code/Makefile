include ../../shared/code/shell_functions.make

all: ../output/parent_opportunity_panel.parquet ../output/constituent_filing_panel.parquet

include ../../shared/code/generic.make

../output/constituent_filing_panel.parquet ../output/parent_opportunity_panel.parquet: \
	build_estimation_panels.R Makefile ../input/symmetric_parent_membership.parquet ../input/parent_485x_exposure.csv \
	../input/parent_485x_exposure_universe.csv ../input/hpd_485x_registration_dob_links.csv \
	../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet | $(OOPR)
	$(R) $< 2019-01-01 2022-12-31 2025-01-01 2026-07-08 6

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/parent_485x_exposure.csv: ../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | \
	../input
	ln -sf $< $@

../input/parent_485x_exposure_universe.csv: \
	../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv | ../input
	ln -sf $< $@

../input/hpd_485x_registration_dob_links.csv: \
	../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	ln -sf $< $@

../input/historical_parent_site_characteristics.parquet: \
	../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet | ../input
	ln -sf $< $@

../input/post_policy_parent_site_characteristics.parquet: \
	../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet | ../input
	ln -sf $< $@

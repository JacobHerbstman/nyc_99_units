include ../../shared/code/shell_functions.make

all: ../output/parent_485x_exposure.csv \
	../report/parent_485x_exposure.txt

../output/parent_485x_exposure.csv: classify_parent_485x_exposure.R parent_exposure_manual_reviews.csv \
	../../shared/code/source_pipeline_utils.R ../input/parent_485x_exposure_universe.csv \
	../input/nys_ag_offering_plan_search_audit.csv ../input/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<


../report/parent_485x_exposure.txt: report_data.R ../../shared/code/write_data_report.R ../output/parent_485x_exposure.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure


../input/parent_485x_exposure_universe.csv: ../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_search_audit.csv: ../../load_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_search_audit.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_matches.csv: ../../load_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_matches.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv: check-build_parent_485x_exposure_universe ;

.PHONY: check-build_parent_485x_exposure_universe

check-build_parent_485x_exposure_universe:
	$(MAKE) -C ../../build_parent_485x_exposure_universe/code all ../output/parent_485x_exposure_universe.csv

../../load_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_search_audit.csv \
	../../load_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_matches.csv: check-load_nys_ag_offering_plan_matches ;

.PHONY: check-load_nys_ag_offering_plan_matches

check-load_nys_ag_offering_plan_matches:
	$(MAKE) -C ../../load_nys_ag_offering_plan_matches/code all ../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv

../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv: check-link_hpd_485x_registrations ;

.PHONY: check-link_hpd_485x_registrations

check-link_hpd_485x_registrations:
	$(MAKE) -C ../../link_hpd_485x_registrations/code all ../output/hpd_485x_registration_dob_links.csv

include ../../shared/code/generic.make

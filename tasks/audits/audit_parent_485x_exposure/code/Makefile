SHELL := bash
include ../../../shell_functions.make

all: ../output/parent_485x_exposure.csv \
	../output/parent_485x_exposure_summary.csv \
	../output/parent_485x_exposure_by_unit.csv \
	../output/parent_485x_exposure_review_queue.csv

../output/parent_485x_exposure.csv: classify_parent_485x_exposure.R \
	parent_exposure_manual_reviews.csv \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_485x_exposure_universe.csv \
	../input/nys_ag_offering_plan_search_audit.csv \
	../input/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv | ../output
	$(R) $<

../output/parent_485x_exposure_summary.csv \
../output/parent_485x_exposure_by_unit.csv \
../output/parent_485x_exposure_review_queue.csv: ../output/parent_485x_exposure.csv
	@test -s "$@"

../input/parent_485x_exposure_universe.csv: ../../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_search_audit.csv: ../../../fetch_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_search_audit.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_matches.csv: ../../../fetch_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_matches.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../audit_hpd_485x_registration_linkage/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_485x_exposure_universe.csv \
	../input/nys_ag_offering_plan_search_audit.csv \
	../input/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv

include ../../generic.make

include ../../shared/code/shell_functions.make

all: ../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	../report/nys_ag_offering_plan_matches.txt \
	../report/nys_ag_offering_plan_search_audit.txt

../output/nys_ag_offering_plan_search_audit.csv: ../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv Makefile | ../output
	printf '%s  %s\n' 57a5097e9c3f35e1c3ec439eb2576251b87c14d04bee7f01dfe80e461800be0e $< | shasum -a 256 -c -
	cp $< $@

../output/nys_ag_offering_plan_matches.csv: ../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_matches.csv Makefile | ../output
	printf '%s  %s\n' 1703b417d18cdc0f094531dc3f22b5e2f45fa9ec5161c8a402a2b859f4d56da2 $< | shasum -a 256 -c -
	cp $< $@




../report/nys_ag_offering_plan_matches.txt: report_data.R ../../shared/code/write_data_report.R ../output/nys_ag_offering_plan_matches.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< nys_ag_offering_plan_matches

../report/nys_ag_offering_plan_search_audit.txt: report_data.R ../../shared/code/write_data_report.R ../output/nys_ag_offering_plan_search_audit.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< nys_ag_offering_plan_search_audit


include ../../shared/code/generic.make

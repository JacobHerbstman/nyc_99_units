include ../../shared/code/shell_functions.make

all: ../output/source_registry_checks.csv \
	../report/source_registry_checks.txt

../output/source_registry_checks.csv: validate_source_registry.R source_catalog.csv manual_manifest.csv archive_requests.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<




../report/source_registry_checks.txt: report_data.R ../../shared/code/write_data_report.R ../output/source_registry_checks.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< source_registry_checks


include ../../shared/code/generic.make

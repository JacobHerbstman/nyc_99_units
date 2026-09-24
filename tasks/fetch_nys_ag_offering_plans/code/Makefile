include ../../shared/code/shell_functions.make

RAW := ../../../data_raw/nys_ag_offering_plan_matches

all: ../output/nys_ag_offering_plan_search_audit_20260826.csv ../output/nys_ag_offering_plan_matches_20260826.csv \
	../output/historical_ag_query_supplement_2019_2022_20260922.csv \
	../output/historical_ag_query_supplement_2023_companions_20260922.csv

include ../../shared/code/generic.make

# Captures are copied only when missing, and published only if their bytes match
# checksums.sha256. The query scripts in this folder are the recipe that made
# them; the build does not rerun them.
../output/nys_ag_offering_plan_search_audit_20260826.csv: $(RAW)/2026-08-26/nys_ag_offering_plan_search_audit.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/nys_ag_offering_plan_matches_20260826.csv: $(RAW)/2026-08-26/nys_ag_offering_plan_matches.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/historical_ag_query_supplement_2019_2022_20260922.csv: \
	$(RAW)/2026-09-22/historical_ag_query_supplement_2019_2022.csv ../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/historical_ag_query_supplement_2023_companions_20260922.csv: \
	$(RAW)/2026-09-22/historical_ag_query_supplement_2023_companions.csv ../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

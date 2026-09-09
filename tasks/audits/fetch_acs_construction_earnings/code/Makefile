include ../../../shared/code/shell_functions.make

all: ../report/puma_boundaries.txt \
	../report/community_district_boundaries.txt \
	../output/acs_2023_puma.json \
	../report/acs_2023_puma.txt \
	../output/nyc_puma_2020_2026-09-08.geojson \
	../output/community_districts_2026-09-08.geojson \
	../output/acs_2023_tract.json \
	../output/acs_2023_county.json \
	../output/B24031.json \
	../output/B24041.json \
	../report/acs_2023_tract.txt \
	../report/acs_2023_county.txt

../output/acs_2023_%.json: fetch_acs.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $*

include download_recipes.make

../report/acs_2023_%.txt: report_source.R ../output/acs_2023_%.json ../../../shared/code/write_data_report.R \
	Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< $*

../report/puma_boundaries.txt: report_boundaries.R ../output/nyc_puma_2020_2026-09-08.geojson \
	../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< puma

../report/community_district_boundaries.txt: report_boundaries.R \
	../output/community_districts_2026-09-08.geojson ../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< community_district



include ../../../shared/code/generic.make

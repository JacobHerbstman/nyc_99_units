include ../../../shared/code/shell_functions.make

all: ../output/community_district_99_overlay.pdf \
	../output/community_district_earnings.csv \
	../output/community_district_earnings_map.pdf \
	../report/community_district_earnings.txt \
	../report/community_district_findings.md \
	../output/acs_construction_earnings.csv \
	../output/construction_earnings.pdf \
	../output/tract_precision.pdf \
	../report/feasibility.md \
	../report/acs_construction_earnings.txt

../output/acs_construction_earnings.csv: clean_acs.R ../input/acs_2023_tract.json \
	../input/acs_2023_county.json ../input/B24031.json ../input/B24041.json Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/construction_earnings.pdf: plot_earnings.R ../output/acs_construction_earnings.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $<

../output/tract_precision.pdf: plot_precision.R ../output/acs_construction_earnings.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/feasibility.md: summarize_feasibility.R ../output/acs_construction_earnings.csv ../README.md \
	Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $<

../report/acs_construction_earnings.txt: report_data.R ../output/acs_construction_earnings.csv \
	../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $<

../output/community_district_earnings.csv: build_community_earnings.R ../input/acs_2023_puma.json \
	../input/nyc_puma_2020_2026-09-08.geojson ../input/community_districts_2026-09-08.geojson Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/community_district_earnings_map.pdf: map_community_earnings.R \
	../output/community_district_earnings.csv ../input/community_districts_2026-09-08.geojson Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< earnings

../output/community_district_99_overlay.pdf: map_community_earnings.R \
	../output/community_district_earnings.csv ../input/community_districts_2026-09-08.geojson \
	../input/geographic_filings.parquet Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< overlay

../report/community_district_earnings.txt: report_community_data.R ../output/community_district_earnings.csv \
	../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $<

../report/community_district_findings.md: summarize_community_earnings.R \
	../output/community_district_earnings.csv ../output/acs_construction_earnings.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $<

../input/acs_2023_tract.json: ../../fetch_acs_construction_earnings/output/acs_2023_tract.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acs_2023_county.json: ../../fetch_acs_construction_earnings/output/acs_2023_county.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/B24031.json: ../../fetch_acs_construction_earnings/output/B24031.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/B24041.json: ../../fetch_acs_construction_earnings/output/B24041.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acs_2023_puma.json: ../../fetch_acs_construction_earnings/output/acs_2023_puma.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_puma_2020_2026-09-08.geojson: ../../fetch_acs_construction_earnings/output/nyc_puma_2020_2026-09-08.geojson | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/community_districts_2026-09-08.geojson: ../../fetch_acs_construction_earnings/output/community_districts_2026-09-08.geojson | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/geographic_filings.parquet: ../../../analyze_borough_bunching/output/geographic_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../fetch_acs_construction_earnings/output/acs_2023_tract.json \
	../../fetch_acs_construction_earnings/output/acs_2023_county.json \
	../../fetch_acs_construction_earnings/output/B24031.json \
	../../fetch_acs_construction_earnings/output/B24041.json \
	../../fetch_acs_construction_earnings/output/acs_2023_puma.json \
	../../fetch_acs_construction_earnings/output/nyc_puma_2020_2026-09-08.geojson \
	../../fetch_acs_construction_earnings/output/community_districts_2026-09-08.geojson: check-fetch_acs_construction_earnings ;

.PHONY: check-fetch_acs_construction_earnings

check-fetch_acs_construction_earnings:
	$(MAKE) -C ../../fetch_acs_construction_earnings/code all ../output/acs_2023_tract.json ../output/acs_2023_county.json ../output/B24031.json ../output/B24041.json ../output/acs_2023_puma.json ../output/nyc_puma_2020_2026-09-08.geojson ../output/community_districts_2026-09-08.geojson

../../../analyze_borough_bunching/output/geographic_filings.parquet: check-analyze_borough_bunching ;

.PHONY: check-analyze_borough_bunching

check-analyze_borough_bunching:
	$(MAKE) -C ../../../analyze_borough_bunching/code all ../output/geographic_filings.parquet

include ../../../shared/code/generic.make

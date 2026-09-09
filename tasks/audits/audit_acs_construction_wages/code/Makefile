all: ../output/community_district_99_overlay.pdf ../output/community_district_earnings.csv ../output/community_district_earnings_map.pdf ../report/community_district_earnings.txt ../report/community_district_findings.md ../output/acs_construction_earnings.csv ../output/construction_earnings.pdf ../output/tract_precision.pdf ../report/feasibility.md ../report/acs_construction_earnings.txt

../output/acs_construction_earnings.csv: clean_acs.R ../input/acs_2023_tract.json ../input/acs_2023_county.json ../input/B24031.json ../input/B24041.json | ../output
	$(R) $<

../output/construction_earnings.pdf: plot_earnings.R ../output/acs_construction_earnings.csv | ../output
	$(R) $<

../output/tract_precision.pdf: plot_precision.R ../output/acs_construction_earnings.csv | ../output
	$(R) $<

../report/feasibility.md: summarize_feasibility.R ../output/acs_construction_earnings.csv ../README.md | ../report
	$(R) $<

../report/acs_construction_earnings.txt: report_data.R ../output/acs_construction_earnings.csv ../../../shared/code/write_data_report.R | ../report
	$(R) $<

../output/community_district_earnings.csv: build_community_earnings.R ../input/acs_2023_puma.json ../input/nyc_puma_2020_2026-09-08.geojson ../input/community_districts_2026-09-08.geojson | ../output
	$(R) $<

../output/community_district_earnings_map.pdf: map_community_earnings.R ../output/community_district_earnings.csv ../input/community_districts_2026-09-08.geojson | ../output
	$(R) $< earnings

../output/community_district_99_overlay.pdf: map_community_earnings.R ../output/community_district_earnings.csv ../input/community_districts_2026-09-08.geojson ../input/geographic_filings.parquet | ../output
	$(R) $< overlay

../report/community_district_earnings.txt: report_community_data.R ../output/community_district_earnings.csv ../../../shared/code/write_data_report.R | ../report
	$(R) $<

../report/community_district_findings.md: summarize_community_earnings.R ../output/community_district_earnings.csv ../output/acs_construction_earnings.csv | ../report
	$(R) $<

../report:
	mkdir -p $@

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

include ../../generic.make

include ../../../shared/code/shell_functions.make

all: ../output/block_construction_bins.csv \
	../output/district_construction_bins.csv \
	../output/workplace_earnings_maps.pdf \
	../output/district_earnings_bins.pdf \
	../report/block_construction_bins.txt \
	../report/district_construction_bins.txt \
	../report/findings.md

../output/block_construction_bins.csv: build_blocks.R ../input/ny_wac_S000_JT02_2019.csv.gz \
	../input/ny_wac_SE01_JT02_2019.csv.gz ../input/ny_wac_SE02_JT02_2019.csv.gz \
	../input/ny_wac_SE03_JT02_2019.csv.gz ../input/ny_wac_S000_JT02_2020.csv.gz \
	../input/ny_wac_SE01_JT02_2020.csv.gz ../input/ny_wac_SE02_JT02_2020.csv.gz \
	../input/ny_wac_SE03_JT02_2020.csv.gz ../input/ny_wac_S000_JT02_2021.csv.gz \
	../input/ny_wac_SE01_JT02_2021.csv.gz ../input/ny_wac_SE02_JT02_2021.csv.gz \
	../input/ny_wac_SE03_JT02_2021.csv.gz ../input/ny_wac_S000_JT02_2022.csv.gz \
	../input/ny_wac_SE01_JT02_2022.csv.gz ../input/ny_wac_SE02_JT02_2022.csv.gz \
	../input/ny_wac_SE03_JT02_2022.csv.gz ../input/ny_wac_S000_JT02_2023.csv.gz \
	../input/ny_wac_SE01_JT02_2023.csv.gz ../input/ny_wac_SE02_JT02_2023.csv.gz \
	../input/ny_wac_SE03_JT02_2023.csv.gz ../input/ny_xwalk.csv.gz ../input/community_districts.geojson Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $<

../output/district_construction_bins.csv: aggregate_districts.R ../output/block_construction_bins.csv \
	../input/community_districts.geojson Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/workplace_earnings_maps.pdf: map_bins.R ../output/district_construction_bins.csv \
	../input/community_districts.geojson Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/district_earnings_bins.pdf: plot_bins.R ../output/district_construction_bins.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $<

../report/%_construction_bins.txt: report_data.R ../output/%_construction_bins.csv \
	../../../shared/code/write_data_report.R Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< $*

../report/findings.md: summarize_bins.R ../output/block_construction_bins.csv \
	../output/district_construction_bins.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $<

../input/ny_wac_S000_JT02_2019.csv.gz: ../../fetch_lodes_construction/output/ny_wac_S000_JT02_2019.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE01_JT02_2019.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2019.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE02_JT02_2019.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2019.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE03_JT02_2019.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2019.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_S000_JT02_2020.csv.gz: ../../fetch_lodes_construction/output/ny_wac_S000_JT02_2020.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE01_JT02_2020.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2020.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE02_JT02_2020.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2020.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE03_JT02_2020.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2020.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_S000_JT02_2021.csv.gz: ../../fetch_lodes_construction/output/ny_wac_S000_JT02_2021.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE01_JT02_2021.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2021.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE02_JT02_2021.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2021.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE03_JT02_2021.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2021.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_S000_JT02_2022.csv.gz: ../../fetch_lodes_construction/output/ny_wac_S000_JT02_2022.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE01_JT02_2022.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2022.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE02_JT02_2022.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2022.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE03_JT02_2022.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2022.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_S000_JT02_2023.csv.gz: ../../fetch_lodes_construction/output/ny_wac_S000_JT02_2023.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE01_JT02_2023.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2023.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE02_JT02_2023.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2023.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_wac_SE03_JT02_2023.csv.gz: ../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2023.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/ny_xwalk.csv.gz: ../../fetch_lodes_construction/output/ny_xwalk.csv.gz | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/community_districts.geojson: ../../fetch_acs_construction_earnings/output/community_districts_2026-09-08.geojson | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../fetch_lodes_construction/output/ny_wac_S000_JT02_2019.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2019.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2019.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2019.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_S000_JT02_2020.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2020.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2020.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2020.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_S000_JT02_2021.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2021.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2021.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2021.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_S000_JT02_2022.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2022.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2022.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2022.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_S000_JT02_2023.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE01_JT02_2023.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE02_JT02_2023.csv.gz \
	../../fetch_lodes_construction/output/ny_wac_SE03_JT02_2023.csv.gz \
	../../fetch_lodes_construction/output/ny_xwalk.csv.gz: check-fetch_lodes_construction ;

.PHONY: check-fetch_lodes_construction

check-fetch_lodes_construction:
	$(MAKE) -C ../../fetch_lodes_construction/code all ../output/ny_wac_S000_JT02_2019.csv.gz ../output/ny_wac_SE01_JT02_2019.csv.gz ../output/ny_wac_SE02_JT02_2019.csv.gz ../output/ny_wac_SE03_JT02_2019.csv.gz ../output/ny_wac_S000_JT02_2020.csv.gz ../output/ny_wac_SE01_JT02_2020.csv.gz ../output/ny_wac_SE02_JT02_2020.csv.gz ../output/ny_wac_SE03_JT02_2020.csv.gz ../output/ny_wac_S000_JT02_2021.csv.gz ../output/ny_wac_SE01_JT02_2021.csv.gz ../output/ny_wac_SE02_JT02_2021.csv.gz ../output/ny_wac_SE03_JT02_2021.csv.gz ../output/ny_wac_S000_JT02_2022.csv.gz ../output/ny_wac_SE01_JT02_2022.csv.gz ../output/ny_wac_SE02_JT02_2022.csv.gz ../output/ny_wac_SE03_JT02_2022.csv.gz ../output/ny_wac_S000_JT02_2023.csv.gz ../output/ny_wac_SE01_JT02_2023.csv.gz ../output/ny_wac_SE02_JT02_2023.csv.gz ../output/ny_wac_SE03_JT02_2023.csv.gz ../output/ny_xwalk.csv.gz

../../fetch_acs_construction_earnings/output/community_districts_2026-09-08.geojson: check-fetch_acs_construction_earnings ;

.PHONY: check-fetch_acs_construction_earnings

check-fetch_acs_construction_earnings:
	$(MAKE) -C ../../fetch_acs_construction_earnings/code all ../output/community_districts_2026-09-08.geojson

include ../../../shared/code/generic.make

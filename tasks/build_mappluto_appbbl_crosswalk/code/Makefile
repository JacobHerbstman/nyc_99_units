include ../../shared/code/shell_functions.make

all: ../output/mappluto_appbbl_crosswalk.csv \
	../report/mappluto_appbbl_crosswalk.txt

../output/mappluto_appbbl_crosswalk.csv: build_mappluto_appbbl_crosswalk.R \
	../../shared/code/source_pipeline_utils.R ../input/mappluto_files.csv Makefile ../input/nyc_pluto_25v4_csv.zip \
	| ../output \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh
	$(R) $<


../report/mappluto_appbbl_crosswalk.txt: report_data.R ../../shared/code/write_data_report.R ../output/mappluto_appbbl_crosswalk.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_appbbl_crosswalk


../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_files.csv

../input/nyc_pluto_25v4_csv.zip: ../../fetch_mappluto_archive/output/dcp_pluto_current_25v4_nyc_pluto_25v4_csv.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../fetch_mappluto_archive/output/mappluto_files.csv \
	../../fetch_mappluto_archive/output/dcp_pluto_current_25v4_nyc_pluto_25v4_csv.zip: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../fetch_mappluto_archive/code all ../output/mappluto_files.csv ../output/dcp_pluto_current_25v4_nyc_pluto_25v4_csv.zip

include ../../shared/code/generic.make

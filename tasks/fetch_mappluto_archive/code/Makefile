include ../../shared/code/shell_functions.make

EARLY_MAPPLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 \
	17v1_1
MAPPLUTO_RELEASES := 18v1_1 18v2 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 \
	23v1 23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1

PLUTO_ARCHIVES := $(foreach v,$(PLUTO_RELEASES),../output/nyc_pluto_$(v).zip)
MAPPLUTO_ARCHIVES := $(foreach v,$(EARLY_MAPPLUTO_RELEASES),../output/mappluto_$(v).zip) \
	$(foreach v,$(MAPPLUTO_RELEASES),../output/nyc_mappluto_$(v)_arc_shp.zip)
# Current releases and archive metadata are dated captures in data_raw/.
CAPTURES := ../output/nyc_mappluto_25v4_shp.zip ../output/dcp_mappluto_current_25v4_meta_mappluto.pdf \
	../output/nyc_pluto_25v4_csv.zip ../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf \
	../output/dcp_pluto_current_25v4_pluto_readme.pdf \
	../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_pluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_mappluto_current_20260501_mappluto_planning_content.json \
	../output/dcp_pluto_current_20260501_mappluto_planning_content.json

all: ../output/mappluto_files.csv

include ../../shared/code/generic.make

# checksums.sha256 records the bytes of every published file. Files are fetched
# or copied only when missing; editing the ledger re-verifies all of them here.
../output/mappluto_files.csv: source_files.csv checksums.sha256 $(PLUTO_ARCHIVES) $(MAPPLUTO_ARCHIVES) \
	$(CAPTURES) ../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	shasum -a 256 --quiet -c checksums.sha256
	$(R) ../../shared/code/copy_data.R $< $@

$(filter-out ../output/nyc_pluto_17v1.zip ../output/nyc_pluto_17v1_1.zip,$(PLUTO_ARCHIVES)): \
	../output/nyc_pluto_%.zip: | ../output ../temp
	wget -q --tries=3 https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_$*.zip -O ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@

$(filter-out ../output/mappluto_17v1_1.zip,$(MAPPLUTO_ARCHIVES)): ../output/%.zip: | ../output ../temp
	wget -q --tries=3 https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/$*.zip -O ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@

# These releases are served under a revision query string.
../output/nyc_pluto_17v1.zip ../output/nyc_pluto_17v1_1.zip: ../output/nyc_pluto_%.zip: | ../output ../temp
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_$*.zip?r=1' -o ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@

../output/mappluto_17v1_1.zip: | ../output ../temp
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_17v1_1.zip?r=2' -o ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@

../output/nyc_mappluto_25v4_shp.zip: ../../../data_raw/dcp_mappluto_current/25v4/nyc_mappluto_25v4_shp.zip | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_25v4_meta_mappluto.pdf: ../../../data_raw/dcp_mappluto_current/25v4/meta_mappluto.pdf | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/nyc_pluto_25v4_csv.zip: ../../../data_raw/dcp_pluto_current/25v4/nyc_pluto_25v4_csv.zip | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf: ../../../data_raw/dcp_pluto_current/25v4/pluto_datadictionary.pdf | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_readme.pdf: ../../../data_raw/dcp_pluto_current/25v4/pluto_readme.pdf | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_pluto_archive_20260501_mappluto_archive_index.json: \
	../../../data_raw/dcp_mappluto_archive/20260501/mappluto_archive_index.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_20260501_mappluto_planning_content.json: \
	../../../data_raw/dcp_mappluto_current/20260501/mappluto_planning_content.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_20260501_mappluto_planning_content.json: \
	../../../data_raw/dcp_pluto_current/20260501/mappluto_planning_content.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

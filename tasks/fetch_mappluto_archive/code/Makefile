include ../../shared/code/shell_functions.make

EARLY_MAPPLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1
MAPPLUTO_RELEASES := 18v1_1 18v2 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 23v1 \
	23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1

all: ../output/mappluto_files.csv ../report/mappluto_files.txt

../output/mappluto_files.csv: source_files.csv Makefile $(foreach v,$(PLUTO_RELEASES),../output/nyc_pluto_$(v).zip) \
	$(foreach v,$(MAPPLUTO_RELEASES),../output/nyc_mappluto_$(v)_arc_shp.zip) \
	$(foreach v,$(EARLY_MAPPLUTO_RELEASES),../output/mappluto_$(v).zip) \
	../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_mappluto_current_20260501_mappluto_planning_content.json \
	../output/dcp_mappluto_current_25v4_meta_mappluto.pdf ../output/nyc_mappluto_25v4_shp.zip \
	../output/dcp_pluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_pluto_current_20260501_mappluto_planning_content.json ../output/nyc_pluto_25v4_csv.zip \
	../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf ../output/dcp_pluto_current_25v4_pluto_readme.pdf | \
	../output
	cp $< $@

../output/mappluto_17v1_1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_17v1_1.zip?r=2' -o $@.download
	printf '%s  %s\n' a042208f2532208082229c90a4d45ee836c6d52fab99771feb0889105d9d2ef3 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json: \
	../../../data_raw/dcp_mappluto_archive/20260501/mappluto_archive_index.json Makefile | ../output
	printf '%s  %s\n' 6f96a0a39c8158121784b0b77000c80516880d97d7245d268b551f5a200dc286 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_20260501_mappluto_planning_content.json: \
	../../../data_raw/dcp_mappluto_current/20260501/mappluto_planning_content.json Makefile | ../output
	printf '%s  %s\n' c2a11df383c8c60f5b27dc7f7f6a180d0fc63c263487677893eb2e66f89900c7 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_25v4_meta_mappluto.pdf: ../../../data_raw/dcp_mappluto_current/25v4/meta_mappluto.pdf \
	Makefile | ../output
	printf '%s  %s\n' ad1f420cca33389a65c6deb9cf89a64442491922d9519f3785ab87d81fa36754 $< | shasum -a 256 -c -
	cp $< $@

../output/nyc_mappluto_25v4_shp.zip: ../../../data_raw/dcp_mappluto_current/25v4/nyc_mappluto_25v4_shp.zip Makefile | \
	../output
	printf '%s  %s\n' 99df5709806c4e1c4392c7759ba88b593fb87ff4aff5b955b4c925d98b19db92 $< | shasum -a 256 -c -
	cp $< $@

../output/nyc_pluto_17v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_17v1.zip?r=1' -o $@.download
	printf '%s  %s\n' a11baaf485d5a91c2b859972706da05dfb768e760e0154db1bb2b72012525b5f $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/nyc_pluto_17v1_1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_17v1_1.zip?r=1' -o $@.download
	printf '%s  %s\n' 1a700b25d1f26d0ce06198499e708eab4c5d6f2e39362f663abaf30a7ae3d4cf $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_20260501_mappluto_archive_index.json: \
	../../../data_raw/dcp_mappluto_archive/20260501/mappluto_archive_index.json Makefile | ../output
	printf '%s  %s\n' 6f96a0a39c8158121784b0b77000c80516880d97d7245d268b551f5a200dc286 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_20260501_mappluto_planning_content.json: \
	../../../data_raw/dcp_pluto_current/20260501/mappluto_planning_content.json Makefile | ../output
	printf '%s  %s\n' c2a11df383c8c60f5b27dc7f7f6a180d0fc63c263487677893eb2e66f89900c7 $< | shasum -a 256 -c -
	cp $< $@

../output/nyc_pluto_25v4_csv.zip: ../../../data_raw/dcp_pluto_current/25v4/nyc_pluto_25v4_csv.zip Makefile | ../output
	printf '%s  %s\n' 3306cf4cde7e4989693e752931e254680f1fa95783f1849ce1eca141c30ce9fd $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf: \
	../../../data_raw/dcp_pluto_current/25v4/pluto_datadictionary.pdf Makefile | ../output
	printf '%s  %s\n' b831d1c2784771cc071ab4b0eac55489f0a3d6ad7986d5045b205a4a1ab171b1 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_readme.pdf: ../../../data_raw/dcp_pluto_current/25v4/pluto_readme.pdf Makefile | \
	../output
	printf '%s  %s\n' 09e430adf31a7d71942a44fe2388e53cce6a36a3b55849bd8d2e731006941f1d $< | shasum -a 256 -c -
	cp $< $@

../report/mappluto_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/mappluto_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_files

../output/nyc_pluto_%.zip: Makefile checksums.sha256 | ../output
	wget -q --tries=3 https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_$*.zip -O $@.download
	awk '$$2 == "$@" { print $$1 "  $@.download" }' checksums.sha256 | shasum -a 256 -c -
	mv $@.download $@

../output/%.zip: Makefile checksums.sha256 | ../output
	wget -q --tries=3 https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/$*.zip -O $@.download
	awk '$$2 == "$@" { print $$1 "  $@.download" }' checksums.sha256 | shasum -a 256 -c -
	mv $@.download $@

include ../../shared/code/generic.make

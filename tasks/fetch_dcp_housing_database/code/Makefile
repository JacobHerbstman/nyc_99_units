include ../../shared/code/shell_functions.make

FILES := ../output/dcp_housing_database_project_level_20260501_housing_project_level_archive.json \
	../output/dcp_housing_database_project_level_20260501_housing_project_level_content_api.json \
	../output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip \
	../output/dcp_housing_database_project_level_25Q4_Housing_Database_Data_Dictionary.xlsx \
	../output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip

all: ../output/dcp_housing_database_files.csv

include ../../shared/code/generic.make

# checksums.sha256 records the bytes of every published file. Files are fetched
# or copied only when missing; editing the ledger re-verifies all of them here.
../output/dcp_housing_database_files.csv: source_files.csv checksums.sha256 $(FILES) \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	shasum -a 256 --quiet -c checksums.sha256
	$(R) ../../shared/code/copy_data.R $< $@ source_id vintage file_role

../output/dcp_housing_database_project_level_20260501_housing_project_level_archive.json: \
	../../../data_raw/dcp_housing_database_project_level/20260501/housing_project_level_archive.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_20260501_housing_project_level_content_api.json: \
	../../../data_raw/dcp_housing_database_project_level/20260501/housing_project_level_content_api.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_25Q4_Housing_Database_Data_Dictionary.xlsx: \
	../../../data_raw/dcp_housing_database_project_level/25Q4/Housing_Database_Data_Dictionary.xlsx | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip: \
	../../../data_raw/dcp_housing_database_project_level/25Q4/nychdb_25q4_csv.zip | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip: | ../output ../temp
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-database/nychousingdb_23q4_csv.zip' -o ../temp/$(@F)
	awk '$$2 == "$@" { print $$1 "  ../temp/$(@F)" }' checksums.sha256 | shasum -a 256 -c -
	mv ../temp/$(@F) $@

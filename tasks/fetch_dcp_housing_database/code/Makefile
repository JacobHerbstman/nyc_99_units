include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_files.csv \
	../report/dcp_housing_database_files.txt

../output/dcp_housing_database_files.csv: source_files.csv Makefile \
	../output/dcp_housing_database_project_level_20260501_housing_project_level_archive.json \
	../output/dcp_housing_database_project_level_20260501_housing_project_level_content_api.json \
	../output/dcp_housing_database_project_level_25Q4_Housing_Database_Data_Dictionary.xlsx \
	../output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../output
	cp $< $@

../output/dcp_housing_database_project_level_20260501_housing_project_level_archive.json: ../../../data_raw/dcp_housing_database_project_level/20260501/housing_project_level_archive.json Makefile | ../output
	printf '%s  %s\n' d8440f4325edf85fd3d31ee08f8b6f23be91f824bce7643761e979ac8a626337 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_20260501_housing_project_level_content_api.json: ../../../data_raw/dcp_housing_database_project_level/20260501/housing_project_level_content_api.json Makefile | ../output
	printf '%s  %s\n' c279ff2f123e97a08f86f3f8d53605346c0838ab38a760e08dd809b33d416a18 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_25Q4_Housing_Database_Data_Dictionary.xlsx: ../../../data_raw/dcp_housing_database_project_level/25Q4/Housing_Database_Data_Dictionary.xlsx Makefile | ../output
	printf '%s  %s\n' fb77519cf5a6f52b0d5fa27ade4a6f7df0d9f192d791b50080d73653fe189947 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-database/housing-project-level/nychdb_25q4_csv.zip' -o $@.download
	printf '%s  %s\n' 76f16a63535ea661700afd2440f143e718f9ffa4e8685de6e166c4ea208cada2 $@.download | shasum -a 256 -c -
	mv $@.download $@




../report/dcp_housing_database_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_housing_database_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_housing_database_files


include ../../shared/code/generic.make

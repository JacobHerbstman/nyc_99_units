include ../../shared/code/shell_functions.make

all: ../output/borough_boundaries_2026-09-08.geojson

include ../../shared/code/generic.make

../output/borough_boundaries_2026-09-08.geojson: ../../../data_raw/nyc_borough_boundaries/2026-09-08/borough_boundaries.geojson \
	checksums.sha256 copy_boundaries.R ../../shared/code/write_data_report.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) copy_boundaries.R

# The Open Data API is mutable: query it only when the dated capture is missing.
../../../data_raw/nyc_borough_boundaries/2026-09-08/borough_boundaries.geojson: | ../temp
	wget --no-use-server-timestamps --timeout=60 --tries=2 -O ../temp/borough_boundaries.geojson 'https://data.cityofnewyork.us/resource/gthc-hcne.geojson?$$limit=10'
	awk '$$2 == "../output/borough_boundaries_2026-09-08.geojson" { print $$1 "  ../temp/borough_boundaries.geojson" }' checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/borough_boundaries.geojson $@

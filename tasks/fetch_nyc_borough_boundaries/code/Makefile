SHELL := /bin/bash
.DELETE_ON_ERROR:

all: ../output/borough_boundaries_2026-09-08.geojson

../output/borough_boundaries_2026-09-08.geojson: Makefile | ../output
	wget --no-use-server-timestamps --timeout=60 --tries=2 -O ../output/borough_boundaries_2026-09-08.geojson.part 'https://data.cityofnewyork.us/resource/gthc-hcne.geojson?$$limit=10'
	mv ../output/borough_boundaries_2026-09-08.geojson.part $@

include ../../generic.make

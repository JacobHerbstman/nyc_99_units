include ../../../shared/code/shell_functions.make

all: ../output/onderdonk_floor_2026-09-21.json ../output/kingsbrook_hcr_floor_plans_2018.pdf \
	../output/kingsbrook_hcr_addendum_2018.pdf ../output/kingsbrook_phase_I_esa_2025.pdf \
	../output/kingsbrook_rawp_2026.pdf

include ../../../shared/code/generic.make

../output/onderdonk_floor_2026-09-21.json: five_floor.make five_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/18/query?where=PARID%20IN%20(%274034660030%27,%274034660058%27)&outFields=PARID,GROSS_SQFT,LAND_AREA,NUM_BLDGS,TAXYR,BLDG_CLASS&returnGeometry=false&f=json' --output ../temp/onderdonk_floor_2026-09-21.json
	cd ../temp && sed -n '/  onderdonk_floor_2026-09-21.json$$/p' ../code/five_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/onderdonk_floor_2026-09-21.json $@

../output/kingsbrook_hcr_floor_plans_2018.pdf: five_floor.make five_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://hcr.ny.gov/vital-brooklyn-sites-e-l-attachment-4' --output ../temp/kingsbrook_hcr_floor_plans_2018.pdf
	cd ../temp && sed -n '/  kingsbrook_hcr_floor_plans_2018.pdf$$/p' ../code/five_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/kingsbrook_hcr_floor_plans_2018.pdf $@

../output/kingsbrook_hcr_addendum_2018.pdf: five_floor.make five_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://hcr.ny.gov/system/files/documents/2019/03/rfp-vitalbrooklyn-sites-e-l-addendum1.pdf' --output ../temp/kingsbrook_hcr_addendum_2018.pdf
	cd ../temp && sed -n '/  kingsbrook_hcr_addendum_2018.pdf$$/p' ../code/five_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/kingsbrook_hcr_addendum_2018.pdf $@

../output/kingsbrook_phase_I_esa_2025.pdf: five_floor.make five_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C224448/Application.BCP.C224448.2025-06-24.Phase%20I%20ESA%20.pdf' --output ../temp/kingsbrook_phase_I_esa_2025.pdf
	cd ../temp && sed -n '/  kingsbrook_phase_I_esa_2025.pdf$$/p' ../code/five_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/kingsbrook_phase_I_esa_2025.pdf $@

../output/kingsbrook_rawp_2026.pdf: five_floor.make five_floor_2026-09-21/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C224448/Work%20Plan.BCP.C224448.2026-06-01.RAWP.pdf' --output ../temp/kingsbrook_rawp_2026.pdf
	cd ../temp && sed -n '/  kingsbrook_rawp_2026.pdf$$/p' ../code/five_floor_2026-09-21/sources.sha256 | shasum -a 256 -c -
	mv ../temp/kingsbrook_rawp_2026.pdf $@

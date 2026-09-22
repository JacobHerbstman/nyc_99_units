# Frozen September 15 assessment query and the documents used to check its areas.
all: dof_subset_validation_2026-09-15/assessments.json \
	dof_subset_validation_2026-09-15/assessment_count.json \
	dof_subset_validation_2026-09-15/assessment_schema.json \
	../output/dof_assessment_layout.xlsx \
	../output/noble_cb1_notice_2026-06-09.pdf \
	../output/sackett_property_2022-07-06.pdf \
	../output/sackett_project_2022-07-06.pdf \
	../output/dof_map_30042620220913162303.pdf

dof_subset_validation_2026-09-15/%.json: dof_subset_validation_2026-09-15/%_url.txt dof_subset_validation_2026-09-15/json.sha256 | ../temp
	curl --fail --silent --show-error --location --retry 2 "$$(cat $<)" --output ../temp/$*.json
	cd ../temp && sed -n '/  $*.json$$/p' ../code/dof_subset_validation_2026-09-15/json.sha256 | shasum -a 256 -c -
	mv ../temp/$*.json $@

../output/dof_assessment_layout.xlsx: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://www.nyc.gov/assets/finance/downloads/tar/layout-pts-property-master.xlsx' --output ../temp/dof_assessment_layout.xlsx
	cd ../temp && sed -n '/  dof_assessment_layout.xlsx$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dof_assessment_layout.xlsx $@

../output/noble_cb1_notice_2026-06-09.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://www.nyc.gov/assets/brooklyncb1/downloads/pdf/meeting-notices/2026/REVISED-Combined-Public-Hearing-and-Board-Meeting-Notice-06-09-26.pdf' --output ../temp/noble_cb1_notice_2026-06-09.pdf
	cd ../temp && sed -n '/  noble_cb1_notice_2026-06-09.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/noble_cb1_notice_2026-06-09.pdf $@

../output/sackett_property_2022-07-06.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224222/Application.BCP.C224222.2022-07-06.Major%20Amendment%20Application-Attachment%20A-Property%20Information.pdf' --output ../temp/sackett_property_2022-07-06.pdf
	cd ../temp && sed -n '/  sackett_property_2022-07-06.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/sackett_property_2022-07-06.pdf $@

../output/sackett_project_2022-07-06.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224222/Application.BCP.C224222.2022-07-06.Major%20Amendment%20Application-Attachment%20B-Project%20Description.pdf' --output ../temp/sackett_project_2022-07-06.pdf
	cd ../temp && sed -n '/  sackett_project_2022-07-06.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/sackett_project_2022-07-06.pdf $@

../output/dof_map_30042620220913162303.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30042620220913162303' --output ../temp/dof_map_30042620220913162303.pdf
	cd ../temp && sed -n '/  dof_map_30042620220913162303.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dof_map_30042620220913162303.pdf $@

# Earlier boundary evidence inspected in the manual two-parent review.
all: ../output/greenpoint_boundary_2019-11-25.pdf ../output/sackett_irm_2022-03-04.pdf \
	../output/gowanus_existing_conditions_2024-03.pdf

../output/greenpoint_boundary_2019-11-25.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224190/Agreement.BCP.C224190.2019-11-25.BCP%20Amendment%20No.%202%20-%20Correction%20to%20Site%20Size%20%26%20Modification%20to%20Boundary%20.pdf' --output ../temp/greenpoint_boundary_2019-11-25.pdf
	cd ../temp && sed -n '/  greenpoint_boundary_2019-11-25.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/greenpoint_boundary_2019-11-25.pdf $@

../output/sackett_irm_2022-03-04.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224222/Application.BCP.C224222.2022-03-04.Interim%20Remedial%20Measures%20Work%20Plan.pdf' --output ../temp/sackett_irm_2022-03-04.pdf
	cd ../temp && sed -n '/  sackett_irm_2022-03-04.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/sackett_irm_2022-03-04.pdf $@

../output/gowanus_existing_conditions_2024-03.pdf: dof_subset_validation.make dof_subset_validation_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 --user-agent 'Mozilla/5.0' 'https://www.esd.ny.gov/sites/default/files/media/document/Item-VA-Exhibit-4-Gowanus-Existing-Conditions-Report.pdf' --output ../temp/gowanus_existing_conditions_2024-03.pdf
	cd ../temp && sed -n '/  gowanus_existing_conditions_2024-03.pdf$$/p' ../code/dof_subset_validation_2026-09-15/sources.sha256 | shasum -a 256 -c -
	mv ../temp/gowanus_existing_conditions_2024-03.pdf $@

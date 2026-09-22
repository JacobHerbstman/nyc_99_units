all: ../output/dof_map_30231520260601154944.pdf \
	../output/dof_map_30395820260520142453.pdf \
	../output/dof_map_30727420250214160509.pdf \
	../output/dof_map_30823520251202145125.pdf \
	../output/2026Q0143_Site-Plan.pdf \
	../output/2026Q0143_DOB_approval.pdf \
	../output/2026Q0143_Project-Description.pdf \
	../output/2026Q0143_Discussion-of-Findings.pdf \
	../output/2026Q0143_Tax-Map.pdf \
	../output/2025Q0444_Project-Description.pdf \
	../output/2025Q0444_Site-Plan.pdf \
	../output/2025Q0444_DOB-Approval.pdf \
	../output/2026Q0143_Owner-Authorization.pdf \
	../output/2026Q0143_LandUse.pdf \
	../output/2025Q0444_Owner-Authorization.pdf \
	../output/2025Q0444_LandUse.pdf

all: ../output/orchard_site_management_2024-12-12.pdf \
	../output/webster_mta_property_interests_2023-02-23.pdf \
	../output/orchard_remedial_investigation_2022-08-15.pdf

../output/orchard_site_management_2024-12-12.pdf: site_research.make site_research_followup_2026-09-20_supervisor/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C241256/Work%20Plan.BCP.C241256.2024-12-12.SMP.pdf' -O ../temp/orchard_site_management_2024-12-12.pdf
	cd ../temp && sed -n 's|  ../../output/orchard_site_management_2024-12-12.pdf$$|  orchard_site_management_2024-12-12.pdf|p' ../code/site_research_followup_2026-09-20_supervisor/sources.sha256 | shasum -a 256 -c -
	pdfinfo ../temp/orchard_site_management_2024-12-12.pdf > /dev/null
	mv ../temp/orchard_site_management_2024-12-12.pdf $@

../output/webster_mta_property_interests_2023-02-23.pdf: site_research.make site_research_followup_2026-09-20_supervisor/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://www.mta.info/document/105851' --output ../temp/webster_mta_property_interests_2023-02-23.pdf
	cd ../temp && sed -n 's|  ../../output/webster_mta_property_interests_2023-02-23.pdf$$|  webster_mta_property_interests_2023-02-23.pdf|p' ../code/site_research_followup_2026-09-20_supervisor/sources.sha256 | shasum -a 256 -c -
	pdfinfo ../temp/webster_mta_property_interests_2023-02-23.pdf > /dev/null
	mv ../temp/webster_mta_property_interests_2023-02-23.pdf $@

../output/orchard_remedial_investigation_2022-08-15.pdf: site_research.make site_research_followup_2026-09-20_supervisor/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C241256/Report.BCP.C241256.2022-08-15.RIR.pdf' -O ../temp/orchard_remedial_investigation_2022-08-15.pdf
	cd ../temp && sed -n 's|  ../../output/orchard_remedial_investigation_2022-08-15.pdf$$|  orchard_remedial_investigation_2022-08-15.pdf|p' ../code/site_research_followup_2026-09-20_supervisor/sources.sha256 | shasum -a 256 -c -
	pdfinfo ../temp/orchard_remedial_investigation_2022-08-15.pdf > /dev/null
	mv ../temp/orchard_remedial_investigation_2022-08-15.pdf $@

../output/dof_map_30231520260601154944.pdf \
../output/dof_map_30395820260520142453.pdf \
../output/dof_map_30727420250214160509.pdf \
../output/dof_map_30823520251202145125.pdf: ../output/dof_map_%.pdf: site_research.make site_research_brooklyn_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/$*' --output ../temp/dof_map_$*.pdf
	cd ../temp && sed -n 's|  ../../output/dof_map_$*.pdf$$|  dof_map_$*.pdf|p' ../code/site_research_brooklyn_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dof_map_$*.pdf $@

../output/2026Q0143_Site-Plan.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KJZZPNN4AI5XNG26R6BG5JEW34C' --output ../temp/2026Q0143_Site-Plan.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_Site-Plan.pdf$$|  2026Q0143_Site-Plan.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_Site-Plan.pdf $@

../output/2026Q0143_DOB_approval.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/artifact/01QY2C5KLNUBZTDZMHVJAYY56FNNHZ4OOT' --output ../temp/2026Q0143_DOB_approval.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_DOB_approval.pdf$$|  2026Q0143_DOB_approval.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_DOB_approval.pdf $@

../output/2026Q0143_Project-Description.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KMAFLSDYVPDWZAKIEQ2VFZJEE33' --output ../temp/2026Q0143_Project-Description.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_Project-Description.pdf$$|  2026Q0143_Project-Description.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_Project-Description.pdf $@

../output/2026Q0143_Discussion-of-Findings.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KJOBXSXD4UICBH3WRII2LIS5P7Y' --output ../temp/2026Q0143_Discussion-of-Findings.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_Discussion-of-Findings.pdf$$|  2026Q0143_Discussion-of-Findings.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_Discussion-of-Findings.pdf $@

../output/2026Q0143_Tax-Map.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KMGQPTVXWBJSJD27CRFPBWD6N7Q' --output ../temp/2026Q0143_Tax-Map.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_Tax-Map.pdf$$|  2026Q0143_Tax-Map.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_Tax-Map.pdf $@

../output/2025Q0444_Project-Description.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KOPLK56TKTCCJGYAAAOY6WSTSC6' --output ../temp/2025Q0444_Project-Description.pdf
	cd ../temp && sed -n 's|  ../../output/2025Q0444_Project-Description.pdf$$|  2025Q0444_Project-Description.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2025Q0444_Project-Description.pdf $@

../output/2025Q0444_Site-Plan.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KPNGXSCFUBI75BKY3LC3HO6MLMW' --output ../temp/2025Q0444_Site-Plan.pdf
	cd ../temp && sed -n 's|  ../../output/2025Q0444_Site-Plan.pdf$$|  2025Q0444_Site-Plan.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2025Q0444_Site-Plan.pdf $@

../output/2025Q0444_DOB-Approval.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/artifact/01QY2C5KPKD3QOAGH5L5DII4EXOOQHHDOQ' --output ../temp/2025Q0444_DOB-Approval.pdf
	cd ../temp && sed -n 's|  ../../output/2025Q0444_DOB-Approval.pdf$$|  2025Q0444_DOB-Approval.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2025Q0444_DOB-Approval.pdf $@

../output/2026Q0143_Owner-Authorization.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KJM335CQBG3MVFLHG3L3IC2JQGJ' --output ../temp/2026Q0143_Owner-Authorization.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_Owner-Authorization.pdf$$|  2026Q0143_Owner-Authorization.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_Owner-Authorization.pdf $@

../output/2026Q0143_LandUse.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KKOJAHN4H3N4NHJK4HQ3CHUYYCX' --output ../temp/2026Q0143_LandUse.pdf
	cd ../temp && sed -n 's|  ../../output/2026Q0143_LandUse.pdf$$|  2026Q0143_LandUse.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2026Q0143_LandUse.pdf $@

../output/2025Q0444_Owner-Authorization.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KJFQV5JHRRTIFHLANOLRYURWX5G' --output ../temp/2025Q0444_Owner-Authorization.pdf
	cd ../temp && sed -n 's|  ../../output/2025Q0444_Owner-Authorization.pdf$$|  2025Q0444_Owner-Authorization.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2025Q0444_Owner-Authorization.pdf $@

../output/2025Q0444_LandUse.pdf: site_research.make site_research_large_parents_2026-09-16/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location 'https://zap-api-production.herokuapp.com/document/package/01QY2C5KOVSJNNSW6YQFEKO3W64KPVYMKF' --output ../temp/2025Q0444_LandUse.pdf
	cd ../temp && sed -n 's|  ../../output/2025Q0444_LandUse.pdf$$|  2025Q0444_LandUse.pdf|p' ../code/site_research_large_parents_2026-09-16/sources.sha256 | shasum -a 256 -c -
	mv ../temp/2025Q0444_LandUse.pdf $@

all: ../output/sutphin_site_a_boa_application_2023-04-06.pdf \
	../output/sutphin_site_b_boa_application_2024-06-07.pdf \
	../output/schenectady_dec_bcp_application_2025.pdf \
	../output/schenectady_hcr_board_2026-05-13.pdf

../output/sutphin_site_a_boa_application_2023-04-06.pdf: site_research.make site_research_followup_2026-09-20_woodside_sutphin/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://dos.ny.gov/147-35-95th-avenue-boa-conformance-application' -O ../temp/sutphin_site_a_boa_application_2023-04-06.pdf
	cd ../temp && sed -n '/  sutphin_site_a_boa_application_2023-04-06.pdf$$/p' ../code/site_research_followup_2026-09-20_woodside_sutphin/sources.sha256 | shasum -a 256 -c -
	mv ../temp/sutphin_site_a_boa_application_2023-04-06.pdf $@

../output/sutphin_site_b_boa_application_2024-06-07.pdf: site_research.make site_research_followup_2026-09-20_woodside_sutphin/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://dos.ny.gov/2024-06-07-final-94-15-sutphin-blvd-final-boa-application-proofs-delivery-dos' -O ../temp/sutphin_site_b_boa_application_2024-06-07.pdf
	cd ../temp && sed -n '/  sutphin_site_b_boa_application_2024-06-07.pdf$$/p' ../code/site_research_followup_2026-09-20_woodside_sutphin/sources.sha256 | shasum -a 256 -c -
	mv ../temp/sutphin_site_b_boa_application_2024-06-07.pdf $@

../output/schenectady_dec_bcp_application_2025.pdf: site_research.make site_research_followup_2026-09-20_atlantic_schenectady/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C224448/Application.BCP.C224448.2025-10-29.Complete%20BCP%20Application.pdf' -O ../temp/schenectady_dec_bcp_application_2025.pdf
	cd ../temp && sed -n '/  schenectady_dec_bcp_application_2025.pdf$$/p' ../code/site_research_followup_2026-09-20_atlantic_schenectady/sources.sha256 | shasum -a 256 -c -
	mv ../temp/schenectady_dec_bcp_application_2025.pdf $@

../output/schenectady_hcr_board_2026-05-13.pdf: site_research.make site_research_followup_2026-09-20_atlantic_schenectady/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://hcr.ny.gov/system/files/documents/2026/08/may-13-2026-board-book-1_0_0.pdf' -O ../temp/schenectady_hcr_board_2026-05-13.pdf
	cd ../temp && sed -n '/  schenectady_hcr_board_2026-05-13.pdf$$/p' ../code/site_research_followup_2026-09-20_atlantic_schenectady/sources.sha256 | shasum -a 256 -c -
	mv ../temp/schenectady_hcr_board_2026-05-13.pdf $@

# Motto original public documents; recorded ACRIS exports remain in the snapshot.

all: ../output/motto_dec_bca_2020.pdf

../output/motto_dec_bca_2020.pdf: site_research.make site_research_followup_2026-09-21_motto/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C203125/Agreement.BCP.C203125.2020-02-18.Executed%20BCA.pdf' -O ../temp/dec_bca_2020.pdf
	cd ../temp && sed -n '/  dec_bca_2020.pdf$$/p' ../code/site_research_followup_2026-09-21_motto/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dec_bca_2020.pdf $@

all: ../output/motto_dec_bca_amendment_2020_subdivide.pdf

../output/motto_dec_bca_amendment_2020_subdivide.pdf: site_research.make site_research_followup_2026-09-21_motto/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C203125/Agreement.BCP.C203125.2020-07-08.Executed%20BCA%20Amendment%20No.%201%20-%20Subdivide%20Tax%20Lot%20.pdf' -O ../temp/dec_bca_amendment_2020_subdivide.pdf
	cd ../temp && sed -n '/  dec_bca_amendment_2020_subdivide.pdf$$/p' ../code/site_research_followup_2026-09-21_motto/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dec_bca_amendment_2020_subdivide.pdf $@

all: ../output/motto_dec_final_engineering_report_appendix_d.pdf

../output/motto_dec_final_engineering_report_appendix_d.pdf: site_research.make site_research_followup_2026-09-21_motto/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C203125/Report.BCP.C203125.2022-12-29.FER_APPENDIX%20D.pdf' -O ../temp/dec_final_engineering_report_appendix_d.pdf
	cd ../temp && sed -n '/  dec_final_engineering_report_appendix_d.pdf$$/p' ../code/site_research_followup_2026-09-21_motto/sources.sha256 | shasum -a 256 -c -
	mv ../temp/dec_final_engineering_report_appendix_d.pdf $@

all: ../output/motto_dof_map_after_20200416.pdf

../output/motto_dof_map_after_20200416.pdf: site_research.make site_research_followup_2026-09-21_motto/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20231920200416175925' -O ../temp/motto_dof_map_after_20200416.pdf
	cd ../temp && sed -n '/  motto_dof_map_after_20200416.pdf$$/p' ../code/site_research_followup_2026-09-21_motto/sources.sha256 | shasum -a 256 -c -
	mv ../temp/motto_dof_map_after_20200416.pdf $@

all: ../output/motto_dof_map_before_20190617.pdf

../output/motto_dof_map_before_20190617.pdf: site_research.make site_research_followup_2026-09-21_motto/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20231920190617141001' -O ../temp/motto_dof_map_before_20190617.pdf
	cd ../temp && sed -n '/  motto_dof_map_before_20190617.pdf$$/p' ../code/site_research_followup_2026-09-21_motto/sources.sha256 | shasum -a 256 -c -
	mv ../temp/motto_dof_map_before_20190617.pdf $@

all: ../output/dof_subset_godwin_companion.geojson

../output/dof_subset_godwin_companion.geojson: site_research.make dof_subset_2026-09-21/sources.sha256 | ../output ../temp
	wget --no-use-server-timestamps -q 'https://services6.arcgis.com/yG5s3afENB5iO9fj/ArcGIS/rest/services/DTM_ETL_DAILY_view/FeatureServer/0/query?f=geojson&where=BBL%3D%272057000088%27&outFields=BBL%2CLOT%2CBLOCK%2CBORO%2CShape__Area&returnGeometry=true&outSR=2263' -O ../temp/godwin_companion.geojson
	cd ../temp && shasum -a 256 -c ../code/dof_subset_2026-09-21/sources.sha256
	mv ../temp/godwin_companion.geojson $@

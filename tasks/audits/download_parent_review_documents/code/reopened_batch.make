include ../../../shared/code/shell_functions.make

all: ../output/reopened_02_dec_c224350_application_2022.pdf \
	../output/reopened_02_dec_c224350_consent_order_2024.pdf \
	../output/reopened_02_esd_gowanus_gpp_2024.pdf \
	../output/reopened_02_esd_gowanus_technical_memo_2024.pdf \
	../output/reopened_03_17dcp067k_eas.pdf \
	../output/reopened_03_append2_feis.pdf \
	../output/reopened_05_dof_map_2008.pdf \
	../output/reopened_05_dof_map_2021.pdf \
	../output/reopened_06_dof_map_2014.pdf \
	../output/reopened_06_dof_map_2025.pdf \
	../output/reopened_06_dec_c203182_bcp_application.pdf \
	../output/reopened_06_dob_zd1_220212918.pdf \
	../output/reopened_08_jackson_cpc_180385.pdf \
	../output/reopened_10_dof_before_2008.pdf \
	../output/reopened_10_dof_after_2019.pdf

include ../../../shared/code/generic.make

../output/reopened_02_dec_c224350_application_2022.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224350/Application.BCP.C224350.2022-01-13.Complete%20Application.pdf' --output ../temp/reopened_02_dec_c224350_application_2022.pdf
	cd ../temp && sed -n '/  reopened_02_dec_c224350_application_2022.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_02_dec_c224350_application_2022.pdf $@

../output/reopened_02_dec_c224350_consent_order_2024.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C224350/Consent%20Order.BCP.C224350.2024-04-01.318_Nevins_Street.pdf' --output ../temp/reopened_02_dec_c224350_consent_order_2024.pdf
	cd ../temp && sed -n '/  reopened_02_dec_c224350_consent_order_2024.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_02_dec_c224350_consent_order_2024.pdf $@

../output/reopened_02_esd_gowanus_gpp_2024.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://esd.ny.gov/sites/default/files/media/document/Gowanus-Neighborhood-Development-Proposed-General-Project-Plan.pdf' --output ../temp/reopened_02_esd_gowanus_gpp_2024.pdf
	cd ../temp && sed -n '/  reopened_02_esd_gowanus_gpp_2024.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_02_esd_gowanus_gpp_2024.pdf $@

../output/reopened_02_esd_gowanus_technical_memo_2024.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://esd.ny.gov/sites/default/files/media/document/Item-VA-Exhibit%203-Gowanus-ESD-Technical-Memorandum.pdf' --output ../temp/reopened_02_esd_gowanus_technical_memo_2024.pdf
	cd ../temp && sed -n '/  reopened_02_esd_gowanus_technical_memo_2024.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_02_esd_gowanus_technical_memo_2024.pdf $@

../output/reopened_03_17dcp067k_eas.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/eas/17dcp067k_eas.pdf' --output ../temp/reopened_03_17dcp067k_eas.pdf
	cd ../temp && sed -n '/  reopened_03_17dcp067k_eas.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_03_17dcp067k_eas.pdf $@

../output/reopened_03_append2_feis.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://www1.nyc.gov/assets/planning/download/pdf/applicants/env-review/960-franklin-ave/append2-feis.pdf' --output ../temp/reopened_03_append2_feis.pdf
	cd ../temp && sed -n '/  reopened_03_append2_feis.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_03_append2_feis.pdf $@

../output/reopened_05_dof_map_2008.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/40042820081207105706' --output ../temp/reopened_05_dof_map_2008.pdf
	cd ../temp && sed -n '/  reopened_05_dof_map_2008.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_05_dof_map_2008.pdf $@

../output/reopened_05_dof_map_2021.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/40042820210609123051' --output ../temp/reopened_05_dof_map_2021.pdf
	cd ../temp && sed -n '/  reopened_05_dof_map_2021.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_05_dof_map_2021.pdf $@

../output/reopened_06_dof_map_2014.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20304320140109152807' --output ../temp/reopened_06_dof_map_2014.pdf
	cd ../temp && sed -n '/  reopened_06_dof_map_2014.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_06_dof_map_2014.pdf $@

../output/reopened_06_dof_map_2025.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20304320250507162556' --output ../temp/reopened_06_dof_map_2025.pdf
	cd ../temp && sed -n '/  reopened_06_dof_map_2025.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_06_dof_map_2025.pdf $@

../output/reopened_06_dec_c203182_bcp_application.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://extapps.dec.ny.gov/data/DecDocs/C203182/Application.BCP.C203182.2024-12-04.Complete%20BCP%20Application.pdf' --output ../temp/reopened_06_dec_c203182_bcp_application.pdf
	cd ../temp && sed -n '/  reopened_06_dec_c203182_bcp_application.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_06_dec_c203182_bcp_application.pdf $@

../output/reopened_06_dob_zd1_220212918.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://www.pincusco.com/wp-content/uploads/2026/04/ZD1-ES443460578-2026_03_31-10_49_35.pdf' --output ../temp/reopened_06_dob_zd1_220212918.pdf
	cd ../temp && sed -n '/  reopened_06_dob_zd1_220212918.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_06_dob_zd1_220212918.pdf $@

../output/reopened_08_jackson_cpc_180385.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://www.nyc.gov/assets/planning/download/pdf/about/cpc/180385.pdf' --output ../temp/reopened_08_jackson_cpc_180385.pdf
	cd ../temp && sed -n '/  reopened_08_jackson_cpc_180385.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_08_jackson_cpc_180385.pdf $@

../output/reopened_10_dof_before_2008.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20330820081205152609' --output ../temp/reopened_10_dof_before_2008.pdf
	cd ../temp && sed -n '/  reopened_10_dof_before_2008.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_10_dof_before_2008.pdf $@

../output/reopened_10_dof_after_2019.pdf: reopened_batch.make reopened_batch_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location --user-agent 'Mozilla/5.0' 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20330820190917174936' --output ../temp/reopened_10_dof_after_2019.pdf
	cd ../temp && sed -n '/  reopened_10_dof_after_2019.pdf$$/p' ../code/reopened_batch_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/reopened_10_dof_after_2019.pdf $@

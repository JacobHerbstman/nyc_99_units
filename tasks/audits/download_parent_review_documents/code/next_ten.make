include ../../../shared/code/shell_functions.make

all: ../output/concourse_310_322_rir_2020.pdf \
	../output/concourse_261_esa_2021.pdf \
	../output/wallabout_appraisal_2023.pdf \
	../output/willets_phase1_smp_2023.pdf \
	../output/concourse_261_315_smp_2025.pdf \
	../output/concourse_261_315_coc_2025.pdf \
	../output/wallabout_dof_2021.pdf \
	../output/rockaway_dof_2024.pdf \
	../output/concourse_261_dof_2015.pdf

include ../../../shared/code/generic.make

../output/concourse_310_322_rir_2020.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C203121/Report.BCP.C203121.2020-07-01.Final%20Remedial%20Investigation%20Report.pdf' --output ../temp/concourse_310_322_rir_2020.pdf
	cd ../temp && sed -n '/  concourse_310_322_rir_2020.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/concourse_310_322_rir_2020.pdf $@

../output/concourse_261_esa_2021.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C203151/Report.BCP.C203151.2023-07-25.Remedial%20Investigation%20Report%20_Lot%201%20App.%20A%20_%20File%202%20of%202.pdf' --output ../temp/concourse_261_esa_2021.pdf
	cd ../temp && sed -n '/  concourse_261_esa_2021.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/concourse_261_esa_2021.pdf $@

../output/wallabout_appraisal_2023.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://mayafiles.tase.co.il/rpdf/1563001-1564000/P1563409-01.pdf' --output ../temp/wallabout_appraisal_2023.pdf
	cd ../temp && sed -n '/  wallabout_appraisal_2023.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/wallabout_appraisal_2023.pdf $@

../output/willets_phase1_smp_2023.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C241146H/Work%20Plan.BCP.C241146H.2023-12-08.Final%20Site%20Management%20Plan.pdf' --output ../temp/willets_phase1_smp_2023.pdf
	cd ../temp && sed -n '/  willets_phase1_smp_2023.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/willets_phase1_smp_2023.pdf $@

../output/concourse_261_315_smp_2025.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C203151/Work%20Plan.BCP.C203151.2025-12-10.SMP.pdf' --output ../temp/concourse_261_315_smp_2025.pdf
	cd ../temp && sed -n '/  concourse_261_315_smp_2025.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/concourse_261_315_smp_2025.pdf $@

../output/concourse_261_315_coc_2025.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://extapps.dec.ny.gov/data/DecDocs/C203151/Certificate%20of%20Completion.BCP.C203151.2025-12-26.Copyrite_Plastic_Sheets_COC.pdf' --output ../temp/concourse_261_315_coc_2025.pdf
	cd ../temp && sed -n '/  concourse_261_315_coc_2025.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/concourse_261_315_coc_2025.pdf $@

../output/wallabout_dof_2021.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30224920210108124517' --output ../temp/wallabout_dof_2021.pdf
	cd ../temp && sed -n '/  wallabout_dof_2021.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/wallabout_dof_2021.pdf $@

../output/rockaway_dof_2024.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/41553720240626105013' --output ../temp/rockaway_dof_2024.pdf
	cd ../temp && sed -n '/  rockaway_dof_2024.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/rockaway_dof_2024.pdf $@

../output/concourse_261_dof_2015.pdf: next_ten.make site_research_next10_2026-09-22/sources.sha256 | $(OOPR)
	curl --fail --silent --show-error --location 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20234420151130181804' --output ../temp/concourse_261_dof_2015.pdf
	cd ../temp && sed -n '/  concourse_261_dof_2015.pdf$$/p' ../code/site_research_next10_2026-09-22/sources.sha256 | shasum -a 256 -c -
	mv ../temp/concourse_261_dof_2015.pdf $@

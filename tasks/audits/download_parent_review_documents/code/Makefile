include ../../../shared/code/shell_functions.make

all: ../output/1660_boone_bcp_application_2024-10-28.pdf ../output/4121_third_rawp_2025-10-01.pdf ../output/4133_third_rawp_2025-10-30.pdf ../output/4137_third_rawp_2025-07-31.pdf ../output/4121_third_fact_sheet_2026-09-04.pdf ../output/4133_third_fact_sheet_2026-09-02.pdf

../output/4121_third_rawp_2025-10-01.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/a42e12f9-ce9f-f011-8274-005056b05749/download' --output ../temp/4121_third_rawp.pdf
	mv ../temp/4121_third_rawp.pdf $@

../output/4133_third_rawp_2025-10-30.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/a7e7c9c4-b6b5-f011-827a-005056b05749/download' --output ../temp/4133_third_rawp.pdf
	mv ../temp/4133_third_rawp.pdf $@

../output/4137_third_rawp_2025-07-31.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/80ea4186-4b6e-f011-826d-005056b05749/download' --output ../temp/4137_third_rawp.pdf
	mv ../temp/4137_third_rawp.pdf $@

../output/4121_third_fact_sheet_2026-09-04.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/dd147366-11a8-f111-82a3-005056b05749/download' --output ../temp/4121_third_fact_sheet.pdf
	mv ../temp/4121_third_fact_sheet.pdf $@

../output/4133_third_fact_sheet_2026-09-02.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 180 'https://a002-epic.nyc.gov/api/files/5b698ceb-c3a7-f111-82a3-005056b05749/download' --output ../temp/4133_third_fact_sheet.pdf
	mv ../temp/4133_third_fact_sheet.pdf $@

../output/1660_boone_bcp_application_2024-10-28.pdf: Makefile | ../output ../temp
	curl --fail --location --retry 2 'https://extapps.dec.ny.gov/data/DecDocs/C203130/Application.BCP.C203130.2024-10-28.Complete%20BCP%20Application.pdf' --output ../temp/1660_boone_bcp_application.pdf
	pdfinfo ../temp/1660_boone_bcp_application.pdf > /dev/null
	mv ../temp/1660_boone_bcp_application.pdf $@

include boundary_documents.make
include dof_subset_validation.make
include filing_sites.make
include site_research.make
include site_research_batch10.make

include ../../../shared/code/generic.make

DOF_SUBSET_MAPS := 20297420081205110113 20297420230216165325 20367220200117121751 \
	20367220250919145859 20379720180104164133 20379720250603094306 \
	20394320091022131752 20394320201214173146 20396320190214154133 \
	20396320230214161010 20570020081206212858 20570020251119112812 \
	30042620081209191642 30042620250918151843 30042620260824112916 \
	30226520081205122526 30226520240625095122 30256720081205134723 \
	30256720250314151409 30307620191110112044 30307620220811171416 \
	30340020081205180757 30340020210723144407 40999920171228094756 \
	40999920220131162425

all: $(addprefix ../output/dof_map_,$(addsuffix .pdf,$(DOF_SUBSET_MAPS))) \
	../output/563_sackett_bcp_amendment_2026-03-18.pdf

../output/dof_map_%.pdf: Makefile dof_subset_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/$*' --output ../temp/dof_map_$*.pdf
	cd ../temp && sed -n '/  dof_map_$*.pdf$$/p' ../code/dof_subset_2026-09-15/sources.sha256 | shasum -a 256 -c -
	pdfinfo ../temp/dof_map_$*.pdf > /dev/null
	mv ../temp/dof_map_$*.pdf $@

../output/563_sackett_bcp_amendment_2026-03-18.pdf: Makefile dof_subset_2026-09-15/sources.sha256 | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 'https://extapps.dec.ny.gov/data/DecDocs/C224222/Agreement.BCP.C224222.2026-03-18.Amendment_No3_Multiple_Changes_563%20Sackett%20Street.pdf' --output ../temp/563_sackett_bcp_amendment_2026-03-18.pdf
	cd ../temp && sed -n '/  563_sackett_bcp_amendment_2026-03-18.pdf$$/p' ../code/dof_subset_2026-09-15/sources.sha256 | shasum -a 256 -c -
	pdfinfo ../temp/563_sackett_bcp_amendment_2026-03-18.pdf > /dev/null
	mv ../temp/563_sackett_bcp_amendment_2026-03-18.pdf $@

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

include ../../../shared/code/generic.make

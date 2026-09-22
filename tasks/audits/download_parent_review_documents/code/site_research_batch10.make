all: ../output/bedford_beverly_recorded_ee_2024-12-20.pdf \
	../output/bedford_beverly_rir_2023-10-26.pdf \
	../output/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf \
	../output/dof_map_30513520240607105717.pdf

../output/bedford_beverly_recorded_ee_2024-12-20.pdf: site_research_batch10.make | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C224384/Easement.BCP.C224384.2024-12-20.Recorded%20EE.pdf' -O ../temp/bedford_beverly_recorded_ee_2024-12-20.pdf
	printf '%s\n' 'a5e50b8678092d70f8209f2a9863d2e3ced6aff8fd4b70900edba41f113d6b8f  ../temp/bedford_beverly_recorded_ee_2024-12-20.pdf' | shasum -a 256 -c -
	mv ../temp/bedford_beverly_recorded_ee_2024-12-20.pdf $@

../output/bedford_beverly_rir_2023-10-26.pdf: site_research_batch10.make | ../output ../temp
	wget --no-use-server-timestamps -q 'https://extapps.dec.ny.gov/data/DecDocs/C224384/Report.BCP.C224384.2023-10-26.Remedial%20Investigation%20Report.pdf' -O ../temp/bedford_beverly_rir_2023-10-26.pdf
	printf '%s\n' 'd109faafca2d33be24b547777545ba30deccaaa3c46dfeeea1acea8c446df208  ../temp/bedford_beverly_rir_2023-10-26.pdf' | shasum -a 256 -c -
	mv ../temp/bedford_beverly_rir_2023-10-26.pdf $@

../output/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf: site_research_batch10.make | ../output ../temp
	wget --no-use-server-timestamps -q 'https://www.nyc.gov/assets/brooklyncb1/downloads/pdf/meeting-minutes/Combine_Public_Hearing_and_Board_Meeting_Minutes_2-8-22.pdf' -O ../temp/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf
	printf '%s\n' '354dce436b148da80ef32d377c87754fa29231126828b5d9dcd1d6e75e7061fe  ../temp/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf' | shasum -a 256 -c -
	mv ../temp/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf $@

../output/dof_map_30513520240607105717.pdf: site_research_batch10.make | ../output ../temp
	wget --no-use-server-timestamps -q 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30513520240607105717' -O ../temp/dof_map_30513520240607105717.pdf
	printf '%s\n' 'd098fb5dd5421a4aaed2a07585941bd505e4193a22945cde612cebde5dcb5258  ../temp/dof_map_30513520240607105717.pdf' | shasum -a 256 -c -
	mv ../temp/dof_map_30513520240607105717.pdf $@

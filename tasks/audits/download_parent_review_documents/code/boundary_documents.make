all: ../output/astoria_cove_geotechnical_2023-12.pdf ../output/turnbull_hdc_authorization_2026-06.pdf ../output/rockaway_village_tefra_2021-11-18.pdf ../output/boyland_zoning_B01328447.pdf ../output/grand_concourse_citizen_plan_2025-09.pdf ../output/grand_concourse_application_2025-08.pdf

../output/astoria_cove_geotechnical_2023-12.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://extapps.dec.ny.gov/data/DecDocs/C241295/Application.BCP.C241295.2023-12-01.Phase%20I%20Report%20.pdf' --output ../temp/astoria_cove_geotechnical_2023-12.pdf
	pdfinfo ../temp/astoria_cove_geotechnical_2023-12.pdf > /dev/null
	mv ../temp/astoria_cove_geotechnical_2023-12.pdf $@

../output/turnbull_hdc_authorization_2026-06.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://www.nychdc.com/sites/default/files/2026-06/0.%20Memo-Approval%20of%20an%20Authorizing%20Resolution%20relating%20to%20Multi%20Family%202026%20Series%20G-K-Final%20Signed.pdf' --output ../temp/turnbull_hdc_authorization_2026-06.pdf
	pdfinfo ../temp/turnbull_hdc_authorization_2026-06.pdf > /dev/null
	mv ../temp/turnbull_hdc_authorization_2026-06.pdf $@

../output/rockaway_village_tefra_2021-11-18.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://www.nychdc.com/sites/default/files/2021-11/Nov%2018%202021%20HDC%20TEFRA%20Notice%20-%20Final%2011.10.21.pdf' --output ../temp/rockaway_village_tefra_2021-11-18.pdf
	pdfinfo ../temp/rockaway_village_tefra_2021-11-18.pdf > /dev/null
	mv ../temp/rockaway_village_tefra_2021-11-18.pdf $@

../output/boyland_zoning_B01328447.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://www.pincusco.com/property-data/ZD1_B01328447_2.pdf' --output ../temp/boyland_zoning_B01328447.pdf
	pdfinfo ../temp/boyland_zoning_B01328447.pdf > /dev/null
	mv ../temp/boyland_zoning_B01328447.pdf $@

../output/grand_concourse_citizen_plan_2025-09.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://extapps.dec.ny.gov/data/DecDocs/C203188/Work%20Plan.BCP.C203188.2025-09-30.Citizen%20Participation%20Plan.pdf' --output ../temp/grand_concourse_citizen_plan_2025-09.pdf
	pdfinfo ../temp/grand_concourse_citizen_plan_2025-09.pdf > /dev/null
	mv ../temp/grand_concourse_citizen_plan_2025-09.pdf $@

../output/grand_concourse_application_2025-08.pdf: boundary_documents.make | ../output ../temp
	curl --fail --location --retry 2 --connect-timeout 20 --max-time 240 'https://extapps.dec.ny.gov/data/DecDocs/C203188/Application.BCP.C203188.2025-08-14.Complete%20Application.pdf' --output ../temp/grand_concourse_application_2025-08.pdf
	pdfinfo ../temp/grand_concourse_application_2025-08.pdf > /dev/null
	mv ../temp/grand_concourse_application_2025-08.pdf $@

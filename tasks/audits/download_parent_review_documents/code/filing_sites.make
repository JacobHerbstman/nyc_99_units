all: ../output/flatbush_ida_minutes_2020-05-12.pdf \
	../output/flatbush_tax_map_2008.pdf ../output/flatbush_tax_map_2020.pdf

../output/flatbush_ida_minutes_2020-05-12.pdf: filing_sites.make | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 'https://publicmarkets.nyc/sites/default/files/2020-08/IDA%20Board%20of%20Directors%20Meeting%20Minutes%20May%2012%202020.pdf' --output ../temp/flatbush_ida_minutes_2020-05-12.pdf
	pdfinfo ../temp/flatbush_ida_minutes_2020-05-12.pdf > /dev/null
	mv ../temp/flatbush_ida_minutes_2020-05-12.pdf $@

../output/flatbush_tax_map_2008.pdf: filing_sites.make | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30017420081209172959' --output ../temp/flatbush_tax_map_2008.pdf
	pdfinfo ../temp/flatbush_tax_map_2008.pdf > /dev/null
	mv ../temp/flatbush_tax_map_2008.pdf $@

../output/flatbush_tax_map_2020.pdf: filing_sites.make | ../output ../temp
	curl --fail --silent --show-error --location --retry 2 'https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30017420200212111425' --output ../temp/flatbush_tax_map_2020.pdf
	pdfinfo ../temp/flatbush_tax_map_2020.pdf > /dev/null
	mv ../temp/flatbush_tax_map_2020.pdf $@

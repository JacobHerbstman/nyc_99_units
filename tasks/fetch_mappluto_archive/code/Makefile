include ../../shared/code/shell_functions.make

all: ../output/mappluto_files.csv \
	../report/mappluto_files.txt

../output/mappluto_files.csv: source_files.csv Makefile \
	../output/dcp_mappluto_archive_09v1_mappluto_09v1.zip \
	../output/dcp_mappluto_archive_09v2_mappluto_09v2.zip \
	../output/dcp_mappluto_archive_10v1_mappluto_10v1.zip \
	../output/dcp_mappluto_archive_10v2_mappluto_10v2.zip \
	../output/dcp_mappluto_archive_11v1_mappluto_11v1.zip \
	../output/dcp_mappluto_archive_11v2_mappluto_11v2.zip \
	../output/dcp_mappluto_archive_12v1_mappluto_12v1.zip \
	../output/dcp_mappluto_archive_12v2_mappluto_12v2.zip \
	../output/dcp_mappluto_archive_13v1_mappluto_13v1.zip \
	../output/dcp_mappluto_archive_13v2_mappluto_13v2.zip \
	../output/dcp_mappluto_archive_14v1_mappluto_14v1.zip \
	../output/dcp_mappluto_archive_14v2_mappluto_14v2.zip \
	../output/dcp_mappluto_archive_15v1_mappluto_15v1.zip \
	../output/dcp_mappluto_archive_16v1_mappluto_16v1.zip \
	../output/dcp_mappluto_archive_16v2_mappluto_16v2.zip \
	../output/dcp_mappluto_archive_17v1_mappluto_17v1.zip \
	../output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip \
	../output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip \
	../output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip \
	../output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip \
	../output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip \
	../output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip \
	../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip \
	../output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip \
	../output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip \
	../output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip \
	../output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip \
	../output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip \
	../output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip \
	../output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip \
	../output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip \
	../output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip \
	../output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip \
	../output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip \
	../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip \
	../output/dcp_mappluto_current_20260501_mappluto_planning_content.json \
	../output/dcp_mappluto_current_25v4_meta_mappluto.pdf \
	../output/dcp_mappluto_current_25v4_nyc_mappluto_25v4_shp.zip \
	../output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip \
	../output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip \
	../output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip \
	../output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip \
	../output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip \
	../output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip \
	../output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip \
	../output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip \
	../output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip \
	../output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip \
	../output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip \
	../output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip \
	../output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip \
	../output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip \
	../output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip \
	../output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip \
	../output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip \
	../output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip \
	../output/dcp_pluto_archive_20260501_mappluto_archive_index.json \
	../output/dcp_pluto_current_20260501_mappluto_planning_content.json \
	../output/dcp_pluto_current_25v4_nyc_pluto_25v4_csv.zip \
	../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf \
	../output/dcp_pluto_current_25v4_pluto_readme.pdf | ../output
	cp $< $@

../output/dcp_mappluto_archive_09v1_mappluto_09v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_09v1.zip' -o $@.download
	printf '%s  %s\n' 7c186c4030f979af10653d4011ad27e365ee8438825f6e4e3c7355a669d767a8 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_09v2_mappluto_09v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_09v2.zip' -o $@.download
	printf '%s  %s\n' c6fd31aee3a2d00a1d4ec756d9915f8d67e4a8507c37db138f449330a993fb00 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_10v1_mappluto_10v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_10v1.zip' -o $@.download
	printf '%s  %s\n' cf3262f315be2a4b8817255c433a79034648000aeb7920670b7894050180cfb5 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_10v2_mappluto_10v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_10v2.zip' -o $@.download
	printf '%s  %s\n' 0027277fb28149f1adaaa97e9c91eadab206f758b6dfe88d754c6949d1ed6c80 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_11v1_mappluto_11v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_11v1.zip' -o $@.download
	printf '%s  %s\n' 74935db6c508647b8f6f1f3cc2573a0624790dfdf886032bac47d9805d22dfb1 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_11v2_mappluto_11v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_11v2.zip' -o $@.download
	printf '%s  %s\n' 512c5c51a4f6ce9f5a5e2a23834a39b5f7a7b9dc3f9b4ceca4749d472d698947 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_12v1_mappluto_12v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_12v1.zip' -o $@.download
	printf '%s  %s\n' fa69b49b49adaa18fc70046bc99208eac2907784a6d7bff637b9cbd9b97b936b $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_12v2_mappluto_12v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_12v2.zip' -o $@.download
	printf '%s  %s\n' 3bdba0bc14547690db05e508bf105ac6ae1785049de7679df2508ce9d919d21d $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_13v1_mappluto_13v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_13v1.zip' -o $@.download
	printf '%s  %s\n' 6d37abdda46b14d7420e42e190b0e2512b14fd61e0c4f3c88b17c19cb10f50d3 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_13v2_mappluto_13v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_13v2.zip' -o $@.download
	printf '%s  %s\n' 638f28381133583dfe4f5728d582c4a3c53fdeb0dfcdeb80b9f7c473924dc8c6 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_14v1_mappluto_14v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_14v1.zip' -o $@.download
	printf '%s  %s\n' 9c67f46c953d36d9f2c1f71e8c27a8e6075e8a62e7acad01e6f5815855019a2b $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_14v2_mappluto_14v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_14v2.zip' -o $@.download
	printf '%s  %s\n' 180371f109ce2f72d5c66c94876086842772f90daa19107928063e0f4da86e39 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_15v1_mappluto_15v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_15v1.zip' -o $@.download
	printf '%s  %s\n' 5a387cdd34bc66966827240169dc0102d09120a36926b4594535a0fc9cc385e4 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_16v1_mappluto_16v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_16v1.zip' -o $@.download
	printf '%s  %s\n' 515876c01615973b406b3134019c894b690c9fe9f8a9bf497c00c1d14c4bd7b2 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_16v2_mappluto_16v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_16v2.zip' -o $@.download
	printf '%s  %s\n' a4e7512f0c35035bb82534c73239123e7d81e6c1d50e3c0cb8901498ba117691 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_17v1_mappluto_17v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_17v1.zip' -o $@.download
	printf '%s  %s\n' 80f051555feb272e669e6b858230b98fbf2abf8c9cdb25bedf1248fda9352319 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/mappluto_17v1_1.zip?r=2' -o $@.download
	printf '%s  %s\n' a042208f2532208082229c90a4d45ee836c6d52fab99771feb0889105d9d2ef3 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_18v1_1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 8fc5f00aa1f97432f9f4ea03b421539b4e5c69f879cab7ad35944aa3d04d6fba $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_18v2_1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 8061daa84e8001f9cf46574967cbdbb80bea3a05047ff4fce6276842bcca552b $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_18v2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 4275f7d997e2e9309bf3b71d0c16080b913b06ec92e2e587c279f52406d9d85f $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_19v1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 5fe68f6946bf929b01c09320c4d332e241e85d171ce3207442d916ab91298066 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_19v2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 998cff383d2eb431749cea3286258caa154c9a55d05a2b099000cd0aa1caf178 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20260501_mappluto_archive_index.json: ../../../data_raw/dcp_mappluto_archive/20260501/mappluto_archive_index.json Makefile | ../output
	printf '%s  %s\n' 6f96a0a39c8158121784b0b77000c80516880d97d7245d268b551f5a200dc286 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 9175343129e624cf013a599c2970d43912f7d07e3a9671963732bd7bf2373e7d $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 8b340821ef9360ecd2dc5bf5158a45d884fdb4a443d8aee8dd460dea9c1d8a53 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v3_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 0ec17ca2f846ed6e7d06be63da81307984073a9d8e3ff782b3b5b67a23d24bcc $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v4_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 172f5fc2fb8e414ba6770f568abd16a338db2f5ddb175ebb7f742dcc6f262a0d $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v5_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 63ee21b647c64e1f038e6cb0a66742d855c9273d6e7c84b0c2fbd0399d56bcd8 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v6_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 2916244173b227d12ad0894be77d1e8fa66cf8c134a202099a7b5820c0e58ee1 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v7_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 669e7d522682e39bc083bfef700470678c1d7580561874bafad491de409c8e2f $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_20v8_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 80b2e4a32133536466838c6bc552083c9f7bbbcca29c366f1acc331dcbaaeb1d $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_21v1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' e37f30e11cd6569170d687b97aae2142cac987ed2a75495e60961c1bdb35cde6 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_21v3_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 8ea278260c6a0ca5caae4fe01edec5be5c0aee2460ffa9c379184cbfa10d7d20 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_22v1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 52974c12f498be1c33c2f8767b229148707457cd55c1958b40f36c6b4184c42a $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_22v2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 7adf2591d42450e6960e4d1f7ba0e0f52e2017c50f737f9b27c0ca2aa769e918 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 0939ef60d8ccd8231b853dffc596b8a67e63ec88273e01018539002a757b4208 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v1_1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 48b97117d4d8f4841a3b2cd9e82d940189345a3b695853464dbb70adb451f9b0 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v1_2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 2977162c6259ab585cd55c740603cff634d46a14d2f2826c6ca3bd401be6cfbb $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v2_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 6ebd27cd1c7d7d4d8e64f9584eb9a1ffbc1dfa4599d23ab698886c434bfc13e1 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v3_arc_shp.zip' -o $@.download
	printf '%s  %s\n' 54d30e6ac6a51762cb8e57ca90dbfcbab3b314c78761f3c7612f26ea4502968d $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/mappluto/nyc_mappluto_23v3_1_arc_shp.zip' -o $@.download
	printf '%s  %s\n' be30304f951e542fa28c6757b458d84987418fdcbcc0479d6d8f75cc93b864e2 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_mappluto_current_20260501_mappluto_planning_content.json: ../../../data_raw/dcp_mappluto_current/20260501/mappluto_planning_content.json Makefile | ../output
	printf '%s  %s\n' c2a11df383c8c60f5b27dc7f7f6a180d0fc63c263487677893eb2e66f89900c7 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_25v4_meta_mappluto.pdf: ../../../data_raw/dcp_mappluto_current/25v4/meta_mappluto.pdf Makefile | ../output
	printf '%s  %s\n' ad1f420cca33389a65c6deb9cf89a64442491922d9519f3785ab87d81fa36754 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_mappluto_current_25v4_nyc_mappluto_25v4_shp.zip: ../../../data_raw/dcp_mappluto_current/25v4/nyc_mappluto_25v4_shp.zip Makefile | ../output
	printf '%s  %s\n' 99df5709806c4e1c4392c7759ba88b593fb87ff4aff5b955b4c925d98b19db92 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_09v1.zip' -o $@.download
	printf '%s  %s\n' a05fde6a388477c29c85633181633e055023cf01bd48cf2c4aa195c74fb06a76 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_09v2.zip' -o $@.download
	printf '%s  %s\n' cf56a9f465f74e4413ddc0c4e9aa33af5cde70c960c599e0c1aa9ad67118041c $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_10v1.zip' -o $@.download
	printf '%s  %s\n' 0486b8ca5be901d3d40aacae15ea0b7bc964fac3dbcbd51de88c329c3844397a $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_10v2.zip' -o $@.download
	printf '%s  %s\n' fc4dd018ecd2b9069f3548e91bf38adcef75a92e11a339da50cf26030cba2b0b $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_11v1.zip' -o $@.download
	printf '%s  %s\n' 79017f9771a9e9d0c111941ea3f59b995b85b14fbe969939ccdff80154a31e67 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_11v2.zip' -o $@.download
	printf '%s  %s\n' 07229addf969cc82e7a53107a247eb3fa9010cdb2549c556a458b9986182c3ff $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_12v1.zip' -o $@.download
	printf '%s  %s\n' 6de314dbdd818b18b3734f24a0b4f5e3b2e5f2a47cd1d2da11f3db0e15174fda $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_12v2.zip' -o $@.download
	printf '%s  %s\n' 589f5f9a752a63b0e9c352bb3169e150b6463db3ded06a56795abfd466d9ce91 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_13v1.zip' -o $@.download
	printf '%s  %s\n' da696eb7388b92b6f7ffc66551bddb46525307f31d94440bc613fe76ec055971 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_13v2.zip' -o $@.download
	printf '%s  %s\n' 473a96d211d917d1e6630b9379221385495e47c6f604f49ac66adb9d268e94e8 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_14v1.zip' -o $@.download
	printf '%s  %s\n' 5598e9d660df28035a06d425ce0f1d19e105fa9f42f69dc0127d409532adb4ce $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_14v2.zip' -o $@.download
	printf '%s  %s\n' 58d3ecb9d1fa8bbd75af1dc6a7fcf8b2c6c993d3be3e4c0e0b22965ac3e32360 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_15v1.zip' -o $@.download
	printf '%s  %s\n' 7373d132047cb320e642ab3bb3aef015abf8f8916d5ebd611f5c947d66cbb9ea $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_16v1.zip' -o $@.download
	printf '%s  %s\n' c43ee7c1218796dbd049955a7641449ed79d07fe80e3412024142c39dfe397f6 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_16v2.zip' -o $@.download
	printf '%s  %s\n' 0a5144f0ea53e6b7f9133d2723b580461daa42a77084ba44cfbdf81d841ea4c5 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_17v1.zip?r=1' -o $@.download
	printf '%s  %s\n' a11baaf485d5a91c2b859972706da05dfb768e760e0154db1bb2b72012525b5f $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_17v1_1.zip?r=1' -o $@.download
	printf '%s  %s\n' 1a700b25d1f26d0ce06198499e708eab4c5d6f2e39362f663abaf30a7ae3d4cf $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip: Makefile | ../output
	curl --fail --location --retry 3 'https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/pluto/nyc_pluto_18v1.zip' -o $@.download
	printf '%s  %s\n' 545e0dfb0899012bae49d2c6ec3c038dcd9876bf81133d69260a31a60dd34848 $@.download | shasum -a 256 -c -
	mv $@.download $@

../output/dcp_pluto_archive_20260501_mappluto_archive_index.json: ../../../data_raw/dcp_mappluto_archive/20260501/mappluto_archive_index.json Makefile | ../output
	printf '%s  %s\n' 6f96a0a39c8158121784b0b77000c80516880d97d7245d268b551f5a200dc286 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_20260501_mappluto_planning_content.json: ../../../data_raw/dcp_pluto_current/20260501/mappluto_planning_content.json Makefile | ../output
	printf '%s  %s\n' c2a11df383c8c60f5b27dc7f7f6a180d0fc63c263487677893eb2e66f89900c7 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_nyc_pluto_25v4_csv.zip: ../../../data_raw/dcp_pluto_current/25v4/nyc_pluto_25v4_csv.zip Makefile | ../output
	printf '%s  %s\n' 3306cf4cde7e4989693e752931e254680f1fa95783f1849ce1eca141c30ce9fd $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_datadictionary.pdf: ../../../data_raw/dcp_pluto_current/25v4/pluto_datadictionary.pdf Makefile | ../output
	printf '%s  %s\n' b831d1c2784771cc071ab4b0eac55489f0a3d6ad7986d5045b205a4a1ab171b1 $< | shasum -a 256 -c -
	cp $< $@

../output/dcp_pluto_current_25v4_pluto_readme.pdf: ../../../data_raw/dcp_pluto_current/25v4/pluto_readme.pdf Makefile | ../output
	printf '%s  %s\n' 09e430adf31a7d71942a44fe2388e53cce6a36a3b55849bd8d2e731006941f1d $< | shasum -a 256 -c -
	cp $< $@




../report/mappluto_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/mappluto_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_files


include ../../shared/code/generic.make

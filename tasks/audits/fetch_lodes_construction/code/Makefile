all: ../output/ny_wac_S000_JT02_2019.csv.gz ../output/ny_wac_SE01_JT02_2019.csv.gz ../output/ny_wac_SE02_JT02_2019.csv.gz ../output/ny_wac_SE03_JT02_2019.csv.gz ../output/ny_wac_S000_JT02_2020.csv.gz ../output/ny_wac_SE01_JT02_2020.csv.gz ../output/ny_wac_SE02_JT02_2020.csv.gz ../output/ny_wac_SE03_JT02_2020.csv.gz ../output/ny_wac_S000_JT02_2021.csv.gz ../output/ny_wac_SE01_JT02_2021.csv.gz ../output/ny_wac_SE02_JT02_2021.csv.gz ../output/ny_wac_SE03_JT02_2021.csv.gz ../output/ny_wac_S000_JT02_2022.csv.gz ../output/ny_wac_SE01_JT02_2022.csv.gz ../output/ny_wac_SE02_JT02_2022.csv.gz ../output/ny_wac_SE03_JT02_2022.csv.gz ../output/ny_wac_S000_JT02_2023.csv.gz ../output/ny_wac_SE01_JT02_2023.csv.gz ../output/ny_wac_SE02_JT02_2023.csv.gz ../output/ny_wac_SE03_JT02_2023.csv.gz ../output/ny_xwalk.csv.gz ../output/version.txt ../output/lodes_ny.sha256sum ../report/ny_wac_S000_JT02_2019.txt ../report/ny_wac_SE01_JT02_2019.txt ../report/ny_wac_SE02_JT02_2019.txt ../report/ny_wac_SE03_JT02_2019.txt ../report/ny_wac_S000_JT02_2020.txt ../report/ny_wac_SE01_JT02_2020.txt ../report/ny_wac_SE02_JT02_2020.txt ../report/ny_wac_SE03_JT02_2020.txt ../report/ny_wac_S000_JT02_2021.txt ../report/ny_wac_SE01_JT02_2021.txt ../report/ny_wac_SE02_JT02_2021.txt ../report/ny_wac_SE03_JT02_2021.txt ../report/ny_wac_S000_JT02_2022.txt ../report/ny_wac_SE01_JT02_2022.txt ../report/ny_wac_SE02_JT02_2022.txt ../report/ny_wac_SE03_JT02_2022.txt ../report/ny_wac_S000_JT02_2023.txt ../report/ny_wac_SE01_JT02_2023.txt ../report/ny_wac_SE02_JT02_2023.txt ../report/ny_wac_SE03_JT02_2023.txt ../report/ny_xwalk.txt

include download_recipes.make

../report/%.txt: report_source.R ../output/%.csv.gz ../output/lodes_ny.sha256sum ../../../shared/code/write_data_report.R | ../report
	$(R) $< $*

../report:
	mkdir -p $@

include ../../generic.make

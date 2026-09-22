../output/%_36005.csv: download_recipes.make | ../output
	wget -q --no-use-server-timestamps --timeout=60 --tries=2 -O $@.part https://data.bls.gov/cew/data/api/$*/a/area/36005.csv && mv $@.part $@

../output/%_36047.csv: download_recipes.make | ../output
	wget -q --no-use-server-timestamps --timeout=60 --tries=2 -O $@.part https://data.bls.gov/cew/data/api/$*/a/area/36047.csv && mv $@.part $@

../output/%_36061.csv: download_recipes.make | ../output
	wget -q --no-use-server-timestamps --timeout=60 --tries=2 -O $@.part https://data.bls.gov/cew/data/api/$*/a/area/36061.csv && mv $@.part $@

../output/%_36081.csv: download_recipes.make | ../output
	wget -q --no-use-server-timestamps --timeout=60 --tries=2 -O $@.part https://data.bls.gov/cew/data/api/$*/a/area/36081.csv && mv $@.part $@

../output/%_36085.csv: download_recipes.make | ../output
	wget -q --no-use-server-timestamps --timeout=60 --tries=2 -O $@.part https://data.bls.gov/cew/data/api/$*/a/area/36085.csv && mv $@.part $@

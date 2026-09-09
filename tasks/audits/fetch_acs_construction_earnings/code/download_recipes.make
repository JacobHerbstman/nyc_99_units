../output/B24031.json: download_recipes.make | ../output
	wget --no-use-server-timestamps --quiet --timeout=60 --tries=2 -O ../output/B24031.json.part 'https://api.census.gov/data/2023/acs/acs5/groups/B24031.json'
	mv ../output/B24031.json.part $@

../output/B24041.json: download_recipes.make | ../output
	wget --no-use-server-timestamps --quiet --timeout=60 --tries=2 -O ../output/B24041.json.part 'https://api.census.gov/data/2023/acs/acs5/groups/B24041.json'
	mv ../output/B24041.json.part $@


../output/nyc_puma_2020_2026-09-08.geojson: download_recipes.make | ../output
	wget --no-use-server-timestamps --quiet --timeout=60 --tries=2 -O ../output/nyc_puma_2020_2026-09-08.geojson.part 'https://data.cityofnewyork.us/resource/pikk-p9nv.geojson?$$limit=100'
	mv ../output/nyc_puma_2020_2026-09-08.geojson.part $@

../output/community_districts_2026-09-08.geojson: download_recipes.make | ../output
	wget --no-use-server-timestamps --quiet --timeout=60 --tries=2 -O ../output/community_districts_2026-09-08.geojson.part 'https://data.cityofnewyork.us/resource/5crt-au7u.geojson?$$limit=100'
	mv ../output/community_districts_2026-09-08.geojson.part $@

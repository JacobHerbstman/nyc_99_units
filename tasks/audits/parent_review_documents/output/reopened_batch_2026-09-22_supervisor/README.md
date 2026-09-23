# Supervisor source checks, 22 September 2026

`broadway_bis_123766433.json` is the unchanged NYC DOB BIS Jobs response to
`https://data.cityofnewyork.us/resource/ic3t-wcy2.json?$where=job__=%27123766433%27&$limit=100`.
Retrieved 2026-09-22; SHA-256 `30a28ee3f115ad578ffe52690fa884cad5f26bb5ee2f1dc0f90798ec8d115e40`.
It contains documents 01 and 02, with December 16, 2022 permit actions, no sign-off, and withdrawal_flag=0. It supports an earlier permit, not formal withdrawal.

`jamaica90_bis_420666256.json` is the unchanged public response at https://data.cityofnewyork.us/resource/ic3t-wcy2.json?job__=420666256. Retrieved 2026-09-22; SHA-256 `b0be6cd1af6bda371866c072d2b5f377482a1bb5c9fa9d53ab53c348743b2b19`. The BIS record retains 203 proposed units and no verified withdrawal; the NOW record has 213 proposed units.

`jamaica90_now_q01233524.json` is the unchanged public response at https://data.cityofnewyork.us/resource/w9ak-ipjd.json?job_filing_number=Q01233524-I1. Retrieved 2026-09-22; SHA-256 `def452a37bc3bb215bdf190d32b0f5216fea0f756fb199130ab9345a5b172198`. The BIS record retains 203 proposed units and no verified withdrawal; the NOW record has 213 proposed units.

The Jackson CPC resolution was successfully saved after the researcher's download failure. Its unchanged bytes, URL and hash are registered in `../reopened_batch_2026-09-22/sources.csv` and published as `../../output/reopened_08_jackson_cpc_180385.pdf`.

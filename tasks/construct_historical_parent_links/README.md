# Construct historical parent links

The evidence that two historical filings belong to one development.

`extract_historical_parent_link_fields.R` selects the historical linkage
universe: 23Q4 Housing Database New Building filings from 2010 through 2023
with at least six Class A units and a matched pre-filing parcel. 2010 filings
let a 2011 filing be tested as a parent anchor. Filings in an accepted manual
link (`parent_opportunities_manual/output/pair_decisions.csv`) stay in even
without land data. Each filing gets its description, job references and MPP
project codes, coordinates, and the owner and former lot recorded for its lot
in its own pre-filing release. Owners come only from the archived parcel map;
later DOB owners do not supply historical links.

`construct_historical_parent_pairs.R` takes every pair of filings within 365
days and records: the same filing lot; a strict lot-history link (the same
matched lot or archived former lot, without relying on a crosswalk recovery or
a later lot change); a lot link that does rely on one; an explicit job
reference or shared project code; the same owner within 100 m; and exact
polygon touching. Touching is tested in the MapPLUTO shapefile of the earlier
filing's release, among the lots of filings that used that release, and joins
a pair when the filings are at most 30 days apart or other evidence supports
it. The output keeps pairs within 250 m or with any of this evidence.

Parent construction reads both outputs.

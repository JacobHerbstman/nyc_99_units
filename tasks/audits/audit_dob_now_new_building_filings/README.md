# Audit staged DOB NOW New Building filings

This audit checks identifier uniqueness, date and unit coverage, BBL and BIN
coverage, and construction-area coverage in the staged DOB NOW filing files.
It classifies every source row by whether the filing's explicit borough, block,
and lot fields agree with the source's separate reported `bbl` field. The full
disagreement ledger keeps the source identifiers and project fields needed for
manual review. It does not feed the production analysis.

The two BBL measures are not treated as interchangeable. `filing_bbl` is built
from the borough, block, and lot entered for the filing. `reported_bbl` preserves
the separate BBL supplied by the DOB NOW Open Data extract. A common reported
BBL can help identify filings tied to one underlying site, while distinct filing
BBLs can identify the lots assigned to separate proposed buildings.

## Benchmark: 1800 Park Avenue

The seven initial filings submitted on March 4, 2026—M01338581, M01338583,
M01338590, M01338597, M01338604, M01338609, and M01338614—each propose 99
units and list seven distinct filing lots. The separate reported BBL points to
Manhattan block 1749, lot 33 for all seven; one filing also lists lot 33 as its
explicit filing lot. This is the benchmark case for testing that parent
construction retains the common-site signal without erasing the seven
filing-lot signals.

The Real Deal article to retain for the slides is [“David Bistricer embraces
99-unit playbook”](https://therealdeal.com/new-york/2026/03/06/david-bistricer-embraces-99-unit-playbook/),
published March 6, 2026. It reports that Clipper Equity planned seven buildings
at the East Harlem site.

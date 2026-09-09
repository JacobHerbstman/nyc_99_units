# Construction earnings bins at workplaces

Audit only. Census LODES8 New York WAC JT02 (all private jobs), 2019–2023; CNS04 counts construction-sector jobs, including all occupations. WAC locations represent workplaces, not residences. Earnings segments are nominal monthly amounts: SE01 <=1250; SE02 1251–3333; SE03 >3333. These are coarse earnings bins, not hourly wages or compensation inclusive of benefits. Multiple jobs per worker can be counted. Employer offices may differ from building sites. Published counts use disclosure protection and modeled workplace allocation.

Inputs are linked source WAC files and the Census block crosswalk, plus existing NYC DCP district boundaries. Assign 2020-block internal points to 71 administrative areas in EPSG2263; retain park areas and unmatched points in block data and report them. No nearest-district reassignment. Main maps show the 59 standard districts. Assert one polygon per assigned point, unique join keys, and exact reconciliation of the three construction earnings bins to S000 at each block-year.

Outputs: block-year construction counts with district assignment; district-year counts and shares; maps of pooled 2019–2023 earnings-bin shares and annual high-bin shares; district stacked bars. Pool by adding job counts across years, not averaging district percentages; pooled counts are job-years. Zero-count districts have missing shares. Dataset reports and computed findings are in report/.

Run make in code/. Source snapshot September 8, 2026; see acquisition version.txt and verified publisher checksums. All work remains in audits.

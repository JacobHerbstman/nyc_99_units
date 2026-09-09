# QCEW construction pay by borough

Exploratory audit only. Inputs: BLS annual QCEW area slices, 2019–2023, from fetch_qcew_construction. Private ownership (5), all establishment sizes (0). Five counties map to NYC boroughs. Industries: 23 construction; 236 building construction; 2361 residential building construction; 237 heavy/civil engineering; 238 specialty trades. Categories overlap and must not be summed.

Outputs: borough-year-industry CSV and a two-page PDF showing annual nominal weekly pay and pay relative to Manhattan in the same year/industry. Standard data report in report/. Nondisclosed pay/employment/payroll remain missing, never zero. Missing source rows are explicitly flagged. Annual pay is payroll divided by annual average employment (published values retained); it is not an individual worker's annual earnings. No hourly conversion or inflation adjustment. Each year is shown separately.

QCEW includes covered wage/salary jobs, all occupations within each industry, and excludes most self-employment. Office location can differ from construction-site location, particularly for temporary sites. Data cannot identify the wage floor's bindingness at individual 99-unit projects.

Run make in code/. Source vintage: September 8, 2026. Code is an uncommitted audit addition to revision 7bbf6d5. No production inputs or framework are changed.

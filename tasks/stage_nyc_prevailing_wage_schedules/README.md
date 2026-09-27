# Stage NYC construction prevailing wage rates

Reads the Comptroller's construction worker prevailing wage schedules from
`fetch_nyc_prevailing_wage_schedules` into one table,
`nyc_prevailing_wage_rates_2018_2026.csv`: 2,157 rates in the eight July–June
schedules from 2018–19 through 2025–26. Each row is one rate in one schedule,
keyed by `schedule` and `rate_order`, its position in the schedule:

- `classification`, the trade section heading (84 distinct), and `rate_title`,
  with any description printed between the title and the rate;
- `effective_start` and `effective_end`: a rate that changes during the year
  has one row per effective period under the same title;
- `wage_per_hour`, `supplement_per_hour` (supplemental benefits) and their sum
  `total_per_hour`, in dollars.

The rates are the union rates for public work, citywide; they do not vary by
site. Overtime, shift and holiday rules, apprentice schedules and the notes on
overtime benefits are not kept. The one residential classification is the
plumber rate for one- to three-family homes.

`stage_wage_schedules.R` reads the PDF text with `pdftools`. After removing page
headers, footers and blank lines, every rate is an effective period followed
by its wage and benefit lines, which the script checks. A rate's title is the
nearest line above that reads as a title; the search stops at the section
heading, which then is the title, or at the previous rate or note on a rate,
where the previous title continues. Titles were reviewed for every schedule;
two rates in each steamfitter section share the title "Steamfitter -Temporary
Services", so titles are not unique within a schedule.

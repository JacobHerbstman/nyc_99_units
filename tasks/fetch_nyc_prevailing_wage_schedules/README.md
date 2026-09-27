# Fetch NYC construction prevailing wage schedules

Publishes the NYC Comptroller's construction worker prevailing wage schedules
(Labor Law Article 8, §220) for July 1, 2018 through June 30, 2026, captured
September 27, 2026 from the
[archived schedules](https://comptroller.nyc.gov/services/for-the-public/workers-rights/wage-schedules/prevailing-wage-archived-schedules/).
Each schedule sets the hourly wage and supplemental benefit rate of every trade
classification for public work in the city; the rates are the union rates, the
benchmark against which the 485-x construction wage floor ($40 an hour from
2024) and a developer's usual wages can be compared. They are citywide and do
not vary by site.

`nyc_construction_prevailing_wage_schedule_<year>.pdf` holds one schedule per
July–June year. The Comptroller amends the current year's schedule during the
year, so only closed years are captured; each archived file is the last
amendment of its year. `schedule_urls.csv` lists the source URLs. The capture
in `data_raw/nyc_prevailing_wage_schedules/2026-09-27/` is the source of record;
a schedule is downloaded only when its capture is missing, and
`code/checksums.sha256` verifies the captures and the published copies.
`stage_nyc_prevailing_wage_schedules` reads the rates into a table.

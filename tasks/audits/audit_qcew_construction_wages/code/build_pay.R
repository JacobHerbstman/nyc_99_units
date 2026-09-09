# setwd("tasks/audits/audit_qcew_construction_wages/code")
library(readr)
library(dplyr)
library(tidyr)
rows <- list()
for (year in 2019:2023) {
  for (county in c("36005", "36047", "36061", "36081", "36085")) {
    raw <- read_csv(paste0("../input/", year, "_", county, ".csv"), col_types = cols(area_fips = col_character(), industry_code = col_character()))
    stopifnot(all(raw$year == year), all(raw$area_fips == county), all(raw$qtr == "A"))
    rows[[paste(year, county)]] <- raw |> filter(own_code == 5, size_code == 0, industry_code %in% c("23", "236", "2361", "237", "238")) |>
      select(area_fips, year, industry_code, disclosure_code, annual_avg_estabs, annual_avg_emplvl, total_annual_wages, annual_avg_wkly_wage, avg_annual_pay) |>
      mutate(source_row = TRUE)
  }
}
pay <- bind_rows(rows)
stopifnot(!anyDuplicated(pay[c("area_fips", "year", "industry_code")]))
pay <- expand_grid(area_fips = c("36005", "36047", "36061", "36081", "36085"), year = 2019:2023, industry_code = c("23", "236", "2361", "237", "238")) |>
  left_join(pay, by = c("area_fips", "year", "industry_code"), relationship = "one-to-one") |>
  mutate(status = case_when(is.na(source_row) ~ "missing source row", disclosure_code == "N" ~ "not disclosed", TRUE ~ "published"),
         borough = recode(area_fips, `36005` = "Bronx", `36047` = "Brooklyn", `36061` = "Manhattan", `36081` = "Queens", `36085` = "Staten Island"),
         industry = recode(industry_code, `23` = "All construction", `236` = "Building construction", `2361` = "Residential building", `237` = "Heavy/civil engineering", `238` = "Specialty trades"),
         across(c(annual_avg_emplvl, total_annual_wages, annual_avg_wkly_wage, avg_annual_pay), ~ if_else(status == "published", .x, NA_real_))) |>
  select(-source_row) |> arrange(industry_code, area_fips, year)
stopifnot(nrow(pay) == 125, all(pay$annual_avg_wkly_wage[pay$status == "published"] > 0))
# Published annual average employment is rounded: allow that rounding in the payroll identity.
valid <- filter(pay, status == "published")
stopifnot(all(abs(valid$total_annual_wages - valid$avg_annual_pay * valid$annual_avg_emplvl) <= valid$avg_annual_pay * 0.51 + valid$annual_avg_emplvl * 0.51))
write_csv(pay, "../output/borough_construction_pay.csv")

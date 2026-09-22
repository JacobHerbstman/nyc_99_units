# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(jsonlite); library(dplyr); library(tidyr); library(readr); library(sf); library(stringr)})
rows <- fromJSON("../input/acs_2023_puma.json")
pumas <- as_tibble(rows[-1, , drop = FALSE], .name_repair = "minimal")
names(pumas) <- rows[1, ]
pumas <- pumas |> rename(puma = `public use microdata area`, puma_name = NAME)
stopifnot(!anyNA(pumas$puma), !anyDuplicated(pumas$puma), all(pumas$state == "36"))
puma_boundaries <- st_read("../input/nyc_puma_2020_2026-09-08.geojson", quiet = TRUE)
nyc_ids <- sprintf("%05d", as.integer(puma_boundaries$puma))
stopifnot(length(nyc_ids) == 55, !anyDuplicated(nyc_ids), all(nyc_ids %in% pumas$puma))
pumas <- pumas |> filter(puma %in% nyc_ids)
# Census names explicitly identify the districts represented by each PUMA.
parsed <- str_match(pumas$puma_name, "^NYC-(Manhattan|Bronx|Brooklyn|Queens|Staten Island) Community Districts? ([0-9]+(?: & [0-9]+)?)--")
stopifnot(!anyNA(parsed))
pumas$borough <- parsed[, 2]
pumas$district_group <- parsed[, 3]
pumas <- pumas |> mutate(borough_code = recode(borough, Manhattan = 1L, Bronx = 2L,
                                               Brooklyn = 3L, Queens = 4L, `Staten Island` = 5L),
                         pooled = grepl(" & ", district_group),
                         community_district = district_group) |>
  separate_longer_delim(community_district, delim = " & ") |>
  mutate(community_district = as.integer(community_district),
         boro_cd = 100L * borough_code + community_district)
cd <- st_read("../input/community_districts_2026-09-08.geojson", quiet = TRUE) |>
  mutate(boro_cd = as.integer(boro_cd)) |>
  filter(boro_cd %% 100 < 20)
stopifnot(nrow(cd) == 59, nrow(pumas) == 59, !anyDuplicated(cd$boro_cd),
          !anyDuplicated(pumas$boro_cd), setequal(cd$boro_cd, pumas$boro_cd),
          n_distinct(pumas$puma) == 55, sum(pumas$pooled) == 8)
results <- list()
for (table in c("B24031", "B24041")) {
  results[[table]] <- pumas |>
    transmute(boro_cd, borough, community_district, puma, puma_name, district_group, pooled,
              table, universe = ifelse(table == "B24031", "All employed", "Full-time, year-round"),
              period = "2019-2023", dollar_year = 2023L,
              estimate_raw = as.numeric(.data[[paste0(table, "_005E")]]),
              moe_raw = as.numeric(.data[[paste0(table, "_005M")]]),
              estimate_annotation = .data[[paste0(table, "_005EA")]],
              moe_annotation = .data[[paste0(table, "_005MA")]])
}
results <- bind_rows(results) |> mutate(
  estimate_status = case_when(estimate_annotation %in% c("250,000+", "2,500-") ~ "Bounded median",
                             is.na(estimate_raw) | estimate_raw < -1e8 ~ "Unavailable",
                             !is.na(estimate_annotation) & nzchar(estimate_annotation) ~ "Other annotation",
                             TRUE ~ "Numeric median"),
  earnings = if_else(estimate_status == "Numeric median", estimate_raw, NA_real_),
  moe = if_else(moe_raw >= 0 & (is.na(moe_annotation) | !nzchar(moe_annotation)), moe_raw, NA_real_),
  relative_moe = if_else(earnings > 0, moe / earnings, NA_real_),
  imprecise = relative_moe > .5,
  ci90_lower = earnings - moe, ci90_upper = earnings + moe,
  geography_note = "Published PUMA estimate assigned to named community district; boundaries approximate") |>
  arrange(boro_cd, table)
stopifnot(nrow(results) == 118, !anyDuplicated(results[c("boro_cd", "table")]),
          !anyNA(results[c("boro_cd", "puma", "table")]))
write_csv(results, "../output/community_district_earnings.csv", na = "")
print(results |> distinct(puma, table, .keep_all = TRUE) |> count(universe, estimate_status, imprecise))

# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages({library(jsonlite); library(dplyr); library(readr)})
all_estimates <- list()
for (geography in c("tract", "county")) {
  rows <- fromJSON(paste0("../input/acs_2023_", geography, ".json"))
  data <- as.data.frame(rows[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(data) <- rows[1, ]
  if (geography == "county") data$tract <- NA_character_
  stopifnot(!anyDuplicated(data[c("state", "county", "tract")]),
            all(data$state == "36"), setequal(data$county, c("005", "047", "061", "081", "085")))
  for (table in c("B24031", "B24041")) {
    metadata <- fromJSON(paste0("../input/", table, ".json"))$variables
    stopifnot(metadata[[paste0(table, "_005E")]]$label == "Estimate!!Total:!!Construction",
              grepl("Median Earnings", metadata[[paste0(table, "_005E")]]$concept))
    all_estimates[[paste(geography, table)]] <- data |>
      transmute(geography, geoid = paste0(state, county, if_else(is.na(tract), "", tract)),
                name = NAME, state, county, tract, table,
                universe = ifelse(table == "B24031", "All employed", "Full-time, year-round"),
                estimate_raw = as.numeric(.data[[paste0(table, "_005E")]]),
                moe_raw = as.numeric(.data[[paste0(table, "_005M")]]),
                estimate_annotation = .data[[paste0(table, "_005EA")]],
                moe_annotation = .data[[paste0(table, "_005MA")]])
  }
}
earnings <- bind_rows(all_estimates) |>
  mutate(borough = recode(county, `005` = "Bronx", `047` = "Brooklyn", `061` = "Manhattan",
                         `081` = "Queens", `085` = "Staten Island"),
         period = "2019-2023", dollar_year = 2023L,
         estimate_status = case_when(
           estimate_annotation %in% c("250,000+", "2,500-") ~ "Bounded median",
           is.na(estimate_raw) | estimate_raw < -1e8 ~ "Unavailable",
           !is.na(estimate_annotation) & nzchar(estimate_annotation) ~ "Other annotation",
           TRUE ~ "Numeric median"),
         earnings = if_else(estimate_status == "Numeric median", estimate_raw, NA_real_),
         moe = if_else(moe_raw >= 0 & (is.na(moe_annotation) | !nzchar(moe_annotation)), moe_raw, NA_real_),
         relative_moe = if_else(earnings > 0, moe / earnings, NA_real_),
         precision = case_when(
           estimate_status != "Numeric median" ~ estimate_status,
           is.na(relative_moe) ~ "No relative MOE",
           relative_moe > .5 ~ "MOE exceeds 50%",
           TRUE ~ "MOE at most 50%"),
         ci90_lower = earnings - moe, ci90_upper = earnings + moe) |>
  arrange(geography, geoid, table)
stopifnot(nrow(earnings) == sum(vapply(all_estimates, nrow, integer(1))),
          !anyNA(earnings[c("geography", "geoid", "table")]),
          !anyDuplicated(earnings[c("geography", "geoid", "table")]),
          all(earnings$earnings >= 0, na.rm = TRUE),
          all(earnings$precision[earnings$geography == "county"] == "MOE at most 50%"))
write_csv(earnings, "../output/acs_construction_earnings.csv", na = "")
print(earnings |> count(geography, universe, precision))

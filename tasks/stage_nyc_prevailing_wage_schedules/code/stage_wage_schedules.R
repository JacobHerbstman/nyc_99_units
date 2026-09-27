# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/stage_nyc_prevailing_wage_schedules/code")

suppressPackageStartupMessages({
  library(dplyr)
  library(pdftools)
  library(stringr)
  library(tibble)
})
source("../../shared/code/write_data_report.R")

# One row per rate in each July-June schedule: the trade classification (the
# capitalized section heading), the rate's title and description, its
# effective period, and the hourly wage and supplemental benefit. With page
# headers, footers and blank lines removed, every rate is an effective period
# followed by its wage and benefit lines. Its title is the nearest line above
# that reads as a title (short, capitalized, not a sentence, a continuation or
# a section label), with the lines between as its description. Searching stops
# at the heading, which then is the title, or at the previous rate or note on
# a rate, where the previous title continues,
# as in a mid-year change. A heading with an unclosed parenthesis continues on
# the next line, and a title that closes one began on the line above.
schedules <- c("2018_2019", "2019_2020", "2020_2021", "2021_2022", "2022_2023", "2023_2024", "2024_2025",
  "2025_2026")
page_furniture <- "^(OFFICE OF THE COMPTROLLER|CONSTRUCTION WORKER PREVAILING WAGE SCHEDULE|PUBLISH DATE)"
section_labels <- c("Overtime", "Overtime Description", "Overtime Holidays", "Paid Holidays", "Shift Rates", "None")

rates <- bind_rows(lapply(schedules, function(schedule) {
  lines <- str_squish(unlist(str_split(pdf_text(paste0("../input/nyc_construction_prevailing_wage_schedule_", schedule,
    ".pdf")), "\\n")))
  lines <- lines[lines != "" & !str_detect(lines, page_furniture)]
  heading <- str_detect(lines, "^[A-Z][A-Z0-9 ,&/()'.:-]+$") & !str_detect(lines, "\\.\\.\\.") &
    str_detect(lines, "[A-Z]{3}")
  open_heading <- which(heading & str_count(lines, "\\(") > str_count(lines, "\\)"))
  lines[open_heading + 1] <- paste(lines[open_heading], lines[open_heading + 1])
  heading[open_heading] <- FALSE
  effective <- which(str_detect(lines, "^Effective Period:"))
  stopifnot(heading[open_heading + 1], str_detect(lines[effective + 1], "^Wage Rate per Hour: \\$[0-9.]+$"),
    str_detect(lines[effective + 2], "^Supplemental Benefit Rate per Hour: \\$[0-9.]+$"))
  note <- str_detect(lines, "^\\*? ?Supplemental") | str_detect(lines, regex("rate( per hour)?:? ?\\$", ignore_case = TRUE))
  boundary <- heading | note
  title_like <- nchar(lines) <= 90 & !str_detect(lines, "^[a-z($]") & !str_detect(lines, "[.,;:]$") &
    !str_detect(lines, " (of|and|the|to|or|for|in|with|a|on)$") & !note & !lines %in% section_labels
  classification <- title <- description <- character(length(effective))
  for (k in seq_along(effective)) {
    i <- effective[k] - 1L
    while (!boundary[i] && !title_like[i]) i <- i - 1L
    if (!boundary[i]) {
      title[k] <- lines[i]
      if (str_count(lines[i], "\\)") > str_count(lines[i], "\\(")) title[k] <- paste(lines[i - 1L], lines[i])
      description[k] <- paste(lines[seq_len(effective[k] - 1L - i) + i], collapse = " ")
    } else if (heading[i]) {
      title[k] <- lines[i]
      description[k] <- paste(lines[seq_len(effective[k] - 1L - i) + i], collapse = " ")
    } else {
      title[k] <- title[k - 1L]
      description[k] <- description[k - 1L]
    }
    classification[k] <- lines[max(which(heading[seq_len(effective[k])]))]
  }
  period <- str_match(lines[effective], "^Effective Period: ([0-9/]+) [-\u2013] ([0-9/]+)$")
  tibble(schedule = str_replace(schedule, "_", "-"), rate_order = seq_along(effective), classification,
    rate_title = title,
    rate_description = na_if(description, ""),
    effective_start = as.Date(period[, 2], "%m/%d/%Y"), effective_end = as.Date(period[, 3], "%m/%d/%Y"),
    wage_per_hour = as.numeric(str_extract(lines[effective + 1], "[0-9.]+$")),
    supplement_per_hour = as.numeric(str_extract(lines[effective + 2], "[0-9.]+$")))
})) |>
  mutate(total_per_hour = wage_per_hour + supplement_per_hour)

stopifnot(!anyNA(rates$classification), !anyNA(rates$rate_title), !anyNA(rates$effective_start),
  !anyNA(rates$effective_end), all(rates$effective_start <= rates$effective_end), all(rates$wage_per_hour > 0))

SaveData(rates, c("schedule", "rate_order"),
  "../output/nyc_prevailing_wage_rates_2018_2026.csv")

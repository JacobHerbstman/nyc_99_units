# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_acs_construction_earnings/code")
# geography <- "tract"
suppressPackageStartupMessages(library(jsonlite))
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
geography <- args[1]
stopifnot(geography %in% c("tract", "county", "puma"))
rows <- fromJSON(paste0("../output/acs_2023_", geography, ".json"))
data <- as.data.frame(rows[-1, , drop = FALSE], stringsAsFactors = FALSE)
names(data) <- rows[1, ]
# Cast only estimate/MOE fields; source sentinel codes remain visible.
for (column in c("B24031_005E", "B24031_005M", "B24041_005E", "B24041_005M")) {
  data[[column]] <- as.numeric(data[[column]])
}
write_data_report(data, if (geography == "tract") c("state", "county", "tract") else if (geography == "county") c("state", "county") else c("state", "public use microdata area"),
                  paste0("../output/acs_2023_", geography, ".json"), paste0("../report/acs_2023_", geography, ".txt"))

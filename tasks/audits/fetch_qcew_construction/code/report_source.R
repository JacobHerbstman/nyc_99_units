# setwd("tasks/audits/fetch_qcew_construction/code")
# slice <- "2019_36005"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
slice <- args[1]
stopifnot(grepl("^20(19|2[0-3])_360(05|47|61|81|85)$", slice))
d <- read_csv(paste0("../output/", slice, ".csv"), show_col_types = FALSE)
stopifnot(nrow(d) > 0, all(d$year == as.integer(substr(slice, 1, 4))), all(d$qtr == "A"))
write_data_report(d, c("area_fips", "own_code", "industry_code", "agglvl_code", "size_code", "year", "qtr"), paste0("../output/", slice, ".csv"), paste0("../report/", slice, ".txt"))

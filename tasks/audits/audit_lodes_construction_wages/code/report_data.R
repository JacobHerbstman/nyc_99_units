# setwd("tasks/audits/audit_lodes_construction_wages/code")
# level <- "district"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
level <- args[1]
stopifnot(level %in% c("block", "district"))
d <- read_csv(paste0("../output/", level, "_construction_bins.csv"), show_col_types = FALSE)
write_data_report(d, c("year", if (level == "block") "w_geocode" else "boro_cd"), paste0("../output/", level, "_construction_bins.csv"), paste0("../report/", level, "_construction_bins.txt"))

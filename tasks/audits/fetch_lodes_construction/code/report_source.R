# setwd("tasks/audits/fetch_lodes_construction/code")
# slice <- "ny_wac_S000_JT02_2019"
library(readr)
source("../../../shared/code/write_data_report.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
slice <- args[1]
stopifnot(slice == "ny_xwalk" || grepl("^ny_wac_(S000|SE0[1-3])_JT02_20(19|2[0-3])$", slice))
checksums <- readLines("../output/lodes_ny.sha256sum")
expected <- checksums[endsWith(checksums, paste0(slice, ".csv"))]
stopifnot(length(expected) == 1)
actual <- system(paste0("gzip -dc ../output/", slice, ".csv.gz | shasum -a 256"), intern = TRUE)
stopifnot(substr(actual, 1, 64) == substr(expected, 1, 64))
d <- read_csv(paste0("../output/", slice, ".csv.gz"), col_types = if (slice == "ny_xwalk") cols(.default = col_character()) else cols(w_geocode = col_character()))
key <- if (slice == "ny_xwalk") "tabblk2020" else "w_geocode"
stopifnot(nrow(d) > 0)
write_data_report(d, key, paste0("../output/", slice, ".csv.gz"), paste0("../report/", slice, ".txt"))

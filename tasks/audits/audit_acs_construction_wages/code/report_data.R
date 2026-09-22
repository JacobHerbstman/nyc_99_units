# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages(library(readr))
source("../../../shared/code/write_data_report.R")
data <- read_csv("../output/acs_construction_earnings.csv",
                 col_types = cols(geoid = col_character(), state = col_character(), county = col_character(), tract = col_character()))
write_data_report(data, c("geography", "geoid", "table"), "../output/acs_construction_earnings.csv",
                  "../report/acs_construction_earnings.txt")

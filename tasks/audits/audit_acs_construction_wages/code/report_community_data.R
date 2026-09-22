# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/audit_acs_construction_wages/code")
suppressPackageStartupMessages(library(readr))
source("../../../shared/code/write_data_report.R")
data <- read_csv("../output/community_district_earnings.csv", col_types = cols(puma = col_character()))
write_data_report(data, c("boro_cd", "table"), "../output/community_district_earnings.csv",
                  "../report/community_district_earnings.txt")

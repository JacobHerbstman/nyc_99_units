# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/setup_environment/code")

options(repos = c(CRAN = "https://cloud.r-project.org"))

cran_pkgs <- c(
  "arrow", "data.table", "dplyr", "foreign", "ggplot2", "httr", "httr2",
  "igraph", "jsonlite", "lubridate", "readr", "rvest", "scales", "sf",
  "stringr", "survey", "tibble", "tidyr", "units"
)

for (pkg in cran_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

pkgs <- as.data.frame(installed.packages()[sort(cran_pkgs), c("Package", "Version")])
write.table(pkgs, "../output/R_packages.txt", sep = "\t", row.names = FALSE, quote = FALSE)
cat("Wrote", nrow(pkgs), "packages to ../output/R_packages.txt\n")

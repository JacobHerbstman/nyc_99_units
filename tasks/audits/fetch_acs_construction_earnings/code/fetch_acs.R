# setwd("/Users/jacobherbstman/Desktop/nyc_99_units/tasks/audits/fetch_acs_construction_earnings/code")
# geography <- "tract"
suppressPackageStartupMessages({library(httr2); library(jsonlite)})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1)
geography <- args[1]
stopifnot(geography %in% c("tract", "county", "puma"))
if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) readRenviron(path.expand("~/.Renviron"))
if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) stop("CENSUS_API_KEY is not configured.", call. = FALSE)
request <- request("https://api.census.gov/data/2023/acs/acs5") |>
  req_url_query(get = "NAME,B24031_005E,B24031_005M,B24031_005EA,B24031_005MA,B24041_005E,B24041_005M,B24041_005EA,B24041_005MA",
                `for` = if (geography == "tract") "tract:*" else if (geography == "county") "county:005,047,061,081,085" else "public use microdata area:*",
                `in` = if (geography == "tract") "state:36 county:005,047,061,081,085" else "state:36",
                key = Sys.getenv("CENSUS_API_KEY")) |>
  req_timeout(60)
# Request errors can contain the credential-bearing URL: never emit them.
response <- tryCatch(req_perform(request), error = function(e) {
  stop("Census request failed; check connectivity and the configured key. Request details withheld.", call. = FALSE)
})
body <- resp_body_raw(response)
rows <- tryCatch(fromJSON(rawToChar(body)), error = function(e) {
  stop("Census response was not valid JSON. Response details withheld.", call. = FALSE)
})
stopifnot(is.matrix(rows), nrow(rows) > 1,
          all(c("NAME", "B24031_005E", "B24041_005M", "state") %in% rows[1, ]))
data <- as.data.frame(rows[-1, , drop = FALSE], stringsAsFactors = FALSE)
names(data) <- rows[1, ]
stopifnot(all(data$state == "36"))
if (geography != "puma") stopifnot(setequal(data$county, c("005", "047", "061", "081", "085")))
if (geography == "puma") stopifnot(!anyNA(data$`public use microdata area`), !anyDuplicated(data$`public use microdata area`))
if (geography == "tract") stopifnot(!anyDuplicated(data[c("state", "county", "tract")]))
if (geography == "county") stopifnot(nrow(data) == 5, !anyDuplicated(data$county))
writeBin(body, paste0("../output/acs_2023_", geography, ".json.part"))
stopifnot(file.rename(paste0("../output/acs_2023_", geography, ".json.part"),
                      paste0("../output/acs_2023_", geography, ".json")))
cat("Saved", nrow(data), geography, "records; credentials were not written.\n")

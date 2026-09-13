# Saving and deterministic data summaries, shared by producing tasks.
write_data_report <- function(data, keys, source_file, report_file, require_unique = TRUE) {
  if (length(keys) && require_unique) stopifnot(!anyNA(data[keys]), !anyDuplicated(data[keys]))
  lines <- c(paste("Rows:", nrow(data)), paste("Columns:", ncol(data)),
             paste("Key fields:", if (length(keys)) paste(keys, collapse = ", ") else "aggregate table or source rows without a designated key"),
             paste("Saved-file MD5:", unname(tools::md5sum(source_file))))
  if (length(keys)) {
    lines <- c(lines, paste("Rows missing a key field:", sum(!complete.cases(data[keys]))),
               paste("Repeated keys beyond the first row:", sum(duplicated(data[keys]))))
  }
  for (column in names(data)) {
    x <- data[[column]]
    line <- paste(column, paste(class(x), collapse = "/"),
                  "nonmissing", sum(!is.na(x)), "distinct", length(unique(x[!is.na(x)])), sep = " | ")
    if (is.numeric(x) && any(!is.na(x))) {
      line <- paste(line, "min/median/mean/max",
                    paste(signif(c(min(x, na.rm = TRUE), median(x, na.rm = TRUE),
                                   mean(x, na.rm = TRUE), max(x, na.rm = TRUE)), 7), collapse = "/"))
    }
    lines <- c(lines, line)
  }
  writeLines(lines, report_file)
}

# Keep the caller's row order and CSV/Parquet representation. Reports describe
# the saved data, including any types inferred when a CSV is read back.
SaveData <- function(data, keys, output_file, require_unique = TRUE, na = "") {
  temporary_file <- tempfile(tmpdir = dirname(output_file))
  on.exit(unlink(temporary_file))
  extension <- tools::file_ext(output_file)
  if (extension == "parquet") {
    arrow::write_parquet(data, temporary_file)
    saved <- arrow::read_parquet(temporary_file)
  } else if (extension == "csv") {
    readr::write_csv(data, temporary_file, na = na)
    saved <- readr::read_csv(temporary_file, show_col_types = FALSE, guess_max = Inf)
  } else {
    stop("SaveData expects a .csv or .parquet output: ", output_file)
  }
  report_file <- file.path("../report", sub("\\.[^.]+$", ".txt", basename(output_file)))
  write_data_report(saved, keys, temporary_file, report_file, require_unique)
  if (!file.rename(temporary_file, output_file)) stop("Could not publish output: ", output_file)
}

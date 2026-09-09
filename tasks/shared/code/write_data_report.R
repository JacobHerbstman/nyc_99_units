# Reused by the ACS source and analysis tasks; report the data actually saved.
write_data_report <- function(data, keys, source_file, report_file) {
  stopifnot(!anyNA(data[keys]), !anyDuplicated(data[keys]))
  lines <- c(paste("Rows:", nrow(data)), paste("Columns:", ncol(data)),
             paste("Unique nonmissing key:", paste(keys, collapse = ", ")),
             paste("Saved-file MD5:", unname(tools::md5sum(source_file))))
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

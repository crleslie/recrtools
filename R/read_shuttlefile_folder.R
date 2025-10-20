#' Read and process TRAFx ShuttleFiles
#'
#' Reads all ShuttleFiles in a folder, parses hourly counts and download metadata,
#' and returns a list with counts and header information. Optionally, it can
#' create 'counts' and 'header' objects directly in the user environment.
#'
#' @param folder Character. Path to folder containing ShuttleFiles (.txt)
#' @param return Character. Which data to return: "both" (default), "counts", or "header"
#' @param tz Character. Time zone for POSIXct conversion; defaults to system TZ
#' @param split_output Logical. If TRUE and return = "both", creates 'counts' and 'header' directly in the user's environment
#' @return A list with elements `counts` and `header` (if `return = "both"`), or a single data frame
#' @examples
#' \dontrun{
#' # Return list
#' result <- read_shuttlefiles("data/trafx_2025")
#' counts_df <- result$counts
#' header_df <- result$header
#'
#' # Split output directly to environment
#' read_shuttlefiles("data/trafx_2025", split_output = TRUE)
#' head(counts)
#' head(header)
#' }
#' @export

read_shuttlefiles <- function(folder, return = c("both", "counts", "header")) {

  return <- match.arg(return)

  # Set user system timezone
  tz <- Sys.timezone()  # or pass from function argument

  # Internal helper: fill down NA values
  fill_down <- function(x) {
    for (i in seq_along(x)) {
      if (is.na(x[i]) && i > 1) x[i] <- x[i-1]
    }
    x
  }

  # Internal helper: substring from right
  substrRight <- function(x, n) {
    substr(x, nchar(x) - n + 1, nchar(x))
  }

  # List ShuttleFiles
  files <- list.files(path = folder, pattern = "\\.txt$", ignore.case = TRUE,
                      full.names = TRUE, recursive = TRUE)
  if (length(files) == 0) stop("No ShuttleFiles found in folder: ", folder)

  # Parse files
  parsed <- lapply(files, function(file) {
    raw <- scan(file = file, what = "raw", sep = "\n", blank.lines.skip = FALSE, quiet = TRUE)
    df <- data.frame(raw = raw, stringsAsFactors = FALSE)
    n <- nrow(df)

    # Identify row type
    df$type <- ifelse(grepl("[[:digit:]]", substr(df$raw, 1, 1)), "record", "meta")
    df$rowID <- seq_len(n)

    # Extract record fields
    df$date <- ifelse(df$type == "record", substr(df$raw, 1, 8), NA)
    df$time <- ifelse(df$type == "record", substr(df$raw, 10, 14), NA)
    df$dateTime <- ifelse(df$type == "record", substr(df$raw, 1, 14), NA)

    # Counts
    df$count1 <- ifelse(df$type == "record", substr(df$raw, 16, 20), NA)
    df$count2 <- ifelse(df$type == "record", substr(df$raw, 22, 26), NA)

    # Metadata
    df$serial <- ifelse(substr(df$raw, 1, 16) == "  *Serial Number", substrRight(df$raw, 6), NA)
    df$counter <- ifelse(substr(df$raw, 1, 10) == "  *Counter", substr(df$raw, 20, nchar(df$raw)), NA)
    df$mode <- ifelse(substr(df$raw, 1, 7) == "  *Mode", substr(df$raw, 20, nchar(df$raw)), NA)
    df$volt <- ifelse(substr(df$raw, 1, 7) == "  *Batt", substr(df$raw, 20, nchar(df$raw)), NA)
    df$downloadTime <- ifelse(substr(df$raw, 1, 5) == "=TIME", substr(df$raw, 24, nchar(df$raw)), NA)
    df$startTime <- ifelse(substr(df$raw, 1, 6) == "=START", substr(df$raw, 24, nchar(df$raw)), NA)
    df$dockTime <- ifelse(substr(df$raw, 1, 5) == "=DOCK", substr(df$raw, 29, nchar(df$raw)), NA)

    # Fill down metadata
    df$counter <- fill_down(df$counter)
    df$mode <- fill_down(df$mode)
    df$serial <- fill_down(df$serial)
    df$volt <- fill_down(df$volt)
    df$downloadTime <- fill_down(df$downloadTime)
    df$startTime <- fill_down(df$startTime)
    df$dockTime <- fill_down(df$dockTime)

    # Counts dataframe
    counts <- df[df$type == "record", ]
    counts$dateTime <- as.POSIXct(counts$dateTime, format = "%y-%m-%d,%H:%M", tz = tz)
    counts$date <- as.Date(counts$date, format = "%y-%m-%d")
    counts$count1 <- as.numeric(counts$count1)
    counts$count2 <- as.numeric(counts$count2)
    counts <- counts[, c("counter", "serial", "dateTime", "date", "time", "count1", "count2")]

    # Header dataframe
    header <- df[df$type == "record", ]
    header$downloadTime <- as.POSIXct(header$downloadTime, format = "%y-%m-%d,%H:%M", tz = tz)
    header$startTime    <- as.POSIXct(header$startTime,    format = "%y-%m-%d,%H:%M", tz = tz)
    header$dockTime     <- as.POSIXct(header$dockTime,     format = "%y-%m-%d %H:%M:%S", tz = tz)
    header <- header[!duplicated(header$counter), ]
    header <- header[, c("counter", "mode", "serial", "volt", "downloadTime", "startTime", "dockTime")]

    list(counts = counts, header = header)
  })

  # Combine all files
  counts_all <- do.call(rbind, lapply(parsed, `[[`, "counts"))
  header_all <- do.call(rbind, lapply(parsed, `[[`, "header"))


  # Return requested output
  result <- switch(return,
                   counts = counts_all,
                   header = header_all,
                   both = list(counts = counts_all, header = header_all))

  if (split_output && return == "both") {
    list2env(result, envir = parent.frame())
    message("Objects 'counts' and 'header' have been created in your environment.")
    invisible(NULL)
  } else {
    return(result)
  }
}

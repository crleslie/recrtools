#' Read and process TRAFx Shuttle Files
#'
#' This function reads one or more TRAFx Shuttle Files (.txt) from a single file
#' or a folder containing multiple files, and returns processed data frames for
#' analysis. It extracts both the hourly counts recorded by each counter as well
#' as the download metadata (e.g., serial numbers, timestamps, and counter mode).
#'
#' @param path Character. The file path to either a single `.txt` shuttle file
#'   or a folder containing multiple shuttle files.
#' @param tz Character. Time zone for timestamp conversion. Defaults to your
#'   computer's time zone.
#' @param return Character. Determines what the function returns. Options are:
#'   \itemize{
#'     \item{"counts"} - only the hourly counts data frame.
#'     \item{"header"} - only the metadata/header data frame.
#'     \item{"both"} (default) - a **list** containing two data frames: `counts`
#'       and `header`.
#'   }
#'
#' @return Depending on the `return` argument:
#' \itemize{
#'   \item If `return = "counts"`: a single data frame with all hourly counts.
#'   \item If `return = "header"`: a single data frame with counter metadata.
#'   \item If `return = "both"`: a **list** with two components:
#'         \describe{
#'           \item{counts}{Data frame with all hourly counts.}
#'           \item{header}{Data frame with counter metadata.}
#'         }
#' }
#'
#' This means that when you choose `return = "both"`, the function will give you
#' one object, and you can access the counts data frame with `result$counts` and
#' the header data frame with `result$header`.
#'
#'
#' The structure of each data frame is as follows:
#'
#' If `return = "counts"` or `return = "both"`, the `counts` data frame has:
#' \describe{
#'   \item{counter}{Character. Name of the counter unit.}
#'   \item{serial}{Character. Serial number of the counter.}
#'   \item{dateTime}{POSIXct. Combined date and hour of the count. Time zone as specified by `tz`.}
#'   \item{date}{Date. The date of the count.}
#'   \item{time}{Character. Hour portion of the count (HH:MM).}
#'   \item{count1}{Numeric. First count channel (if only one sensor attached, all counts are in this column).}
#'   \item{count2}{Numeric. Second count channel (if a second sensor is available; 0 if not used).}
#' }
#'
#' If `return = "header"` or `return = "both"`, the `header` data frame has:
#' \describe{
#'   \item{counter}{Character. Name of the counter unit.}
#'   \item{mode}{Character. Counter mode (e.g. Infrared (IR+) for pedestrian configuration).}
#'   \item{serial}{Character. Serial number of the counter.}
#'   \item{volt}{Character or numeric. Battery voltage at the time of download.}
#'   \item{downloadTime}{POSIXct. Timestamp when the file was downloaded from the counter.}
#'   \item{startTime}{POSIXct. Timestamp when the counter recording period started.}
#'   \item{dockTime}{POSIXct. Timestamp when the counter was physically downloaded via the dock/shuttle (if applicable).}
#' }
#'
#' @examples
#' \dontrun{
#' # Example 1: Read a single file (using included example data)
#' example_file <- system.file("extdata", "ShuttleFile_EXAMPLE.TXT", package = "recrtools")
#'
#' # Process the file and return both counts and header information
#' data <- read_shuttlefile(example_file, return = "both")
#'
#' # Access each part of the result
#' counts <- data$counts   # Hourly counts data frame
#' header <- data$header   # Metadata / header data frame
#'
#'
#' # Example 2: Read all ShuttleFiles in a data folder using an RStudio project structure
#' # Assume your RStudio project has the following folder structure:
#' #   Trail Counter Project/   # Your RStudio project folder
#' #       ├── data/            # raw ShuttleFiles go here
#' #       │    └── trafx_downloads/
#' #       ├── scripts/         # R scripts/functions
#' #       ├── results/         # processed data or figures
#' #       └── ...
#'
#' # The "data/trafx_downloads/" path is relative to the project root.
#' folder_path <- "data/trafx_downloads/"
#'
#' # Process all ShuttleFiles in the folder
#' all_data <- read_shuttlefile(folder_path, return = "both")
#'
#' # Extract the individual data frames from the list
#' counts_df <- all_data$counts
#' header_df <- all_data$header
#'
#'
#' # Example 3: Read a specific ShuttleFile by path
#' # Can provide a relative or absolute path to a single file
#' single_file <- "data/trafx_downloads/TRAFX_2024-06-15.TXT"
#'
#' # Only return the hourly counts
#' counts_only <- read_shuttlefile(single_file, return = "counts")
#' }
#'
#' @export

read_shuttlefile <- function(
    path,
    tz = Sys.timezone(),
    return = c("both", "counts", "header")
    ) {

  return <- match.arg(return)

  #------------------------------------------------------------
  # Detect file(s)
  #------------------------------------------------------------
  if (dir.exists(path)) {
    files <- list.files(
      path,
      pattern = "\\.txt$",
      full.names = TRUE,
      recursive = FALSE,
      ignore.case = TRUE
      )
  } else if (file.exists(path)) {
    files <- path
  } else {
    stop("`path` must be a valid file or directory.", call. = FALSE)
  }

  if (length(files) == 0) {
    stop("No .txt files found in the specified path.", call. = FALSE)
  }


  #------------------------------------------------------------
  # Internal helper: fill down NA values
  #------------------------------------------------------------
  fill_down <- function(x) {
    for (i in seq_along(x)) {
      if (is.na(x[i]) && i > 1) x[i] <- x[i-1]
    }
    x
  }

  #------------------------------------------------------------
  # Internal helper: substring from right
  #------------------------------------------------------------
  substrRight <- function(x, n) {
    substr(x, nchar(x) - n + 1, nchar(x))
  }

  #------------------------------------------------------------
  # Parse files
  #------------------------------------------------------------
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
  return(result)
}

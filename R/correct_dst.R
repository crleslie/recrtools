#' Correct TRAFx ShuttleFiles for Daylight Saving Time
#'
#' Adjusts timestamps in TRAFx ShuttleFiles for DST changes (spring or fall).
#' Automatically computes the DST change date for the specified year and optionally
#' skips files that do not span the DST change.
#'
#' @param path Character. Path to a single ShuttleFile (.txt) or a folder of files.
#' @param direction Character. Either "begin" to advance 1 hour (spring forward)
#'   or "end" to subtract 1 hour (fall back).
#' @param year Numeric. Full 4-digit year of the DST change (used to auto-calculate date).
#' @param skip_no_change Logical. If TRUE, files that do not span the DST change are skipped. Defaults to TRUE.
#' @param output_dir Character. Optional. Directory to save corrected files. Defaults to a "dst_corrected" folder inside the input folder.
#'
#' @return NULL. Writes corrected ShuttleFiles to the specified output folder.
#'
#' @examples
#' \dontrun{
#' # Correct all files in a folder for spring DST
#' correct_dst("data/trafx_downloads/", direction = "begin", year = 2024)
#'
#' # Correct a single file for fall DST
#' correct_dst("data/trafx_downloads/ShuttleFile_001.txt", direction = "end", year = 2024)
#' }
#' @export

correct_dst <- function(path,
                        direction = c("begin", "end"),
                        year,
                        skip_no_change = TRUE,
                        output_dir = NULL) {

  direction <- match.arg(direction)

  # Determine files and default output folder
  if (dir.exists(path)) {
    files <- list.files(path, pattern = "\\.txt$", full.names = TRUE)
    out_dir <- if (is.null(output_dir)) file.path(path, "dst_corrected") else output_dir
  } else if (file.exists(path)) {
    files <- path
    out_dir <- if (is.null(output_dir)) file.path(dirname(path), "dst_corrected") else output_dir
  } else {
    stop("`path` must be a valid file or directory.")
  }

  if (!file.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

  # Compute DST change date automatically
  if (direction == "begin") {
    dst_date <- as.Date(paste0(year, "-03-01"))
    dst_date <- dst_date + ((7 - as.integer(format(dst_date, "%w")) + 7) %% 7) + 7
  } else {
    dst_date <- as.Date(paste0(year, "-11-01"))
    dst_date <- dst_date + ((7 - as.integer(format(dst_date, "%w"))) %% 7)
  }
  dst_change <- as.POSIXct(paste(dst_date, "02:00:00"))

  lapply(files, function(file) {
    raw <- scan(file, what = "character", sep = "\n", blank.lines.skip = FALSE, quiet = TRUE)
    type <- ifelse(grepl("^[0-9]", raw), "record", "meta")

    # Extract timestamps for records
    dateTime <- as.POSIXct(ifelse(type == "record", substr(raw, 1, 14), NA),
                           format = "%y-%m-%d,%H:%M")

    # Safety check: skip files without DST change
    if (skip_no_change && !any(dateTime == dst_change, na.rm = TRUE)) {
      message("Skipping file (no timestamps at or after DST change): ", basename(file))
      return(NULL)
    }

    # Counts
    count1 <- ifelse(type == "record", substr(raw, 16, 20), NA)
    count2 <- ifelse(type == "record", substr(raw, 22, 26), NA)

    # Apply DST adjustment
    adjDateTime <- dateTime
    if (direction == "begin") {
      adjDateTime[!is.na(dateTime) & dateTime >= dst_change] <- adjDateTime[!is.na(dateTime) & dateTime >= dst_change] + 3600
    } else {
      adjDateTime[!is.na(dateTime) & dateTime >= dst_change] <- adjDateTime[!is.na(dateTime) & dateTime >= dst_change] - 3600
    }

    # Recombine
    shuttleOut <- ifelse(type == "meta", raw,
                         paste(format(adjDateTime, "%y-%m-%d,%H:%M"), count1, count2, sep = ","))

    # Write corrected file
    file_name <- tools::file_path_sans_ext(basename(file))
    writeLines(shuttleOut, file.path(out_dir, paste0(file_name, "_DST_Corrected.txt")))
  })

  message("DST-corrected files written to: ", out_dir)
  invisible(NULL)
}

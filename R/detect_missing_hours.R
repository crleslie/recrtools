detect_missing_hours <- function(data, datetime_col, count_col = NULL, group_vars = NULL,
                                 tz = Sys.timezone(), fill = FALSE) {
  # ------------------------------
  # Step 1: Input checks
  # ------------------------------
  # Check datetime column
  if (!datetime_col %in% names(data)) {
    stop(paste0("datetime_col \"", datetime_col, "\" not found in data"))
  }

  # Check count column
  if (!is.null(count_col) && !count_col %in% names(data)) {
    stop(paste0("count_col \"", count_col, "\" not found in data"))
  }

  # Check grouping variables
  if (is.null(group_vars)) {
    warning(
      "No grouping variables were specified. ",
      "As a result, missing hours were be detected across the entire time range of the dataset rather than separately for each counter or location. ",
      "If your dataset contains multiple counters or locations, this may produce incorrect min/max timestamps or incorrectly flag hours as missing. ",
      "To avoid this, specify one or more grouping variables (e.g., location_id, serial) using the 'group_vars' argument so that missing hours are detected within each group."
    )


  } else {
    # Make sure all group_vars exist
    missing_groups <- group_vars[!group_vars %in% names(data)]
    if (length(missing_groups) > 0) {
      stop(paste0("Grouping variables not found in data: ", paste(missing_groups, collapse = ", ")))
    }
  }


  # Convert datetime column to POSIXct (preserves timezone)
  data[[datetime_col]] <- as.POSIXct(data[[datetime_col]], tz = tz)

  # ------------------------------
  # Step 2: Define grouping
  # ------------------------------
  if (is.null(group_vars)) {
    data$.__group <- 1  # single dummy group
    group_vars <- ".__group"
  }

  # ------------------------------
  # Step 3: Function to handle a single group
  # ------------------------------
  fill_group <- function(sub_data) {
    # 3a. Range of datetime
    rng <- range(sub_data[[datetime_col]], na.rm = TRUE)

    # 3b. Complete sequence of hourly timestamps
    full_hours <- seq(rng[1], rng[2], by = "hour")

    # 3c. Identify missing timestamps
    missing_hours <- setdiff(full_hours, sub_data[[datetime_col]])

    # 3d. Flag missing hours in original data
    sub_data$is_missing <- FALSE

    # 3e. Fill missing rows if requested
    if (fill && length(missing_hours) > 0) {
      # Build missing rows using existing column names and types
      new_rows <- sub_data[rep(1, length(missing_hours)), , drop = FALSE]

      # Set datetime for missing rows
      new_rows[[datetime_col]] <- missing_hours

      # Set counts or other columns to NA
      if (!is.null(count_col)) new_rows[[count_col]] <- NA

      # Flag as missing
      new_rows$is_missing <- TRUE

      # Keep grouping columns consistent
      for (gv in group_vars) new_rows[[gv]] <- unique(sub_data[[gv]])

      # Bind to original
      sub_data <- rbind(sub_data, new_rows)
    } else if (length(missing_hours) > 0) {
      # If not filling, just flag the rows (we create placeholder rows for flagging)
      placeholder <- sub_data[1:length(missing_hours), , drop = FALSE]
      placeholder[] <- NA
      placeholder[[datetime_col]] <- missing_hours
      placeholder$is_missing <- TRUE
      for (gv in group_vars) placeholder[[gv]] <- unique(sub_data[[gv]])

      sub_data <- rbind(sub_data, placeholder)
    }

    # Sort by datetime
    sub_data[order(sub_data[[datetime_col]]), ]
  }

  # ------------------------------
  # Step 4: Split-apply-combine by group
  # ------------------------------
  groups <- split(data, interaction(data[group_vars], drop = TRUE))
  result <- do.call(rbind, lapply(groups, fill_group))

  # Remove temporary group column if created
  if ("__group" %in% names(result)) result$.__group <- NULL

  # ------------------------------
  # Step 5: Summary attribute
  # ------------------------------
  missing_summary <- aggregate(is_missing ~ interaction(result[group_vars], drop = TRUE),
                               data = result, sum)
  message("Missing hours per group:\n")
  print(missing_summary)

  return(result)
}

#' Recode "Other" responses in a survey column using a dictionary
#'
#' This function handles a standard survey pattern: a primary select one column with an "Other" option,
#' and a free-text column with "other" responses. It applies a dictionary-based recoding for any text
#' responses and standardizes the final output.
#'
#' @param select_col Character vector. The primary selected option (may include "Other").
#' @param other_col Character vector. The free-text responses for "Other" answers.
#' @param dict Named list. Dictionary mapping category names to keywords for recoding.
#' @param na_values Character or numeric vector. Values that should be treated as NA (default: c("777", 777, NA)).
#'
#' @return A character vector of recoded responses.
#'
#' @examples
#' survey <- tibble(
#'   response_id = 1:5,
#'   activity_select = c("biking", "hiking", "other", "other", "running"),
#'   activity_other_text = c(NA, NA, "mountain biking", "trail run", NA)
#' )
#'
#' dict <- list(
#'   biking = c("bike", "biking", "cycling"),
#'   running = c("run", "running", "jog"),
#'   hiking = c("hike", "walk", "stroll")
#' )
#'
#' survey <- survey %>%
#'   mutate(auto_recode = recode_other(activity_select, activity_other_text, dict))
#'
#' @export

recode_by_dict <- function(select_col, other_col, dict, na_values = c("777", 777, NA)) {

  # Vectorized function for dictionary recoding
  recode_text <- function(x) {
    if (is.na(x) || x %in% na_values || stringr::str_trim(x) == "") return(x)

    x <- tolower(x)
    for (key in names(dict)) {
      pattern <- paste0("\\b(", paste(dict[[key]], collapse = "|"), ")\\b")
      if (stringr::str_detect(x, pattern)) return(key)
    }
    return("other")
  }

  # Apply logic: if select_col != "Other", take it; else recode other_col
  vapply(seq_along(select_col), function(i) {
    sel <- select_col[i]
    oth <- other_col[i]

    if (!is.na(sel) && tolower(sel) != "other") {
      tolower(sel)
    } else {
      recode_text(oth)
    }
  }, character(1))
}

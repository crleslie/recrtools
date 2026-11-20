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

recode_by_dict <- function(select_col, other_col, dict,
                           na_values = c("777", 777, NA),
                           sep = ",",
                           collapse = paste0(sep)) {

  # Dictionary recoding of a single write-in string.
  # Returns the matching dict key, "other" if nothing matches,
  # or the original value if it is NA / blank / a na_value.
  recode_text <- function(x) {
    if (is.na(x) || x %in% na_values || stringr::str_trim(x) == "") return(x)

    x <- tolower(x)
    for (key in names(dict)) {
      pattern <- paste0("\\b(", paste(dict[[key]], collapse = "|"), ")\\b")
      if (stringr::str_detect(x, pattern)) return(key)
    }
    return("other")
  }

  vapply(seq_along(select_col), function(i) {
    sel <- select_col[i]
    oth <- other_col[i]

    # Missing selection: fall back to recoding the write-in (original behavior)
    if (is.na(sel)) return(as.character(recode_text(oth)))

    # Split the (possibly comma separated) selection list into tokens
    tokens <- trimws(strsplit(as.character(sel), sep, fixed = TRUE)[[1]])
    tokens <- tolower(tokens[tokens != ""])
    is_other <- tokens == "other"

    # No "other" selected: just return the (normalized) selections
    if (!any(is_other)) return(paste(tokens, collapse = collapse))

    # Single select where "other" is the only choice (original behavior)
    if (length(tokens) == 1) return(as.character(recode_text(oth)))

    # Select multiple: swap "other" for the matched category, if there is one.
    # If there is no match (or no usable write-in), "other" stays in the list.
    new_val <- recode_text(oth)
    if (!is.na(new_val) && new_val %in% names(dict)) {
      tokens[is_other] <- new_val
    }

    # Drop duplicates, e.g. "a, other" where other matched "a"
    paste(unique(tokens), collapse = collapse)
  }, character(1))
}

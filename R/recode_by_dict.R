#' Recode "Other" responses in a survey column using a dictionary
#'
#' Handles a standard survey pattern: a select-one or select-multiple column
#' with an "Other" option, plus a free-text column holding the write-in
#' response. Select-multiple answers are a delimited string, e.g.
#' `"biking, other, hiking"`.
#'
#' When "Other" is selected and the write-in matches the dictionary, "other" is
#' replaced by the matched category. If there is no match, or the write-in is
#' blank/NA, "other" is kept. Duplicates created by the replacement are removed.
#'
#' Dictionary terms are matched as whole words or phrases, case-insensitively.
#' Terms are treated as regular expressions, so escape special characters such
#' as `(`, `)` and `.`. The first matching category in dictionary order wins, so
#' list more specific categories first.
#'
#' @param select_col Character vector. The selected option(s). For select-one
#'   questions a single value; for select-multiple questions a delimited string
#'   (see `sep`). May include "Other".
#' @param other_col Character vector. The free-text write-in responses
#'   for "Other" answers.
#' @param dict Named list. Dictionary mapping category names to character
#'   vectors of terms used for recoding.
#' @param na_values Character or numeric vector. Write-in values that are not
#'   recoded and are returned as-is (default: `c("777", 777, NA)`).
#' @param sep Character. Delimiter separating selections in `select_col`
#'   (default: `","`).
#' @param collapse Character. Delimiter used to join selections in the output
#'   (default: same as `sep`, with no added space).
#'
#' @return A character vector the same length as `select_col`. Select-one rows
#'   return a single category; select-multiple rows return the selections
#'   joined with `collapse`, with "other" replaced where a match was found.
#'
#' @examples
#' survey <- dplyr::tibble(
#'   response_id = 1:6,
#'   activity_select = c("biking", "hiking", "other", "other", "running",
#'                       "hiking, other"),
#'   activity_other_text = c(NA, NA, "mountain biking", "trail run", NA,
#'                           "morning jog")
#' )
#'
#' dict <- list(
#'   biking = c("bike", "biking", "cycling"),
#'   running = c("run", "running", "jog"),
#'   hiking = c("hike", "walk", "stroll")
#' )
#'
#' survey |>
#'   dplyr::mutate(
#'     auto_recode = recode_by_dict(activity_select, activity_other_text, dict)
#'   )
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
      pattern <- stringr::regex(paste0("\\b(", paste(dict[[key]], collapse = "|"), ")\\b"), ignore_case = TRUE)
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

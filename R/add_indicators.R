#' Add indicator columns for a select-multiple question
#'
#' Splits a delimited select-multiple column and adds one indicator column
#' per option: 1 if the option was selected, 0 if not.
#'
#' Selections are split on `delim`, trimmed of surrounding whitespace, and
#' matched exactly (case-sensitive) against `options`.
#'
#' If a row contains one of the missing-value `codes` (e.g. `"888"`), every
#' indicator for that row is set to that code instead of 0/1, so the code
#' carries through to the new columns. If a row contains more than one code,
#' the first one in `codes` order is used. Rows where `col` is `NA` get `NA`
#' on every indicator. Rows with a non-missing value that contains none of the
#' options get 0 on every indicator.
#'
#' A warning lists any values in `col` that are not in `options` or `codes`.
#'
#' @param data A data frame.
#' @param col Unquoted name of the select-multiple column.
#' @param options Character vector of option values. One indicator column is
#'   created for each.
#' @param codes Character vector of missing-value codes that override the
#'   indicators. Must be coercible to integer (default: `c("888", "999")`).
#' @param delim Character. Delimiter separating selections in `col`, matched
#'   literally, not as a regular expression (default: `","`).
#' @param prefix Character. Prefix for the new column names, which are named
#'   `{prefix}_{option}`. Defaults to the column name followed by `"_ind"`.
#' @param place Where to put the new columns: `"after"` places them
#'   immediately after `col`, `"end"` leaves them at the end of the data
#'   frame.
#'
#' @return `data` with one integer indicator column added per element of
#'   `options`. Indicators are `NA` where `col` is `NA`.
#'
#' @examples
#' df <- data.frame(
#'   id = 1:4,
#'   activity = c("biking, hiking", "hiking", "888", NA)
#' )
#'
#' add_indicators(df, activity, options = c("biking", "hiking"))
#' #   id       activity activity_ind_biking activity_ind_hiking
#' # 1  1 biking, hiking                   1                   1
#' # 2  2         hiking                   0                   1
#' # 3  3            888                 888                 888
#' # 4  4           <NA>                  NA                  NA
#'
#' add_indicators(df, activity, options = c("biking", "hiking"),
#'                prefix = "act", place = "end")
#'
#' @importFrom dplyr bind_cols coalesce relocate all_of `%>%`
#' @importFrom purrr map map_int map_lgl set_names
#' @importFrom rlang enquo as_name `%||%`
#' @importFrom stringr str_split str_trim fixed
#' @importFrom tibble as_tibble
#' @export
#'
add_indicators <- function(data, col, options, codes = c("888", "999"),
                           delim = ",", prefix = NULL,
                           place = c("after", "end")) {
  place     <- match.arg(place)
  col_name  <- as_name(enquo(col))
  prefix    <- prefix %||% paste0(col_name, "_ind")
  ind_names <- paste0(prefix, "_", options)

  is_na <- is.na(data[[col_name]])

  sel <- data[[col_name]] %>%
    as.character() %>%
    str_split(fixed(delim)) %>%
    map(str_trim)

  unexpected <- setdiff(unique(unlist(sel)), c(options, codes, NA))
  if (length(unexpected) > 0) {
    warning("Values in `", col_name, "` not in options or codes: ",
            paste(unexpected, collapse = ", "), call. = FALSE)
  }

  code_hit <- map_int(sel, \(x) {
    hit <- intersect(codes, x)
    if (length(hit) > 0) as.integer(hit[1]) else NA_integer_
  })

  ind <- options %>%
    set_names(ind_names) %>%
    map(\(opt) {
      flag <- as.integer(map_lgl(sel, \(x) opt %in% x))
      flag[is_na] <- NA_integer_                         # NEW: NA in, NA out
      coalesce(code_hit, flag)   # code wins where present, otherwise 0/1/NA
    }) %>%
    as_tibble()

  out <- bind_cols(data, ind)

  if (place == "after") {
    out <- relocate(out, all_of(ind_names), .after = all_of(col_name))
  }
  out
}

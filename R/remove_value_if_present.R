#' Remove a value from a comma-separated string if present
#'
#' Used for select-multiple survey questions where a value should be
#' removed from a comma-separated response string — either because it
#' duplicates a paired single-select field (e.g. a "primary" activity
#' also listed in an "additional activities" field), or because a
#' manually specified value (e.g. "None") should be dropped when other
#' items were also selected, due to validation limitations in the
#' original survey instrument.
#'
#' @param list_col Character vector of comma-separated values, one string per row.
#' @param remove_val Character vector of values to remove. Either length 1
#'   (applied to every row, e.g. `"None"`) or the same length as `list_col`
#'   (one value per row, e.g. a paired `activity_primary` column).
#' @param empty_value Character. The value to return if removing `remove_val`
#'   leaves nothing behind, and `if_empty = "replace"`. This is normally an
#'   invalidation code (default is `"888"`), not an actual response value.
#' @param if_empty Character. Controls what happens when removing `remove_val`
#'   leaves no items behind.
#'   \itemize{
#'     \item `"replace"` (default): return `empty_value`. Use this when an
#'       empty result means the response is invalid — e.g. the only additional
#'       activity selected duplicated the primary activity.
#'     \item `"keep_original"`: return `list_col` unchanged. Use this when
#'       `remove_val` by itself is a valid, meaningful answer — e.g. a
#'       respondent who only selected "None".
#'   }
#'
#' @return A character vector the same length as `list_col`. Rows where
#'   `list_col` or the corresponding `remove_val` is `NA` are returned
#'   unchanged (`NA`).
#'
#' @examples
#' # Row-varying value to remove (e.g. primary duplicated in additional list)
#' remove_value_if_present(c("A,B,C", "A,B"), c("B", "A"))
#' #> c("A,C", "B")
#'
#' # Constant value to remove, invalid if nothing left
#' remove_value_if_present(c("None,A", "B,C"), "None")
#' #> c("A", "B,C")
#'
#' # Constant value to remove, but "None" alone is a valid response
#' remove_value_if_present(c("None,A", "None"), "None", if_empty = "keep_original")
#' #> c("A", "None")
#'
#' @importFrom purrr map2_chr
#' @importFrom stringr str_split str_trim
#' @export
remove_value_if_present <- function(list_col, remove_val,
                                    empty_value = "888",
                                    if_empty = c("replace", "keep_original")) {
  if_empty <- match.arg(if_empty)

  if (length(remove_val) != 1 && length(remove_val) != length(list_col)) {
    stop("`remove_val` must be length 1 or the same length as `list_col`.")
  }

  map2_chr(list_col, remove_val, function(lst, val) {
    if (is.na(lst) || is.na(val)) return(lst)
    items <- str_trim(str_split(lst, ",")[[1]])
    items <- items[!items %in% str_trim(val)]
    if (length(items) == 0) {
      if (if_empty == "keep_original") lst else empty_value
    } else {
      paste(items, collapse = ",")
    }
  })
}

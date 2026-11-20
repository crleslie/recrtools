#' Pad a delimited ranking list to a fixed length
#'
#' Splits a delimited ranking string (e.g. `"parking, trails"`) and fills
#' unused rank positions with a missing-value code until the list has `n`
#' items. Items are trimmed of surrounding whitespace and rejoined with
#' `delim` with no added space, so `"a, b"` becomes `"a,b,999"`.
#'
#' Lists that already have `n` or more items are returned unchanged apart
#' from trimming and rejoining; they are never truncated. `NA` input returns
#' `NA`. An empty string is treated as a one-item list containing an empty
#' item, so it is padded like any other value; convert blanks to `NA` first
#' if that is not what you want.
#'
#' @param x Character vector of delimited ranking lists.
#' @param n Integer. Expected number of list items (default: `3`).
#' @param fill Character. Value used to pad missing rank positions
#'   (default: `"999"`).
#' @param delim Character. Delimiter separating items, matched literally and
#'   used to rejoin the output (default: `","`).
#'
#' @return A character vector the same length as `x`.
#'
#' @examples
#' pad_rank_list(c("a, b", "a", "a, b, c", NA))
#' #> [1] "a,b,999"   "a,999,999" "a,b,c"     NA
#'
#' pad_rank_list("a", n = 5, fill = "888")
#' #> [1] "a,888,888,888,888"
#'
#' @importFrom stringr str_split str_trim fixed
#' @importFrom purrr map2_chr
#' @importFrom magrittr `%>%`
#' @export

pad_rank_list <- function(x, n = 3, fill = "999", delim = ",") {
  str_split(x, fixed(delim)) %>%
    map2_chr(is.na(x), \(v, na) {
      if (na) return(NA_character_)
      v <- str_trim(v)
      paste(c(v, rep(fill, max(0, n - length(v)))), collapse = delim)
    })
}

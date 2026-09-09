test_that("removes exact match", {
  expect_equal(remove_value_if_present("A,B,C", "B"), "A,C")
})

test_that("returns default value when list empties out", {
  expect_equal(remove_value_if_present("B", "B"), "888")
})

test_that("keeps original when list empties out and if_empty = keep_original", {
  expect_equal(remove_value_if_present("None", "None", if_empty = "keep_original"), "None")
})

test_that("no match leaves list unchanged", {
  expect_equal(remove_value_if_present("A,C", "B"), "A,C")
})

test_that("handles NA in either input", {
  expect_equal(remove_value_if_present(NA, "B"), NA_character_)
  expect_equal(remove_value_if_present("A,B", NA), "A,B")
})

test_that("trims whitespace before matching", {
  expect_equal(remove_value_if_present("A, B, C", "B"), "A,C")
})

test_that("recycles a length-1 remove_val across rows", {
  expect_equal(
    remove_value_if_present(c("None,A", "B,C"), "None"),
    c("A", "B,C")
  )
})

test_that("errors on mismatched lengths", {
  expect_error(remove_value_if_present(c("A,B", "C,D"), c("A", "B", "C")))
})

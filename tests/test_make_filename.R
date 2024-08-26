library(testthat)
library(fars)

testthat::expect_that("accident_2013.csv.bz2", is_identical_to(fars::make_filename(2013)))


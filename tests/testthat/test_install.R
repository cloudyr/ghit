context("Install packages")
r <- options("repos")
options("repos" = "http://cran.rstudio.com")

test_that("Install a single package", {
    expect_true(length(ghit::install_github("leeper/ghit")) == 1)
})

test_that("Install multiple packages", {
    expect_true(length(ghit::install_github(c("eddelbuettel/drat", "leeper/ghit"))) == 2)
})

options("repos" = r)

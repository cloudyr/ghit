context("Install packages")

test_that("Install a single package", {
    expect_true(length(install_github("leeper/ghit")) == 1)
})

test_that("Install multiple packages", {
    expect_true(length(install_github(c("eddelbuettel/drat", "leeper/ghit"))) == 2)
})

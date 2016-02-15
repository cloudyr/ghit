context("Install packages")
Sys.setenv("R_TESTS" = "")
tmp <- file.path(tempdir(), "tmplib")
suppressWarnings(dir.create(tmp))

test_that("Install a single package", {
    i1 <- install_github("leeper/ghit", lib = tmp, verbose = TRUE)
    expect_true(length(i1) == 1)
    remove.packages("ghit", lib = tmp)
})

test_that("Install a single package w/o vignettes", {
    i2 <- install_github("leeper/ghit", build_vignettes = FALSE, lib = tmp)
    expect_true(length(i2) == 1)
    remove.packages("ghit", lib = tmp)
})

test_that("Install multiple packages", {
    i3 <- install_github(c("leeper/ghit", "leeper/crandatapkgs"), lib = tmp)
    expect_true(length(i3) == 2)
    remove.packages(c("ghit", "crandatapkgs"), lib = tmp)
})

test_that("Install from a branch", {
    i4 <- install_github("leeper/ghit[kitten]", lib = tmp)
    expect_true(length(i3) == 2)
    remove.packages("anRpackage", lib = tmp)
})

#test_that("Install from a ref", {})
#test_that("Install from a tag", {})
#test_that("Install from a pull request", {})

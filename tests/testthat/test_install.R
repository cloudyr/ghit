context("Install packages")
tmp <- file.path(tempdir(), "tmplib")
suppressWarnings(dir.create(tmp))

test_that("Install a single package", {
    expect_true(length(install_github("leeper/webuse", lib = tmp, verbose = TRUE)) == 1)
})

test_that("Install a single package w/o vignettes", {
    #expect_true(length(install_github("leeper/webuse", build_vignettes = FALSE, lib = tmp)) == 1)
})


test_that("Install multiple packages", {
    expect_true(length(install_github(c("leeper/webuse", "leeper/crandatapkgs"), lib = tmp)) == 2)
})

#test_that("Install from a branch", {})
#test_that("Install from a ref", {})
#test_that("Install from a tag", {})
#test_that("Install from a pull request", {})

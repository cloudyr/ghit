context("Install packages")
Sys.setenv("R_TESTS" = "")
tmp <- file.path(tempdir(), "tmplib")
suppressWarnings(dir.create(tmp))

test_that("Install a single package", {
    i1 <- suppressWarnings(install_github("cloudyr/ghit", lib = tmp, verbose = TRUE))
    expect_true(length(i1) == 1)
})

test_that("Install a single package, removing old install", {
    i1 <- suppressWarnings(install_github("cloudyr/ghit", lib = tmp, uninstall = TRUE, verbose = TRUE))
    expect_true(length(i1) == 1)
})

test_that("Install a single package w/o vignettes", {
    i2 <- suppressWarnings(install_github("cloudyr/ghit", build_vignettes = FALSE, lib = tmp))
    expect_true(length(i2) == 1)
})

test_that("Install from a branch", {
    i4 <- install_github("cloudyr/ghit[kitten]", lib = tmp)
    expect_true(length(i4) == 1)
})

test_that("Install from a commit ref", {
    i5 <- suppressWarnings(install_github("cloudyr/ghit@6d118d08", lib = tmp))
    expect_true(length(i5) == 1)
})

test_that("Install from a tag", {
    i6 <- suppressWarnings(install_github("cloudyr/ghit@v0.1.1", lib = tmp))
    expect_true(length(i6) == 1)
})

test_that("Install from a pull request", {
    if (packageVersion("git2r") > "0.13.1.9000") {
        i7 <- suppressWarnings(install_github("cloudyr/ghit#13", lib = tmp))
        expect_true(length(i7) == 1)
    } else {
        expect_true(TRUE)
    }
})

# cleanup
if ("ghit" %in% installed.packages(lib.loc = tmp)[, "Package"]) {
    remove.packages("ghit", lib = tmp)
}
if ("anRpackage" %in% installed.packages(lib = tmp)[, "Package"]) {
    remove.packages("anRpackage", lib = tmp)
}
unlink(tmp)

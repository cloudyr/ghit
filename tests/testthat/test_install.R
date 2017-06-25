context("Install packages")
Sys.setenv("R_TESTS" = "")

tmp <- tempfile()
if (dir.create(tmp)) {

    test_that("Install a single package", {
        expect_true(length(i1 <- suppressWarnings(install_github("leeper/testghit", lib = tmp, verbose = TRUE))) == 1)
        expect_true(length(i1 <- suppressWarnings(install_bitbucket("imanuelcostigan/devtest", lib = tmp, verbose = TRUE))) == 1)
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("Install a single package, removing old install", {
        expect_true(length(i1 <- suppressWarnings(install_github("leeper/testghit", lib = tmp, uninstall = TRUE, verbose = TRUE))) == 1)
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("Install a single package w/o vignettes", {
        expect_true(length(i2 <- suppressWarnings(install_github("leeper/testghit", build_vignettes = FALSE, lib = tmp))) == 1)
        expect_true(length(i2 <- suppressWarnings(install_bitbucket("imanuelcostigan/devtest", build_vignettes = FALSE, lib = tmp))) == 1)
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("Install from a branch", {
        expect_true(length(i4 <- install_github("leeper/testghit[branch]", lib = tmp)) == 1)
        if ("testghit" %in% installed.packages(lib = tmp)[, "Package"]) {
            remove.packages("testghit", lib = tmp)
        }
        expect_true(length(i4 <- install_bitbucket("imanuelcostigan/devtest[dev]", lib = tmp)) == 1)
        if ("devtest" %in% installed.packages(lib = tmp)[, "Package"]) {
            remove.packages("devtest", lib = tmp)
        }
    })

    test_that("Install from a commit ref", {
        expect_true(length(i5 <- suppressWarnings(install_github("leeper/testghit@c039683f13", lib = tmp))) == 1)
        expect_true(length(i5 <- suppressWarnings(install_bitbucket("imanuelcostigan/devtest@309fa0a", lib = tmp))) == 1)
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("Install from a tag", {
        expect_true(length(i6 <- suppressWarnings(install_github("leeper/testghit@v0.0.1", lib = tmp))) == 1)
        expect_true(length(i6 <- suppressWarnings(install_bitbucket("imanuelcostigan/devtest@v0.1", lib = tmp))) == 1)
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("Install from a pull request", {
        if (packageVersion("git2r") > "0.13.1.9000") {
            expect_true(length(i7 <- suppressWarnings(install_github("leeper/testghit#1", lib = tmp))) == 1)
            expect_error(length(i7 <- suppressWarnings(install_bitbucket("imanuelcostigan/devtest#1", lib = tmp))) == 1)
        } else {
            expect_true(TRUE)
        }
        remove.packages(c("testghit", "devtest"), lib = tmp)
    })

    test_that("An invalid reponame returns informative error", {
        expect_error(install_github("missinguser"), "Invalid 'repo' string")
    })

    # cleanup
    if ("testghit" %in% installed.packages(lib.loc = tmp)[, "Package"]) {
        remove.packages("testghit", lib = tmp)
    }
    if ("devtest" %in% installed.packages(lib.loc = tmp)[, "Package"]) {
        remove.packages("devtest", lib = tmp)
    }
    unlink(tmp)
}

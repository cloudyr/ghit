context("Test internals: parse, checkout, build")
x1 <- ghit:::parse_reponame("cloudyr/ghit")
test_that("Parse reponame", {
    expect_true(is.list(x1))
    expect_true(x1$user == "cloudyr")
    expect_true(x1$pkgname == "ghit")
    expect_true(is.na(x1$ref))
    expect_true(is.na(x1$branch))
    expect_true(is.na(x1$pull))
    expect_true(is.na(x1$subdir))
})
chk1 <- ghit:::checkout_github(x1, "github.com")
chk2 <- ghit:::checkout_github(x1, "github.com", verbose = TRUE)
test_that("checkout package", {
    expect_true(is.character(chk1))
    expect_true(is.character(chk2))
})
test_that("build package and insert", {
    desc <- read.dcf(file.path(chk1, "DESCRIPTION"))
    expect_true(ghit:::build_and_insert(x1$pkgname, chk1, unname(desc[1,"Version"]), 
                                        build_args = " --no-build-vignettes", verbose = FALSE))
    expect_true(ghit:::build_and_insert(x1$pkgname, chk1, unname(desc[1,"Version"]), 
                                        build_args = " --no-build-vignettes", verbose = TRUE))
    expect_true(any(grepl("ghit", dir(file.path(tempdir(), "ghitdrat", "src", "contrib")))))
})

context("Subdirectories")
x2 <- ghit:::parse_reponame("cloudyr/ghit/R")
test_that("Parse reponame, subdirectory", {
    expect_true(is.list(x2))
    expect_true(x2$user == "cloudyr")
    expect_true(x2$pkgname == "ghit")
    expect_true(is.na(x2$ref))
    expect_true(is.na(x2$branch))
    expect_true(is.na(x2$pull))
    expect_true(x2$subdir == "R")
})
test_that("checkout package subdirectory", {
    expect_true(is.character(ghit:::checkout_github(x2, "github.com")))
})

context("Commits")
x3 <- ghit:::parse_reponame("cloudyr/ghit[kitten]")
test_that("Parse reponame, branch", {
    expect_true(is.list(x3))
    expect_true(x3$user == "cloudyr")
    expect_true(x3$pkgname == "ghit")
    expect_true(is.na(x3$ref))
    expect_true(x3$branch == "kitten")
    expect_true(is.na(x3$pull))
    expect_true(is.na(x3$subdir))
})
test_that("checkout branch", {
    expect_true(is.character(ghit:::checkout_github(x3, "github.com")))
})

context("Commits")
x4 <- ghit:::parse_reponame("cloudyr/ghit@6d118d08")
test_that("Parse reponame, ref", {
    expect_true(is.list(x4))
    expect_true(x4$user == "cloudyr")
    expect_true(x4$pkgname == "ghit")
    expect_true(x4$ref == "6d118d08")
    expect_true(is.na(x4$branch))
    expect_true(is.na(x4$pull))
    expect_true(is.na(x4$subdir))
})
test_that("checkout commit", {
    expect_true(is.character(ghit:::checkout_github(x4, "github.com")))
})

context("Releases")
x5 <- ghit:::parse_reponame("cloudyr/ghit@v0.1.1")
test_that("Parse reponame, release", {
    expect_true(is.list(x5))
    expect_true(x5$user == "cloudyr")
    expect_true(x5$pkgname == "ghit")
    expect_true(x5$ref == "v0.1.1")
    expect_true(is.na(x5$branch))
    expect_true(is.na(x5$pull))
    expect_true(is.na(x5$subdir))
})
test_that("checkout release", {
    expect_true(is.character(ghit:::checkout_github(x5, "github.com")))
})

context("Pull requests")
x6 <- ghit:::parse_reponame("cloudyr/ghit#13")
test_that("Parse reponame, pull request", {
    expect_true(is.list(x6))
    expect_true(x6$user == "cloudyr")
    expect_true(x6$pkgname == "ghit")
    expect_true(is.na(x6$ref))
    expect_true(is.na(x6$branch))
    expect_true(x6$pull == "13")
    expect_true(is.na(x6$subdir))
})
test_that("checkout pull request", {
    expect_true(is.character(ghit:::checkout_github(x6, "github.com")))
})


test_that("error on checkout fake branch", {
    p <- ghit:::parse_reponame("cloudyr/ghit[fakebranch]")
    expect_error(ghit:::checkout_github(p, "github.com"))
})

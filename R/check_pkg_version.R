check_pkg_version <- function(p, vers, lib = .libPaths()) {
    if (p$pkgname %in% installed.packages(lib.loc = lib)[, "Package"]) {
        curr <- try(as.character(utils::packageVersion(p$pkgname, lib.loc = lib)), silent = TRUE)
    } else {
        curr <- NA_character_
    }
    if (!inherits(curr, "try-error") && !is.na(curr)) {
        com <- utils::compareVersion(vers, curr)
        ghitmsg(com < 0,
            warning(sprintf("Package %s older (%s) than currently installed version (%s).", p$pkgname, vers, curr))
        )
    }
}

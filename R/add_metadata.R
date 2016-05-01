add_metadata <- function(pkgdir, p, verbose = FALSE) {
    ghitmsg(verbose, message(sprintf("Adding metadata to DESCRIPTION for package %s...", p$pkgname)))
    desc <- file.path(pkgdir, "DESCRIPTION")
    dcf <- read.dcf(desc)
    meta <- c("github", p$user, p$pkgname, p$sha1)
    dimn <- list(NULL, c("RemoteType", "GithubUsername", "GithubRepo", "GithubSHA1"))
    metamat <- matrix(meta, nrow = 1, dimnames = dimn)
    dcf <- cbind(dcf, metamat)
    write.dcf(dcf, file = desc)
    return(TRUE)
}

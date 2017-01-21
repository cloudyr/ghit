build_and_insert <- function(pkgname, d, ver, build_args = "", verbose = FALSE) {
    
    arg <- c("CMD build", build_args, d)
    ghitmsg(verbose, message(sprintf("Building package %s...", pkgname)))
    rpath <- file.path(R.home("bin"), "R")
    build_output <- tempfile()
    on.exit(unlink(build_output))
    success <- suppressWarnings(system2(rpath, arg, stdout = build_output))
    if (success != 0) {
        stop(sprintf("Package build for %s failed with the following output:\n", pkgname), 
             paste0(readLines(build_output), collapse = "\n"))
    }
    tarball <- file.path(paste0(pkgname, "_", ver, ".tar.gz"))
    on.exit(unlink(tarball), add = TRUE)
    pkgdir <- make_drat(verbose = verbose)
    ghitmsg(verbose, message(sprintf("Writing package %s to internal repository...", pkgname)))
    file.copy(tarball, to = pkgdir, overwrite = TRUE)
    tools::write_PACKAGES(pkgdir, type = "source")
    
    return(TRUE)
}

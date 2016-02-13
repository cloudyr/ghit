build_and_insert <- function(pkgname, d, ver, build_args = "", basic_args = "", verbose = FALSE) {
    p <- Sys.getenv("PATH")
    ptmp <- paste0(normalizePath(R.home("bin")), ";", p)
    Sys.setenv(PATH = ptmp)
    on.exit(Sys.setenv(PATH = p))
    
    arg <- paste0("CMD build ", d, " ", build_args, basic_args)
    if (verbose) {
        message(sprintf("Building package %s...", pkgname))
    }
    success <- system2("R", arg, stdout = if (verbose) "" else FALSE)
    if (success != 0) {
        stop(sprintf("Package build for %s failed!", pkgname))
    }
    tarball <- paste0(pkgname, "_", ver, ".tar.gz")
    on.exit(unlink(tarball), add = TRUE)
    
    pkgdir <- file.path(tempdir(), "ghitdrat", "src", "contrib")
    if (!dir.exists(pkgdir)) {
        suppressWarnings(dir.create(file.path(tempdir())))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat")))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "src")))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "src", "contrib")))
    }
    if (verbose) {
        message(sprintf("Writing package %s to internal repository...", pkgname))
    }
    file.copy(tarball, to = pkgdir, overwrite = TRUE)
    tools::write_PACKAGES(pkgdir, type = "source")
    
    return(TRUE)
}

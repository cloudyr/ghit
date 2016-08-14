build_and_insert <- function(pkgname, d, ver, build_args = "", verbose = FALSE) {
    
    arg <- c("CMD build", build_args, d)
    if (verbose) {
        message(sprintf("Building package %s...", pkgname))
    }
    rpath <- file.path(R.home("bin"), "R")
    success <- system2(rpath, arg, stdout = if (verbose) "" else FALSE)
    if (success != 0) {
        stop(sprintf("Package build for %s failed!", pkgname))
    }
    tarball <- file.path(paste0(pkgname, "_", ver, ".tar.gz"))
    on.exit(unlink(tarball), add = TRUE)
    
    pkgdir <- file.path(tempdir(), "ghitdrat", "src", "contrib")
    if (((getRversion() >= "3.2.0") && !dir.exists(pkgdir)) || (!file.exists(pkgdir))) {
        suppressWarnings(dir.create(file.path(tempdir())))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat")))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "src")))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "src", "contrib")))
    }
    win_os <- .Platform[["pkgType"]] %in% "win.binary"
    if (isTRUE(win_os)) {
        RV <- paste0(R.Version()[["major"]], ".", strsplit(R.Version()[["minor"]], "\\.")[[1]][1])
        windir <- file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib", RV)
        if (((getRversion() >= "3.2.0") && !dir.exists(windir)) || (!file.exists(windir))) {
            suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin")))
            suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin", "windows")))
            suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib")))
            suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib", RV)))
        }
        tools::write_PACKAGES(windir, type = "win.binary")
    }
    if (verbose) {
        message(sprintf("Writing package %s to internal repository...", pkgname))
    }
    file.copy(tarball, to = pkgdir, overwrite = TRUE)
    tools::write_PACKAGES(pkgdir, type = "source")
    
    return(TRUE)
}

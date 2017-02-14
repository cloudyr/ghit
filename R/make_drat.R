make_drat <- function(verbose) {
    repodir <- file.path(tempdir(), "ghitdrat", "src", "contrib")
    setup_repodir(verbose = verbose)
    ghitmsg(verbose, message("Writing PACKAGES file for internal repository..."))
    tools::write_PACKAGES(repodir, type = "source")

    win_os <- .Platform[["pkgType"]] %in% "win.binary"
    if (isTRUE(win_os)) {
        windir <- setup_repodir_windows(verbose = verbose)
        ghitmsg(verbose, message("Writing PACKAGES file for Windows binaries in internal repository..."))
        tools::write_PACKAGES(windir, type = "win.binary")
    }
    return(repodir)
}

setup_repodir <- function(verbose) {
    repodir <- file.path(tempdir(), "ghitdrat", "src")
    if ((getRversion() >= "3.2.0") && !dir.exists(repodir)) {
        ghitmsg(verbose, message(sprintf("Creating internal package repository in %s...", repodir)))
        dir.create(file.path(tempdir(), "ghitdrat", "src", "contrib"), recursive = TRUE)
    } else if (!file.exists(repodir)) {
        ghitmsg(verbose, message(sprintf("Creating internal package repository in %s...", repodir)))
        dir.create(file.path(tempdir(), "ghitdrat", "src", "contrib"), recursive = TRUE)
    } else {
        ghitmsg(verbose, message(sprintf("Using internal package repository in %s...", repodir)))
    }
    return(paste0("file:///", repodir))
}

setup_repodir_windows <- function(verbose) {
    RV <- paste0(R.Version()[["major"]], ".", strsplit(R.Version()[["minor"]], "\\.")[[1]][1])
    windir <- file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib", RV)
    if (((getRversion() >= "3.2.0") && !dir.exists(windir))) {
        ghitmsg(verbose, message("Creating Windows binary folder in internal repository..."))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib", RV), recursive = TRUE))
    } else if (!file.exists(windir)) {
        ghitmsg(verbose, message("Creating Windows binary folder in internal repository..."))
        suppressWarnings(dir.create(file.path(tempdir(), "ghitdrat", "bin", "windows", "contrib", RV), recursive = TRUE))
    }
    return(windir)
}

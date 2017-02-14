preinstall_suggests <- function(suggests, p, type, repos, dependencies = NA, verbose = FALSE, ...) {
    ghitmsg(verbose, message(sprintf("Installing 'Suggests' packages for '%s': %s", 
                                     p$pkgname, 
                                     paste0(suggests, collapse = ", "))
                             ))
    suggests <- suggests[!suggests %in% installed.packages()[, "Package"]]
    if (length(suggests)) {
        utils::install.packages(suggests, type = type, 
                                repos = repos,
                                dependencies = NA,
                                verbose = verbose,
                                quiet = !verbose,
                                ...)
    }
}

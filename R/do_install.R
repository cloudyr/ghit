do_install <- function(to_install, type, repos, dependencies = NA, opts, verbose = FALSE, ...) {
    # internal function to execute final install
    # used by `install_github()` and `install_bitbucket()`
    
    loaded <- to_install[to_install %in% loadedNamespaces()]
    if (length(loaded)) {
        ghitmsg(verbose, message(sprintf("Unloading packages %s...", paste0(loaded, collapse = ", "))))
        try(sapply(loaded, unloadNamespace))
    }
    dependencymsg <- if (length(dependencies)) {
        if (is.na(dependencies[1L])) {
            paste0(paste0(to_install, collapse = ", "), " and 'Depends', 'Imports', 'LinkingTo'")
        } else {
            paste0(paste0(to_install, collapse = ", "), " and ", paste0("'", dependencies, "'", collapse = ", "))
        }
    } else {
        paste0(to_install, collapse = ", ")
    }
    ghitmsg(verbose, message(sprintf("Installing packages %s...", dependencymsg)))
    utils::install.packages(to_install, type = type, 
                            repos = repos,
                            dependencies = dependencies,
                            verbose = verbose,
                            quiet = !verbose,
                            ...)
    
    v_out <- sapply(to_install, function(x) {
        if ("lib" %in% names(opts)) {
            z <- try(as.character(utils::packageVersion(x, lib.loc = c(opts$lib,.libPaths()))), silent = TRUE)
        } else {
            z <- try(as.character(utils::packageVersion(x)), silent = TRUE)
        }
        if (inherits(z, "try-error")) NA_character_ else z
    })
    if (length(loaded)) {
        ghitmsg(verbose, message(sprintf("Reloading packages %s...", paste0(loaded, collapse = ", "))) )
        sapply(loaded, requireNamespace)
    }
    
    return(v_out)
}

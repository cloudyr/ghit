install_github <- 
function(repo, host = "github.com", credentials = NULL, 
         build_args = NULL, build_vignettes = TRUE, uninstall = FALSE, 
         verbose = FALSE, 
         repos = getOption("repos", c(CRAN = "https://cloud.r-project.org")),
         dependencies = c("Depends", "Imports", "Suggests"), ...) {
    
    install(repo = repo, 
            host = host, 
            credentials = credentials, 
            build_args = build_args, 
            build_vignettes = build_vignettes, 
            verbose = verbose, 
            repos = repos,
            dependencies = dependencies, 
            ...)
}

install_bitbucket <- 
function(repo, host = "bitbucket.org", credentials = NULL, 
         build_args = NULL, build_vignettes = TRUE, verbose = FALSE, 
         repos = getOption("repos", c(CRAN = "http://cloud.r-project.org")),
         dependencies = c("Depends", "Imports", "Suggests"), ...) {
    
    u <- strsplit(repo, "/", fixed = TRUE)[[1]][1]
    install(repo = repo, 
            host = paste0(u, "@", host), 
            credentials = credentials, 
            build_args = build_args, 
            build_vignettes = build_vignettes, 
            verbose = verbose, 
            repos = repos,
            dependencies = dependencies, 
            ...)
}

install_git <- 
function(repo, host, credentials = NULL, 
         build_args = NULL, build_vignettes = TRUE, verbose = FALSE, 
         repos = getOption("repos", c(CRAN = "http://cloud.r-project.org")),
         dependencies = c("Depends", "Imports", "Suggests"), ...) {
    
    install(repo = repo, 
            host = paste0(u, "@", host), 
            credentials = credentials, 
            build_args = build_args, 
            build_vignettes = build_vignettes, 
            verbose = verbose, 
            repos = repos,
            dependencies = dependencies, 
            ...)
}

install <- 
function(repo, host, credentials, build_args, 
         build_vignettes = TRUE, verbose = FALSE, 
         repos, dependencies = c("Depends", "Imports", "Suggests"), ...) {

    opts <- list(...)
    
    # setup build args
    if (is.null(build_args)) {
        build_args <- ""
    }
    if (!build_vignettes) {
        if (!grepl("build-vignettes", build_args, fixed = TRUE)) {
            build_args <- paste0(build_args, " --no-build-vignettes")
        }
    }
    
    # setup drat
    repodir <- setup_repodir()
    
    # download and build packages
    to_install <- sapply(unique(repo), function(x) {
        # parse reponame
        ghitmsg(verbose, message(sprintf("Parsing reponame for '%s'...", x)))
        p <- parse_reponame(repo = x)
        d <- checkout_github(p, host = host, credentials = credentials, verbose = verbose)
        on.exit(unlink(d), add = TRUE)
        
        ghitmsg(verbose, message(sprintf("Reading package metadata for '%s'...", x)))
        description <- read.dcf(file.path(d, "DESCRIPTION"))
        p$pkgname <- unname(description[1, "Package"])
        vers <- unname(description[1,"Version"])
        if ("lib" %in% names(opts)) {
            if (p$pkgname %in% installed.packages(lib.loc = c(.libPaths(), opts$lib))[, "Package"]) {
                curr <- try(as.character(utils::packageVersion(p$pkgname, lib.loc = c(.libPaths(), opts$lib))), silent = TRUE)
            } else {
                curr <- NA_character_
            }
        } else {
            if (p$pkgname %in% installed.packages()[, "Package"]) {
                curr <- try(as.character(utils::packageVersion(p$pkgname)), silent = TRUE)
            } else {
                curr <- NA_character_
            }
        }
        if (!inherits(curr, "try-error") && !is.na(curr)) {
            com <- utils::compareVersion(vers, curr)
            ghitmsg(com < 0, 
                warning(sprintf("Package %s older (%s) than currently installed version (%s).", p$pkgname, vers, curr))
            )
        }
        
        # build package and insert into drat
        build_and_insert(p$pkgname, d, vers, build_args, verbose = verbose)
        return(p$pkgname)
    })
    
    # conditionally uninstall old versions
    if (isTRUE(uninstall)) {
        uninstall_old(to_install, lib = opts$lib, verbose = verbose)
    }
    
    # install packages from drat and dependencies from CRAN
    loaded <- to_install[to_install %in% loadedNamespaces()]
    if (length(loaded)) {
        ghitmsg(verbose, message(sprintf("Unloading packages %s...", paste0(loaded, collapse = ", "))))
        try(sapply(loaded, unloadNamespace))
    }
    ghitmsg(verbose, 
            message(sprintf("Installing packages%s...", 
                    if (length(dependencies)) paste0(" and ", paste(dependencies, collapse = ", ")) else ""))
           )
    contrib <- file.path(c("TemporaryRepo" = paste0("file:///", repodir), repos), "src", "contrib")
    utils::install.packages(to_install, type = "source", 
                            contriburl = contrib,
                            dependencies = dependencies,
                            verbose = verbose,
                            quiet = !verbose,
                            ...)
    
    v_out <- sapply(to_install, function(x) {
        if ("lib" %in% names(opts)) {
            z <- try(as.character(utils::packageVersion(x, lib.loc = c(.libPaths(), opts$lib))), silent = TRUE)
        } else {
            z <- try(as.character(utils::packageVersion(x)), silent = TRUE)
        }
        if (inherits(z, "try-error")) NA_character_ else z
    })
    if (length(loaded)) {
        ghitmsg(verbose, message(sprintf("reloading packages %s...", paste0(loaded, collapse = ", "))) )
        sapply(loaded, requireNamespace)
    }
    
    return(v_out)
}

setup_repodir <- function() {
    repodir <- file.path(tempdir(), "ghitdrat")
    suppressWarnings(dir.create(repodir))
    suppressWarnings(dir.create(file.path(repodir, "src")))
    suppressWarnings(dir.create(file.path(repodir, "src", "contrib")))
    on.exit(unlink(repodir), add = TRUE)
    return(repodir)
}

uninstall_old <- function(pkgs, lib, verbose = FALSE) {    
    if (!is.null(lib)) {
        if (verbose) {
            un <- try(utils::remove.packages(pkgs, lib = lib), silent = TRUE)
        } else {
            un <- suppressMessages(try(utils::remove.packages(pkgs, lib = lib), silent = TRUE))
        }
    } else {
        un <- try(utils::remove.packages(pkgs), silent = TRUE)
        if (verbose) {
            
        } else {
            un <- suppressMessages(try(utils::remove.packages(pkgs), silent = TRUE))
        }
    }
    if (inherits(un, "try-error")) {
        ghitmsg(verbose, paste0("Note: ", message(attributes(un)$condition$message)))
    }
    invisible(NULL)
}

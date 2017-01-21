#' @title Install R package from GitHub
#' @description \code{install_github} allows users to install R packages hosted on GitHub without needing to install or load the heavy dependencies required by devtools. ghit provides a drop-in replacement that provides (almost) identical functionality to \code{devtools::install_github()}.
#' @param repo A character vector naming one or more GitHub repository containing an R package to install (e.g., \dQuote{leeper/ghit}), or optionally a branch (\dQuote{leeper/ghit[dev]}), a reference (\dQuote{leeper/ghit@b200fb1bd}), tag (\dQuote{leeper/ghit@v0.2}), or subdirectory (\dQuote{leeper/ghit/R}). These arguments can be placed in any order and in any combination (e.g., \dQuote{leeper/ghit[master]@abc123/R}).
#' @param host A character string naming a host, to enable installation of enterprise-hosted GitHub packages.
#' @param credentials}{An argument passed to the \code{credentials} argument to \code{\link[git2r]{clone}}. See \code{\link[git2r]{cred_user_pass}} or \code{\link[git2r]{cred_ssh_key}}.
#' @param build_args A character string used to control the package build, passed to \code{R CMD build}.
#' @param build_vignettes A logical specifying whether to build package vignettes, passed to \code{R CMD build}. Can be slow. Note: The default is \code{TRUE}, unlike in \code{devtools::install_github()}.
#' @param uninstall A logical specifying whether to uninstall previous installations using \code{\link[utils]{remove.packages}} before attempting install. This is useful for installing an older version of a package than the one currently installed.
#' @param verbose A logical specifying whether to print details of package building and installation.
#' @param repos A character vector specifying one or more URLs for CRAN-like repositories from which package dependencies might be installed. By default, value is taken from \code{options("repos")} or set to the CRAN cloud repository.
#' @param type A character vector passed to the \code{type} argument of \code{\link[utils]{install.packages}}.
#' @param dependencies A character vector specifying which dependencies to install (of \dQuote{Depends}, \dQuote{Imports}, \dQuote{Suggests}, etc.). The default, \code{NA}, means \code{c("Depends", "Imports", "LinkingTo")}. See \code{\link[utils]{install.packages}} for a fuller explanation.
#' @param \dots Additional arguments to control installation of package, passed to \code{\link[utils]{install.packages}}.
#' @return A named character vector of R package versions installed.
#' @author Thomas J. Leeper
#' @examples
#' \dontrun{
#' tmp <- file.path(tempdir(), "tmplib")
#' dir.create(tmp)
#' # install a single package
#' install_github("cloudyr/ghit", lib = tmp)
#' 
#' # install multiple packages
#' install_github(c("cloudyr/ghit", "leeper/crandatapkgs"), lib = tmp)
#' 
#' # cleanup
#' unlink(tmp, recursive = TRUE)
#' }
#' @importFrom git2r init clone config commits remote_ls
#' @importFrom utils install.packages installed.packages remove.packages packageVersion compareVersion capture.output
#' @importFrom tools write_PACKAGES
#' @export
install_github <- 
function(repo, host = "github.com", credentials = NULL, 
         build_args = NULL, build_vignettes = TRUE, uninstall = FALSE, 
         verbose = FALSE, 
         repos = NULL,
         type = if (.Platform[["pkgType"]] %in% "win.binary") "both" else "source",
         dependencies = NA, ...) {

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
    
    # setup drat & configure `repos`
    repodir <- file.path(tempdir(), "ghitdrat")
    if (is.null(repos)) {
        tmp_repos <- getOption("repos")
        if ("@CRAN@"  %in% tmp_repos) {
            tmp_repos["CRAN"] <- "https://cloud.r-project.org"
        }
        repos <- tmp_repos
        rm(tmp_repos)
    }
    repos <- c("TemporaryRepo" = paste0("file:///", repodir), repos)
    
    
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
        suggests <- strsplit(gsub("[[:space:]]+", "", description[1, "Suggests"]), ",")[[1L]]
        
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
        if (isTRUE(build_vignettes)) {
            # install Suggests dependencies, non-recursively
            if (!is.null(suggests) && suggests != "") {
                ghitmsg(verbose, message(sprintf("Installing 'Suggests' packages for '%s'...", p$pkgname)))
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
        }
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
            message(sprintf("Installing packages %s...", 
                    if (length(dependencies)) paste0("and ", paste(dependencies, collapse = ", ")) else ""))
           )
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
        ghitmsg(verbose, message(sprintf("reloading packages %s...", paste0(loaded, collapse = ", "))) )
        sapply(loaded, requireNamespace)
    }
    
    return(v_out)
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

#' @title Install R package from Bitbucket
#' @description \code{install_bitbucket} allows users to install R packages hosted on Bitbucket without needing to install or load the heavy dependencies required by devtools. ghit provides a drop-in replacement that provides (almost) identical functionality to \code{devtools::install_bitbucket()}.
#' @param repo A character vector naming one or more GitHub repository containing an R package to install (e.g., \dQuote{imanuelcostigan/devtest}), or optionally a branch (\dQuote{imanuelcostigan/devtest[dev]}), a reference (\dQuote{imanuelcostigan/devtest@309fa0a}), tag (\dQuote{imanuelcostigan/devtest@v0.1}), or subdirectory (\dQuote{imanuelcostigan/samplepackage/R}). These arguments can be placed in any order and in any combination (e.g., \dQuote{imanuelcostigan/devtest[master]@abc123/R}). As the use of pull request (PR) references are not supported by Bitbucket, you should install from the PR's source repository and branch.
#' @param host A character string naming a host, to enable installation of enterprise-hosted Bitbucket Server packages.
#' @param credentials}{An argument passed to the \code{credentials} argument to \code{\link[git2r]{clone}}. See \code{\link[git2r]{cred_user_pass}} or \code{\link[git2r]{cred_ssh_key}}.
#' @param build_args A character string used to control the package build, passed to \code{R CMD build}.
#' @param build_vignettes A logical specifying whether to build package vignettes, passed to \code{R CMD build}. Can be slow. Note: The default is \code{TRUE}, unlike in \code{devtools::install_github()}.
#' @param uninstall A logical specifying whether to uninstall previous installations using \code{\link[utils]{remove.packages}} before attempting install. This is useful for installing an older version of a package than the one currently installed.
#' @param verbose A logical specifying whether to print details of package building and installation.
#' @param repos A character vector specifying one or more URLs for CRAN-like repositories from which package dependencies might be installed. By default, value is taken from \code{options("repos")} or set to the CRAN cloud repository.
#' @param type A character vector passed to the \code{type} argument of \code{\link[utils]{install.packages}}.
#' @param dependencies A character vector specifying which dependencies to install (of \dQuote{Depends}, \dQuote{Imports}, \dQuote{Suggests}, etc.).
#' @param \dots Additional arguments to control installation of package, passed to \code{\link[utils]{install.packages}}.
#' @return A named character vector of R package versions installed.
#' @author Imanuel Costigan
#' @examples
#' \dontrun{
#' tmp <- file.path(tempdir(), "tmplib")
#' dir.create(tmp)
#' # install a single package. Multiple package install is also supported.
#' install_bitbucket("imanuelcostigan/devtest", lib = tmp)
#'
#' # cleanup
#' unlink(tmp, recursive = TRUE)
#' }
#' @importFrom git2r init clone config commits remote_ls
#' @importFrom utils install.packages installed.packages remove.packages packageVersion compareVersion capture.output
#' @importFrom tools write_PACKAGES
#' @export

install_bitbucket <- function(repo, host = "bitbucket.org", credentials = NULL,
    build_args = NULL, build_vignettes = TRUE, uninstall = FALSE,
    verbose = FALSE,
    repos = NULL,
    type = if (.Platform[["pkgType"]] %in% "win.binary") "both" else "source",
    dependencies = c("Depends", "Imports"), ...) {

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
        d <- checkout_bitbucket(p, host = host, credentials = credentials, verbose = verbose)
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
    if (is.null(repos)) {
        tmp_repos <- getOption("repos")
        if ("@CRAN@"  %in% tmp_repos) {
            tmp_repos["CRAN"] <- "https://cloud.r-project.org"
        }
        repos <- tmp_repos
        rm(tmp_repos)
    }
    repos <- c("TemporaryRepo" = repodir, repos)
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


checkout_bitbucket <- function(p, host = "bitbucket.org", credentials = NULL, verbose = FALSE) {
    ghitmsg(verbose, message(sprintf("Creating local git repository for %s...", p$pkgname)) )
    d <- tempfile(pattern = p$pkgname)
    dir.create(d)
    gitrepo <- git2r::init(d)
    git2r::config(gitrepo, user.name = "ghit", user.email = "example@example.com")
    git2r::remote_add(gitrepo, "bitbucket",
        paste0("https://", host, "/", paste(p$user, p$pkgname, sep = "/"), ".git"))

    if (is.na(p$pull)) {
        if (verbose) {
            ghitmsg(verbose, message(sprintf("Checking out package %s to local git repository...", p$pkgname)))
            git2r::fetch(gitrepo, name = "bitbucket", credentials = credentials)
        } else {
            utils::capture.output(git2r::fetch(gitrepo, name = "bitbucket", credentials = credentials))
        }
        if (!is.na(p$branch)) {
            ghitmsg(verbose, message(sprintf("Checking out branch %s for package %s...", p$branch, p$pkgname)))
            ghitmsg(!length(grep(paste0("bitbucket/", p$branch), names(git2r::branches(gitrepo)))),
                stop("Branch not found!"))
            git2r::checkout(gitrepo, branch = p$branch, create = TRUE, force = TRUE)
        } else {
            git2r::checkout(gitrepo, branch = "master", create = TRUE, force = TRUE)
        }
    } else {
        # Bitbucket.org does not support the pull request refspec
        # https://bitbucket.org/site/master/issues/5814/reify-pull-requests-by-making-them-a-ref
        stop("Bitbucket.org does not support pull request refspecs. ",
            "You should install from the source branch of the pull request directly.")
    }
    # checkout commits or tags
    if (!is.na(p$ref)) {
        # commits
        a <- grep(substring(p$ref, 2, nchar(p$ref)),
            sapply(git2r::commits(gitrepo), function(x) attributes(x)[["sha"]]), fixed = TRUE)
        if (length(a)) {
            ghitmsg(verbose, message(sprintf("Checking out commit %s for packge %s...", p$ref, p$pkgname)) )
            git2r::checkout(git2r::commits(gitrepo)[[a[1]]], force = TRUE)
        } else {
            # tags
            b <- grep(p$ref, names(git2r::tags(gitrepo)), fixed = TRUE)
            if (length(b)) {
                ghitmsg(verbose, message(sprintf("Checking out tag %s for packge %s...", p$ref, p$pkgname)) )
                git2r::checkout(git2r::tags(gitrepo)[[b[1]]], force = TRUE)
            } else {
                stop("Reference (sha or git tag) not found!")
            }
        }
    }
    # checkout directories
    if (!is.na(p$subdir)) {
        ghitmsg(verbose, message(sprintf("Checking out package subdirectory for %s...", p$pkgname)) )
        d <- file.path(d, p$subdir)
    }
    p$sha1 <- git2r::commits(gitrepo)[[1]]@sha
    try(add_bb_metadata(d, p, verbose = verbose), silent = TRUE)
    return(d)
}

add_bb_metadata <- function(pkgdir, p, verbose = FALSE) {
    ghitmsg(verbose, message(sprintf("Adding metadata to DESCRIPTION for package %s...", p$pkgname)))
    desc <- file.path(pkgdir, "DESCRIPTION")
    dcf <- read.dcf(desc)
    meta <- c("bitbucket", p$user, p$pkgname, p$sha1)
    dimn <- list(NULL, c("RemoteType", paste0("Bitbucket", c("Username", "Repo", "SHA1"))))
    metamat <- matrix(meta, nrow = 1, dimnames = dimn)
    dcf <- cbind(dcf, metamat)
    write.dcf(dcf, file = desc)
    return(TRUE)
}

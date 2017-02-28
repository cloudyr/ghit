#' @title Install R package from Bitbucket
#' @description \code{install_bitbucket} allows users to install R packages
#'   hosted on Bitbucket without needing to install or load the heavy
#'   dependencies required by devtools. ghit provides a drop-in replacement that
#'   provides (almost) identical functionality to
#'   \code{devtools::install_bitbucket()}. The \code{install_bitbucket_server}
#'   interface provides some convenient default values for \code{host} and
#'   \code{credentials} for corporate users.
#' @param repo A character vector naming one or more GitHub repository
#'   containing an R package to install (e.g.,
#'   \dQuote{imanuelcostigan/devtest}), or optionally a branch
#'   (\dQuote{imanuelcostigan/devtest[dev]}), a reference
#'   (\dQuote{imanuelcostigan/devtest@309fa0a}), tag
#'   (\dQuote{imanuelcostigan/devtest@v0.1}), or subdirectory
#'   (\dQuote{imanuelcostigan/samplepackage/R}). These arguments can be placed
#'   in any order and in any combination (e.g.,
#'   \dQuote{imanuelcostigan/devtest[master]@abc123/R}). As the use of pull
#'   request (PR) references are not supported by Bitbucket, you should install
#'   from the PR's source repository and branch.
#' @param host A character string naming a host. This defaults to
#'   \code{bitbucket.org} when using the \code{install_bitbucket()} interface
#'   and can be set other values to enable installation of Bitbucket Server
#'   packages. However, the \code{install_bitbucket_server()} provides a more
#'   convenient default value sourced from the \code{BITBUCKET_HOST} environment
#'   variable by default.
#' @param credentials An argument passed to the \code{credentials} argument to
#'   \code{\link[git2r]{fetch}}. See \code{\link[git2r]{cred_user_pass}} or
#'   \code{\link[git2r]{cred_ssh_key}}. This defaults to: using the use the SSH
#'   key via \code{\link[git2r]{cred_ssh_key}} when using the
#'   \code{install_bitbucket()} interface; and supplying to
#'   \code{\link[git2r]{cred_user_pass}} the username and password values stored
#'   in the \code{USERNAME} and \code{BITBUCKET_PASS} environment variables when
#'   using \code{install_bitbucket_server()} interface.
#' @param build_args A character string used to control the package build,
#'   passed to \code{R CMD build}.
#' @param build_vignettes A logical specifying whether to build package
#'   vignettes, passed to \code{R CMD build}. Can be slow. Note: The default is
#'   \code{TRUE}, unlike in \code{devtools::install_github()}.
#' @param uninstall A logical specifying whether to uninstall previous
#'   installations using \code{\link[utils]{remove.packages}} before attempting
#'   install. This is useful for installing an older version of a package than
#'   the one currently installed.
#' @param verbose A logical specifying whether to print details of package
#'   building and installation.
#' @param repos A character vector specifying one or more URLs for CRAN-like
#'   repositories from which package dependencies might be installed. By
#'   default, value is taken from \code{options("repos")} or set to the CRAN
#'   cloud repository.
#' @param type A character vector passed to the \code{type} argument of
#'   \code{\link[utils]{install.packages}}.
#' @param dependencies A character vector specifying which dependencies to
#'   install (of \dQuote{Depends}, \dQuote{Imports}, \dQuote{Suggests}, etc.).
#' @param \dots Additional arguments to control installation of package, passed
#'   to \code{\link[utils]{install.packages}}.
#' @return A named character vector of R package versions installed.
#' @author Imanuel Costigan
#' @examples
#' \dontrun{
#' tmp <- file.path(tempdir(), "tmplib")
#' dir.create(tmp)
#' # install a single package. Multiple package install is also supported.
#' install_bitbucket("imanuelcostigan/devtest", lib = tmp)
#'
#' # Install from Bitbucket Server
#' install_bitbucket_server("projectname/reponame")
#'
#' # cleanup
#' unlink(tmp, recursive = TRUE)
#' }
#' @importFrom git2r init clone config commits remote_ls
#' @importFrom utils install.packages installed.packages remove.packages
#'   packageVersion compareVersion capture.output
#' @importFrom tools write_PACKAGES
#' @aliases install_bitbucket_server
#' @export
install_bitbucket <- function(repo, host = "bitbucket.org", credentials = NULL,
    build_args = NULL, build_vignettes = TRUE, uninstall = FALSE,
    verbose = FALSE,
    repos = NULL,
    type = "source",
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
    repos <- make_repos(repos = repos)

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
        check_pkg_version(p, vers = vers, lib = if ("lib" %in% names(opts)) c(.libPaths(), opts$lib) else .libPaths())
        
        # install Suggests dependencies, non-recursively
        if ("Suggests" %in% colnames(description)) {
            suggests <- clean_suggests(description)
            if (isTRUE(build_vignettes) && !is.null(suggests) && suggests != "") {
                preinstall_suggests(suggests = suggests, p = p, type = type, repos = repos, 
                                    dependencies = dependencies, verbose = verbose, ...)
            }
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
    do_install(to_install, type = type, repos = repos, dependencies = dependencies, opts = opts, verbose = verbose, ...)
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

#' @rdname install_bitbucket
#' @export
install_bitbucket_server <- function(repo,
  host = Sys.getenv("BITBUCKET_HOST"), credentials = bitbucket_cred(),
  build_args = NULL, build_vignettes = TRUE, uninstall = FALSE,
  verbose = FALSE, repos = NULL,
  type = if (.Platform[["pkgType"]] %in% "win.binary")
    "both"
  else
    "source",
  dependencies = c("Depends", "Imports"), ...) {

  install_bitbucket(repo, host, credentials, build_args, build_vignettes,
      uninstall, verbose, repos, type, dependencies, ...)

}

bitbucket_cred <- function(user_var = "USERNAME", pass_var = "BITBUCKET_PASS") {
  git2r::cred_user_pass(username = Sys.getenv(user_var),
      password = Sys.getenv(pass_var))
}

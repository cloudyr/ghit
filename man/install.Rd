\name{install_github}
\alias{install_github}
\title{Install R package from GitHub}
\usage{
install_github(repo, host = "github.com", credentials = NULL, 
               build_args = NULL, build_vignettes = TRUE, 
               uninstall = FALSE, verbose = FALSE, 
               repos = getOption("repos", c(CRAN = "https://cloud.r-project.org")),
               dependencies = c("Depends", "Imports", "Suggests"), ...)
}
\arguments{
    \item{repo}{A character vector naming one or more GitHub repository containing an R package to install (e.g., \dQuote{leeper/ghit}), or optionally a branch (\dQuote{leeper/ghit[dev]}), a reference (\dQuote{leeper/ghit@b200fb1bd}), tag (\dQuote{leeper/ghit@v0.2}), or subdirectory (\dQuote{leeper/ghit/R}). These arguments can be placed in any order and in any combination (e.g., \dQuote{leeper/ghit[master]@abc123/R}).}
    \item{host}{A character string naming a host, to enable installation of enterprise-hosted GitHub packages.}
    \item{credentials}{An argument passed to the \code{credentials} argument to \code{\link[git2r]{clone}}. See \code{\link[git2r]{cred_user_pass}} or \code{\link[git2r]{cred_ssh_key}}.}
    \item{build_args}{A character string used to control the package build, passed to \code{R CMD build}.}
    \item{build_vignettes}{A logical specifying whether to build package vignettes, passed to \code{R CMD build}. Can be slow. Note: The default is \code{TRUE}, unlike in \code{devtools::install_github()}.}
    \item{uninstall}{A logical specifying whether to uninstall previous installations using \code{\link[utils]{remove.packages}} before attempting install. This is useful for installing an older version of a package than the one currently installed.}
    \item{verbose}{A logical specifying whether to print details of package building and installation.}
    \item{repos}{A character vector specifying one or more URLs for CRAN-like repositories from which package dependencies might be installed. By default, value is taken from \code{options("repos")} or set to the CRAN cloud repository.}
    \item{dependencies}{A character vector specifying which dependencies to install (of \dQuote{Depends}, \dQuote{Imports}, \dQuote{Suggests}, etc.).}
    \item{...}{Additional arguments to control installation of package, passed to \code{\link[utils]{install.packages}}.}
}
\description{\code{install_github} allows users to install R packages hosted on GitHub without needing to install or load the heavy dependencies required by devtools. ghit provides a drop-in replacement that provides (almost) identical functionality to \code{devtools::install_github()}.}
\value{A named character vector of R package versions installed.}
\author{Thomas J. Leeper}
\examples{
\dontrun{
tmp <- file.path(tempdir(), "tmplib")
dir.create(tmp)
# install a single package
install_github("leeper/ghit", lib = tmp)

# install multiple packages
install_github(c("leeper/ghit", "leeper/crandatapkgs"), lib = tmp)

# cleanup
unlink(tmp, recursive = TRUE)
}
}

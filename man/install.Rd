\name{install_github}
\alias{install_github}
\title{Install R package from GitHub}
\usage{
install_github(repo, branch = NULL, host = "github.com", 
               credentials = NULL, build_args = NULL, 
               verbose = FALSE, dependencies = c("Depends", "Imports"), ...)
}
\arguments{
    \item{repo}{A character vector naming one or more GitHub repository containing, at its top level, an R package to install (e.g., \dQuote{leeper/ghit}), or optionally a reference (\dQuote{leeper/ghit@b200fb1bd}), tag (\dQuote{leeper/ghit@v0.2}), or pull request (\dQuote{leeper/ghit/#1}).}
    \item{branch}{A character string naming a branch. The default, \code{NULL}, is the master brannch.}
    \item{host}{A character string naming a host, to enable installation of enterprise-hosted GitHub packages.}
    \item{credentials}{An argument passed to the \code{credentials} argument to \code{\link[git2r]{clone}}.}
    \item{build_args}{A character string used to control the package build, passed to \code{R CMD build}.}
    \item{verbose}{A logical specifying whether to print details of package building and installation.}
    \item{dependencies}{A character vector specifying which dependencies to install (of \dQuote{Depends}, \dQuote{Imports}, \dQuote{Suggests}, etc.).}
    \item{...}{Additional arguments to control installation of package, passed to \code{\link[utils]{install.packages}}.}
}
\description{\code{\link{install_github}} allows users to install R packages hosted on GitHub without needing to install or load the heavy dependencies required by devtools. ghit provides a drop-in replacement that provides (almost) identical functionality to \code{devtools::install_github()}, but is also vectorized to allow easy installing of multiple packages.}
\value{A named list of R package versions installed.}
\author{Thomas J. Leeper, with some code from Josh O'Brien (\href{http://stackoverflow.com/questions/30223957/elegantly-extract-r-package-dependencies-of-a-package-not-listed-on-cran}{on StackOverflow}).}
\examples{
r <- options("repos")
options("repos" = "http://cran.rstudio.com")

tmp <- "./tmplib"
dir.create(tmp)
# install a single package
ghit::install_github("leeper/ghit", lib = tmp)

# install multiple packages
ghit::install_github(c("eddelbuettel/drat", "leeper/ghit"), lib = tmp)

# cleanup
unlink(tmp, recursive = TRUE)
options("repos" = r)
}

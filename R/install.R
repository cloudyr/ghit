install_one <- 
function(repo, branch = NULL, host = "github.com", 
         credentials = NULL, build_args = NULL, verbose = FALSE, ...) {

  wd <- getwd()
  on.exit(setwd(wd))
  setwd(tempdir())
  
  pkgname <- strsplit(repo, "/")[[1]][2]
  d <- tempfile(pattern = pkgname)
  git2r::clone(url = paste0("https://", host, "/", repo, ".git"), 
               local_path = d, 
               branch = branch, 
               credentials = credentials,
               progress = verbose)
  
  description <- read.dcf(file.path(d, "DESCRIPTION"))
  # handle dependencies here
  jj <- intersect(c("Depends", "Imports", "Suggests"), colnames(description))
  val <- unlist(strsplit(description[, jj], ","), use.names = FALSE)
  val <- gsub("\\s.*", "", trimws(val))
  deps <- val[val != "R"]
  need <- deps[!deps %in% installed.packages()[,"Package"]]
  if (length(need)) {
    utils::install.packages(need, verbose = verbose, ...)
  }
  
  
  # check for compiled code (modified from devtools::check_build_tools())
  if (file.exists(file.path(d, "src"))) {
    # do a check
  }
  
  # build package
  success <- system(paste0(Sys.which("R"), " CMD build ", d, " ", build_args))
  if (success != 0) {
    stop("Package build failed!")
  }
  tarball <- paste0(pkgname, "_", description[1,"Version"], ".tar.gz")
  
  repodir <- file.path(tempdir(), "drat")
  on.exit(unlink(repodir))
  if (!dir.exists(repodir)) {
    drat::initRepo(name = "drat", basepath = tempdir())
  }
  drat::insertPackage(tarball, repodir = repodir)
  utils::install.packages(pkgname, type = "source", 
                          repos = c("TemporaryRepo" = paste0("file:", repodir), options("repos")[[1]]),
                          verbose = verbose,
                          ...)
  return(utils::packageVersion(pkgname))
}

install_github <- 
function(repo, 
         branch = NULL, 
         host = "github.com", 
         credentials = NULL, 
         build_args = NULL, 
         verbose = FALSE, 
         ...) {
  stats::setNames(lapply(repo, install_one, 
                         branch = branch, 
                         host = host,
                         credentials = credentials,
                         build_args = build_args,
                         verbose = verbose,
                         ...), 
                  sapply(strsplit(repo, "/"), `[`, 2))
}

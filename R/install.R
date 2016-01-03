install_one <- 
function(repo, branch = NULL, host = "github.com", 
         credentials = NULL, build_args = NULL, verbose = FALSE, 
         dependencies = c("Depends", "Imports"), ...) {

    wd <- getwd()
    on.exit(setwd(wd))
    setwd(tempdir())
    
    # identify refs, subdirectories, and pull requests
    reponame <- strsplit(repo, "/")[[1]]
    if (!is.na(reponame[3])) {
        pkgname <- reponame[2]
        ref <- NA_character_
        pull <- NA_character_
        subdir <- paste0(reponame[3:length(reponame)], collapse = "/")
    } else if (grepl("@", reponame[2])) {
        pkgname <- strsplit(reponame[2], "@")[[1]][1]
        ref <- strsplit(reponame[2], "@")[[1]][2]
        pull <- NA_character_
        subdir <- NA_character_
    } else if (grepl("#", reponame[2])) {
        pkgname <- strsplit(reponame[2], "#")[[1]][1]
        ref <- NA_character_
        pull <- strsplit(reponame[2], "#")[[1]][2]
        subdir <- NA_character_
    } else {
        pkgname <- reponame[2]
        ref <- NA_character_
        pull <- NA_character_
        subdir <- NA_character_
    }
    
    d <- tempfile(pattern = pkgname)
    on.exit(unlink(d, recursive = TRUE), add = TRUE)
    if (is.na(pull)) {
        git2r::clone(url = paste0("https://", host, "/", 
                                  paste(reponame[1], pkgname, sep = "/"), 
                                  ".git"), 
                     local_path = d, 
                     branch = branch, 
                     credentials = credentials,
                     progress = verbose)
        # checkout commits, tags, or directories
        gitrepo <- git2r::repository(d)
        if (!is.na(ref)) {
            # commits
            a <- grep(substring(ref, 2, nchar(ref)), 
                      sapply(git2r::commits(gitrepo), methods::slot, "sha"), fixed = TRUE)
            if (length(a)) {
                git2r::checkout(git2r::commits(gitrepo)[[a[1]]], force = TRUE)
            } else {
                # tags
                b <- grep(ref, names(git2r::tags(gitrepo)), fixed = TRUE)
                if (length(b)) {
                    git2r::checkout(git2r::tags(gitrepo)[[b[1]]], force = TRUE)
                } else {
                    stop("Reference (sha or git tag) not found!")
                }
            }
        } else if (!is.na(subdir)) {
            # subdirectory
            d <- file.path(d, subdir)
        }
    } else {
        # handle pull request
        
    }
    
    description <- read.dcf(file.path(d, "DESCRIPTION"))
    pkgname <- unname(description[, "Package"])
    
    # handle dependencies here
    if (length(dependencies)) {
        jj <- intersect(dependencies, colnames(description))
        if (length(jj)) {
            val <- unlist(strsplit(description[, jj], ","), use.names = FALSE)
            val <- gsub("\\s.*", "", trimws(val))
            deps <- val[val != "R"]
            need <- deps[!deps %in% installed.packages()[,"Package"]]
            if (length(need)) {
                utils::install.packages(need, verbose = verbose, quiet = !verbose, ...)
            }
        }
    }
    
    # check for compiled code
    if (file.exists(file.path(d, "src"))) {
        # do a check for build tools?
        # could modify from devtools::check_build_tools()
    }
    
    # build package
    success <- system2("R", paste0("CMD build ", d, " ", build_args), stdout = FALSE)
    if (success != 0) {
        success <- system2(file.path(R.home("bin"), "R.exe"), paste0("CMD build ", d, " ", build_args), stdout = FALSE)
        if (success != 0) {
            stop("Package build failed!")
        }
    }
    tarball <- paste0(pkgname, "_", description[1,"Version"], ".tar.gz")
    on.exit(unlink(tarball), add = TRUE)
    
    repodir <- file.path(tempdir(), "drat")
    on.exit(unlink(repodir), add = TRUE)
    if (!dir.exists(repodir)) {
        drat::initRepo(name = "drat", basepath = tempdir())
    }
    drat::insertPackage(tarball, repodir = repodir)
    utils::install.packages(pkgname, type = "source", 
                            repos = c("TemporaryRepo" = paste0("file:", repodir), options("repos")[[1]]),
                            verbose = verbose,
                            quiet = !verbose,
                            ...)
    return(as.character(utils::packageVersion(pkgname)))
}

install_github <- 
function(repo, 
         branch = NULL, 
         host = "github.com", 
         credentials = NULL, 
         build_args = NULL, #" --no-save --no-environ --no-restore --silent", 
         verbose = FALSE, 
         dependencies = c("Depends", "Imports"),
         ...) {
    sapply(repo,
           install_one,
           branch = branch, 
           host = host,
           credentials = credentials,
           build_args = build_args,
           verbose = verbose,
           ...)
}

install_one <- 
function(repo, branch = NULL, host = "github.com", 
         credentials = NULL, build_args = NULL, verbose = FALSE, 
         dependencies = c("Depends", "Imports", "Suggests"), ...) {

    wd <- getwd()
    on.exit(setwd(wd))
    setwd(tempdir())
    
    #basic_args <- " --no-save --no-environ --no-restore --silent"
    basic_args <- " "
    
    reponame <- strsplit(repo, "/")[[1]]
    # branch (not specified by branch argument)
    if (grepl("[", reponame[2], fixed = TRUE)) {
        a <- strsplit(reponame[2], "[", fixed = TRUE)[[1]]
        pkgname <- a[1]
        b <- strsplit(a[2], "]", fixed = TRUE)[[1]]
        branch <- b[1]
        reponame <- c(reponame[1], paste0(a[1], b[2]))
        rm(a)
        rm(b)
    }
    # identify refs, subdirectories, and pull requests
    if (!is.na(reponame[3])) {
        # sub-directory
        pkgname <- reponame[2]
        ref <- NA_character_
        pull <- NA_character_
        subdir <- paste0(reponame[3:length(reponame)], collapse = "/")
    } else if (grepl("@", reponame[2])) {
        # reference/commit
        pkgname <- strsplit(reponame[2], "@")[[1]][1]
        ref <- strsplit(reponame[2], "@")[[1]][2]
        pull <- NA_character_
        subdir <- NA_character_
    } else if (grepl("#", reponame[2])) {
        # pull request
        pkgname <- strsplit(reponame[2], "#")[[1]][1]
        ref <- NA_character_
        pull <- strsplit(reponame[2], "#")[[1]][2]
        subdir <- NA_character_
    } else {
        # top-level package
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
            if (length(deps)) {
                need <- deps[!deps %in% installed.packages()[,"Package"]]
                if (length(need)) {
                    utils::install.packages(need, verbose = verbose, INSTALL_opts = basic_args, quiet = !verbose, ...)
                }
            }
        }
    }
    
    # check for compiled code
    if (file.exists(file.path(d, "src"))) {
        # do a check for build tools?
        # could modify from devtools::check_build_tools()
    }
    
    # build package
    arg <- paste0("CMD build ", d, " ", build_args, basic_args)
    success <- system2("R", arg, stdout = FALSE)
    if (success != 0) {
        success <- system2(file.path(R.home("bin"), "R.exe"), arg, stdout = FALSE)
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
                            INSTALL_opts = basic_args, 
                            quiet = !verbose,
                            ...)
    return(as.character(utils::packageVersion(pkgname)))
}

install_github <- 
function(repo, 
         branch = NULL, 
         host = "github.com", 
         credentials = NULL, 
         build_args = NULL, 
         verbose = FALSE, 
         dependencies = c("Depends", "Imports", "Suggests"),
         ...) {
    vapply(repo,
           install_one,
           FUN.VALUE = character(length(repo)),
           branch = branch, 
           host = host,
           credentials = credentials,
           build_args = build_args,
           verbose = verbose,
           ...)
}

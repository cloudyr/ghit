checkout_pkg <- function(p, host = "github.com", credentials = NULL, verbose = FALSE) {
    if (verbose) {
        message(sprintf("Creating local git repository for %s...", p$pkgname))
    }
    d <- tempfile(pattern = p$pkgname)
    dir.create(d)
    gitrepo <- git2r::init(d)
    git2r::config(gitrepo, user.name = "ghit", user.email = "example@example.com")
    git2r::remote_add(gitrepo, "github",
                      paste0("https://", host, "/", paste(p$user, p$pkgname, sep = "/"), ".git"))
    if (verbose) {
        message(sprintf("Checking out package %s to local git repository...", p$pkgname))
        git2r::fetch(gitrepo, name = "github", credentials = credentials)
    } else {
        utils::capture.output(git2r::fetch(gitrepo, name = "github", credentials = credentials))
    }
    
    if (is.na(p$pull)) {
        if (!is.na(p$branch)) {
            if (verbose) {
                message(sprintf("Checking out branch %s for packge %s...", p$branch, p$pkgname))
            }
            if (!length(grep(paste0("github/", p$branch), names(git2r::branches(gitrepo))))) {
                stop("Branch not found!")
            }
            git2r::checkout(gitrepo, branch = p$branch, create = TRUE, force = TRUE)
        } else {
            git2r::checkout(gitrepo, branch = "master", create = TRUE, force = TRUE)
        }
        
        # checkout commits, tags, or directories
        if (!is.na(p$ref)) {
            # commits
            a <- grep(substring(p$ref, 2, nchar(p$ref)), 
                      sapply(git2r::commits(gitrepo), methods::slot, "sha"), fixed = TRUE)
            if (length(a)) {
                if (verbose) {
                    message(sprintf("Checking out commit %s for packge %s...", p$ref, p$pkgname))
                }
                git2r::checkout(git2r::commits(gitrepo)[[a[1]]], force = TRUE)
            } else {
                # tags
                b <- grep(p$ref, names(git2r::tags(gitrepo)), fixed = TRUE)
                if (length(b)) {
                    if (verbose) {
                        message(sprintf("Checking out tag %s for packge %s...", p$ref, p$pkgname))
                    }
                    git2r::checkout(git2r::tags(gitrepo)[[b[1]]], force = TRUE)
                } else {
                    stop("Reference (sha or git tag) not found!")
                }
            }
        } else if (!is.na(p$subdir)) {
            # subdirectory
            d <- file.path(d, p$subdir)
            if (verbose) {
                message(sprintf("Checking out package subdirectory for %s...", p$pkgname))
            }
        }
    } else {
        # handle pull request
        git2r::fetch(gitrepo, name = "github", credentials = credentials)
        paste0("refs/pull/", p$pull)
        if (verbose) {
            message(sprintf("Checking out pull request %s for %s...", p$pull, p$pkgname))
        }
        stop("Pull requests are not  yetimplemented!")
        #git2r::checkout(gitrepo, branch = "GHITBRANCH", create = TRUE, force = TRUE)
    }
    return(d)
}

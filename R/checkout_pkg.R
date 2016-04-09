checkout_pkg <- function(p, host = "github.com", credentials = NULL, verbose = FALSE) {
    ghitmsg(verbose, message(sprintf("Creating local git repository for %s...", p$pkgname)) )
    d <- tempfile(pattern = p$pkgname)
    dir.create(d)
    gitrepo <- git2r::init(d)
    git2r::config(gitrepo, user.name = "ghit", user.email = "example@example.com")
    git2r::remote_add(gitrepo, "github",
                      paste0("https://", host, "/", paste(p$user, p$pkgname, sep = "/"), ".git"))
    
    if (is.na(p$pull)) {
        if (verbose) {
            ghitmsg(verbose, message(sprintf("Checking out package %s to local git repository...", p$pkgname)))
            git2r::fetch(gitrepo, name = "github", credentials = credentials)
        } else {
            utils::capture.output(git2r::fetch(gitrepo, name = "github", credentials = credentials))
        }    
        if (!is.na(p$branch)) {
            ghitmsg(verbose, message(sprintf("Checking out branch %s for packge %s...", p$branch, p$pkgname)))
            ghitmsg(!length(grep(paste0("github/", p$branch), names(git2r::branches(gitrepo)))), 
                    stop("Branch not found!"))
            git2r::checkout(gitrepo, branch = p$branch, create = TRUE, force = TRUE)
        } else {
            git2r::checkout(gitrepo, branch = "master", create = TRUE, force = TRUE)
        }
    } else {
        # handle pull request
        ghitmsg(packageVersion("git2r") < "0.13.1.9000", 
                stop("Checkout of pull requests requires git2r version >= 0.13.1.9000") )
        ghitmsg(verbose,
                message(sprintf("Finding pull request #%s for package %s...", p$pull, p$pkgname)) )
        rem <- git2r::remote_ls("github", gitrepo)
        w <- which(grepl(paste0("refs/pull/",p$pull,"/head"), names(rem), fixed = TRUE))
        ghitmsg(!length(w), stop(sprintf("Pull request #%s not found for %s!", p$pull, p$pkgname)) )
        if (verbose) {
            message(sprintf("Extracting pull request #%s for %s...", p$pull, p$pkgname))
            git2r::fetch(gitrepo, name = "github", credentials = credentials,
                         refspec = paste0("pull/",p$pull,"/head:refs/heads/PULLREQUEST", p$pull))
        } else {
            capture.output(git2r::fetch(gitrepo, name = "github", credentials = credentials,
                           refspec = paste0("pull/",p$pull,"/head:refs/heads/PULLREQUEST", p$pull)))
        }    
        ghitmsg(verbose, message(sprintf("Checking out pull request %s for %s...", p$pull, p$pkgname)) )
        git2r::checkout(gitrepo, branch = paste0("PULLREQUEST", p$pull), force = TRUE)
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
    p$sha1 <- commits(gitrepo)[[1]]@sha
    try(add_metadata(d, p, verbose = verbose), silent = TRUE)
    return(d)
}

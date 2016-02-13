parse_reponame <- function(repo) {
    reponame <- strsplit(repo, "/")[[1]]
    
    # branch
    if (grepl("[", reponame[2], fixed = TRUE)) {
        a <- strsplit(reponame[2], "[", fixed = TRUE)[[1]]
        pkgname <- a[1]
        b <- strsplit(a[2], "]", fixed = TRUE)[[1]]
        branch <- b[1]
        reponame <- c(reponame[1], paste0(a[1], if (!is.na(b[2])) b[2] else NULL))
        rm(a)
        rm(b)
    } else {
        branch <- NA_character_
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
        pkgname <- strsplit(reponame[2], "@+")[[1]][1]
        ref <- strsplit(reponame[2], "@+")[[1]][2]
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
    
    return(list(user = reponame[1],
                pkgname = pkgname,
                branch = branch,
                ref = ref,
                pull = pull,
                subdir = subdir))
}

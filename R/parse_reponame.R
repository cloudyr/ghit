parse_reponame <- function(repo) {
    
    # user/repository
    regex_repo <- "^[[:alnum:]._-]+/[[:alnum:]._-]+"
    reponame <- regmatches(repo, regexpr(regex_repo, repo))
    
    spl <- strsplit(reponame, "/")[[1]]
    username <- spl[1]
    pkgname <- spl[2]
    
    # branch
    regex_branch <- "(?<=\\[)[[:alnum:]._-]+(?=\\])"
    if (grepl(regex_branch, repo, perl = TRUE)) {
        branch <- regmatches(repo, regexpr(regex_branch, repo, perl = TRUE))
    } else {
        branch <- NA_character_
    }

    # setup return values in case top-level, master branch
    ref <- NA_character_
    pull <- NA_character_
    subdir <- NA_character_
    
    # reference/commit
    if (grepl("@", repo)) {
        regex_ref <- "@[[:alnum:]._-]+"
        m <- regmatches(repo, regexpr(regex_ref, repo))
        ref <- substring(m, 2, nchar(m))
        rm(m)
    }
    
    # pull request
    if (grepl("#", repo)) {
        regex_pull <- "#[[:alnum:]._-]+"
        m <- regmatches(repo, regexpr(regex_pull, repo))
        pull <- substring(m, 2, nchar(m))
    }
    
    # sub-directory
    s <- substring(repo, nchar(reponame) + 1, nchar(repo))
    if (grepl("/", s)) {
        regex_subdir <- "/[[:alnum:]/._-]+"
        subdir <- regmatches(s, regexpr(regex_subdir, s))
        subdir <- substring(subdir, 2, nchar(subdir))
    }
    
    # return
    return(list(user = username,
                pkgname = pkgname,
                branch = branch,
                ref = ref,
                pull = pull,
                subdir = subdir))
}

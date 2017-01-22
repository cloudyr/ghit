make_repos <- function(repos) {
    repodir <- file.path(tempdir(), "ghitdrat")
    if (is.null(repos)) {
        tmp_repos <- getOption("repos")
        if ("@CRAN@"  %in% tmp_repos) {
            tmp_repos["CRAN"] <- "https://cloud.r-project.org"
        }
        repos <- tmp_repos
        rm(tmp_repos)
    }
    c("TemporaryRepo" = paste0("file:///", repodir), repos)
}

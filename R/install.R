install_github <- 
function(repo, host = "github.com", credentials = NULL, 
         build_args = NULL, build_vignettes = TRUE, verbose = FALSE, 
         repos = getOption("repos", c(CRAN = "http://cloud.r-project.org")),
         dependencies = c("Depends", "Imports", "Suggests"), ...) {

    wd <- getwd()
    on.exit(setwd(wd))
    setwd(tempdir())
    
    # setup build args
    #basic_args <- " --no-save --no-environ --no-restore --silent"
    basic_args <- " "
    if (is.null(build_args)) {
        build_args <- ""
    }
    if (!build_vignettes) {
        if (!grepl("build-vignettes", build_args, fixed = TRUE)) {
            build_args <- paste0(build_args, " --no-build-vignettes")
        }
    }
    
    # setup drat
    repodir <- file.path(tempdir(), "ghitdrat")
    suppressWarnings(dir.create(repodir))
    suppressWarnings(dir.create(file.path(repodir, "src")))
    suppressWarnings(dir.create(file.path(repodir, "src", "contrib")))
    on.exit(unlink(repodir), add = TRUE)
    
    # download and build packages
    to_install <- sapply(unique(repo), function(x) {
        # parse reponame
        if (verbose) {
            message(sprintf("Parsing reponame for '%s'...", x))
        }
        p <- parse_reponame(repo = x)
        d <- checkout_pkg(p, host = host, credentials = credentials, verbose = verbose)
        on.exit(unlink(d), add = TRUE)
        
        description <- read.dcf(file.path(d, "DESCRIPTION"))
        p$pkgname <- unname(description[1, "Package"])
        
        # check for compiled code
        if (file.exists(file.path(d, "src"))) {
            # do a check for build tools?
            # could modify from devtools::check_build_tools()
        }
        
        # build package
        build_and_insert(p$pkgname, d, unname(description[1,"Version"]), build_args, basic_args, verbose = verbose)
        return(p$pkgname)
    })
    
    if (("ghit" %in% to_install) && ("ghit" %in% loadedNamespaces())) {
        on.exit(unloadNamespace("ghit"), add = TRUE)
        on.exit(requireNamespace("ghit"), add = TRUE)
    }
    
    # install packages from drat and dependencies from CRAN
    if (verbose) {
        message(sprintf("Installing packages%s...", 
                        if (length(dependencies)) paste0(" and ", paste(dependencies, collapse = ", ")) else ""))
    }
    contrib <- file.path(c("TemporaryRepo" = paste0("file:", repodir), repos), "src", "contrib")
    utils::install.packages(to_install, type = "source", 
                            contriburl = contrib,
                            dependencies = dependencies,
                            verbose = verbose,
                            INSTALL_opts = basic_args, 
                            quiet = !verbose,
                            ...)
    
    v_out <- sapply(to_install, function(x) as.character(utils::packageVersion(x)))
    return(v_out)
}

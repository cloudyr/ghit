# ghit: Lightweight GitHub Package Installer

**ghit** provides a lightweight alternative to `devtools::install_github()` that uses git2r and the native R package management functionality to install R packages hosted on GitHub. At present, `devtools::install_github()` provides the most convenient way to install development versions of R packages, but devtools has 16 direct package dependencies and is therefore a quite heavy duty package to load simply to install packages.

ghit is therefore a simpler alternative to perform the single task of installing GitHub packages without the rest of devtools. It achieves this by using git2r to pull GitHub packages (including those requiring authentication), and relying on native R tools for building packages, storing those packages in a local and disposable CRAN-like repository, and installing them (and their dependencies) with `install.packages()`. From v0.2.15, an `install_bitbucket()` installer is also provided.

## Package Functionality

Like `devtools::install_github()`, `ghit::install_github()` is a vectorized package installer that is extremely flexible:

```R
library("ghit")
tmp <- file.path(tempdir(), "tmplib")
dir.create(tmp)
on.exit(unlink(tmp))

# single package
install_github("hadley/devtools", lib = tmp)

# multiple packages
install_github(c("hadley/devtools", "cloudyr/travisci"), lib = tmp)

# package in subdirectory
install_github("pablobarbera/twitter_ideology/pkg/tweetscores", lib = tmp)

# package in misnamed repository
install_github("klutometis/roxygen", lib = tmp)

# package at a given commit
install_github("leeper/rio@a8d0fca27", lib = tmp)

# package from a pull request
install_github("cloudyr/ghit#13", lib = tmp)

# package from a branch
install_github("kbenoit/quanteda[dev]", lib = tmp)
```

Note that branch names, commits, and subdirectories can be placed in essentially any order as long as the proper notation is followed.


## Profiling ##

ghit is similarly efficient to  `devtools::install_github()`, but is much less verbose by default:

```R
> system.time(ghit::install_github("cloudyr/ghit"))
   user  system elapsed 
   0.92    0.29    4.64

> system.time(devtools::install_github("cloudyr/ghit"))
Downloading GitHub repo cloudyr/ghit@master
Installing ghit
"C:/PROGRA~1/R/R-32~1.3/bin/x64/R" --no-site-file --no-environ --no-save --no-restore CMD INSTALL  \
  "C:/Users/Thomas/AppData/Local/Temp/RtmpGGraeG/devtools1b6459fa28a1/cloudyr-ghit-45ac056" --library="C:/Program Files/R/R-3.2.3/library"  \
  --install-tests 

* installing *source* package 'ghit' ...
** R
** inst
** tests
** preparing package for lazy loading
** help
*** installing help indices
** building package indices
** testing if installed package can be loaded
*** arch - i386
*** arch - x64
* DONE (ghit)
   user  system elapsed 
   1.16    0.12    4.36 
```

## Package Installation

[![CRAN Version](https://www.r-pkg.org/badges/version/ghit)](https://cran.r-project.org/package=ghit)
![Downloads](https://cranlogs.r-pkg.org/badges/ghit)
[![Travis-CI Build Status](https://travis-ci.org/cloudyr/ghit.png?branch=master)](https://travis-ci.org/cloudyr/ghit)
[![Appveyor Build status](https://ci.appveyor.com/api/projects/status/0nr5r6fycm8jcxm0?svg=true)](https://ci.appveyor.com/project/cloudyr/ghit)
[![codecov.io](https://codecov.io/github/cloudyr/ghit/coverage.svg?branch=master)](https://codecov.io/github/cloudyr/ghit?branch=master)

The package is available on [CRAN](https://cran.r-project.org/package=ghit) and can be installed directly in R using:

```R
install.packages("ghit")
```

The latest development version on GitHub can be installed using itself:

```R
ghit::install_github("cloudyr/ghit")
```


# ghit: Lightweight GitHub Package Installer #

**ghit** provides a lightweight alternative to `devtools::install_github()` that uses git2r and the native R package management functionality to install R packages hosted on GitHub. At present, `devtools::install_github()` provides the most convenient way to install development versions of R packages, but devtools has 16 direct package dependencies and is therefore a quite heavy duty package to load simply to install packages. ghit is therefore a simpler alternative to perform the single task of installing GitHub packages without the rest of devtools.

## Package Installation ##

The package is available on [CRAN](http://cran.r-project.org/package=ghit) and can be installed directly in R using:

```R
install.packages("ghit")
```

The latest development version on GitHub can be installed using itself:

```R
ghit::install_github("leeper/ghit")
```

Or, lacking that, using **devtools**:

```R
if(!require("devtools")){
    install.packages("devtools")
    library("devtools")
}
install_github("leeper/ghit")
```

[![CRAN Version](http://www.r-pkg.org/badges/version/ghit)](http://cran.r-project.org/package=ghit)
![Downloads](http://cranlogs.r-pkg.org/badges/ghit)
[![Travis-CI Build Status](https://travis-ci.org/leeper/ghit.png?branch=master)](https://travis-ci.org/leeper/ghit)
[![Appveyor Build status](https://ci.appveyor.com/api/projects/status/0nr5r6fycm8jcxm0?svg=true)](https://ci.appveyor.com/project/leeper/ghit)
[![codecov.io](http://codecov.io/github/leeper/ghit/coverage.svg?branch=master)](http://codecov.io/github/leeper/ghit?branch=master)

## Package Functionality ##

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

# package from a branch
install_github("kbenoit/quanteda[dev]", lib = tmp)
```


## Profiling ##

ghit is similarly efficient to  `devtools::install_github()`, but is much less verbose by default:

```R
> system.time(ghit::install_github("leeper/ghit"))
   user  system elapsed 
   0.92    0.29    4.64

> system.time(devtools::install_github("leeper/ghit"))
Downloading GitHub repo leeper/ghit@master
Installing ghit
"C:/PROGRA~1/R/R-32~1.3/bin/x64/R" --no-site-file --no-environ --no-save --no-restore CMD INSTALL  \
  "C:/Users/Thomas/AppData/Local/Temp/RtmpGGraeG/devtools1b6459fa28a1/leeper-ghit-45ac056" --library="C:/Program Files/R/R-3.2.3/library"  \
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


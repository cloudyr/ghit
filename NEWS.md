# CHANGES TO v0.2.15

* Refactored various parts of internal code so that `install_github()` and `install_bitbucket()` rely on same workhorse functionality and thus do not duplicate as much code.

# CHANGES TO v0.2.14

* Improved installation of packages in `install_github()` when `build_vignettes = TRUE` (the default) and "Suggests" packages are not already installed by introducing a pre-build run of `install.packages()` for the "Suggests" packages. "Suggests" are not installed recursively unless "Suggests" is listed explicitly in `dependencies`. (#24)

# CHANGES TO v0.2.13

* Added support for Bitbucket remote by way of `install_bitbucket()`. Note that installing from a pull request reference is unsupported by Bitbucket (#15, @imanuelcostigan).
* Implemented `install_bitbucket_server()` which provides a more convenient interface to using Bitbucket Server for some users (@imanuelcostigan)

# CHANGES TO v0.2.12

 * Removed hard-coded `type` argument in `install.packages()` to allow install of binary package dependencies on Windows or OS X. (#19)
 * Changed the way a default CRAN mirror was being set in cases where there was no default mirror specified. (#19)
 * Switched to roxygen2 documentation.

# CHANGES TO v0.2.10

 * Added more informative error when repo string is malformed. (#17, h/t Joseph Stachelek)

# CHANGES TO v0.2.9

 * Removed automatic installation of "Suggests" dependencies.

# CHANGES TO v0.2.8

 * Fixed a small bug in printing the package name when `verbose = TRUE`.

# CHANGES TO v0.2.7 

 * **ghit** is now hosted by the cloudyr project.

# CHANGES TO v0.2.6 

 * `install_github()` now installs devtools-style metadata into the DESCRIPTION file to faciliate compatibility with `devtools::session_info()` printing. (#16)
 * A new `uninstall` argument to `install_github()` allows users to remove old package installation(s) before installing the new package(s). (#14)
 * Some internal code cleanup has been performed to ease package maintenance.

# CHANGES TO v0.2.5 

 * CRAN release.

# CHANGES TO v0.2.3 

 * Added support for installing pull requests thanks to an update to git2r. This will only work with the development version of git2r (available from GitHub). (#10)
 * Packages with a loaded namespace are now unloaded before installation and reloaded thereafter.

# CHANGES TO v0.2.1 

 * Fixed a reference to `compareVersion()` that triggered a warning at the opposite times from expected.

# CHANGES TO v0.2.0 

 * CRAN Release.

# CHANGES TO v0.1.21 

 * Refactored `parse_reponame()` to allow arguments in basically any order.

# CHANGES TO v0.1.14 

 * Removed drat dependency, which fixed the persistent 'user.name' configuration error. (#11)

# CHANGES TO v0.1.11 

 * Refactor to vectorize `install_github()` so dependencies are installed collectively.

# CHANGES TO v0.1.9 

 * Set repo configuration in case global defaults are not set.

# CHANGES TO v0.1.8 

 * Add an argument `build_vignettes` to control vignette building. (#9)

# CHANGES TO v0.1.7 

 * Install suggested packages by default. (#9)

# CHANGES TO v0.1.5 

 * Exposed a `dependencies` argument to control installation of dependencies.
 * Experiment with references, tags, pull requests, and files.

# CHANGES TO v0.1.3 

 * Update path to R binary.

# CHANGES TO v0.1.2 

 * Fix config() error.

# CHANGES TO v0.1.1 

 * Initial release

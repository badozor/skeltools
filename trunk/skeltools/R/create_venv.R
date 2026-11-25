#' Create the Python environment of a project
#'
#' Equivalent, from R, of:
#' ```
#' cd path
#' path_for_python/python -m venv myenv
#' source myenv/bin/activate
#' pip install -r requirements.txt
#' ```
#' The environment is created inside the project. Packages are read from
#' `requirements.txt` (written by the Python layer of [create_project()]) or
#' given with `packages`. The `pip` of the environment is called directly,
#' so no activation is needed.
#'
#' When `ipykernel` is installed in the environment, the environment is also
#' registered as a Jupyter kernel with the same name
#' (`python -m ipykernel install --user --name myenv`), so that the line
#' `Jupyter: myenv` of the Quarto template points to it. The kernel is
#' registered for the current user, outside the project folder.
#'
#' @param path project folder.
#' @param python path of the Python interpreter used to create the
#'   environment. Defaults to `python3`, then `python`, found on the `PATH`.
#' @param name name of the environment folder.
#' @param packages packages to install. Defaults to the content of
#'   `requirements.txt` when it exists.
#' @param install installs the packages. With `FALSE`, only the empty
#'   environment is created.
#' @param kernel registers the environment as a Jupyter kernel when
#'   `ipykernel` is installed.
#' @param quiet suppresses messages and the output of `pip`.
#' @return the absolute path of the environment, invisibly.
#' @examples
#' \dontrun{
#' create_venv("~/projects/myproject")
#' create_venv("~/projects/myproject", python = "/usr/local/bin/python3.12")
#' }
#' @export
create_venv <- function(path = ".", python = NULL, name = "myenv",
                        packages = NULL, install = TRUE, kernel = TRUE,
                        quiet = FALSE) {
  if (!dir.exists(path)) {
    stop("Folder '", path, "' does not exist.", call. = FALSE)
  }
  path <- normalizePath(path)
  python <- find_python(python)
  env <- file.path(path, name)
  if (file.exists(env)) {
    stop("'", env, "' already exists. Nothing was changed.", call. = FALSE)
  }

  req <- file.path(path, "requirements.txt")
  use_req <- is.null(packages) && file.exists(req)
  if (is.null(packages) && !use_req) packages <- character()

  if (!quiet) message("Creating the Python environment: ", env)
  status <- system2(python, c("-m", "venv", shQuote(env)))
  if (status != 0) {
    stop("'", python, " -m venv' failed.", call. = FALSE)
  }

  if (isTRUE(install) && (use_req || length(packages) > 0)) {
    pip <- if (.Platform$OS.type == "windows") {
      file.path(env, "Scripts", "pip.exe")
    } else {
      file.path(env, "bin", "pip")
    }
    args <- if (use_req) c("install", "-r", shQuote(req)) else
      c("install", shQuote(packages))
    if (quiet) args <- c(args, "--quiet")
    if (!quiet) message("Installing the Python packages (this can take a while)")
    status <- system2(pip, args)
    if (status != 0) {
      stop("pip install failed. The environment was kept in '", env, "'.",
           call. = FALSE)
    }
  }
  py_env <- if (.Platform$OS.type == "windows") {
    file.path(env, "Scripts", "python.exe")
  } else {
    file.path(env, "bin", "python")
  }
  if (isTRUE(kernel) &&
      system2(py_env, c("-c", shQuote("import ipykernel")),
              stdout = FALSE, stderr = FALSE) == 0) {
    status <- system2(py_env, c("-m", "ipykernel", "install", "--user",
                                "--name", shQuote(name),
                                "--display-name", shQuote(name)),
                      stdout = if (quiet) FALSE else "",
                      stderr = if (quiet) FALSE else "")
    if (status != 0) {
      warning("Jupyter kernel '", name, "' could not be registered.",
              call. = FALSE)
    } else if (!quiet) {
      message("Jupyter kernel registered: ", name)
    }
  }
  if (!quiet) {
    act <- if (.Platform$OS.type == "windows") "Scripts\\activate" else
      "source bin/activate"
    message("Done. To activate it in a terminal: cd ", env, " && ", act)
  }
  invisible(env)
}

find_python <- function(python = NULL) {
  if (!is.null(python)) {
    if (!file.exists(python) && !nzchar(Sys.which(python))) {
      stop("Python interpreter not found: ", python, call. = FALSE)
    }
    return(python)
  }
  for (p in c("python3", "python")) {
    w <- Sys.which(p)
    if (nzchar(w)) return(unname(w))
  }
  stop("No Python interpreter found. Give its path with `python`.",
       call. = FALSE)
}

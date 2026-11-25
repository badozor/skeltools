#' Create a project from the skeltools templates
#'
#' Assembles the base template (`data/`, `archive/`, `tmp/`, `src/R/`)
#' and, optionally, the Python and C/C++ layers.
#'
#' Each layer is a folder `inst/templates/<layer>/` containing:
#' * `files/`: files copied into the project. `{{name}}` and `{{date}}`
#'   are replaced in the content, `__name__` in file names,
#'   and the `dot-` prefix becomes `.` (e.g. `dot-gitkeep` -> `.gitkeep`).
#' * `gitignore`: fragment appended to the project `.gitignore`.
#' * `structure.md`, `start.md`: fragments inserted into `README.md`.
#'
#' @param path project path. Must not exist or must be an empty folder.
#' @param python adds the Python layer (`src/python/`, `requirements.txt`).
#' @param cpp adds the C/C++ layer (`src/cpp/`, Rcpp example).
#' @param git initialises a git repository with an initial commit.
#' @param rproj creates the `<name>.Rproj` file.
#' @param open opens the project in RStudio at the end (if available).
#' @param quiet suppresses messages.
#' @return the absolute project path, invisibly.
#' @seealso [list_layers()]
#' @examples
#' p <- file.path(tempdir(), "myproject")
#' create_project(p, python = TRUE, cpp = TRUE)
#' list.files(p, recursive = TRUE, all.files = TRUE)
#' unlink(p, recursive = TRUE)
#' @export
create_project <- function(path, python = FALSE, cpp = FALSE, git = FALSE,
                           rproj = TRUE, open = FALSE, quiet = FALSE) {
  stopifnot(is.character(path), length(path) == 1L, nzchar(path))
  check_target(path)

  layers <- c("base", if (isTRUE(python)) "python", if (isTRUE(cpp)) "cpp")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path <- normalizePath(path)
  vars <- list(name = basename(path), date = format(Sys.Date(), "%Y-%m-%d"))

  for (layer in layers) copy_layer(layer, path, vars, rproj = rproj)

  write_gitignore(layers, path)
  write_readme(layers, path, vars)
  if (isTRUE(git)) init_git(path, quiet = quiet)

  if (!quiet) {
    message("Project '", vars$name, "' created in: ", path)
    message("Layers: ", paste(layers, collapse = ", "))
  }
  if (isTRUE(open) && requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::openProject(path, newSession = TRUE)
  }
  invisible(path)
}

#' List the available template layers
#'
#' @return a character vector of layer names (`"base"` first).
#' @examples
#' list_layers()
#' @export
list_layers <- function() {
  layers <- list.dirs(templates_dir(), recursive = FALSE, full.names = FALSE)
  c("base", setdiff(sort(layers), "base"))
}

#' Entry point for RStudio (File > New Project)
#'
#' Called by RStudio through `inst/rstudio/templates/project/skeltools.dcf`.
#' RStudio itself creates the folder and the `.Rproj` file.
#'
#' @param path path chosen in RStudio.
#' @param ... form parameters (`python`, `cpp`, `git`).
#' @keywords internal
#' @export
rstudio_project <- function(path, ...) {
  opts <- list(...)
  create_project(path,
                 python = isTRUE(opts$python),
                 cpp    = isTRUE(opts$cpp),
                 git    = isTRUE(opts$git),
                 rproj  = FALSE,
                 quiet  = TRUE)
}

# ---- internal functions ---------------------------------------------------

templates_dir <- function() {
  d <- system.file("templates", package = "skeltools")
  if (!nzchar(d)) stop("Templates folder not found.", call. = FALSE)
  d
}

check_target <- function(path) {
  if (!file.exists(path)) return(invisible(TRUE))
  if (!dir.exists(path)) {
    stop("'", path, "' exists and is not a folder.", call. = FALSE)
  }
  if (length(list.files(path, all.files = TRUE, no.. = TRUE)) > 0) {
    stop("'", path, "' exists and is not empty. Nothing was changed.",
         call. = FALSE)
  }
  invisible(TRUE)
}

render <- function(text, vars) {
  for (n in names(vars)) {
    text <- gsub(paste0("{{", n, "}}"), vars[[n]], text, fixed = TRUE)
  }
  text
}

read_fragment <- function(layer, file) {
  f <- file.path(templates_dir(), layer, file)
  if (file.exists(f)) readLines(f, warn = FALSE) else character()
}

target_name <- function(rel, vars) {
  parts <- strsplit(rel, "/", fixed = TRUE)[[1]]
  parts <- sub("^dot-", ".", parts)
  parts <- gsub("__name__", vars$name, parts, fixed = TRUE)
  paste(parts, collapse = "/")
}

copy_layer <- function(layer, path, vars, rproj = TRUE) {
  src <- file.path(templates_dir(), layer, "files")
  if (!dir.exists(src)) stop("Unknown layer: ", layer, call. = FALSE)
  rel <- list.files(src, recursive = TRUE, all.files = TRUE)
  if (!rproj) rel <- rel[!grepl("\\.Rproj$", rel)]
  for (r in rel) {
    dest <- file.path(path, target_name(r, vars))
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    if (file.exists(dest)) {
      stop("Conflict between layers: '", target_name(r, vars), "'.",
           call. = FALSE)
    }
    txt <- readLines(file.path(src, r), warn = FALSE)
    writeLines(render(txt, vars), dest, useBytes = TRUE)
  }
}

write_gitignore <- function(layers, path) {
  frag <- lapply(layers, read_fragment, file = "gitignore")
  writeLines(unlist(lapply(frag, c, "")), file.path(path, ".gitignore"))
}

write_readme <- function(layers, path, vars) {
  f <- file.path(path, "README.md")
  structure <- unlist(lapply(layers, read_fragment, file = "structure.md"))
  start <- lapply(layers, read_fragment, file = "start.md")
  start <- unlist(lapply(start[lengths(start) > 0], c, ""))
  txt <- readLines(f, warn = FALSE)
  out <- unlist(lapply(txt, function(l) {
    if (l == "{{structure}}") structure
    else if (l == "{{start}}") start
    else l
  }))
  writeLines(render(out, vars), f, useBytes = TRUE)
}

init_git <- function(path, quiet = FALSE) {
  if (!nzchar(Sys.which("git"))) {
    warning("git not found, repository not initialised.", call. = FALSE)
    return(invisible(FALSE))
  }
  run <- function(...) {
    system2("git", c("-C", shQuote(path), ...), stdout = FALSE, stderr = FALSE)
  }
  run("init", "-q")
  run("add", ".")
  ok <- run("commit", "-q", "-m",
            shQuote("Initial project structure")) == 0
  if (!ok && !quiet) {
    message("Note: initial commit not made (set git user.name / user.email).")
  }
  invisible(ok)
}

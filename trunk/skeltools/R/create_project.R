#' Creer un projet a partir des templates skeltools
#'
#' Assemble le template de base (`data/`, `archive/`, `tmp/`, `src/R/`)
#' et, en option, les couches Python et C/C++.
#'
#' Chaque couche est un dossier de `inst/templates/<couche>/` contenant :
#' * `files/` : fichiers copies dans le projet. `{{name}}` et `{{date}}`
#'   sont remplaces dans le contenu, `__name__` dans les noms de fichiers,
#'   et le prefixe `dot-` devient `.` (ex. `dot-gitkeep` -> `.gitkeep`).
#' * `gitignore` : fragment ajoute au `.gitignore` du projet.
#' * `structure.md`, `start.md` : fragments inseres dans le `README.md`.
#'
#' @param path chemin du projet. Doit ne pas exister ou etre un dossier vide.
#' @param python ajoute la couche Python (`src/python/`, `requirements.txt`).
#' @param cpp ajoute la couche C/C++ (`src/cpp/`, exemple Rcpp).
#' @param git initialise un depot git avec un commit initial.
#' @param rproj cree le fichier `<nom>.Rproj`.
#' @param open ouvre le projet dans RStudio a la fin (si disponible).
#' @param quiet supprime les messages.
#' @return le chemin absolu du projet, de facon invisible.
#' @seealso [list_layers()]
#' @examples
#' p <- file.path(tempdir(), "monprojet")
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
    message("Projet '", vars$name, "' cree dans : ", path)
    message("Couches : ", paste(layers, collapse = ", "))
  }
  if (isTRUE(open) && requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::openProject(path, newSession = TRUE)
  }
  invisible(path)
}

#' Lister les couches de templates disponibles
#'
#' @return un vecteur de noms de couches (`"base"` en premier).
#' @examples
#' list_layers()
#' @export
list_layers <- function() {
  layers <- list.dirs(templates_dir(), recursive = FALSE, full.names = FALSE)
  c("base", setdiff(sort(layers), "base"))
}

#' Point d'entree pour RStudio (File > New Project)
#'
#' Appelee par RStudio via `inst/rstudio/templates/project/rtemplates.dcf`.
#' RStudio cree lui-meme le dossier et le fichier `.Rproj`.
#'
#' @param path chemin choisi dans RStudio.
#' @param ... parametres du formulaire (`python`, `cpp`, `git`).
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

# ---- fonctions internes ---------------------------------------------------

templates_dir <- function() {
  d <- system.file("templates", package = "skeltools")
  if (!nzchar(d)) stop("Dossier des templates introuvable.", call. = FALSE)
  d
}

check_target <- function(path) {
  if (!file.exists(path)) return(invisible(TRUE))
  if (!dir.exists(path)) {
    stop("'", path, "' existe et n'est pas un dossier.", call. = FALSE)
  }
  if (length(list.files(path, all.files = TRUE, no.. = TRUE)) > 0) {
    stop("'", path, "' existe et n'est pas vide. Rien n'a ete modifie.",
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
  if (!dir.exists(src)) stop("Couche inconnue : ", layer, call. = FALSE)
  rel <- list.files(src, recursive = TRUE, all.files = TRUE)
  if (!rproj) rel <- rel[!grepl("\\.Rproj$", rel)]
  for (r in rel) {
    dest <- file.path(path, target_name(r, vars))
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    if (file.exists(dest)) {
      stop("Conflit entre couches : '", target_name(r, vars), "'.",
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
    warning("git introuvable, depot non initialise.", call. = FALSE)
    return(invisible(FALSE))
  }
  run <- function(...) {
    system2("git", c("-C", shQuote(path), ...), stdout = FALSE, stderr = FALSE)
  }
  run("init", "-q")
  run("add", ".")
  ok <- run("commit", "-q", "-m",
            shQuote("Initialisation de la structure du projet")) == 0
  if (!ok && !quiet) {
    message("Note : commit initial non fait (configure user.name / user.email).")
  }
  invisible(ok)
}

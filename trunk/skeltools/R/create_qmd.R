#' Create a Quarto report (.qmd)
#'
#' Writes a Quarto report from the skeltools template: YAML header (author,
#' ORCID, email, parameters, bibliography), a setup chunk that sources the
#' project R scripts (`src/R/*.R`), the sections Objective, Data, Methods,
#' Results, Discussion and References, and an appendix with
#' `sessionInfo()`. An empty `references.bib` is created next to the report
#' if it does not exist.
#'
#' The report is meant to sit at the root of a project created with
#' [create_project()]: paths such as `src/R` and `data/` are relative to the
#' folder of the `.qmd` file, which is the working directory used by Quarto.
#'
#' Default author details can be set once per session or in `.Rprofile`
#' with `options(skeltools.author = , skeltools.orcid = , skeltools.email = )`.
#' An empty `orcid` or `email` removes the corresponding line.
#'
#' @param file path of the report. The `.qmd` extension is added if missing.
#' @param template name of the Quarto template, see [list_qmd_templates()]:
#'   `"report"` (standard report) or `"PBreport"` (customised report).
#' @param title report title. Defaults to the file name without extension.
#' @param author author name.
#' @param orcid author ORCID, or `""` to omit it.
#' @param email author email, or `""` to omit it.
#' @param bib creates `references.bib` next to the report if it is missing.
#' @param overwrite replaces an existing report.
#' @param open opens the report in RStudio (if available).
#' @param quiet suppresses messages.
#' @return the absolute path of the report, invisibly.
#' @seealso [create_project()] with `quarto = TRUE`.
#' @examples
#' d <- file.path(tempdir(), "qmd-example")
#' dir.create(d)
#' create_qmd(file.path(d, "analysis"), title = "First analysis")
#' create_qmd(file.path(d, "custom"), template = "PBreport")
#' list.files(d)
#' unlink(d, recursive = TRUE)
#' @export
create_qmd <- function(file, template = "report", title = NULL,
                       author = getOption("skeltools.author", "Pierre Bady"),
                       orcid = getOption("skeltools.orcid", "0000-0003-1398-4689"),
                       email = getOption("skeltools.email", "pierre.bady@gmail.com"),
                       bib = TRUE, overwrite = FALSE, open = FALSE,
                       quiet = FALSE) {
  stopifnot(is.character(file), length(file) == 1L, nzchar(file))
  template <- match.arg(template, list_qmd_templates())
  if (!grepl("\\.qmd$", file, ignore.case = TRUE)) file <- paste0(file, ".qmd")
  dir <- dirname(file)
  if (!dir.exists(dir)) {
    stop("Folder '", dir, "' does not exist.", call. = FALSE)
  }
  if (file.exists(file) && !isTRUE(overwrite)) {
    stop("'", file, "' already exists. Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }
  dir <- normalizePath(dir)
  file <- file.path(dir, basename(file))
  stem <- sub("\\.qmd$", "", basename(file), ignore.case = TRUE)

  vars <- list(
    title  = if (is.null(title)) stem else title,
    name   = basename(dir),
    author = author,
    orcid  = if (is.null(orcid)) "" else orcid,
    email  = if (is.null(email)) "" else email,
    date   = format(Sys.Date(), "%Y-%m-%d")
  )
  txt <- readLines(qmd_template(paste0(template, ".qmd")), warn = FALSE)
  txt <- render(txt, vars)
  txt <- txt[!grepl('^\\s+(orcid|email):\\s*("")?\\s*$', txt)]
  writeLines(txt, file, useBytes = TRUE)

  bib_file <- file.path(dir, "references.bib")
  if (isTRUE(bib) && !file.exists(bib_file)) {
    file.copy(qmd_template("references.bib"), bib_file)
  }

  if (!quiet) message("Quarto report created: ", file)
  if (isTRUE(open) && requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(file)
  }
  invisible(file)
}

#' List the available Quarto templates
#'
#' The templates are the `.qmd` files stored in `inst/qmd/` of the package.
#' To add one, put a `.qmd` file there and reinstall the package.
#'
#' @return a character vector of template names (`"report"` first).
#' @examples
#' list_qmd_templates()
#' @export
list_qmd_templates <- function() {
  d <- system.file("qmd", package = "skeltools")
  tpl <- sub("\\.qmd$", "", list.files(d, pattern = "\\.qmd$"))
  c("report", setdiff(sort(tpl), "report"))
}

qmd_template <- function(file) {
  f <- system.file("qmd", file, package = "skeltools")
  if (!nzchar(f)) stop("Quarto template not found: ", file, call. = FALSE)
  f
}

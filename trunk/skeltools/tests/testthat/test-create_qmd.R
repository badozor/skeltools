test_that("create_qmd writes the report and references.bib", {
  d <- tempfile("qmd")
  dir.create(d)
  f <- create_qmd(file.path(d, "analysis"), title = "My title", quiet = TRUE)
  expect_identical(basename(f), "analysis.qmd")
  expect_true(file.exists(file.path(d, "references.bib")))
  txt <- readLines(f)
  expect_true('title: "My title"' %in% txt)
  expect_true(any(grepl("orcid: 0000-0003-1398-4689", txt, fixed = TRUE)))
  expect_true("Jupyter: myenv" %in% txt)
  expect_true("::: {#refs}" %in% txt)
  expect_false(any(grepl("{{", txt, fixed = TRUE)))
})

test_that("empty orcid and email remove their lines", {
  d <- tempfile("qmd")
  dir.create(d)
  f <- create_qmd(file.path(d, "a.qmd"), author = "Someone", orcid = "",
                  email = "", quiet = TRUE)
  txt <- readLines(f)
  expect_false(any(grepl("orcid:|email:", txt)))
  expect_true(any(grepl('name: "Someone"', txt, fixed = TRUE)))
})

test_that("an existing report is not overwritten by default", {
  d <- tempfile("qmd")
  dir.create(d)
  f <- create_qmd(file.path(d, "a"), quiet = TRUE)
  expect_error(create_qmd(file.path(d, "a"), quiet = TRUE), "already exists")
  expect_silent(create_qmd(file.path(d, "a"), overwrite = TRUE, quiet = TRUE))
})

test_that("create_project(quarto = TRUE) adds the report", {
  p <- file.path(tempfile("rt"), "demo")
  create_project(p, quarto = TRUE, quiet = TRUE)
  expect_true(file.exists(file.path(p, "demo.qmd")))
  expect_true(file.exists(file.path(p, "references.bib")))
  expect_true("/.quarto/" %in% readLines(file.path(p, ".gitignore")))
  expect_true(any(grepl("demo.qmd", readLines(file.path(p, "README.md")),
                        fixed = TRUE)))
})

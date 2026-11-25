test_that("create_venv creates an empty environment", {
  skip_on_cran()
  py <- Sys.which(c("python3", "python"))
  skip_if(all(!nzchar(py)), "no Python")
  d <- tempfile("venv")
  dir.create(d)
  env <- create_venv(d, install = FALSE, quiet = TRUE)
  expect_true(dir.exists(env))
  expect_identical(basename(env), "myenv")
  expect_error(create_venv(d, install = FALSE, quiet = TRUE), "already exists")
})

test_that("the python layer lists the packages and ignores myenv", {
  p <- file.path(tempfile("rt"), "demo")
  create_project(p, python = TRUE, quiet = TRUE)
  req <- readLines(file.path(p, "requirements.txt"))
  expect_true(all(c("scanpy", "leidenalg", "scikit-learn") %in% req))
  expect_true("myenv/" %in% readLines(file.path(p, ".gitignore")))
})

test_that("an unknown interpreter gives a clear error", {
  d <- tempfile("venv")
  dir.create(d)
  expect_error(create_venv(d, python = "/no/such/python", quiet = TRUE),
               "not found")
})

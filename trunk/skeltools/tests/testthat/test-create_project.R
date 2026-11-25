new_path <- function(name = "proj") {
  file.path(tempfile("rt"), name)
}

test_that("the base template creates the expected structure", {
  p <- new_path("demo")
  create_project(p, quiet = TRUE)
  for (d in c("data", "archive", "tmp", "src/R")) {
    expect_true(dir.exists(file.path(p, d)), info = d)
  }
  expect_true(file.exists(file.path(p, "demo.Rproj")))
  expect_true(file.exists(file.path(p, "data", ".gitkeep")))
  expect_true(file.exists(file.path(p, "tmp", ".gitkeep")))
  expect_false(dir.exists(file.path(p, "src", "python")))
  expect_false(dir.exists(file.path(p, "src", "cpp")))

  setup <- readLines(file.path(p, "src", "R", "00_setup.R"))
  expect_true(any(grepl("Project: demo", setup, fixed = TRUE)))
  expect_false(any(grepl("{{", setup, fixed = TRUE)))

  readme <- readLines(file.path(p, "README.md"))
  expect_true(any(grepl("`tmp/`", readme, fixed = TRUE)))
  expect_false(any(grepl("{{", readme, fixed = TRUE)))

  gi <- readLines(file.path(p, ".gitignore"))
  expect_true("tmp/*" %in% gi)
  expect_false("__pycache__/" %in% gi)
})

test_that("python and cpp options add their layers", {
  p <- new_path()
  create_project(p, python = TRUE, cpp = TRUE, quiet = TRUE)
  expect_true(file.exists(file.path(p, "src", "python", "main.py")))
  expect_true(file.exists(file.path(p, "requirements.txt")))
  expect_true(file.exists(file.path(p, "src", "cpp", "hello.cpp")))
  expect_true(file.exists(file.path(p, "src", "R", "01_cpp.R")))
  gi <- readLines(file.path(p, ".gitignore"))
  expect_true(all(c("__pycache__/", "*.so") %in% gi))
  readme <- readLines(file.path(p, "README.md"))
  expect_true(any(grepl("src/python", readme, fixed = TRUE)))
  expect_true(any(grepl("src/cpp", readme, fixed = TRUE)))
})

test_that("a non-empty folder is refused, an empty folder is accepted", {
  p <- new_path()
  dir.create(p, recursive = TRUE)
  expect_silent(create_project(p, quiet = TRUE))
  expect_error(create_project(p, quiet = TRUE), "is not empty")
})

test_that("rproj = FALSE does not create a .Rproj (RStudio case)", {
  p <- new_path()
  rstudio_project(p, python = TRUE)
  expect_length(list.files(p, pattern = "\\.Rproj$"), 0)
  expect_true(dir.exists(file.path(p, "src", "python")))
})

test_that("list_layers returns the layers", {
  expect_identical(list_layers(), c("base", "cpp", "python", "quarto"))
})

test_that("git initialises a repository", {
  skip_if(!nzchar(Sys.which("git")))
  p <- new_path()
  create_project(p, git = TRUE, quiet = TRUE)
  expect_true(dir.exists(file.path(p, ".git")))
})

test_that("layers accepts stored layers and rejects unknown ones", {
  p <- new_path()
  create_project(p, layers = "python", quiet = TRUE)
  expect_true(file.exists(file.path(p, "src", "python", "main.py")))
  q <- new_path()
  expect_error(create_project(q, layers = "fortran", quiet = TRUE),
               "Unknown layer")
  expect_false(file.exists(q))
})

# skeltools 0.1.0

* First release.
* `create_project()`: base template (`data/`, `archive/`, `tmp/`, `src/R/`)
  with optional Python and C/C++ layers, and any other stored layer
  through the `layers` argument.
* `list_layers()`: lists the available layers.
* `create_venv()`: Python environment `myenv/` (venv + pip install of
  `requirements.txt`, Jupyter kernel `myenv` registered inside
  the environment, so specific to the project); also available
  as `create_project(venv = TRUE)`.
* `create_qmd()`: Quarto report template (`.qmd` + `references.bib`);
  also available as `create_project(quarto = TRUE)`.
* RStudio project template (File > New Project).
* Repository organised under `trunk/`: package sources (`trunk/skeltools`),
  PDF manual (`trunk/documentation`), archives (`trunk/Rpackage`).

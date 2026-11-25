# skeltools

Cree la structure standard d'un projet d'analyse R, avec Python et C/C++ en option.

## Organisation du depot

```
skeltools/
└── trunk/
    ├── skeltools/       sources du package R
    ├── documentation/   manuel de reference (PDF)
    └── Rpackage/        archives du package
        ├── skeltools_<version>.tar.gz                        sources compressees
        └── skeltools_<version>_R_x86_64-pc-linux-gnu.tar.gz  binaire Linux
```

## Installation

```r
# depuis GitHub (le package est dans un sous-dossier)
remotes::install_github("badozor/skeltools", subdir = "trunk/skeltools")

# ou depuis l'archive source telechargee (toutes plateformes)
install.packages("skeltools_0.1.0.tar.gz", repos = NULL, type = "source")
```

Le package est ecrit en R pur. L'archive source s'installe donc sous Linux, macOS
et Windows sans compilateur. Le binaire fourni est construit sous Linux.

## Utilisation

```r
library(skeltools)
create_project("~/projets/monprojet")                             # R seul
create_project("~/projets/monprojet", python = TRUE)              # + Python
create_project("~/projets/monprojet", python = TRUE, cpp = TRUE,
               git = TRUE, open = TRUE)                           # tout
list_layers()
```

Dans RStudio : **File > New Project > New Directory > Projet d'analyse (skeltools)**.
Le formulaire propose les cases Python, C/C++ et git.

## Structure creee

```
monprojet/
├── data/          donnees (contenu ignore par git)
├── archive/       anciennes versions, scripts abandonnes
├── tmp/           fichiers temporaires (contenu ignore par git)
├── src/
│   ├── R/         00_setup.R (+ 01_cpp.R avec cpp = TRUE)
│   ├── python/    main.py              (python = TRUE)
│   └── cpp/       hello.cpp, via Rcpp  (cpp = TRUE)
├── monprojet.Rproj
├── README.md
├── .gitignore
└── requirements.txt                    (python = TRUE)
```

## Ajouter une couche

Creer `trunk/skeltools/inst/templates/<couche>/` avec :

| Element | Role |
|---|---|
| `files/` | fichiers copies dans le projet |
| `gitignore` | fragment ajoute au `.gitignore` |
| `structure.md` | lignes du tableau de structure du README |
| `start.md` | paragraphe de la section Demarrage du README |

Conventions dans `files/` : `{{name}}` et `{{date}}` sont remplaces dans le contenu,
`__name__` dans les noms de fichiers, et le prefixe `dot-` devient `.`
(`dot-gitkeep` donne `.gitkeep`, ce qui evite que `R CMD build` ignore les fichiers caches).

Il faut ensuite ajouter l'argument correspondant dans `create_project()` et une case dans
`trunk/skeltools/inst/rstudio/templates/project/skeltools.dcf`.

## Construire les archives et la documentation

Depuis `trunk/` :

```bash
R CMD build skeltools                                  # sources compressees
R CMD check --as-cran skeltools_0.1.0.tar.gz           # verification
R CMD INSTALL --build skeltools_0.1.0.tar.gz           # binaire
mv skeltools_0.1.0*.tar.gz Rpackage/
R CMD Rd2pdf --no-preview --force -o documentation/skeltools_0.1.0.pdf skeltools
```

## Licence

GPL (>= 3)

# skeltools

Cree la structure standard d'un projet d'analyse R, avec Python et C/C++ en option.

## Installation

```r
# depuis GitHub
remotes::install_github("badozor/skeltools")

# ou depuis le dossier source
install.packages("skeltools", repos = NULL, type = "source")
```

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

Creer `inst/templates/<couche>/` avec :

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
`inst/rstudio/templates/project/rtemplates.dcf`.

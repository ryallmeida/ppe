
# Introduction to Computational Methods for the Visualization and Analysis of Political Parties and Elections    [![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/ryallmeida/ppe?tab=MIT-1-ov-file)

This repository contains the codes and materials used in this workshop, delivered as part of the Political Parties and Elections course in the Bachelor’s Degree in Political Science at the Federal University of Pernambuco (UFPE, Brazil), under the supervision of Leon Victor Queiroz (PhD).


# **SYLLABUS** ![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white) 

## **PREREQUISITE KNOWLEDGE AND RESOURCES**  ![RStudio](https://img.shields.io/badge/RStudio-4285F4?style=for-the-badge&logo=rstudio&logoColor=white)

To get the most out of this course, you should already have a basic understanding of R and RStudio, as well as a working knowledge of the tidyverse for data manipulation and visualization. If you do not have these prerequisites, the following resources are recommended to help you get up to speed.

[ANJOS, Adilson dos. Estatística básica com uso do software R. Curitiba: Departamento de Estatística – UFPR, 2010.](https://docs.ufpr.br/~aanjos/TRI/R/rbasico.pdf)

[Grolemund, Garrett. Hands-on programming with R. " O'Reilly Media, Inc.", 2014.](https://rstudio-education.github.io/hopr/basics.html)

[LANDEIRO, Victor Lemes. Introdução ao uso do programa R. Manaus: Instituto Nacional de Pesquisas da Amazônia, Programa de Pós-Graduação em Ecologia](https://cran.r-project.org/doc/contrib/Landeiro-Introducao.pdf)

[Wickham, Hadley, Mine Çetinkaya-Rundel, and Garrett Grolemund. R für Data Science: Daten importieren, bereinigen, umformen und visualisieren. O'Reilly, 2024.](https://pt.r4ds.hadley.nz/)

Mais informações podem ser encontradas em [tidyverse.org](https://tidyverse.org/)

## POINTS AND SUBJECTS

* Motivation to learn R
* Some real applications and Case Studies
* Installation  of R, and development environment (RStudio/IDE)
* Introduction to descriptive statistics  
* Main native plots in R

### [RECOMMENDED] CORE READINGS

[Wickham H (2014). Dados organizados. Journal of Statistical Software. Volume 59, Edição 10.](https://vita.had.co.nz/papers/tidy-data.pdf)

[Hadley Wickham (2010): Uma gramática em camadas de gráficos, Journal of Computational and Graphical Statistics](https://byrneslab.net/classes/biol607/readings/wickham_layered-grammar.pdf)

### SUPPLEMENTARY  READINGS

## PACKAGES 

```R
if (!require(pacman)) install.packages("pacman")

pacman::p_load(tidyverse, 
               geobr, 
               sf, 
               patchwork)
```


GARNIER, Simon *et al*. **viridis(Lite)**: colorblind-friendly color maps for R. Versão 0.6.5. [*S. l.*]: CRAN, 2024. Pacote R. DOI: [10.5281/zenodo.4679423](https://doi.org/10.5281/zenodo.4679423). Disponível em: [https://sjmgarnier.github.io/viridis/](https://sjmgarnier.github.io/viridis/). Acesso em: 24 set. 2026.

PEBESMA, Edzer. Simple features for R: standardized support for spatial vector data. **The R Journal**, [*s. l.*], v. 10, n. 1, p. 439-446, 2018. DOI: [10.32614/RJ-2018-009](https://doi.org/10.32614/RJ-2018-009).

PEBESMA, Edzer; BIVAND, Roger. **Spatial data science**: with applications in R. Boca Raton: Chapman and Hall/CRC, 2023. DOI: [10.1201/9780429459016](https://doi.org/10.1201/9780429459016).

PEDERSEN, Thomas Lin. **patchwork**: the composer of plots. Versão 1.3.2. [*S. l.*]: CRAN, 2025. Pacote R. DOI: [10.32614/CRAN.package.patchwork](https://doi.org/10.32614/CRAN.package.patchwork). Disponível em: [https://CRAN.R-project.org/package=patchwork](https://CRAN.R-project.org/package=patchwork). Acesso em: 24 set. 2026.

PEREIRA, Rafael H. M.; GONCALVES, Caio Nogueira. **geobr**: download official spatial data sets of Brazil. Versão 1.9.1. [*S. l.*]: CRAN, 2024. Pacote R. DOI: [10.32614/CRAN.package.geobr](https://doi.org/10.32614/CRAN.package.geobr). Disponível em: [https://CRAN.R-project.org/package=geobr](https://CRAN.R-project.org/package=geobr). Acesso em: 24 set. 2026.

WICKHAM, Hadley *et al*. Welcome to the tidyverse. **Journal of Open Source Software**, [*s. l.*], v. 4, n. 43, p. 1686, 2019. DOI: [10.21105/joss.01686](https://doi.org/10.21105/joss.01686).

## ORIGINAL DATA SOURSE

[BRASIL. Tribunal Superior Eleitoral. Portal de Dados Abertos do TSE: resultados. Brasília, DF, [2026]. Disponível em: https://dadosabertos.tse.jus.br/. Acesso em: 24 set. 2026.](https://dadosabertos.tse.jus.br/dataset/?groups=resultados&_tags_limit=0)

### DOCUMENTATION

## EXPLORATORY DATA ANALYSIS

## APPENDIX

[The R Graph Gallery (Site para ver modelos de possíveis gráficos no R)](https://r-graph-gallery.com/index.html)




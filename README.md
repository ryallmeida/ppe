
# Introduction to Computational Methods for the Geospatial Visualization of Political Parties and Elections [![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/ryallmeida/ppe?tab=MIT-1-ov-file)

This repository contains the codes and materials used in this workshop, delivered as part of the Political Parties and Elections course in the Bachelor’s Degree in Political Science at the Federal University of Pernambuco (UFPE, Brazil), under the supervision of Leon Victor Queiroz (PhD).


# **SYLLABUS** ![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white) 

## **PREREQUISITE KNOWLEDGE AND RESOURCES**  ![RStudio](https://img.shields.io/badge/RStudio-4285F4?style=for-the-badge&logo=rstudio&logoColor=white)

To get the most out of this course, you should already have a basic understanding of R and RStudio, as well as a working knowledge of the tidyverse for data manipulation and visualization. If you do not have these prerequisites, the following resources are recommended to help you get up to speed.

[ANJOS, Adilson dos. Estatística básica com uso do software R. Curitiba: Departamento de Estatística – UFPR, 2010.](https://docs.ufpr.br/~aanjos/TRI/R/rbasico.pdf)

[Grolemund, Garrett. Hands-on programming with R. " O'Reilly Media, Inc.", 2014.](https://rstudio-education.github.io/hopr/basics.html)

[LANDEIRO, Victor Lemes. Introdução ao uso do programa R. Manaus: Instituto Nacional de Pesquisas da Amazônia, Programa de Pós-Graduação em Ecologia](https://cran.r-project.org/doc/contrib/Landeiro-Introducao.pdf)

Mais informações podem ser encontradas em [tidyverse.org](https://tidyverse.org/)

## POINTS AND SUBJECTS

* Motivation to learn data visualization
* Some real applications
* Introducing the database structure
* Why use these packages?
* Understanding spatial data
* Coordinate reference systems and projections
* Creating and customizing maps

### [RECOMMENDED] CORE READINGS

WICKHAM, Hadley. **ggplot2**: elegant graphics for data analysis. New York: Springer, 2009. (Use R!). ISBN 978-0-387-98140-6. DOI: [10.1007/978-0-387-98141-3](https://doi.org/10.1007/978-0-387-98141-3).

[Hadley Wickham (2010): Uma gramática em camadas de gráficos, Journal of Computational and Graphical Statistics](https://byrneslab.net/classes/biol607/readings/wickham_layered-grammar.pdf)

[Wickham, Hadley, Mine Çetinkaya-Rundel, and Garrett Grolemund. R für Data Science: Daten importieren, bereinigen, umformen und visualisieren. O'Reilly, 2024.](https://pt.r4ds.hadley.nz/)

### SUPPLEMENTARY  READINGS

[Wickham H (2014). Dados organizados. Journal of Statistical Software. Volume 59, Edição 10.](https://vita.had.co.nz/papers/tidy-data.pdf)

## PACKAGES 

```R
if (!require(pacman)) {
  install.packages("pacman")
}
          
pacman::p_load(tidyverse, 
               geobr, 
               sf, 
               patchwork)
```

As análises foram realizadas no R, utilizando o pacote *{tidyverse}* para manipulação dos dados (WICKHAM *et al*., 2019; principalmente usando o *{dplyr}* e *{ggplot}*), adiante o pacote *{geobr}* para obtenção das malhas territoriais do Brasil (PEREIRA; GONCALVES, 2024) e o pacote *{sf}* para o tratamento dos dados espaciais (PEBESMA, 2018; PEBESMA; BIVAND, 2023). Os mapas foram elaborados com a paleta de cores do pacote *{viridis}* (GARNIER *et al*., 2024) e combinados com o pacote *{patchwork}* (PEDERSEN, 2025).

## ORIGINAL DATA SOURSE

[BRASIL. Tribunal Superior Eleitoral. Portal de Dados Abertos do TSE: resultados. Brasília, DF, [2026]. Disponível em: https://dadosabertos.tse.jus.br/. Acesso em: 24 set. 2026.](https://dadosabertos.tse.jus.br/dataset/?groups=resultados&_tags_limit=0)

### DOCUMENTATION 

* **Source:** Brazilian Superior Electoral Court (TSE)
* **Unit of observation:** one row per candidate, per electoral zone, per municipality, per election.
* **Subset:** first round only; unsuccessful candidates only (`NÃO ELEITO`); 2020, 2022 and 2024 elections.
* **Missing values:** `-1` = blank in the TSE database; `-3` = not applicable to that election year. Text fields may appear as `NA` or an empty string.
* **Encoding:** original files in Latin-1, converted to UTF-8 with no data loss.

| Variable | Type | Description | Values / Notes |
|---|---|---|---|
| `FONTE` | integer | Source file identifier | Created for this project; not part of the TSE layout |
| `ANO_ELEICAO` | integer | Election year | `2020`, `2022`, `2024`. By-elections are filed under the preceding regular election year |
| `NR_TURNO` | integer | Election round | `1` only in this subset |
| `TP_ABRANGENCIA` | text | Election scope | `M` municipal · `E` state · `F` federal |
| `SG_UF` | text | State where the election took place | Two-letter state code; `ZZ` = votes cast abroad |
| `SG_UE` | text | Electoral unit the candidate ran in | `BR` (federal), state code (state) or TSE municipality code (municipal) |
| `CD_MUNICIPIO` | text | TSE municipality code where votes were cast | 5 digits, leading zeros restored. **Not** the IBGE code; a crosswalk is needed to join with `geobr` |
| `NR_ZONA` | integer | Electoral zone number | — |
| `CD_CARGO` | integer | Office code | Pairs with `DS_CARGO` |
| `DS_CARGO` | text | Office sought | President, Governor, Senator, Federal Deputy, State Deputy, District Deputy, Mayor, City Councilor |
| `SQ_CANDIDATO` | text | Internal TSE candidate ID | Unique within a single election only; changes across elections |
| `NM_CANDIDATO` | text | Candidate's full name | Not a unique identifier; the same person may appear in more than one election |
| `TP_AGREMIACAO` | text | How the candidate ran | `PARTIDO ISOLADO` (single party) · `COLIGAÇÃO` (coalition). No federations in this subset |
| `SG_PARTIDO` | text | Party abbreviation | — |
| `NM_PARTIDO` | text | Party name | — |
| `DS_COMPOSICAO_COLIGACAO` | text | Parties in the coalition | Abbreviations separated by `/` (the TSE documentation incorrectly says `,`). For single-party runs, contains the party abbreviation |
| `QT_VOTOS_NOMINAIS` | integer | Votes cast for the candidate | **Includes** annulled votes |
| `NM_TIPO_DESTINACAO_VOTOS` | text | How the votes were counted | `Anulado` = annulled (candidate ineligible) · `Anulado sub judice` = annulled pending appeal |
| `QT_VOTOS_NOMINAIS_VALIDOS` | integer | Valid votes for the candidate | **Excludes** annulled votes. Differs from `QT_VOTOS_NOMINAIS` in 248 rows (3,712 votes) |
| `DS_SIT_TOT_TURNO` | text | Candidate's outcome in the round | `NÃO ELEITO` (not elected) only in this subset |

## REFERENCES

GARNIER, Simon *et al*. **viridis(Lite)**: colorblind-friendly color maps for R. Versão 0.6.5. [*S. l.*]: CRAN, 2024. Pacote R. DOI: [10.5281/zenodo.4679423](https://doi.org/10.5281/zenodo.4679423). Disponível em: [https://sjmgarnier.github.io/viridis/](https://sjmgarnier.github.io/viridis/). Acesso em: 24 set. 2026.

PEBESMA, Edzer. Simple features for R: standardized support for spatial vector data. **The R Journal**, [*s. l.*], v. 10, n. 1, p. 439-446, 2018. DOI: [10.32614/RJ-2018-009](https://doi.org/10.32614/RJ-2018-009).

PEBESMA, Edzer; BIVAND, Roger. **Spatial data science**: with applications in R. Boca Raton: Chapman and Hall/CRC, 2023. DOI: [10.1201/9780429459016](https://doi.org/10.1201/9780429459016).

PEDERSEN, Thomas Lin. **patchwork**: the composer of plots. Versão 1.3.2. [*S. l.*]: CRAN, 2025. Pacote R. DOI: [10.32614/CRAN.package.patchwork](https://doi.org/10.32614/CRAN.package.patchwork). Disponível em: [https://CRAN.R-project.org/package=patchwork](https://CRAN.R-project.org/package=patchwork). Acesso em: 24 set. 2026.

PEREIRA, Rafael H. M.; GONCALVES, Caio Nogueira. **geobr**: download official spatial data sets of Brazil. Versão 1.9.1. [*S. l.*]: CRAN, 2024. Pacote R. DOI: [10.32614/CRAN.package.geobr](https://doi.org/10.32614/CRAN.package.geobr). Disponível em: [https://CRAN.R-project.org/package=geobr](https://CRAN.R-project.org/package=geobr). Acesso em: 24 set. 2026.

WICKHAM, Hadley *et al*. Welcome to the tidyverse. **Journal of Open Source Software**, [*s. l.*], v. 4, n. 43, p. 1686, 2019. DOI: [10.21105/joss.01686](https://doi.org/10.21105/joss.01686).

## APPENDIX

[The R Graph Gallery (Site para ver modelos de possíveis gráficos no R)](https://r-graph-gallery.com/index.html)




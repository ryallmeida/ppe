# ============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES 
# ============================================================================
# CODADO ORGININALMENTE EM R, R version 4.5.2 (2025-10-31 ucrt)
# DEMONSTRAÇÃO: a sintaxe do {sf} e {geobr}

pacman::p_load(tidyverse,
               sf,
               geobr)

data(package = "geobr")

# ============================================================================
# DADOS SIMULADOS
# ============================================================================

# Criar dados simulados de cidades
cidades <- data.frame(
  nome = c("São Paulo", "Rio de Janeiro", "Belo Horizonte", "Porto Alegre", "Recife"),
  populacao = c(12325232, 6747815, 2521564, 1488252, 1661017)
)

# Criar pontos simulados para as cidades
pontos <- st_sfc(
  st_point(c(-46.6388, -23.5489)),  # São Paulo
  st_point(c(-43.1729, -22.9068)),  # Rio de Janeiro
  st_point(c(-43.9378, -19.9208)),  # Belo Horizonte
  st_point(c(-51.2302, -30.0331)),  # Porto Alegre
  st_point(c(-34.8771, -8.0539))    # Recife
)

# Criar objeto sf combinando os dados e os pontos
cidades_sf <- st_sf(cidades, geometry = pontos)

# -----------------------------------

# Visualizar a estrutura do objeto sf
str(cidades_sf)

# Imprimir as primeiras linhas do objeto sf
head(cidades_sf)

# Plotar as cidades em um mapa
plot(cidades_sf)

glimpse(cidades_sf)

# Acessar a coluna de nomes
cidades_sf$nome

# Acessar a coluna de população
cidades_sf$populacao

# Acessar a coluna de geometria
cidades_sf$geometry

# -----------------------------------

rm(list = ls())
cat("\014")

# ============================================================================
# SETUP -- roda uma vez só, antes dos 4 plots (não faz parte da "evolução")
# ============================================================================

pe_estado    <- geobr::read_state(code_state = "PE", year = 2020)
municipios   <- geobr::read_municipality(code_muni = "PE", year = 2020)
recife_poly  <- municipios |> dplyr::filter(name_muni == "Recife")

cidades_pe <- data.frame(
  nome = c("Recife", "Caruaru", "Petrolina", "Garanhuns", "Serra Talhada"),
  lon  = c(-34.8771, -35.9761, -40.5030, -36.4966, -38.2942),
  lat  = c(-8.0539, -8.2837, -9.3891, -8.8827, -7.9553)
) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

rota_pe <- cidades_pe |> sf::st_combine() |> sf::st_cast("LINESTRING")

# janela fixa (bbox do ESTADO inteiro, já incluindo Fernando de Noronha
# -- por isso o "buraco vazio" vai aparecer nos plots 1-3)
bb <- sf::st_bbox(pe_estado)

# ============================================================================
# QUADRO 1 -- POINT: cada cidade é uma geometria isolada
# ============================================================================

plot(sf::st_geometry(cidades_pe),
     pch = 19, col = "darkred", cex = 1.3,
     xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")],
     main = "1) POINT -- cada cidade, uma geometria")

# ============================================================================
# QUADRO 2 -- + LINESTRING: conecta os pontos em sequência
# ============================================================================
plot(sf::st_geometry(cidades_pe),
     pch = 19, col = "darkred", cex = 1.3,
     xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")],
     main = "2) + LINESTRING -- conectando os pontos")
plot(sf::st_geometry(rota_pe), col = "darkorange", lwd = 2, add = TRUE)

# ============================================================================
# QUADRO 3 -- + POLYGON: um único município fechado (Recife)
# ============================================================================
plot(sf::st_geometry(cidades_pe),
     pch = 19, col = "darkred", cex = 1.3,
     xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")],
     main = "3) + POLYGON -- um município (Recife)")
plot(sf::st_geometry(rota_pe), col = "darkorange", lwd = 2, add = TRUE)
plot(sf::st_geometry(recife_poly),
     col = adjustcolor("steelblue", 0.6), border = "steelblue4",
     add = TRUE)

# ============================================================================
# QUADRO 4 -- + MULTIPOLYGON: o estado inteiro (continente + Fernando de
# Noronha) -- observe o "arquipélago" surgindo no canto vazio!
# ============================================================================
plot(sf::st_geometry(cidades_pe),
     pch = 19, col = "darkred", cex = 1.3,
     xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")],
     main = "4) + MULTIPOLYGON -- o estado (continente + Noronha)")
plot(sf::st_geometry(rota_pe), col = "darkorange", lwd = 2, add = TRUE)
plot(sf::st_geometry(recife_poly),
     col = adjustcolor("steelblue", 0.6), border = "steelblue4",
     add = TRUE)
plot(sf::st_geometry(pe_estado),
     col = NA, border = "black", lwd = 1.5, add = TRUE)

unique(sf::st_geometry_type(pe_estado))
# [1] MULTIPOLYGON  <- exatamente por causa de Fernando de Noronha


library(geobr)
library(dplyr)

lookup_muni(code_muni = "all") |>
  filter(abbrev_state == "PE") |>
  count(name_meso, name = "n_municipios")

library(geobr)
library(dplyr)

pe <- lookup_muni(code_muni = "all") |>
  filter(abbrev_state == "PE")

# 1) municípios por microrregião (mostrando a mesorregião de cada uma)
pe |>
  count(name_meso, name_micro, name = "n_municipios") |>
  arrange(name_meso, desc(n_municipios))

# 2) quantas microrregiões existem em cada mesorregião
pe |>
  distinct(name_meso, name_micro) |>
  count(name_meso, name = "n_micro")

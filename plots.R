# =============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES 
# =============================================================================
# CODADO ORGININALMENTE EM R, R version 4.5.2 (2025-10-31 ucrt)

# INSTALAÇÃO DOS PACOTES 

if (!require(pacman)) {
  install.packages("pacman")
}

pacman::p_load(tidyverse, 
               geobr, 
               sf, 
               patchwork)

# =============================================================================
# DEMOSTRAÇÃO DO R POTENCIAL DO R EM TERMOS DE PLOTTAGEM
# =============================================================================

demo(graphics)
demo(persp)
demo(image)

rm(list = ls())
cat("\014")

# q()
help("ggplot2")

# =============================================================================

pacman::p_load(maps)
# data(package = "maps")

data(us.cities)

big_cities <- subset(us.cities, pop > 500000)
qplot(long, lat, data = big_cities) + borders("state", size = 0.5)

tx_cities <- subset(us.cities, country.etc == "TX")

ggplot(tx_cities, aes(long, lat)) +
  borders("county", "texas", colour = "grey70") +
  geom_point(colour = alpha("black", 0.5))

# --------------------------------------

library(maps)

states <- map_data("state")
arrests <- USArrests
names(arrests) <- tolower(names(arrests))
arrests$region <- tolower(rownames(USArrests))
choro <- merge(states, arrests, by = "region")

# Reordena as linhas, porque a ordem importa ao desenhar polígonos
# e o merge destrói a ordenação original

choro <- choro[order(choro$order), ]

qplot(long, lat, data = choro, group = group,
      fill = assault, geom = "polygon")
qplot(long, lat, data = choro, group = group,
      fill = assault / murder, geom = "polygon")


# -------------------------------------


ia <- map_data("county", "iowa")

centres <- ia %>%
  dplyr::group_by(subregion) %>%
  dplyr::summarise(
    lat  = mean(range(lat,  na.rm = TRUE)),
    long = mean(range(long, na.rm = TRUE))
  )

ggplot(ia, aes(long, lat)) +
  geom_polygon(aes(group = group),
               fill = NA, colour = "grey60") +
  geom_text(aes(label = subregion), data = centres,
            size = 2, angle = 45)

# =============================================================================
# DEMOSTRAÇÃO DO R POTENCIAL DO R EM TERMOS DE PLOTTAGEM
# =============================================================================


rm(list = ls())
cat("\014")

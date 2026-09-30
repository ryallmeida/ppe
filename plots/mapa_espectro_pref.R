# ============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES
# ============================================================================
# plot-mapa-prefeitos.R
#
# ENTRADA : data/prefeitos_eleitos.csv, lido do GitHub (raw), gerado por
#           data-processing-prefeitos.R
# SAÍDA   : mapa_prefeitos_espectro.png e tabela_prefeitos_partido_meso.csv
#
# OBJETIVO
#   (1) Mapa dos municípios de PE coloridos pelo espectro ideológico do
#       partido do prefeito eleito em 2024.
#   (2) Diagnóstico: prefeitos eleitos por partido e mesorregião.
#
# Testado com R >= 4.1 (usa |>).
# ============================================================================

rm(list = ls())
cat("\014")

# ============================================================================
# 0. CONFIGURAÇÃO
# ============================================================================

url_pref    <- "https://raw.githubusercontent.com/ryallmeida/ppe/refs/heads/main/data/prefeitos_eleitos.csv"
pasta_saida <- "C:/Users/ryall/Downloads"

ordem_meso <- c("Metropolitana de Recife", "Mata", "Agreste",
                "Sertão", "São Francisco")

ordem_espectro <- c("Extrema esquerda", "Esquerda", "Centro-esquerda",
                    "Centro", "Centro-direita", "Direita", "Extrema direita")


# ============================================================================
# 1. PACOTES
# ============================================================================

if (!require(pacman)) install.packages("pacman")
pacman::p_load(tidyverse, sf, geobr, scales)


# ============================================================================
# 2. LER prefeitos_eleitos E RESTAURAR OS FATORES
#    (o CSV perde os fatores, então a ordem é recriada aqui)
# ============================================================================

prefeitos_eleitos <- read_csv(
  url_pref,
  col_types = cols(
    CD_MUNICIPIO = col_integer(),
    code_muni    = col_integer(),
    NR_TURNO     = col_integer(),
    SQ_CANDIDATO = col_character(),
    .default     = col_guess()
  ),
  show_col_types = FALSE
) |>
  mutate(
    mesorregiao = factor(mesorregiao, levels = ordem_meso),
    espectro    = factor(espectro,    levels = ordem_espectro)
  )

# Conferências
stopifnot(nrow(prefeitos_eleitos) > 0,
          !anyNA(prefeitos_eleitos$mesorregiao),
          !anyNA(prefeitos_eleitos$espectro))
message("Prefeitos eleitos: ", nrow(prefeitos_eleitos), " (esperado: 184)")
glimpse(prefeitos_eleitos)


# ============================================================================
# 3. CORES (mesma paleta viridis dos boxplots; "Centro" fica vazio)
# ============================================================================

niveis_cor <- setdiff(ordem_espectro, "Centro")
cores_espectro <- setNames(
  scales::viridis_pal(end = 0.95)(length(niveis_cor)),
  niveis_cor
)


# ============================================================================
# 4. MALHA MUNICIPAL + DADOS
# ============================================================================

sf::sf_use_s2(FALSE)   # evita erro ao unir geometrias

# Mesorregião de TODOS os municípios (inclui Fernando de Noronha, que não
# elege prefeito e fica em cinza no mapa)
meso_todos <- lookup_muni(name_muni = "all") |>
  filter(abbrev_state == "PE") |>
  transmute(
    code_muni   = as.integer(code_muni),
    mesorregiao = str_remove(name_meso, " Pernambucan[oa]$")
  )

# Se falhar com 2022, tente year = 2020
mapa_pe <- read_municipality(code_muni = "PE", year = 2022, showProgress = FALSE) |>
  mutate(code_muni = as.integer(code_muni)) |>
  left_join(meso_todos, by = "code_muni") |>
  left_join(
    prefeitos_eleitos |>
      select(code_muni, espectro, SG_PARTIDO, NM_URNA_CANDIDATO),
    by = "code_muni"
  )

# Municípios sem prefeito classificado (esperado: só Fernando de Noronha)
mapa_pe |>
  st_drop_geometry() |>
  filter(is.na(espectro)) |>
  select(code_muni, name_muni) |>
  print()

# Contorno das mesorregiões
mapa_meso <- mapa_pe |>
  group_by(mesorregiao) |>
  summarise(.groups = "drop")


# ============================================================================
# 5. MAPA
# ============================================================================

p_mapa <- ggplot() +
  geom_sf(data = mapa_pe, aes(fill = espectro),
          colour = "white", linewidth = 0.1) +
  geom_sf(data = mapa_meso, fill = NA,
          colour = "grey15", linewidth = 0.5) +
  scale_fill_manual(
    values   = cores_espectro,
    breaks   = niveis_cor,
    name     = "Espectro ideológico",
    drop     = FALSE,
    na.value = "grey85"
  ) +
  labs(
    title    = "Espectro ideológico dos prefeitos eleitos em Pernambuco",
    subtitle = "2024. Partido do prefeito eleito; linhas escuras = mesorregiões",
    caption  = paste0("Espectro: Bolognesi et al. (2025). Malha: IBGE. ",
                      "Cinza = sem eleição (Fernando de Noronha)")
  ) +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(nrow = 1))

p_mapa

ggsave(file.path(pasta_saida, "mapa_prefeitos_espectro.png"),
       p_mapa, width = 8, height = 7, dpi = 200, bg = "white")


# ============================================================================
# 6. DIAGNÓSTICO: PREFEITOS ELEITOS POR PARTIDO E MESORREGIÃO
# ============================================================================

tabela_prefeitos <- prefeitos_eleitos |>
  count(SG_PARTIDO, espectro, mesorregiao) |>
  pivot_wider(names_from = mesorregiao, values_from = n, values_fill = 0) |>
  mutate(
    Total    = rowSums(across(where(is.numeric))),
    espectro = as.character(espectro)
  ) |>
  arrange(desc(Total))

linha_total <- tabela_prefeitos |>
  summarise(across(where(is.numeric), sum)) |>
  mutate(SG_PARTIDO = "Total", espectro = "")

tabela_final <- bind_rows(tabela_prefeitos, linha_total) |>
  rename(Partido = SG_PARTIDO, Espectro = espectro)

print(tabela_final, n = Inf, width = Inf)   # a linha "Total" deve dar 184

write_csv(tabela_final,
          file.path(pasta_saida, "tabela_prefeitos_partido_meso.csv"))


# ============================================================================
# NOTAS
# ============================================================================
# - Fernando de Noronha é o único município esperado em cinza.
# - O mapa tem 6 cores: a categoria "Centro" fica vazia (achado do artigo).
# - SG_PARTIDO é o partido do candidato eleito, não a coligação. Prefeitos de
#   partidos pequenos podem ter sido eleitos com apoio de outros campos.
# - A classificação de Bolognesi et al. (2025) é de 2022; o PRD é estimativa.
# ============================================================================
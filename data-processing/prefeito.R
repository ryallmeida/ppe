# ============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES
# ============================================================================
# data-processing-prefeitos.R
#
# OBJETIVO
#   Ler a votação por CANDIDATO e zona eleitoral (TSE, 2024, PE), manter só
#   os candidatos a Prefeito que foram ELEITOS e anexar:
#     - o código IBGE e a mesorregião do município;
#     - a classificação ideológica do partido (Bolognesi et al., 2025).
#
# SAÍDA (fim do script)
#   prefeitos_eleitos -> tibble com UM prefeito eleito por município
#                        (salvo em data/prefeitos_eleitos.csv e .rds)
#
#   Colunas de prefeitos_eleitos:
#     ANO_ELEICAO, SG_UF, SG_UE, NM_UE, CD_MUNICIPIO (código TSE),
#     NM_MUNICIPIO, code_muni (código IBGE), mesorregiao,
#     NR_TURNO (turno em que foi eleito), SQ_CANDIDATO, NM_URNA_CANDIDATO,
#     SG_PARTIDO, ideologia_media, espectro,
#     votos_candidato, votos_validos_turno, pct_votos
#
# Testado com R >= 4.1 (usa |>).
# ============================================================================

rm(list = ls())
cat("\014")


# ============================================================================
# 0. CONFIGURAÇÃO
# ============================================================================

zip_path      <- "C:/Users/ryall/Downloads/votacao_candidato_munzona_2024.zip"
pasta_destino <- "C:/Users/ryall/Downloads/votacao_candidato_munzona_2024"
arquivo_pe    <- "votacao_candidato_munzona_2024_PE.csv"

cargo_alvo  <- "Prefeito"     # Vice-prefeito é outro cargo e fica de fora
n_esperado  <- 184            # 185 municípios; Fernando de Noronha não elege prefeito

url_tse_ibge <- paste0(
  "https://raw.githubusercontent.com/betafcc/",
  "Municipios-Brasileiros-TSE/master/municipios_brasileiros_tse.csv"
)

ordem_meso <- c("Metropolitana de Recife", "Mata", "Agreste",
                "Sertão", "São Francisco")

ordem_espectro <- c("Extrema esquerda", "Esquerda", "Centro-esquerda",
                    "Centro", "Centro-direita", "Direita", "Extrema direita")


# ============================================================================
# 1. PACOTES
# ============================================================================

if (!require(pacman)) {
  install.packages("pacman")
}

pacman::p_load(tidyverse, 
               geobr)


# ============================================================================
# 2. DESCOMPACTAR E LER (LEIAME do TSE: Latin-1, ";", aspas, #NULO/#NE)
# ============================================================================

stopifnot(file.exists(zip_path))
dir.create(pasta_destino, showWarnings = FALSE, recursive = TRUE)

conteudo_zip <- unzip(zip_path, list = TRUE)$Name
if (!arquivo_pe %in% conteudo_zip) {
  stop("Arquivo não encontrado no ZIP: ", arquivo_pe,
       "\nConteúdo do ZIP: ", paste(conteudo_zip, collapse = ", "))
}
unzip(zip_path, files = arquivo_pe, exdir = pasta_destino, overwrite = TRUE)

ler_tse <- function(caminho) {
  message("Lendo: ", basename(caminho))
  
  df <- read_delim(
    caminho,
    delim     = ";",
    quote     = "\"",
    locale    = locale(encoding = "Latin1"),
    col_types = cols(.default = col_character()),   # tudo texto; converte depois
    na        = c("", "NA", "#NULO", "#NULO#", "#NE"),
    trim_ws   = TRUE,
    progress  = FALSE
  )
  
  # Só colunas de contagem (QT_*) e de ano/turno viram número.
  # Identificadores (SQ_CANDIDATO, CD_MUNICIPIO, ...) permanecem texto.
  cols_num <- names(df)[str_detect(names(df), "^QT_") |
                          names(df) %in% c("ANO_ELEICAO", "NR_TURNO")]
  
  df |>
    mutate(across(all_of(cols_num), ~ suppressWarnings(as.numeric(.x)))) |>
    # -1 (#NULO) e -3 (#NE) são códigos de ausência nos campos numéricos
    mutate(across(starts_with("QT_"), ~ if_else(.x %in% c(-1, -3), NA_real_, .x)))
}

cand_pe <- ler_tse(file.path(pasta_destino, arquivo_pe))
glimpse(cand_pe)

# Falha cedo, mostrando as colunas reais, se o layout for diferente do esperado
colunas_necessarias <- c(
  "ANO_ELEICAO", "NR_TURNO", "SG_UF", "SG_UE", "NM_UE",
  "CD_MUNICIPIO", "NM_MUNICIPIO", "DS_CARGO",
  "SQ_CANDIDATO", "NM_URNA_CANDIDATO", "SG_PARTIDO",
  "DS_SIT_TOT_TURNO", "QT_VOTOS_NOMINAIS_VALIDOS"
)
faltando <- setdiff(colunas_necessarias, names(cand_pe))
if (length(faltando) > 0) {
  stop("Colunas ausentes: ", paste(faltando, collapse = ", "),
       "\nColunas disponíveis: ", paste(names(cand_pe), collapse = ", "))
}

# Inspeção dos valores que vão guiar o filtro
count(cand_pe, DS_CARGO)
cand_pe |>
  filter(str_to_upper(DS_CARGO) == str_to_upper(cargo_alvo)) |>
  count(NR_TURNO, DS_SIT_TOT_TURNO)


# ============================================================================
# 3. CLASSIFICAÇÃO IDEOLÓGICA (Bolognesi et al., 2025)
#    Mesma tabela do data-processing.R (votação por partido).
#    PRD não consta no artigo: valor é estimativa própria.
# ============================================================================

classif_ideologia <- tribble(
  ~SG_PARTIDO,     ~ideologia_media, ~espectro,
  "PSTU",           0.525, "Extrema esquerda",
  "PCO",            0.566, "Extrema esquerda",
  "PCB",            0.711, "Extrema esquerda",
  "PSOL",           1.453, "Extrema esquerda",
  "UP",             1.679, "Esquerda",
  "PC do B",        1.834, "Esquerda",
  "PT",             2.761, "Esquerda",
  "PSB",            3.699, "Centro-esquerda",
  "REDE",           3.802, "Centro-esquerda",
  "PDT",            3.977, "Centro-esquerda",
  "PV",             4.245, "Centro-esquerda",
  "SOLIDARIEDADE",  6.193, "Centro-direita",
  "CIDADANIA",      6.358, "Centro-direita",
  "AVANTE",         6.667, "Centro-direita",
  "MDB",            6.698, "Centro-direita",
  "MOBILIZA",       6.945, "Centro-direita",
  "PSDB",           6.966, "Centro-direita",
  "PSD",            7.151, "Direita",
  "PMB",            7.512, "Direita",
  "PODE",           7.666, "Direita",
  "PRTB",           7.718, "Direita",
  "AGIR",           7.780, "Direita",
  "PP",             8.398, "Direita",
  "DC",             8.460, "Direita",
  "REPUBLICANOS",   8.584, "Extrema direita",
  "UNIÃO",          8.749, "Extrema direita",
  "NOVO",           8.934, "Extrema direita",
  "PL",             9.068, "Extrema direita",
  "PRD",            8.409, "Direita"   # estimativa
) |>
  mutate(espectro = factor(espectro, levels = ordem_espectro))


# ============================================================================
# 4. CANDIDATO x TURNO (o arquivo original tem uma linha por zona eleitoral)
# ============================================================================

prefeitos_cand <- cand_pe |>
  filter(str_to_upper(DS_CARGO) == str_to_upper(cargo_alvo)) |>
  group_by(ANO_ELEICAO, SG_UF, SG_UE, NM_UE, CD_MUNICIPIO, NM_MUNICIPIO,
           NR_TURNO, SQ_CANDIDATO, NM_URNA_CANDIDATO, SG_PARTIDO) |>
  summarise(
    situacao        = first(DS_SIT_TOT_TURNO),
    n_situacoes     = n_distinct(DS_SIT_TOT_TURNO),
    votos_candidato = sum(QT_VOTOS_NOMINAIS_VALIDOS, na.rm = TRUE),
    .groups = "drop"
  )

# A situação precisa ser única por candidato e turno (senão a soma por zona mente)
stopifnot(all(prefeitos_cand$n_situacoes == 1))

# Votos válidos do município em cada turno e % do candidato
prefeitos_cand <- prefeitos_cand |>
  group_by(CD_MUNICIPIO, NR_TURNO) |>
  mutate(
    votos_validos_turno = sum(votos_candidato),
    pct_votos           = 100 * votos_candidato / votos_validos_turno
  ) |>
  ungroup()


# ============================================================================
# 5. SÓ OS ELEITOS (1º turno OU 2º turno)
#    Em municípios com 2º turno, os finalistas aparecem como "2º turno" no
#    1º turno, e o eleito aparece como "ELEITO" no 2º.
# ============================================================================

prefeitos_eleitos_bruto <- prefeitos_cand |>
  filter(str_detect(str_to_upper(situacao), "^ELEITO"))

# Conferências
por_municipio <- count(prefeitos_eleitos_bruto, CD_MUNICIPIO)
if (any(por_municipio$n > 1)) {
  print(filter(prefeitos_eleitos_bruto,
               CD_MUNICIPIO %in% por_municipio$CD_MUNICIPIO[por_municipio$n > 1]))
  stop("Há município com mais de um prefeito eleito. Veja a tabela acima.")
}
if (nrow(por_municipio) != n_esperado) {
  warning("Municípios com prefeito eleito: ", nrow(por_municipio),
          " (esperado: ", n_esperado, ")")
}
count(prefeitos_eleitos_bruto, NR_TURNO)   # quantos foram decididos em cada turno


# ============================================================================
# 6. CÓDIGO TSE -> CÓDIGO IBGE -> MESORREGIÃO
#    O CD_MUNICIPIO do TSE NÃO é o código do IBGE.
# ============================================================================

tse_ibge <- read_csv(url_tse_ibge, show_col_types = FALSE) |>
  transmute(
    CD_MUNICIPIO = as.integer(codigo_tse),
    code_muni    = as.integer(codigo_ibge)
  )

meso_pe <- lookup_muni(name_muni = "all") |>
  filter(abbrev_state == "PE") |>
  transmute(
    code_muni   = as.integer(code_muni),
    mesorregiao = name_meso
  )


# ============================================================================
# 7. JUNTAR TUDO -> prefeitos_eleitos
# ============================================================================

prefeitos_eleitos <- prefeitos_eleitos_bruto |>
  mutate(CD_MUNICIPIO = as.integer(CD_MUNICIPIO)) |>
  left_join(tse_ibge,          by = "CD_MUNICIPIO") |>
  left_join(meso_pe,           by = "code_muni") |>
  left_join(classif_ideologia, by = "SG_PARTIDO") |>
  mutate(
    mesorregiao = str_remove(as.character(mesorregiao), " Pernambucan[oa]$"),
    mesorregiao = factor(mesorregiao, levels = ordem_meso)
  ) |>
  select(ANO_ELEICAO, SG_UF, SG_UE, NM_UE, CD_MUNICIPIO, NM_MUNICIPIO,
         code_muni, mesorregiao, NR_TURNO, SQ_CANDIDATO, NM_URNA_CANDIDATO,
         SG_PARTIDO, ideologia_media, espectro,
         votos_candidato, votos_validos_turno, pct_votos)

# Conferências (os três resultados devem ser vazios)
sem_ibge <- prefeitos_eleitos |> filter(is.na(code_muni))   |> distinct(CD_MUNICIPIO, NM_UE)
sem_meso <- prefeitos_eleitos |> filter(is.na(mesorregiao)) |> distinct(CD_MUNICIPIO, NM_UE)
sem_ideo <- prefeitos_eleitos |> filter(is.na(espectro))    |> distinct(SG_PARTIDO)

print(sem_ibge); print(sem_meso); print(sem_ideo)
if (nrow(sem_ibge) + nrow(sem_meso) + nrow(sem_ideo) > 0) {
  stop("Há municípios/partidos sem correspondência. Veja as tabelas acima.")
}

count(prefeitos_eleitos, espectro)
count(prefeitos_eleitos, mesorregiao)
summary(prefeitos_eleitos)


# ============================================================================
# 8. SALVAR
# ============================================================================
dir.create("data", showWarnings = FALSE)

# CSV para o GitHub (UTF-8, vírgula; NA vira célula vazia)
write_csv(prefeitos_eleitos, "data/prefeitos_eleitos.csv", na = "")

# Cópia local em .rds (preserva fatores); não precisa ir ao GitHub
saveRDS(prefeitos_eleitos, "data/prefeitos_eleitos.rds")

message("Salvo: ", nrow(prefeitos_eleitos), " linhas, ",
        ncol(prefeitos_eleitos), " colunas")

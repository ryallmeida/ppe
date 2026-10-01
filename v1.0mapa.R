# ============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES
# ============================================================================
# tutorial-mapa-prefeitos.R
#
# OBJETIVO (didático)
#   Mostrar, passo a passo, como se chega a um mapa ESTÁTICO para artigo:
#   espectro ideológico do partido do prefeito eleito em cada município de
#   Pernambuco (2024). Cada etapa:
#     (i)  diz O QUE está sendo feito e POR QUÊ;
#     (ii) usa funções escritas como  pacote::funcao()  ;
#     (iii) termina com dplyr::glimpse() (ou outra inspeção) para VER o objeto.
#
# SAÍDAS
#   figura_anatomia_mapa.png  -> painel 3x2 com o mapa sendo construído por camadas
#   figura_mapa_final.png/pdf -> figura final, pronta para o artigo
#
# Salve este arquivo em UTF-8 (File > Save with Encoding > UTF-8).
# Testado com R >= 4.1 (usa o pipe nativo |>).
# ============================================================================

rm(list = ls())
cat("\014")

# ============================================================================
# GUIA RÁPIDO DE SINTAXE (leia antes de rodar)
# ============================================================================
#  pacote::funcao()   chama uma função SEM carregar o pacote inteiro.
#                     Ex.: dplyr::glimpse(x). Deixa claro de onde vem cada
#                     função. (Nota: o correto é dplyr::glimpse(); o prefixo
#                     tidyverse:: sozinho não contém as funções.)
#  <-                 atribui um valor a um nome:  x <- 3
#  |>                 "pipe": passa o resultado da esquerda como PRIMEIRO
#                     argumento da função da direita.
#                     x |> f(y)   equivale a   f(x, y)
#  +                  no ggplot2, SOMA camadas ao gráfico, uma sobre a outra.
#  aes()              "estética": liga uma coluna dos dados a um atributo
#                     visual (cor, preenchimento, posição...).
#  dplyr::glimpse()   mostra as colunas, os tipos e as primeiras linhas de
#                     um objeto, na vertical. É a nossa "lupa" em cada passo.
# ============================================================================

# ============================================================================
# 0. CONFIGURAÇÃO E PACOTES
# ============================================================================

url_pref    <- "https://raw.githubusercontent.com/ryallmeida/ppe/refs/heads/main/data/prefeitos_eleitos.csv"
pasta_saida <- "C:/Users/ryall/Downloads"

# Ordem lógica das categorias (da esquerda para a direita no espectro)
ordem_espectro <- c("Extrema esquerda", "Esquerda", "Centro-esquerda",
                    "Centro", "Centro-direita", "Direita", "Extrema direita")

# Instala o que faltar (base::setdiff = "o que está no 1º vetor e não no 2º")
pacotes <- c("dplyr", "readr", "stringr", "ggplot2", "sf", "geobr",
             "scales", "patchwork")
faltam <- base::setdiff(pacotes, base::rownames(utils::installed.packages()))
if (base::length(faltam) > 0) utils::install.packages(faltam)


# ============================================================================
# PASSO 1. LER OS DADOS (readr::read_csv)
#   Pergunta: "o que a tabela contém?"  ->  dplyr::glimpse()
#   col_types força o tipo de cada coluna. Identificadores (códigos) devem
#   ser inteiros ou texto, nunca decimais.
# ============================================================================

base::message("PASSO 1: ler os prefeitos eleitos")

prefeitos_eleitos <- readr::read_csv(
  url_pref,
  col_types = readr::cols(
    CD_MUNICIPIO = readr::col_integer(),
    code_muni    = readr::col_integer(),
    NR_TURNO     = readr::col_integer(),
    SQ_CANDIDATO = readr::col_character(),
    .default     = readr::col_guess()        # as demais: o readr adivinha
  ),
  locale         = readr::locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

dplyr::glimpse(prefeitos_eleitos)

# Procure na saída: <chr> = texto, <int> = inteiro, <dbl> = decimal.
# 'espectro' veio como <chr>: texto simples, sem ordem. Isso é um problema
# (o ggplot ordenaria as categorias em ordem alfabética). Veja o passo 2.


# ============================================================================
# PASSO 2. TRANSFORMAR TEXTO EM FATOR (dplyr::mutate + base::factor)
#   Um FATOR é uma variável categórica com NÍVEIS ordenados.
#   mutate(nova = expressão) cria ou sobrescreve uma coluna.
# ============================================================================

base::message("PASSO 2: transformar 'espectro' em fator ordenado")

prefeitos_eleitos <- prefeitos_eleitos |>
  dplyr::mutate(
    espectro = base::factor(espectro, levels = ordem_espectro)
  )

dplyr::glimpse(prefeitos_eleitos)            # agora: espectro <fct>
base::levels(prefeitos_eleitos$espectro)     # os 7 níveis, na ordem definida

# Quantos prefeitos por categoria?  .drop = FALSE mantém níveis com 0.
dplyr::count(prefeitos_eleitos, espectro, .drop = FALSE)
# Repare: "Centro" = 0. Nenhum prefeito eleito é de partido classificado
# como centro (Bolognesi et al., 2025). O nível existe, mas está vazio.

# Checagem que INTERROMPE o script se algo estiver errado
base::stopifnot(
  base::nrow(prefeitos_eleitos) > 0,
  !base::anyNA(prefeitos_eleitos$espectro)   
  # NA aqui = categoria escrita errado
)

# ============================================================================
# PASSO 3. DEFINIR AS CORES (scales::viridis_pal)
#   Regra de ouro: cada categoria tem SEMPRE a mesma cor, em todas as figuras.
#   Um vetor NOMEADO faz essa ligação: c("Esquerda" = "#...", ...).
#   Viridis: legível em impressão P&B e por pessoas com daltonismo.
# ============================================================================
base::message("PASSO 3: paleta fixa por categoria")

niveis_cor <- base::setdiff(ordem_espectro, "Centro")    
# tira o nível vazio

cores_espectro <- stats::setNames(
  scales::viridis_pal(end = 0.95)(base::length(niveis_cor)),  # 6 cores
  niveis_cor                                                  # nomes
)

# stats::setNames(vetor, nomes) cola um nome em cada elemento do vetor, pela ordem: 1ª cor -> 1º nome, e assim por diante.
# scales::viridis_pal(end = 0.95) devolve uma FUNÇÃO geradora de cores (end = 0.95 corta o amarelo final, que some no fundo branco);
# o 2º parêntese (n) a executa e pede n cores, e base::length(niveis_cor) dá o n (6).

utils::str(cores_espectro)       
# vetor nomeado: nome -> código hexadecimal


# ============================================================================
# PASSO 4. LER A MALHA MUNICIPAL (geobr::read_municipality)
#   Um objeto 'sf' (simple features) é uma tabela comum COM uma coluna
#   especial, 'geom', que guarda o desenho (polígono) de cada linha.
# ============================================================================
base::message("PASSO 4: malha municipal do IBGE")

mapa_bruto <- geobr::read_municipality(code_muni = "PE", 
                                       year = 2022,
                                       showProgress = TRUE)

# Se falhar com 2022, tente year = 2020.
# a literatura mostra que ele é mais estável

dplyr::glimpse(mapa_bruto)                  
# note a coluna 'geom' <MULTIPOLYGON>

base::class(mapa_bruto)                     
# "sf" "tbl_df" ... = tabela + geometria

base::table(sf::st_geometry_type(mapa_bruto))   
# tipos de geometria presentes


# ============================================================================
# PASSO 5. PREPARAR A MALHA (dplyr::mutate + dplyr::filter)
#   - as.integer(): o código do IBGE precisa do MESMO tipo nos dois lados da
#     junção (passo 6), senão o join não encontra correspondência.
#   - filter() mantém só as linhas em que a condição é VERDADEIRA.
#   - Fernando de Noronha não elege prefeito: sai do mapa.
# ============================================================================
base::message("PASSO 5: ajustar tipos e retirar Fernando de Noronha")

n_antes <- base::nrow(mapa_bruto)

mapa_pe <- mapa_bruto |>
  dplyr::mutate(code_muni = base::as.integer(code_muni)) |>
  dplyr::filter(!stringr::str_detect(name_muni, "Noronha"))   # ! = NÃO

base::cat("Municípios antes:", n_antes, "| depois:", base::nrow(mapa_pe), "\n")
dplyr::glimpse(mapa_pe)


# ============================================================================
# PASSO 6. JUNTAR AS TABELAS (dplyr::left_join)
#   left_join(x, y, by = "chave") mantém TODAS as linhas de x (a malha) e
#   acrescenta as colunas de y (os prefeitos) onde a chave for igual.
#   Sem correspondência  ->  NA.  Por isso conferimos depois.
# ============================================================================
base::message("PASSO 6: juntar malha + prefeito eleito")

mapa_pe <- mapa_pe |>
  dplyr::left_join(
    prefeitos_eleitos |> dplyr::select(code_muni, espectro, SG_PARTIDO),
    by = "code_muni"
  )

dplyr::glimpse(mapa_pe)                    # agora com 'espectro' e 'SG_PARTIDO'

# Conferência: algum município ficou sem prefeito? (deve ser 0 linhas)
sem_prefeito <- mapa_pe |>
  sf::st_drop_geometry() |>                # tira o desenho: fica só a tabela
  dplyr::filter(base::is.na(espectro)) |>
  dplyr::select(code_muni, name_muni)

dplyr::glimpse(sem_prefeito)
base::stopifnot(base::nrow(sem_prefeito) == 0)

# Distribuição final (o que o mapa vai mostrar)
mapa_pe |>
  sf::st_drop_geometry() |>
  dplyr::count(espectro, .drop = FALSE) |>
  dplyr::glimpse()


# ============================================================================
# PASSO 7. CONSTRUIR O GRÁFICO POR CAMADAS (ggplot2)
#   A gramática dos gráficos: dados + estéticas + geometrias + escalas + tema.
#   Cada painel abaixo ACRESCENTA UMA COISA ao anterior (com +).
#   Acompanhe a figura 'figura_anatomia_mapa.png' que sai no fim.
# ============================================================================
base::message("PASSO 7: construir o mapa em camadas")

# Ajuste só de tamanho do título dos painéis
tema_painel <- ggplot2::theme(
  plot.title = ggplot2::element_text(size = 10, face = "bold")
)

# --- A. Só a geometria ------------------------------------------------------
# ggplot(data = ...) cria a "tela" e diz de onde vêm os dados.
# geom_sf() desenha os polígonos da coluna 'geom'.
p_a <- ggplot2::ggplot(data = mapa_pe) +
  ggplot2::geom_sf() +
  ggplot2::ggtitle("A. Dados + geom_sf(): só a geometria") +
  ggplot2::theme(legend.position = "none") +
  tema_painel

# --- B. Liga a cor à variável (aes) ----------------------------------------
# aes(fill = espectro): "pinte cada polígono conforme a coluna 'espectro'".
# Sem escala definida, o ggplot usa a paleta PADRÃO (nada científica).
p_b <- ggplot2::ggplot(data = mapa_pe) +
  ggplot2::geom_sf(ggplot2::aes(fill = espectro)) +
  ggplot2::ggtitle("B. + aes(fill = espectro): paleta padrão") +
  ggplot2::theme(legend.position = "none") +
  tema_painel

# --- C. Escala de cores manual (viridis fixo) -------------------------------
# scale_fill_manual(values = vetor nomeado) troca a paleta padrão.
# drop = FALSE mantém todas as categorias na legenda, mesmo as sem polígonos.
p_c <- ggplot2::ggplot(data = mapa_pe) +
  ggplot2::geom_sf(ggplot2::aes(fill = espectro)) +
  ggplot2::scale_fill_manual(values = cores_espectro, breaks = niveis_cor,
                             drop = FALSE) +
  ggplot2::ggtitle("C. + scale_fill_manual(): viridis fixo") +
  ggplot2::theme(legend.position = "none") +
  tema_painel

# --- D. Bordas finas e brancas ---------------------------------------------
# Argumentos FORA do aes() valem para todos os polígonos (constantes):
# colour = cor da borda; linewidth = espessura.
p_d <- ggplot2::ggplot(data = mapa_pe) +
  ggplot2::geom_sf(ggplot2::aes(fill = espectro),
                   colour = "white", linewidth = 0.15) +
  ggplot2::scale_fill_manual(values = cores_espectro, breaks = niveis_cor,
                             drop = FALSE) +
  ggplot2::ggtitle("D. + colour e linewidth: bordas") +
  ggplot2::theme(legend.position = "none") +
  tema_painel

# --- E. Tema sem eixos -----------------------------------------------------
# Em mapas, latitude/longitude e grade raramente ajudam. theme_void() remove.
p_e <- p_d +
  ggplot2::theme_void(base_size = 10) +
  ggplot2::ggtitle("E. + theme_void(): sem eixos nem fundo") +
  ggplot2::theme(legend.position = "none") +
  tema_painel

# --- F. Legenda embaixo ----------------------------------------------------
# theme(legend.position = ...) move a legenda;
# guides(fill = guide_legend(nrow = 2)) organiza os itens em 2 linhas.
p_f <- p_e +
  ggplot2::labs(fill = "Espectro") +
  ggplot2::theme(
    legend.position = "bottom",
    legend.title    = ggplot2::element_text(size = 8),
    legend.text     = ggplot2::element_text(size = 7)
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2)) +
  ggplot2::ggtitle("F. + legenda: theme() e guides()") +
  tema_painel

# Inspecionar um gráfico: ele também é um objeto (uma lista)!
base::class(p_f)
dplyr::glimpse(p_f$layers[[1]]$aes_params)     # parâmetros constantes da camada 1


# ============================================================================
# PASSO 8. JUNTAR OS PAINÉIS (patchwork::wrap_plots)
#   patchwork monta vários gráficos em uma figura; plot_annotation() dá
#   título, subtítulo e fonte ao conjunto.
# ============================================================================
base::message("PASSO 8: painel 'anatomia do gráfico'")

figura_anatomia <- patchwork::wrap_plots(
  list(p_a, p_b, p_c, p_d, p_e, p_f),
  ncol = 3
) +
  patchwork::plot_annotation(
    title    = "Como se constrói o mapa, camada por camada",
    subtitle = "Cada painel acrescenta um elemento ao anterior (operador +)",
    caption  = "Espectro: Bolognesi et al. (2025). Malha: IBGE. Prefeitos: TSE (2024)."
  )

figura_anatomia

ggplot2::ggsave(
  filename = base::file.path(pasta_saida, "figura_anatomia_mapa.png"),
  plot = figura_anatomia, width = 12, height = 9, dpi = 300, bg = "white"
)


# ============================================================================
# PASSO 9. FIGURA FINAL PARA O ARTIGO
#   labs() define título, subtítulo, fonte; o mapa ganha a forma definitiva.
#   Para publicação: fundo branco, 300 dpi (PNG) e uma versão vetorial (PDF).
# ============================================================================
base::message("PASSO 9: figura final")

p_final <- ggplot2::ggplot(data = mapa_pe) +
  ggplot2::geom_sf(ggplot2::aes(fill = espectro),
                   colour = "white", linewidth = 0.15) +
  ggplot2::scale_fill_manual(values = cores_espectro, breaks = niveis_cor,
                             name = "Espectro ideológico", drop = FALSE) +
  ggplot2::labs(
    title    = "Espectro ideológico dos prefeitos eleitos em Pernambuco",
    subtitle = "2024. Cada polígono = um município; cor = partido do prefeito eleito",
    caption  = base::paste0("Fonte: TSE (2024); malha municipal: IBGE; ",
                            "classificação: Bolognesi et al. (2025). ",
                            "Fernando de Noronha não elege prefeito e não entra.")
  ) +
  ggplot2::theme_void(base_size = 12) +
  ggplot2::theme(
    legend.position = "bottom",
    plot.title      = ggplot2::element_text(face = "bold"),
    plot.caption    = ggplot2::element_text(size = 8, hjust = 0)
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(nrow = 1))

p_final

ggplot2::ggsave(base::file.path(pasta_saida, "figura_mapa_final.png"),
                p_final, width = 8, height = 7, dpi = 300, bg = "white")

# PDF vetorial (acentos corretos com cairo_pdf)
ggplot2::ggsave(base::file.path(pasta_saida, "figura_mapa_final.pdf"),
                p_final, width = 8, height = 7, device = grDevices::cairo_pdf)


# ============================================================================
# PASSO 10. REGISTRAR O AMBIENTE (reprodutibilidade)
#   Versões de R e dos pacotes: cole isto num apêndice do trabalho.
# ============================================================================
utils::sessionInfo()


# ============================================================================
# EXERCÍCIOS (para entender a sintaxe)
# ============================================================================
# 1. No passo 7-C, troque cores_espectro por scale_fill_viridis_d(). O que
#    muda na legenda? Por que a cor fixa por nome é mais segura?
# 2. No passo 6, troque left_join por inner_join e rode dplyr::glimpse().
#    O que acontece com o número de municípios se algum não casar?
# 3. No passo 5, remova a linha do filter() e veja Fernando de Noronha
#    ficar sem cor (NA) e o stopifnot() do passo 6 interromper o script.
# 4. No passo 2, apague levels = ordem_espectro e veja em que ordem o
#    ggplot coloca as categorias na legenda.
# ============================================================================
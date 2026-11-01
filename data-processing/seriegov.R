# ==============================================================================
# Universidade Federal de Pernambuco (UFPE)
# Departamento de Ciência Política
# Disciplina: Partidos Políticos e Eleições
#
# ARQUIVO: seriegov.R
#   (versão final: electionsBR para 1998–2022 e arquivo local para 1994)
#
# OBJETIVO (didático):
#   Reproduzir, para a eleição de governador de Pernambuco, a lógica das
#   Figuras 1 e 2 de Reed (1990): a porcentagem de votos de cada candidato
#   segundo a sua ORDEM DE CHEGADA (1º, 2º, 3º lugar...).
#   Pergunta: aparece uma "queda" entre o 2º colocado (n + 1, com n = 1 vaga)
#   e o 3º colocado (n + 2), como a lei de Reed prevê?
#
#   ATENÇÃO SUBSTANTIVA:
#   - Reed tira a MÉDIA de muitos distritos do mesmo tamanho. Aqui há UM só
#     "distrito" (o estado) por eleição, então cada linha do gráfico é UMA
#     eleição, e não uma média.
#   - Reed estuda eleição em TURNO ÚNICO. Governador tem dois turnos; usamos
#     o 1º turno, mas a regra de dois turnos muda os incentivos. Trate o
#     resultado como exploração, não como teste do modelo de Reed.
#
# SAÍDAS (pasta "saidas/"):
#   - figura_1_ordem_chegada_paineis.png  (painéis A–D, construção por camadas)
#   - figura_1_ordem_chegada_final.png / .pdf
#   - figura_2_ordem_ao_longo_do_tempo_paineis.png (painéis E–F)
#   - figura_2_ordem_ao_longo_do_tempo_final.png / .pdf
#   - numero_efetivo_candidatos_pe.csv
#
# CORREÇÃO DE 1998: nesse ano o electionsBR traz QT_VOTOS_NOMINAIS zerada;
#   os votos estão em QT_VOTOS_NOMINAIS_VALIDOS. O Passo 3b substitui as
#   linhas de 1998 usando a tabela bruta (dados_cache/bruto_PE_1998.rds),
#   criada pelo script diagnostico_votos_1998.R. Rode aquele script antes.
#   E na pasta "dados_cache/": um .rds pequeno por ano, cargo e estado
#   (ex.: cargo3_PE_2018.rds), para não baixar tudo de novo quando você rodar outra vez.
#
# SOBRE OS DADOS:
#   1994: o electionsBR não aceita esse ano; o arquivo foi baixado
#   manualmente do TSE e é lido do computador (ver arquivos_locais).
#   Demais anos: o electionsBR está no CRAN, mas os DADOS não ficam no CRAN: a cada
#   chamada, o pacote baixa o arquivo oficial do TSE para uma pasta
#   temporária e o lê. A reprodutibilidade vem de usar uma função
#   padronizada e versionada (registrada no sessionInfo, no passo final).
#
# CODIFICAÇÃO: salve e abra este arquivo em UTF-8.
# VERSÃO MÍNIMA DO R: 4.1 (por causa do pipe nativo |> ).
# ==============================================================================


# ==============================================================================
# GUIA RÁPIDO DE SINTAXE (só o que aparece neste script)
# ------------------------------------------------------------------------------
# pacote::funcao()   chama a função 'funcao' do pacote 'pacote' sem carregar
#                    o pacote inteiro. Ex.: dplyr::filter(). Deixa explícito
#                    de onde vem cada função.
# objeto <- valor    atribuição: guarda 'valor' no nome 'objeto'.
# x |> f()           pipe nativo: passa 'x' como primeiro argumento de f().
#                    Leia como "e então". x |> f() |> g() = g(f(x)).
# function(a) {...}  cria uma função. O último valor calculado é devolvido.
# if (condição) {...} executa o bloco só se a condição for verdadeira.
# c(1, 2, 3)         cria um vetor (uma fila de valores do mesmo tipo).
# ==, !=, %in%       comparações: igual, diferente, "está contido em".
# !                  negação: !TRUE é FALSE.
# lista[[i]]         pega o i-ésimo elemento de uma lista.
# ggplot2: +         no ggplot2, '+' acrescenta uma CAMADA ao gráfico.
# aes()              "estética": diz qual coluna vai para x, y, cor, grupo.
# ==============================================================================


# ==============================================================================
# PASSO 0: CONFIGURAÇÃO E PACOTES
# ------------------------------------------------------------------------------
# Tudo que você pode querer mudar fica aqui em cima: anos, estado, cargo,
# número de vagas, caminhos e URL.
# ==============================================================================
base::message("PASSO 0: configuração e pacotes")

# Pacotes necessários. Instala apenas os que faltarem.
pacotes <- c("electionsBR", "readr", "dplyr", "ggplot2", "patchwork", "viridisLite")
pacotes_faltando <- base::setdiff(pacotes, base::rownames(utils::installed.packages()))
if (base::length(pacotes_faltando) > 0) {
  utils::install.packages(pacotes_faltando)
}

# Parâmetros da análise
anos_eleicao   <- c(1994, 1998, 2002, 2006, 2010, 2014, 2018, 2022)

# Anos que o electionsBR não fornece e que você baixou manualmente do TSE.
# O NOME de cada elemento é o ano; o VALOR é o caminho do arquivo.
# Atenção: no R, use barras normais "/" no caminho do Windows (ou barra
# invertida dupla "\\"). Uma barra invertida simples "\" dá erro, porque o
# R a lê como início de um caractere especial (como "\n", quebra de linha).
arquivos_locais <- c(
  "1994" = "C:/Users/ryall/Downloads/votacao_candidato_munzona_1994_PE.csv"
)
utils::str(arquivos_locais)

# Anos em que os votos NÃO estão em QT_VOTOS_NOMINAIS (descoberto com o
# script diagnostico_votos_1998.R). NOME = ano; VALOR = coluna certa.
# A correção é feita no Passo 3b, a partir da tabela bruta salva no cache.
anos_com_coluna_de_votos_alternativa <- c(
  "1998" = "QT_VOTOS_NOMINAIS_VALIDOS"
)
utils::str(anos_com_coluna_de_votos_alternativa)
sigla_uf       <- "PE"
codigo_cargo   <- "3"   # 3 = Governador no padrão do TSE
turno_analisado <- "1"  # 1º turno (Reed analisa turno único)
numero_vagas   <- 1     # n: governador elege 1 pessoa
posicoes_figura_2 <- 1:4  # posições acompanhadas ao longo do tempo (Figura 2)

# Caminhos
pasta_cache  <- "dados_cache"   # guarda só o recorte de PE/governador (.rds)
pasta_saidas <- "saidas"
base::dir.create(pasta_cache,  showWarnings = FALSE)
base::dir.create(pasta_saidas, showWarnings = FALSE)

# TRUE: reaproveita o .rds se ele já existir. FALSE: sempre baixa de novo.
usar_cache <- TRUE

# O electionsBR baixa o zip do TSE com o país inteiro: aumentamos o tempo
# máximo de download (segundos).
base::options(timeout = 1200)

# Versão do pacote: anote no seu trabalho, junto com a data de execução.
utils::str(base::as.character(utils::packageVersion("electionsBR")))

# Cores: viridis, sempre a mesma cor para o mesmo ano (vetor nomeado).
cores_por_ano <- stats::setNames(
  viridisLite::viridis(base::length(anos_eleicao), end = 0.9),
  base::as.character(anos_eleicao)
)
utils::str(cores_por_ano)

# Cores das posições na Figura 2 (1º, 2º, 3º, 4º lugar).
rotulos_posicao <- base::paste0(posicoes_figura_2, "º lugar")
cores_por_posicao <- stats::setNames(
  viridisLite::viridis(base::length(posicoes_figura_2), end = 0.9),
  rotulos_posicao
)
utils::str(cores_por_posicao)

# Colunas que precisamos encontrar nos arquivos do TSE.
# Se você mudar esta lista, o cache antigo é descartado automaticamente
# (ver Passo 1c).
colunas_necessarias <- c("ANO_ELEICAO",
                         "NR_TURNO",
                         "SG_UF",
                         "CD_CARGO",
                         "SQ_CANDIDATO",
                         "NM_URNA_CANDIDATO",
                         "SG_PARTIDO",
                         "QT_VOTOS_NOMINAIS",
                         "NR_ZONA",
                         "CD_MUNICIPIO",
                         "NM_MUNICIPIO")


# ==============================================================================
# PASSO 1: FUNÇÕES PARA OBTER UM ANO (electionsBR OU ARQUIVO LOCAL)
# ------------------------------------------------------------------------------
# O QUE FAZ: para cada ano, lê os dados de uma de duas fontes:
#   - arquivo baixado manualmente (anos listados em arquivos_locais, ex.: 1994);
#   - electionsBR (demais anos).
# Depois, as DUAS fontes passam pela MESMA padronização e conferência, e o
# recorte (cargo + estado) é guardado num .rds pequeno (cache).
# POR QUÊ: separar "ler" de "padronizar" evita código duplicado e garante que
# 1994 seja tratado exatamente como os outros anos.
# FUNÇÕES PRINCIPAIS: readr::read_delim() lê o CSV local (separado por ";",
# codificação latin1, como os arquivos do TSE); electionsBR::elections_tse()
# baixa os demais anos.
# ==============================================================================
base::message("PASSO 1: definindo as funções de leitura")

# 1a. Lê um CSV do TSE salvo no computador.
ler_csv_local <- function(caminho, ano) {
  if (!base::file.exists(caminho)) {
    base::stop("Ano ", ano, ": arquivo não encontrado em ", caminho,
               ". Confira o caminho em arquivos_locais (Passo 0).")
  }
  tabela <- readr::read_delim(
    caminho,
    delim = ";",
    locale = readr::locale(encoding = "latin1"),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )
  base::message("  ", ano, ": arquivo local lido. Estrutura:")
  dplyr::glimpse(tabela)
  tabela
}

# 1b. Confere e padroniza qualquer tabela, venha de onde vier.
padronizar_recorte <- function(tabela, ano) {
  if (base::is.null(tabela) || base::nrow(tabela) == 0) {
    base::stop("Ano ", ano, ": tabela vazia.")
  }
  
  colunas_ausentes <- base::setdiff(colunas_necessarias, base::names(tabela))
  if (base::length(colunas_ausentes) > 0) {
    base::stop("Ano ", ano, ": faltam as colunas ",
               base::paste(colunas_ausentes, collapse = ", "),
               ".\nColunas disponíveis: ", base::paste(base::names(tabela), collapse = ", "))
  }
  
  recorte <- tabela |>
    dplyr::select(dplyr::all_of(colunas_necessarias)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), base::as.character)) |>
    dplyr::filter(CD_CARGO == codigo_cargo, SG_UF == sigla_uf)
  
  if (base::nrow(recorte) == 0) {
    base::stop("Ano ", ano, ": nenhuma linha com CD_CARGO == ", codigo_cargo,
               " e SG_UF == ", sigla_uf, ". Cargos encontrados: ",
               base::paste(base::sort(base::unique(base::as.character(tabela$CD_CARGO))), collapse = ", "),
               ". UFs encontradas: ",
               base::paste(base::sort(base::unique(base::as.character(tabela$SG_UF))), collapse = ", "))
  }
  recorte
}

# 1c. Decide a fonte, padroniza e usa o cache.
ler_votacao_ano <- function(ano) {
  arquivo_cache <- base::file.path(pasta_cache, base::sprintf("cargo%s_%s_%s.rds", codigo_cargo, sigla_uf, ano))
  
  # Usa o cache só se ele tiver TODAS as colunas pedidas hoje.
  if (usar_cache && base::file.exists(arquivo_cache)) {
    recorte_salvo <- base::readRDS(arquivo_cache)
    colunas_faltando_no_cache <- base::setdiff(colunas_necessarias, base::names(recorte_salvo))
    if (base::length(colunas_faltando_no_cache) == 0) {
      base::message("  ", ano, ": lendo do cache")
      return(recorte_salvo)
    }
    base::message("  ", ano, ": cache desatualizado (faltam ",
                  base::paste(colunas_faltando_no_cache, collapse = ", "),
                  "); lendo de novo da fonte")
  }
  
  ano_texto <- base::as.character(ano)
  if (ano_texto %in% base::names(arquivos_locais)) {
    tabela <- ler_csv_local(arquivos_locais[[ano_texto]], ano)
  } else {
    base::message("  ", ano, ": baixando pelo electionsBR (pode demorar)...")
    tabela <- electionsBR::elections_tse(year = ano, type = "vote_mun_zone", uf = sigla_uf)
  }
  
  recorte <- padronizar_recorte(tabela, ano)
  base::saveRDS(recorte, arquivo_cache)
  recorte
}


# ==============================================================================
# PASSO 2: LER TODOS OS ANOS E JUNTAR
# ------------------------------------------------------------------------------
# O QUE FAZ: aplica a função do Passo 1 a cada ano e empilha os resultados.
# POR QUÊ: precisamos de uma única tabela com todas as eleições.
# Se algum ano falhar, o script não para no primeiro erro: tenta todos e
# depois lista quais falharam e por quê.
# FUNÇÃO PRINCIPAL: dplyr::bind_rows() empilha tabelas com as mesmas colunas;
# base::tryCatch() executa um código e, se der erro, devolve a mensagem.
# ==============================================================================
base::message("PASSO 2: lendo e empilhando os anos")

tentar_ano <- function(ano) {
  base::tryCatch(ler_votacao_ano(ano),
                 error = function(erro) base::conditionMessage(erro))
}

lista_por_ano <- base::lapply(anos_eleicao, tentar_ano)
deu_erro <- base::vapply(lista_por_ano, base::is.character, logical(1))

if (base::any(deu_erro)) {
  base::stop("Falha nos anos ", base::paste(anos_eleicao[deu_erro], collapse = ", "), ":\n",
             base::paste(base::unlist(lista_por_ano[deu_erro]), collapse = "\n"))
}

votacao_bruta <- dplyr::bind_rows(lista_por_ano)

dplyr::glimpse(votacao_bruta)
votacao_bruta |> dplyr::count(ANO_ELEICAO)

base::stopifnot(base::nrow(votacao_bruta) > 0)
base::stopifnot(base::all(colunas_necessarias %in% base::names(votacao_bruta)))


# ==============================================================================
# PASSO 3: FILTRAR GOVERNADOR, 1º TURNO, PERNAMBUCO
# ------------------------------------------------------------------------------
# O QUE FAZ: mantém só as linhas do cargo, turno e estado escolhidos e
# transforma votos de texto em número.
# POR QUÊ: o arquivo traz todos os cargos (presidente, senador, deputados...).
# FUNÇÃO PRINCIPAL: dplyr::filter() mantém as linhas que satisfazem a condição.
# ==============================================================================
base::message("PASSO 3: filtrando cargo, turno e estado")

votacao_governador <- votacao_bruta |>
  dplyr::filter(CD_CARGO == codigo_cargo,
                NR_TURNO == turno_analisado,
                SG_UF == sigla_uf) |>
  dplyr::mutate(ano = base::as.integer(ANO_ELEICAO),
                votos = base::as.numeric(QT_VOTOS_NOMINAIS))

dplyr::glimpse(votacao_governador)
votacao_governador |> dplyr::count(ano)

# Conferência: todo ano escolhido sobreviveu ao filtro?
anos_sem_dados <- base::setdiff(anos_eleicao, base::unique(votacao_governador$ano))
if (base::length(anos_sem_dados) > 0) {
  base::stop("Sem dados de governador para: ", base::paste(anos_sem_dados, collapse = ", "),
             ". Confira o código do cargo e o turno.")
}

# Conferência: votos que não viraram número (NA inesperado).
base::stopifnot(!base::anyNA(votacao_governador$votos))


# ==============================================================================
# PASSO 3b: CORRIGIR OS ANOS COM COLUNA DE VOTOS ALTERNATIVA (1998)
# ------------------------------------------------------------------------------
# O QUE FAZ: para cada ano listado em anos_com_coluna_de_votos_alternativa,
#   1. lê a tabela bruta do cache (todas as colunas);
#   2. recorta cargo, turno e UF;
#   3. renomeia a coluna certa (ex.: QT_VOTOS_NOMINAIS_VALIDOS) para
#      QT_VOTOS_NOMINAIS, para ficar igual aos outros anos;
#   4. APAGA as linhas antigas desse ano em votacao_governador e coloca as novas.
# POR QUÊ: em 1998 a coluna QT_VOTOS_NOMINAIS veio zerada; sem a correção,
#   as porcentagens desse ano viram 0/0 = NaN.
# FUNÇÃO PRINCIPAL: dplyr::rename() muda o nome de uma coluna
#   (sintaxe: novo_nome = nome_antigo).
# ==============================================================================

base::message("PASSO 3b: corrigindo a coluna de votos dos anos listados")

corrigir_votos_ano <- function(ano_texto, coluna_de_votos) {
  arquivo_bruto <- base::file.path(pasta_cache, base::sprintf("bruto_%s_%s.rds", sigla_uf, ano_texto))
  if (!base::file.exists(arquivo_bruto)) {
    base::stop("Ano ", ano_texto, ": não achei ", arquivo_bruto,
               ". Rode antes o script diagnostico_votos_1998.R, que cria esse arquivo.")
  }
  
  dado_bruto <- base::readRDS(arquivo_bruto)
  
  colunas_para_pegar <- c(base::setdiff(colunas_necessarias, "QT_VOTOS_NOMINAIS"), coluna_de_votos)
  colunas_ausentes <- base::setdiff(colunas_para_pegar, base::names(dado_bruto))
  if (base::length(colunas_ausentes) > 0) {
    base::stop("Ano ", ano_texto, ": a tabela bruta não tem ",
               base::paste(colunas_ausentes, collapse = ", "),
               ".\nColunas disponíveis: ", base::paste(base::names(dado_bruto), collapse = ", "))
  }
  
  dado_bruto |>
    dplyr::select(dplyr::all_of(colunas_para_pegar)) |>
    dplyr::rename(QT_VOTOS_NOMINAIS = dplyr::all_of(coluna_de_votos)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), base::as.character)) |>
    dplyr::filter(CD_CARGO == codigo_cargo,
                  NR_TURNO == turno_analisado,
                  SG_UF == sigla_uf) |>
    dplyr::mutate(ano = base::as.integer(ANO_ELEICAO),
                  votos = base::as.numeric(QT_VOTOS_NOMINAIS)) |>
    dplyr::select(dplyr::all_of(base::names(votacao_governador)))
}

if (base::length(anos_com_coluna_de_votos_alternativa) > 0) {
  anos_a_corrigir <- base::as.integer(base::names(anos_com_coluna_de_votos_alternativa))
  
  # Situação ANTES da correção (votos totais por ano). Dentro de um 'if', o R
  # não mostra resultados sozinho; por isso usamos base::print().
  base::print(votacao_governador |>
                dplyr::filter(ano %in% anos_a_corrigir) |>
                dplyr::group_by(ano) |>
                dplyr::summarise(linhas = dplyr::n(), votos_totais = base::sum(votos)))
  
  linhas_corrigidas <- dplyr::bind_rows(base::Map(
    corrigir_votos_ano,
    base::names(anos_com_coluna_de_votos_alternativa),
    anos_com_coluna_de_votos_alternativa
  ))
  dplyr::glimpse(linhas_corrigidas)
  
  # Conferências: há linhas, os votos viraram número e não somam zero.
  base::stopifnot(base::nrow(linhas_corrigidas) > 0)
  base::stopifnot(!base::anyNA(linhas_corrigidas$votos))
  totais_corrigidos <- linhas_corrigidas |>
    dplyr::group_by(ano) |>
    dplyr::summarise(linhas = dplyr::n(), votos_totais = base::sum(votos))
  base::print(totais_corrigidos)
  if (base::any(totais_corrigidos$votos_totais == 0)) {
    base::stop("Mesmo com a coluna alternativa, os votos somam zero em: ",
               base::paste(totais_corrigidos$ano[totais_corrigidos$votos_totais == 0], collapse = ", "))
  }
  
  # Apaga as linhas antigas dos anos corrigidos e coloca as novas.
  votacao_governador <- votacao_governador |>
    dplyr::filter(!(ano %in% anos_a_corrigir)) |>
    dplyr::bind_rows(linhas_corrigidas) |>
    dplyr::arrange(ano)
  
  dplyr::glimpse(votacao_governador)
  base::print(votacao_governador |>
                dplyr::group_by(ano) |>
                dplyr::summarise(linhas = dplyr::n(), votos_totais = base::sum(votos)))
  base::stopifnot(base::all(anos_eleicao %in% votacao_governador$ano))
}


# ==============================================================================
# PASSO 4: SOMAR VOTOS POR CANDIDATO E CALCULAR A ORDEM DE CHEGADA
# ------------------------------------------------------------------------------
# O QUE FAZ: o arquivo vem por município e zona; somamos para ter o total de
# cada candidato no estado. Depois calculamos a porcentagem e a posição.
# POR QUÊ: "ordem de chegada" (order of finish) é a colocação: 1º, 2º, 3º...
# Atenção: aqui as colunas de município e zona (NR_ZONA, CD_MUNICIPIO,
# NM_MUNICIPIO) SOMEM de propósito, porque somamos os votos do estado todo.
# Para análises por município, use a tabela 'votacao_governador' (Passo 3).
# FUNÇÃO PRINCIPAL: dplyr::summarise() resume várias linhas em uma por grupo;
# dplyr::row_number() numera as linhas na ordem pedida (aqui, votos decrescentes).
# ==============================================================================
base::message("PASSO 4: totais por candidato e ordem de chegada")

ordem_de_chegada <- votacao_governador |>
  dplyr::group_by(ano, SQ_CANDIDATO, NM_URNA_CANDIDATO, SG_PARTIDO) |>
  dplyr::summarise(votos = base::sum(votos), .groups = "drop") |>
  dplyr::group_by(ano) |>
  dplyr::mutate(percentual = 100 * votos / base::sum(votos),
                posicao    = dplyr::row_number(dplyr::desc(votos))) |>
  dplyr::ungroup() |>
  dplyr::arrange(ano, posicao)

dplyr::glimpse(ordem_de_chegada)
ordem_de_chegada |> dplyr::count(ano, name = "numero_candidatos")

# Conferência: as porcentagens de cada ano somam 100?
soma_por_ano <- ordem_de_chegada |>
  dplyr::group_by(ano) |>
  dplyr::summarise(soma = base::sum(percentual))
base::stopifnot(base::all(base::abs(soma_por_ano$soma - 100) < 0.001))

# Conferência: todo ano tem pelo menos 2 candidatos?
base::stopifnot(base::all(dplyr::count(ordem_de_chegada, ano)$n >= 2))


# ==============================================================================
# PASSO 5: NÚMERO EFETIVO DE CANDIDATOS (como na Figura 3 de Reed)
# ------------------------------------------------------------------------------
# O QUE FAZ: calcula o índice de Laakso-Taagepera somando sobre CANDIDATOS,
# como Reed faz: 1 / soma(proporção²).
# POR QUÊ: permite comparar com a previsão n + 1 = 2.
# FUNÇÃO PRINCIPAL: readr::write_csv() salva a tabela em CSV.
# ==============================================================================
base::message("PASSO 5: número efetivo de candidatos")

numero_efetivo <- ordem_de_chegada |>
  dplyr::group_by(ano) |>
  dplyr::summarise(numero_efetivo_candidatos = 1 / base::sum((percentual / 100)^2),
                   previsao_reed = numero_vagas + 1)

dplyr::glimpse(numero_efetivo)
base::print(numero_efetivo)

#readr::write_csv(numero_efetivo, base::file.path(pasta_saidas, "numero_efetivo_candidatos_pe.csv"))


# ==============================================================================
# PASSO 6: FUNÇÃO PARA SALVAR FIGURAS
# ------------------------------------------------------------------------------
# O QUE FAZ: salva um gráfico em PNG (300 dpi, fundo branco) e, se pedido,
# em PDF vetorial.
# POR QUÊ: vamos salvar várias figuras do mesmo jeito; função evita repetição.
# FUNÇÃO PRINCIPAL: ggplot2::ggsave() grava o gráfico em arquivo.
# ==============================================================================
base::message("PASSO 6: definindo a função de salvar")

salvar_figura <- function(grafico, nome, largura = 10, altura = 7, com_pdf = TRUE) {
  ggplot2::ggsave(base::file.path(pasta_saidas, base::paste0(nome, ".png")),
                  grafico, width = largura, height = altura, dpi = 300, bg = "white")
  if (com_pdf) {
    ggplot2::ggsave(base::file.path(pasta_saidas, base::paste0(nome, ".pdf")),
                    grafico, width = largura, height = altura,
                    device = grDevices::cairo_pdf)
  }
  base::invisible(grafico)
}

# ==============================================================================
# 7e–7f. CONSTRUÇÃO DO GRÁFICO: DO aes() AO TEMA
# ------------------------------------------------------------------------------
# Cada objeto é o anterior + UMA camada:
#   p1: base do gráfico (eixos x e y definidos no aes)
#   p2: + linhas cinza dos anos comuns
#   p3: + linhas pretas dos anos destacados (dotted e twodash)
#   p4: + tracejado vertical entre n + 1 e n + 2
#   p5: + ano escrito em cima das linhas destacadas
#   p6: + escala do eixo x (começando em 1) e textos
#   p7: + tema (theme_linedraw, fundo branco, borda preta)
# FUNÇÃO PRINCIPAL: ggplot2::ggplot() cria o gráfico; ggplot2::aes() liga
# colunas da tabela a elementos visuais (x, y, grupo, tipo de linha, texto).
# ==============================================================================
base::message("PASSO 7e–7f: construindo o gráfico por camadas")

# Conferência: os objetos das etapas anteriores existem?
objetos_necessarios <- c("dados_figura_1", "linhas_cinza", "linhas_destaque", "rotulos_destaque",
                         "tipos_linha_por_ano", "anos_destaque", "numero_vagas",
                         "cor_destaque", "cor_demais_anos", "espessura_destaque",
                         "espessura_demais_anos", "salvar_figura")
objetos_faltando <- objetos_necessarios[!base::vapply(objetos_necessarios, base::exists, logical(1))]
if (base::length(objetos_faltando) > 0) {
  base::stop("Rode antes as etapas 7a a 7d. Faltam: ", base::paste(objetos_faltando, collapse = ", "))
}

# p1: base. O aes() geral diz que x é a posição e y é a porcentagem;
# todas as camadas seguintes herdam isso.
p1 <- ggplot2::ggplot(mapping = ggplot2::aes(x = posicao, y = percentual))

# p2: linhas finas, contínuas e cinza-claro dos anos não destacados.
p2 <- p1 +
  ggplot2::geom_line(data = linhas_cinza,
                     ggplot2::aes(group = ano_texto),
                     colour = cor_demais_anos, linewidth = espessura_demais_anos,
                     linetype = "solid")

# p3: linhas pretas dos anos destacados; o tipo de linha vem do ano.
p3 <- p2 +
  ggplot2::geom_line(data = linhas_destaque,
                     ggplot2::aes(group = ano_texto, linetype = ano_texto),
                     colour = cor_destaque, linewidth = espessura_destaque) +
  ggplot2::scale_linetype_manual(values = tipos_linha_por_ano, guide = "none")

# p4: tracejado vertical entre o 2º (n + 1) e o 3º colocado (n + 2).
p4 <- p3 +
  ggplot2::geom_vline(xintercept = numero_vagas + 1.5, linetype = "solid", linewidth = 0.5) +
  ggplot2::annotate("text", x = numero_vagas + 1.6,
                    y = base::max(dados_figura_1$percentual),
                    label = "entre n + 1 e n + 2", hjust = 0, size = 3.5)

# p5: o ano escrito em cima de cada linha destacada.
p5 <- p4 +
  ggplot2::geom_text(data = rotulos_destaque,
                     ggplot2::aes(label = ano_texto),
                     colour = cor_destaque, vjust = -0.8, size = 3.8)

# p6: eixo x começando em 1, com todas as posições, e os textos da figura.
p6 <- p5 +
  ggplot2::scale_x_continuous(
    breaks = base::seq_len(base::max(dados_figura_1$posicao)),
    limits = c(1, NA),                                    # começa em 1; NA = o fim vem dos dados
    expand = ggplot2::expansion(mult = c(0, 0.03))        # sem folga à esquerda, pequena folga à direita
  ) +
  ggplot2::labs(
    title    = "",
    subtitle = base::paste0(""),
    caption  = "",
    x = "Ordem de chegada", y = "% dos votos nominais"
  )

# p7: tema. theme_linedraw + fundo branco + borda preta nos quatro lados.
p7_com_grade <- p6 +
  ggplot2::theme_linedraw(base_size = 12) +
  ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    panel.border     = ggplot2::element_rect(fill = NA, colour = "black", linewidth = 0.8),
    plot.background  = ggplot2::element_rect(fill = "white", colour = NA)
  )
base::print(p7_com_grade)
# salvar_figura(p7_com_grade, "figura_1_ordem_chegada_final_com_grade")

# Versão sem grade: a mesma figura, apagando as linhas de grade.
p7_sem_grade <- p7_com_grade +
  ggplot2::theme(panel.grid = ggplot2::element_blank())
base::print(p7_sem_grade)

#salvar_figura(p7_sem_grade, "fig_1")


# ==============================================================================
# PASSO FINAL: REPRODUTIBILIDADE
# ------------------------------------------------------------------------------
# Registra versão do R e dos pacotes usados, para alguém repetir a análise.
# ==============================================================================
base::message("PASSO FINAL: informações da sessão")
utils::sessionInfo()

base::writeLines(utils::capture.output(utils::sessionInfo()),
                 "C:/Users/ryall/OneDrive/Desktop/R/partidos/ppe/data/sessionInfo_seriegovPE.txt")

# ==============================================================================
# PASSO EXTRA: SALVAR AS TABELAS EM CSV E RDS
# ------------------------------------------------------------------------------
# O QUE FAZ: salva 'ordem_de_chegada' e 'votacao_governador' em dois formatos:
#   - .csv: abre em qualquer programa (Excel, LibreOffice, Stata...);
#   - .rds: formato do R; guarda os tipos das colunas exatamente como estão.
# POR QUÊ: permite retomar a análise sem baixar e processar tudo de novo.
# FUNÇÕES PRINCIPAIS: readr::write_csv() grava CSV em UTF-8;
# base::saveRDS() grava um objeto do R em arquivo .rds.
# ==============================================================================
base::message("PASSO EXTRA: salvando as tabelas em CSV e RDS")

# Caminho da pasta. No R, use "/" no caminho do Windows (a "\" simples dá erro).
pasta_dados_finais <- "C:/Users/ryall/OneDrive/Desktop/R/partidos/ppe/data"
base::dir.create(pasta_dados_finais, recursive = TRUE, showWarnings = FALSE)
base::stopifnot(base::dir.exists(pasta_dados_finais))

# Conferência: as tabelas existem?
tabelas_para_salvar <- c("ordem_de_chegada", "votacao_governador")
tabelas_faltando <- tabelas_para_salvar[!base::vapply(tabelas_para_salvar, base::exists, logical(1))]
if (base::length(tabelas_faltando) > 0) {
  base::stop("Rode antes os Passos 0 a 4. Faltam: ", base::paste(tabelas_faltando, collapse = ", "))
}

# Função: salva uma tabela nos dois formatos e confere se gravou certo.
salvar_tabela <- function(nome_tabela) {
  tabela <- base::get(nome_tabela)
  arquivo_csv <- base::file.path(pasta_dados_finais, base::paste0(nome_tabela, ".csv"))
  arquivo_rds <- base::file.path(pasta_dados_finais, base::paste0(nome_tabela, ".rds"))
  
  readr::write_csv(tabela, arquivo_csv)
  base::saveRDS(tabela, arquivo_rds)
  
  # Conferência: relê o .rds e compara o número de linhas.
  base::stopifnot(base::file.exists(arquivo_csv), base::file.exists(arquivo_rds))
  base::stopifnot(base::nrow(base::readRDS(arquivo_rds)) == base::nrow(tabela))
  
  base::message("  ", nome_tabela, ": ", base::nrow(tabela), " linhas salvas")
  base::invisible(c(arquivo_csv, arquivo_rds))
}

arquivos_salvos <- base::unlist(base::lapply(tabelas_para_salvar, salvar_tabela))

# Inspeção: arquivos gravados e tamanho de cada um (em KB).
base::print(base::data.frame(arquivo = base::basename(arquivos_salvos),
                             tamanho_kb = base::round(base::file.size(arquivos_salvos) / 1024, 1)))

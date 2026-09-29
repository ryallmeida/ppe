# ============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES 
# ============================================================================
# CODADO ORGININALMENTE EM R, R version 4.5.2 (2025-10-31 ucrt)
# DEMONSTRAÇÃO: a sintaxe do ggplot2

pacman::p_load(ggplot2)

# -----------------------------------------------------------------
# Sobre o dataset "mpg" (usado na maioria dos exemplos abaixo):
# - Vem junto com o pacote ggplot2, nao precisa instalar nada a mais
# - 234 registros de 38 modelos de carros populares nos EUA (1999-2008)
# - Baseado nos dados de consumo de combustivel da EPA (orgao
#   ambiental dos Estados Unidos)

# - Principais colunas:
#     displ   -> cilindrada do motor (litros)
#     cty     -> consumo na cidade (milhas por galao)
#     hwy     -> consumo na estrada (milhas por galao)
#     cyl     -> numero de cilindros
#     drv     -> tracao: f = dianteira, r = traseira, 4 = 4x4
#     fl      -> tipo de combustivel (p = premium, r = regular, etc.)
#     class   -> categoria do veiculo (compact, suv, midsize, ...)
#     manufacturer / model -> fabricante e modelo
#     year    -> ano do modelo
# - Para explorar: head(mpg), str(mpg), ?mpg
# -----------------------------------------------------------------

data(package = "ggplot2")
data(mpg)


# ===================================================================
# SEÇÃO 1 — SINTAXE BÁSICA
# ===================================================================

# template geral de qualquer grafico em ggplot2:
# ggplot(data = <DADOS>) +
#   <GEOM_FUNCTION>(mapping = aes(<MAPEAMENTOS>),
#                   stat = <STAT>, position = <POSICAO>) +
#   <COORDINATE_FUNCTION> +
#   <FACET_FUNCTION> +
#   <SCALE_FUNCTION> +
#   <THEME_FUNCTION>

# exemplo concreto
ggplot(data = mpg, aes(x = cty, y = hwy)) +
  geom_point()

last_plot()                                  # retorna o ultimo grafico feito
# ggsave("plot.png", width = 5, height = 5)  # salva em disco


# ===================================================================
# SEÇÃO 2 — AES: MAPEAMENTOS ESTÉTICOS
# ===================================================================

# mapeando 3 variaveis de uma vez: posicao (x,y) e cor
ggplot(mpg, aes(x = cty, y = hwy, color = class)) +
  geom_point()

# aes tambem aceita tamanho, forma, transparencia (alpha)...
ggplot(mpg, aes(x = cty, y = hwy)) +
  geom_point(aes(size = cyl, shape = drv, alpha = 0.6))


# ===================================================================
# SEÇÃO 3 — GEOMS: PRIMITIVAS GRÁFICAS
# ===================================================================

data(package = "ggplot2")
data(economics)

# -----------------------------------------------------------------
# Sobre o dataset "economics" (usado nesta seção):
# - Tambem vem junto com o pacote ggplot2, nao precisa instalar nada
# - Dados economicos mensais dos EUA, fonte publica do governo
#   americano (FRED - Federal Reserve Economic Data)
# - Cobre de julho de 1967 ate 2015 (mais de 500 observacoes, uma
#   por mes)
# - Colunas usadas no exemplo abaixo:
#     date     -> data da observacao (uma por mes)
#     unemploy -> numero de desempregados nos EUA naquele mes,
#                 EM MILHARES (contagem bruta, nao e percentual)
# - Outras colunas disponiveis:
#     pce      -> gasto pessoal de consumo (bilhoes de dolares)
#     pop      -> populacao total dos EUA (milhares)
#     psavert  -> taxa de poupanca pessoal (%)
#     uempmed  -> duracao mediana do desemprego (semanas)
# - E uma serie temporal classica: por isso serve bem pra ilustrar
#   geom_path() (liga pontos na ordem dos dados) e geom_ribbon()
#   (faixa sombreada ao longo do tempo) -- coisa que nao faria muito
#   sentido com dados sem ordem natural, como o mpg
# - Para explorar: head(economics), str(economics), ?economics
# -------------------------------

a <- ggplot(economics, aes(date, unemploy))

data(seals)
b <- ggplot(seals, aes(x = long, y = lat))

# -----------------------------------------------------------------
# Sobre o dataset "seals" (usado nesta secao):
# - Tambem vem junto com o pacote ggplot2, nao precisa instalar nada
# - Campo vetorial de movimento de focas: 1155 observacoes, cada
#   uma com uma posicao geografica e um vetor de deslocamento
# - Colunas:
#     lat        -> latitude do ponto
#     long       -> longitude do ponto
#     delta_long -> deslocamento em longitude (eixo x)
#     delta_lat  -> deslocamento em latitude (eixo y)
# - Usado com geom_segment() para desenhar uma "flecha" indo de
#   (long, lat) ate (long + delta_long, lat + delta_lat)
# - Dataset geografico/vetorial -- diferente do mpg (categorico) e
#   do economics (serie temporal), por isso completa bem o trio
# - Para explorar: head(seals), str(seals), ?seals
# -----------------------------------------------------------------

# nao desenha nada, so fixa limites
a + geom_blank()          

b + geom_point() # x, y, alpha, color, shape, size

b + geom_path()  # liga os pontos NA ORDEM DOS DADOS

# um segmento por linha
b + geom_segment(aes(yend = lat + 1,
                     xend = long + 1))  

# poligono fechado e preenchido
a + geom_polygon(aes(alpha = 50))       

# desenha um quadrado ao redor de cada ponto
b + geom_rect(aes(xmin = long, ymin = lat,
                  xmax = long + 1, ymax = lat + 1))

# faixa sombreada
a + geom_ribbon(aes(ymin = unemploy - 900,
                    ymax = unemploy + 900))  
# esse argumento acima precisa de um ymin e um ymax para cada x 
# ele preenche tudo que está entre essas duas alturas.

b + geom_hline(aes(yintercept = lat))          # linha horizontal
b + geom_vline(aes(xintercept = long))         # linha vertical
b + geom_abline(aes(intercept = 0, slope = 1)) # linha diagonal
 
# ----------------------------------

rm(list = ls())
cat("\014")

# ===================================================================
# SEÇÃO 4 — STATS: TRANSFORMAÇÕES ESTATÍSTICAS
# ===================================================================

# hwy     -> consumo na estrada (milhas por galao)
c <- ggplot(mpg, aes(hwy))

# duas formas equivalentes de fazer um histograma:
c + geom_histogram(binwidth = 5)
c + stat_bin(binwidth = 5, geom = "bar")

# resume y para cada x (media, intervalo, etc.)

df <- data.frame(grp = c("A", "B"), fit = 4:5, se = 1:2)

ggplot(df, aes(grp, fit, ymin = fit - se, ymax = fit + se)) +
  stat_summary(fun.data = "mean_cl_boot")

# usa o valor calculado PELO stat como estetica
# cyl     -> numero de cilindros
# hwy     -> consumo na estrada (milhas por galao)

ggplot(mpg, aes(cty, hwy)) +
  stat_density_2d(aes(fill = after_stat(level)),
                  geom = "polygon")

# ----------------------------------

rm(list = ls())
cat("\014")

# ===================================================================
# SEÇÃO 5 — SCALES: ESCALAS
# ===================================================================

# fl      -> tipo de combustivel (p = premium, r = regular, etc.)
n <- ggplot(mpg, aes(fl)) + geom_bar(aes(fill = fl))
print(n)

# pq o aes n recepciona y (sendo o argumento, [x, y]) ?
# geom_bar() já vem com um stat padrão embutido: o stat_count()

# cor discreta escolhida na mao
n + scale_fill_manual(
  values = c("lightblue", "skyblue", "royalblue", "blue", "navy"))

#     displ   -> cilindrada do motor (litros)
#     hwy     -> consumo na estrada (milhas por galao)

# cor continua em gradiente (dois extremos)
ggplot(mpg, aes(displ, hwy, color = cty)) +
  geom_point() +
  scale_color_gradient(low = "red", high = "yellow")

# escalas de posicao: log e inversao

p <- ggplot(mpg, aes(displ, hwy)) + geom_point()
print(p)

p + scale_x_log10()

# usar quando: os valores do eixo tem ordens de grandeza
# muito diferentes (ex: renda, populacao, contagens)
# efeito: comprime valores grandes, espalha valores pequenos

p + scale_y_reverse()

# usar quando: "menor" deveria aparecer no topo do grafico
# (ranking, posicao em corrida) ou o eixo representa
# profundidade/negativo (nivel do mar, altitude abaixo de 0)
# efeito: inverte a direcao do eixo y

# ----------------------------------

rm(list = ls())
cat("\014")


# ===================================================================
# SEÇÃO 6 — FACETING: PEQUENOS MÚLTIPLOS
# ===================================================================

# cty     -> consumo na cidade (milhas por galao)
# hwy     -> consumo na estrada (milhas por galao)
t <- ggplot(mpg, aes(cty, hwy)) + geom_point()
print(t)

# fl      -> tipo de combustivel (p = premium, r = regular, etc.)

t + facet_wrap(~ fl)          # varios paineis, layout automatico
t + facet_grid(. ~ fl)        # um painel por COLUNA
t + facet_grid(year ~ .)      # um painel por LINHA
t + facet_grid(year ~ fl)     # cruza duas variaveis: linhas x colunas

# eixos podem variar livremente entre paineis
t + facet_grid(drv ~ fl, scales = "free")
# drv     -> tracao: f = dianteira, r = traseira, 4 = 4x4

# ----------------------------------

rm(list = ls())
cat("\014")

# ===================================================================
# SEÇÃO 7 — THEMES: APARÊNCIA DO GRÁFICO
# ===================================================================

#     displ   -> cilindrada do motor (litros)
#     hwy     -> consumo na estrada (milhas por galao)

u <- ggplot(mpg, aes(displ, hwy)) + geom_point()
print(u)

u + theme_gray()      # padrao: fundo cinza com grade
u + theme_bw()        # fundo branco com grade
u + theme_minimal()   # tema minimo, sem caixas
u + theme_classic()   # so os eixos, sem grade
u + theme_void()      # tema vazio (so os dados)

# customizando um detalhe especifico, sem trocar o tema inteiro
u + theme(legend.position = "bottom",
          panel.background = element_rect(fill = "aliceblue"))


# ===================================================================
# SEÇÃO 8 — LABELS E LEGENDS
# ===================================================================

t2 <- ggplot(mpg, aes(displ, hwy, color = class)) + geom_point()
print(t2)

t2 + labs(x = "Cilindrada (litros)",
          y = "Consumo na estrada (mpg)",
          title = "Consumo por cilindrada",
          caption = "Fonte: EPA / pacote mpg",
          color = "Classe do veiculo")   # titulo da legenda

# anotar um ponto especifico do grafico
t2 + annotate("text", x = 6, y = 40, label = "Nota")

# esconder uma legenda / mudar sua posicao
t2 + guides(color = "none")
t2 + theme(legend.position = "bottom")

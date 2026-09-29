# =============================================================================
# UNIVERSIDADE FEDERAL DE PERNAMBUCO
# DEPARTAMENTO DE CIÊNCIA POLÍTICA
# DISCIPLINA DE PARTIDOS POLÍTICOS E ELEIÇÕES 
# =============================================================================
# CODADO ORGININALMENTE EM R, R version 4.5.2 (2025-10-31 ucrt)
# DEMONSTRAÇÃO: viridis()

# INSTALAÇÃO DOS PACOTES 

if (!require(pacman)) {
  install.packages("pacman")
}

pacman::p_load(plotly,
               jpeg, 
               ggplot2)

rm(list = ls())
cat("\014")


# ============================================================================
# MONALISA 1
# ============================================================================

library(jpeg)
library(plotly)

# 1. Baixar a imagem (versão reduzida, 300 px de largura, para ficar leve)
download.file(
  "https://commons.wikimedia.org/wiki/Special:FilePath/Mona_Lisa.jpg?width=300",
  destfile = "monalisa.jpg", mode = "wb"
)

# 2. Imagem -> matriz de intensidades (0 = preto, 1 = branco)
img <- readJPEG("monalisa.jpg")
lum <- 0.2126 * img[,,1] + 0.7152 * img[,,2] + 0.0722 * img[,,3]

dim(lum)          # altura x largura: é a sua "base de dados" numérica
lum[1:5, 1:5]     # os números que formam a imagem

# 3. Salvar como tabela, se quiser guardar os números
write.csv(lum, "monalisa_matriz.csv", row.names = FALSE)

# 4. Heatmap com plotly (eixo y invertido para a imagem não ficar de cabeça para baixo)
plot_ly(z = lum, type = "heatmap", colorscale = "Viridis") |>
  layout(
    yaxis = list(autorange = "reversed", scaleanchor = "x", showgrid = FALSE),
    xaxis = list(showgrid = FALSE)
  )

# ============================================================================
# MONALISA 2
# ============================================================================

rm(list = ls())
cat("\014")

# Matriz transcrita da imagem (22 linhas x 20 colunas)
dados <- c(
  46,45,46,46,47,45,47,48,42,35,34,36,43,45,44,44,46,46,46,43,
  48,47,48,48,48,48,36,22,20,16,15,13,13,17,32,45,46,48,46,44,
  50,52,51,51,50,31,23,30,25,22,19,13,10,11, 9,19,49,48,48,48,
  51,52,52,53,33,24,34,43,36,30,20,16,11,10, 8, 8,20,51,50,48,
  52,55,55,47,24,53,66,67,64,56,44,23,14,10, 8, 7, 7,39,51,52,
  54,56,56,23,43,70,73,74,72,65,56,36,20,12, 7, 7, 6, 7,53,51,
  55,58,47,14,51,69,72,70,71,67,55,41,28,15,11, 7, 6, 6,47,46,
  58,58,27,17,53,65,68,68,69,63,54,49,41,26, 8, 7, 6, 5,17,35,
  63,53,18,18,57,63,67,68,66,59,59,54,46,28,10, 7, 7, 6, 9,29,
  62,40,17,19,46,44,50,62,36,35,40,30,26,25,10, 8, 7, 7, 7,22,
  54,36,16,20,33,32,39,64,30,51,27,31,39,36,12,10, 6, 8, 8,24,
  38,31,14,21,62,51,59,62,42,59,57,57,57,35,10, 8, 7, 7, 8,21,
  25,27,13,18,60,68,63,64,49,67,70,64,47,26, 9, 8, 8, 7, 9,29,
  20,17,14,13,58,65,60,62,46,62,64,56,37,20,10, 9, 9, 7, 8,18,
  19,14,13,10,41,57,55,34,24,64,57,45,30,18, 9, 8, 9, 8, 8,13,
  20,13,13,11,30,48,56,43,39,39,49,43,31,17, 9, 9, 8, 7, 8,13,
  23,17,15,11,16,51,64,50,39,48,51,40,26,15,10,10, 9, 7,10,12,
  27,18,12,11,11,21,56,62,52,43,40,27,20,13, 9, 9, 8, 7, 9,13,
  30,19,14,13,13,11,22,57,47,34,23,20,17,11,10, 9, 9, 7, 9,12,
  38,22,13,10, 9, 9,11,14,19,19,17,14,16,16,13, 9, 9, 7, 8,10,
  35,28,12,12,11,10,11,14,36,26,20,20,23,25,20,10, 8, 8, 9, 9,
  33,30,13,12,12,11,11,13,48,42,34,31,32,37,28,13, 9, 8,11, 7
)

m <- matrix(dados, nrow = 22, ncol = 20, byrow = TRUE)

# Heatmap: cada número -> uma cor (escala fixa de 0 a 100, como na barra)
plot_ly(
  z = m, type = "heatmap",
  colorscale = "Inferno",
  zmin = 0, zmax = 100,
  xgap = 1, ygap = 1
) |>
  layout(
    yaxis = list(autorange = "reversed", scaleanchor = "x", showgrid = FALSE),
    xaxis = list(showgrid = FALSE)
  )


df <- data.frame(
  linha  = rep(seq_len(nrow(m)), times = ncol(m)),
  coluna = rep(seq_len(ncol(m)), each  = nrow(m)),
  valor  = as.vector(m)
)

ggplot(df, aes(coluna, linha, fill = valor)) +
  geom_tile(color = "white", linewidth = 0.2) +
  geom_text(aes(label = valor,
                color = valor > 55),          
            size = 2.6, show.legend = FALSE) +
  scale_color_manual(values = c("white", "black")) +
  scale_fill_viridis_c(option = "inferno", limits = c(0, 100)) +
  scale_y_reverse() +
  coord_equal() +
  theme_void() +
  labs(fill = "Valor")

# ------------------------------------------------------------
# 1. sRGB -> CAM02-UCS (J', a', b')
#    Condições de visualização padrão (as mesmas do colorspacious/viscm):
#    branco D65, L_A = 64/pi/5, Y_b = 20, ambiente "average"
# ------------------------------------------------------------
srgb_para_cam02ucs <- function(rgb) {          # rgb: matriz n x 3, valores em [0, 1]
  M_srgb <- matrix(c(0.4124564, 0.3575761, 0.1804375,
                     0.2126729, 0.7151522, 0.0721750,
                     0.0193339, 0.1191920, 0.9503041), 3, byrow = TRUE)
  M02 <- matrix(c( 0.7328, 0.4296, -0.1624,
                   -0.7036, 1.6975,  0.0061,
                   0.0030, 0.0136,  0.9834), 3, byrow = TRUE)
  MH  <- matrix(c( 0.38971, 0.68898, -0.07868,
                   -0.22981, 1.18340,  0.04641,
                   0,       0,        1), 3, byrow = TRUE)
  M_hpe_inv02 <- MH %*% solve(M02)
  
  LA <- 64 / pi / 5; Yb <- 20; Fs <- 1; cc <- 0.69; Nc <- 1
  XYZw <- as.numeric(M_srgb %*% c(1, 1, 1)) * 100
  D    <- Fs * (1 - (1 / 3.6) * exp((-LA - 42) / 92))
  k    <- 1 / (5 * LA + 1)
  FL   <- 0.2 * k^4 * (5 * LA) + 0.1 * (1 - k^4)^2 * (5 * LA)^(1 / 3)
  n    <- Yb / XYZw[2]
  Nbb  <- 0.725 * (1 / n)^0.2
  z    <- 1.48 + sqrt(n)
  RGBw <- as.numeric(M02 %*% XYZw)
  fator <- XYZw[2] / RGBw * D + 1 - D
  
  adaptar <- function(XYZ) {                   # XYZ: matriz 3 x N
    rgbc <- (M02 %*% XYZ) * fator
    p <- M_hpe_inv02 %*% rgbc
    q <- (FL * abs(p) / 100)^0.42
    400 * sign(p) * q / (27.13 + q) + 0.1
  }
  
  # sRGB -> linear -> XYZ
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  XYZ <- M_srgb %*% t(lin) * 100
  ad  <- adaptar(XYZ)
  aw  <- adaptar(matrix(XYZw, 3, 1))
  
  Ra <- ad[1, ]; Ga <- ad[2, ]; Ba <- ad[3, ]
  a  <- Ra - 12 * Ga / 11 + Ba / 11
  b  <- (Ra + Ga - 2 * Ba) / 9
  h  <- atan2(b, a)
  et <- 0.25 * (cos(h + 2) + 3.8)
  A  <- (2 * Ra + Ga + Ba / 20 - 0.305) * Nbb
  Aw <- (2 * aw[1] + aw[2] + aw[3] / 20 - 0.305) * Nbb
  J  <- 100 * pmax(A / Aw, 0)^(cc * z)
  t  <- (50000 / 13 * Nc * Nbb * et * sqrt(a^2 + b^2)) / (Ra + Ga + 21 / 20 * Ba)
  C  <- t^0.9 * sqrt(J / 100) * (1.64 - 0.29^n)^0.73
  M  <- C * FL^0.25
  
  # CAM02-UCS
  Jp <- 1.7 * J / (1 + 0.007 * J)
  Mp <- log(1 + 0.0228 * M) / 0.0228
  cbind(Jp = Jp, ap = Mp * cos(h), bp = Mp * sin(h))
}

# ------------------------------------------------------------
# 2. Superfície do cubo RGB (6 faces), como malha de triângulos
#    O gamut é a imagem da superfície do cubo no espaço CAM02-UCS
# ------------------------------------------------------------
n  <- 50
g  <- seq(0, 1, length.out = n)
uv <- expand.grid(u = g, v = g)

faces <- list(
  cbind(0,       uv$u, uv$v),   # R = 0
  cbind(1,       uv$u, uv$v),   # R = 1
  cbind(uv$u, 0,       uv$v),   # G = 0
  cbind(uv$u, 1,       uv$v),   # G = 1
  cbind(uv$u, uv$v, 0      ),   # B = 0
  cbind(uv$u, uv$v, 1      )    # B = 1
)

rgb_vertices <- do.call(rbind, faces)
xyz          <- srgb_para_cam02ucs(rgb_vertices)

# Índices dos triângulos (0-indexados, como o plotly espera)
idx <- function(i, j) (j - 1) * n + i - 1
tri <- do.call(rbind, lapply(seq_along(faces), function(f) {
  off <- (f - 1) * n^2
  ij  <- expand.grid(i = 1:(n - 1), j = 1:(n - 1))
  rbind(
    cbind(idx(ij$i, ij$j),     idx(ij$i + 1, ij$j),     idx(ij$i, ij$j + 1)) + off,
    cbind(idx(ij$i + 1, ij$j), idx(ij$i + 1, ij$j + 1), idx(ij$i, ij$j + 1)) + off
  )
}))

cores <- rgb(rgb_vertices[, 1], rgb_vertices[, 2], rgb_vertices[, 3])

# ------------------------------------------------------------
# 3. Gráfico 3D
# ------------------------------------------------------------
eixo <- list(showbackground = FALSE, gridcolor = "grey90",
             zerolinecolor = "grey80", showspikes = FALSE)

plot_ly(
  type = "mesh3d",
  x = xyz[, "ap"], y = xyz[, "bp"], z = xyz[, "Jp"],
  i = tri[, 1], j = tri[, 2], k = tri[, 3],
  vertexcolor = cores,
  flatshading = TRUE,
  lighting = list(ambient = 1, diffuse = 0, specular = 0,
                  roughness = 1, fresnel = 0)   # sem sombreamento: cores fiéis
) |>
  layout(
    scene = list(
      xaxis = c(eixo, list(title = "a'")),
      yaxis = c(eixo, list(title = "b'")),
      zaxis = c(eixo, list(title = "J'")),
      aspectmode = "data",
      camera = list(eye = list(x = 1.6, y = -1.6, z = 0.4))
    )
  )

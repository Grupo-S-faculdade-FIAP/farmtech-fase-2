# Análise Estatística do Sistema de Irrigação
# Biblioteca necessárias
library(ggplot2)
library(dplyr)
library(tidyr)

# Simulação de dados coletados (em produção, estes viriam do ESP32)
set.seed(123)
n_amostras <- 1000

# Geração de dados simulados
dados <- data.frame(
  timestamp = Sys.time() + seq(1, n_amostras, 1) * 60,
  umidade = rnorm(n_amostras, mean = 65, sd = 10),
  ph = rnorm(n_amostras, mean = 6.5, sd = 0.5),
  n_presente = sample(c(0,1), n_amostras, replace = TRUE, prob = c(0.3, 0.7)),
  p_presente = sample(c(0,1), n_amostras, replace = TRUE, prob = c(0.3, 0.7)),
  k_presente = sample(c(0,1), n_amostras, replace = TRUE, prob = c(0.3, 0.7)),
  irrigacao_ativa = FALSE
)

# Função para determinar necessidade de irrigação
determinar_irrigacao <- function(umidade, ph, n, p, k) {
  necessita <- FALSE
  
  # Verifica umidade (abaixo de 60%)
  if (umidade < 60) necessita <- TRUE
  
  # Verifica pH (fora do range 6.0-7.0)
  if (ph < 6.0 || ph > 7.0) necessita <- TRUE
  
  # Verifica NPK (ausência de qualquer nutriente)
  if (n == 0 || p == 0 || k == 0) necessita <- TRUE
  
  return(necessita)
}

# Aplica lógica de irrigação
dados$irrigacao_ativa <- mapply(determinar_irrigacao,
                               dados$umidade,
                               dados$ph,
                               dados$n_presente,
                               dados$p_presente,
                               dados$k_presente)

# 1. Análise Descritiva
resumo <- summary(dados[c("umidade", "ph")])
print("=== Análise Descritiva ===")
print(resumo)

# 2. Correlações
cor_matriz <- cor(dados[c("umidade", "ph", "n_presente", "p_presente", "k_presente")])
print("\n=== Matriz de Correlação ===")
print(cor_matriz)

# 3. Análise de Eficiência
eficiencia <- dados %>%
  summarise(
    total_amostras = n(),
    irrigacoes = sum(irrigacao_ativa),
    perc_irrigacao = mean(irrigacao_ativa) * 100
  )

print("\n=== Análise de Eficiência ===")
print(eficiencia)

# 4. Visualizações
# 4.1 Distribuição de Umidade
p1 <- ggplot(dados, aes(x = umidade)) +
  geom_histogram(bins = 30, fill = "blue", alpha = 0.7) +
  geom_vline(xintercept = 60, color = "red", linetype = "dashed") +
  labs(title = "Distribuição da Umidade",
       x = "Umidade (%)",
       y = "Frequência")

# 4.2 Distribuição de pH
p2 <- ggplot(dados, aes(x = ph)) +
  geom_histogram(bins = 30, fill = "green", alpha = 0.7) +
  geom_vline(xintercept = c(6.0, 7.0), color = "red", linetype = "dashed") +
  labs(title = "Distribuição do pH",
       x = "pH",
       y = "Frequência")

# 4.3 Relação Umidade x pH com estado de irrigação
p3 <- ggplot(dados, aes(x = umidade, y = ph, color = irrigacao_ativa)) +
  geom_point(alpha = 0.5) +
  labs(title = "Relação Umidade x pH",
       x = "Umidade (%)",
       y = "pH",
       color = "Irrigação Ativa")

# 5. Análise de Tendências
tendencias <- dados %>%
  mutate(hora = format(timestamp, "%H")) %>%
  group_by(hora) %>%
  summarise(
    media_umidade = mean(umidade),
    media_ph = mean(ph),
    freq_irrigacao = mean(irrigacao_ativa) * 100
  )

print("\n=== Análise de Tendências por Hora ===")
print(tendencias)

# 6. Recomendações baseadas em dados
print("\n=== Recomendações ===")

# Análise de umidade crítica
umidade_critica <- dados %>%
  filter(umidade < 60) %>%
  summarise(
    contagem = n(),
    percentual = n() / n_amostras * 100
  )

# Análise de pH crítico
ph_critico <- dados %>%
  filter(ph < 6.0 | ph > 7.0) %>%
  summarise(
    contagem = n(),
    percentual = n() / n_amostras * 100
  )

# Análise de NPK
npk_analise <- dados %>%
  summarise(
    deficiencia_n = mean(!n_presente) * 100,
    deficiencia_p = mean(!p_presente) * 100,
    deficiencia_k = mean(!k_presente) * 100
  )

print(sprintf("Amostras com umidade crítica: %.1f%%", umidade_critica$percentual))
print(sprintf("Amostras com pH crítico: %.1f%%", ph_critico$percentual))
print("Deficiência de nutrientes (%):")
print(sprintf("N: %.1f%%, P: %.1f%%, K: %.1f%%",
             npk_analise$deficiencia_n,
             npk_analise$deficiencia_p,
             npk_analise$deficiencia_k))

# Salvar gráficos
pdf("analise_irrigacao.pdf")
print(p1)
print(p2)
print(p3)
dev.off()

# Salvar resultados em arquivo
sink("resultados_analise.txt")
print("=== Análise Completa do Sistema de Irrigação ===")
print(Sys.time())
print("\nEstatísticas Descritivas:")
print(resumo)
print("\nMatriz de Correlação:")
print(cor_matriz)
print("\nEficiência do Sistema:")
print(eficiencia)
print("\nTendências por Hora:")
print(tendencias)
sink()
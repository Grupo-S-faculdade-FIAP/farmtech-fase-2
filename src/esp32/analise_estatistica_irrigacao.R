#!/usr/bin/env Rscript

r <- getOption("repos")
r["CRAN"] <- "https://cloud.r-project.org/"
options(repos = r)

cat("FarmTech Solutions - Análise Estatística da Irrigação\n")
cat("====================================================\n\n")

gerar_dados_simulados <- function(n_amostras = 100) {
  dados <- data.frame(
    timestamp = Sys.time() + seq(0, n_amostras-1) * 3600,
    umidade = rnorm(n_amostras, mean = 65, sd = 15),
    pH = rnorm(n_amostras, mean = 6.5, sd = 0.8),
    temperatura = rnorm(n_amostras, mean = 25, sd = 5),
    nitrogenio = sample(c(0, 1), n_amostras, replace = TRUE, prob = c(0.3, 0.7)),
    fosforo = sample(c(0, 1), n_amostras, replace = TRUE, prob = c(0.4, 0.6)),
    potassio = sample(c(0, 1), n_amostras, replace = TRUE, prob = c(0.2, 0.8)),
    irrigacao_ativada = rep(0, n_amostras)
  )
  
  dados$umidade <- pmax(0, pmin(100, dados$umidade))
  dados$pH <- pmax(0, pmin(14, dados$pH))
  dados$temperatura <- pmax(5, pmin(40, dados$temperatura))
  
  return(dados)
}
analisar_decisao_irrigacao <- function(dados) {
  cat("Análise Estatística para Decisão de Irrigação\n")
  cat("===========================================\n")

  # Estatísticas básicas
  cat("Estatísticas dos Sensores (últimas 24h):\n")
  cat(sprintf("Umidade: Média = %.1f%%, DP = %.1f%%, Min = %.1f%%, Máx = %.1f%%\n",
              mean(dados$umidade), sd(dados$umidade), min(dados$umidade), max(dados$umidade)))
  cat(sprintf("pH: Média = %.2f, DP = %.2f, Min = %.2f, Máx = %.2f\n",
              mean(dados$pH), sd(dados$pH), min(dados$pH), max(dados$pH)))
  cat(sprintf("Temperatura: Média = %.1f°C, DP = %.1f°C, Min = %.1f°C, Máx = %.1f°C\n",
              mean(dados$temperatura), sd(dados$temperatura), min(dados$temperatura), max(dados$temperatura)))

  # Análise de nutrientes
  n_ok <- sum(dados$nitrogenio) / length(dados$nitrogenio) * 100
  p_ok <- sum(dados$fosforo) / length(dados$fosforo) * 100
  k_ok <- sum(dados$potassio) / length(dados$potassio) * 100

  cat(sprintf("Nutrientes OK: N=%.1f%%, P=%.1f%%, K=%.1f%%\n", n_ok, p_ok, k_ok))

  # Critérios para irrigação (baseado em cultura do milho)
  deve_irrigar <- FALSE
  motivos <- c()

  # Teste t para umidade (comparar com ideal 60-80%)
  teste_umidade <- t.test(dados$umidade, mu = 70, alternative = "less")
  if (teste_umidade$p.value < 0.05) {
    deve_irrigar <- TRUE
    motivos <- c(motivos, "Umidade abaixo do ideal (teste estatístico)")
  }

  # Teste t para pH (comparar com ideal 5.8-7.0)
  teste_ph <- t.test(dados$pH, mu = 6.4, alternative = "two.sided")
  if (abs(mean(dados$pH) - 6.4) > 0.5) {
    deve_irrigar <- TRUE
    motivos <- c(motivos, "pH fora da faixa ideal")
  }

  # Análise de nutrientes
  if (n_ok < 70) {
    deve_irrigar <- TRUE
    motivos <- c(motivos, "Nitrogênio insuficiente")
  }
  if (p_ok < 60) {
    deve_irrigar <- TRUE
    motivos <- c(motivos, "Fósforo insuficiente")
  }
  if (k_ok < 80) {
    deve_irrigar <- TRUE
    motivos <- c(motivos, "Potássio insuficiente")
  }

  # Análise de correlação entre variáveis
  correlacao_umidade_temp <- cor(dados$umidade, dados$temperatura)
  cat(sprintf("Correlação Umidade-Temperatura: %.3f\n", correlacao_umidade_temp))

  if (correlacao_umidade_temp < -0.3) {
    cat("Observação: Umidade diminui com aumento de temperatura\n")
  }

  # Decisão final
  cat("\nDecisão Estatística de Irrigação:\n")
  if (deve_irrigar) {
    cat("✓ RECOMENDAÇÃO: ATIVAR IRRIGAÇÃO\n")
    cat("Motivos:\n")
    for (motivo in motivos) {
      cat(sprintf("  - %s\n", motivo))
    }
  } else {
    cat("✓ RECOMENDAÇÃO: MANTER IRRIGAÇÃO DESATIVADA\n")
    cat("Condições adequadas para o desenvolvimento do milho\n")
  }

  return(list(deve_irrigar = deve_irrigar, motivos = motivos))
}

# Função para gerar relatório de tendência
gerar_relatorio_tendencia <- function(dados) {
  cat("\nRelatório de Tendências\n")
  cat("=======================\n")

  # Tendência de umidade (regressão linear simples)
  tempo_numeric <- as.numeric(dados$timestamp - min(dados$timestamp)) / 3600 # horas
  modelo_umidade <- lm(umidade ~ tempo_numeric, data = dados)

  coeficiente <- coef(modelo_umidade)[2]
  if (coeficiente > 0.1) {
    tendencia <- "crescente"
  } else if (coeficiente < -0.1) {
    tendencia <- "decrescente"
  } else {
    tendencia <- "estável"
  }

  cat(sprintf("Tendência de umidade: %s (coeficiente: %.3f%%/hora)\n",
              tendencia, coeficiente))

  # Previsão para próximas horas
  horas_previsao <- 6
  previsao_umidade <- predict(modelo_umidade,
                             newdata = data.frame(tempo_numeric = max(tempo_numeric) + horas_previsao))

  cat(sprintf("Previsão de umidade em %d horas: %.1f%%\n", horas_previsao, previsao_umidade))

  if (previsao_umidade < 60) {
    cat("⚠️  ALERTA: Umidade pode ficar crítica em breve!\n")
  }

  return(list(tendencia = tendencia, previsao = previsao_umidade))
}

# Função principal
main <- function() {
  cat("Iniciando análise estatística da irrigação...\n\n")

  # Gerar dados simulados (em produção, viriam do ESP32)
  dados <- gerar_dados_simulados(50) # 50 amostras = ~2 dias

  # Análise de decisão
  resultado <- analisar_decisao_irrigacao(dados)

  # Relatório de tendência
  relatorio <- gerar_relatorio_tendencia(dados)

  # Resumo final
  cat("\nResumo Executivo\n")
  cat("================\n")
  cat("Sistema de Irrigação Inteligente - FarmTech Solutions\n")
  cat("Cultura: MILHO\n")
  cat(sprintf("Análise baseada em %d amostras\n", nrow(dados)))
  cat(sprintf("Decisão: %s\n", ifelse(resultado$deve_irrigar, "IRRIGAR", "NÃO IRRIGAR")))
  cat(sprintf("Tendência: %s\n", relatorio$tendencia))

  if (resultado$deve_irrigar) {
    cat("Ação recomendada: Ativar bomba de irrigação\n")
  } else {
    cat("Ação recomendada: Manter bomba desligada\n")
  }

  cat("\nAnálise concluída!\n")
}

# Executar análise apenas se executado diretamente
if (!exists("TEST_MODE")) {
  main()
}
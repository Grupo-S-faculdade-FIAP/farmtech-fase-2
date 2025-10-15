#!/usr/bin/env Rscript

cat("FarmTech Solutions - Testes de Análise Estatística\n")
cat("===================================================\n\n")

r <- getOption("repos")
r["CRAN"] <- "https://cloud.r-project.org/"
options(repos = r)

# Definir modo de teste para evitar execução automática
TEST_MODE <- TRUE

# Carregar funções do script principal
if (file.exists("../esp32/analise_estatistica_irrigacao.R")) {
  source("../esp32/analise_estatistica_irrigacao.R")
} else if (file.exists("src/esp32/analise_estatistica_irrigacao.R")) {
  source("src/esp32/analise_estatistica_irrigacao.R")
} else {
  stop("Não foi possível encontrar o arquivo analise_estatistica_irrigacao.R")
}

testes_passados <- 0
testes_falhados <- 0
total_testes <- 0
executar_teste <- function(nome_teste, funcao_teste) {
  total_testes <<- total_testes + 1
  cat(sprintf("\n[Teste %d] %s\n", total_testes, nome_teste))
  cat(strrep("-", 60), "\n")
  
  resultado <- tryCatch({
    funcao_teste()
    TRUE
  }, error = function(e) {
    cat("❌ FALHA:", e$message, "\n")
    FALSE
  })
  
  if (resultado) {
    testes_passados <<- testes_passados + 1
    cat("✅ PASSOU\n")
  } else {
    testes_falhados <<- testes_falhados + 1
  }
  
  return(resultado)
}

# Teste 1: Geração de dados simulados
executar_teste("Geração de dados simulados", function() {
  dados <- gerar_dados_simulados(50)
  
  stopifnot(is.data.frame(dados))
  stopifnot(nrow(dados) == 50)
  
  colunas_esperadas <- c("timestamp", "umidade", "pH", "temperatura", 
                        "nitrogenio", "fosforo", "potassio", "irrigacao_ativada")
  stopifnot(all(colunas_esperadas %in% names(dados)))
  stopifnot(all(dados$umidade >= 0 & dados$umidade <= 100))
  stopifnot(all(dados$pH >= 0 & dados$pH <= 14))
  stopifnot(all(dados$temperatura >= 5 & dados$temperatura <= 40))
  stopifnot(all(dados$nitrogenio %in% c(0, 1)))
  stopifnot(all(dados$fosforo %in% c(0, 1)))
  stopifnot(all(dados$potassio %in% c(0, 1)))
  
  cat("  - Dados gerados corretamente com", nrow(dados), "amostras\n")
  cat("  - Todas as colunas presentes\n")
  cat("  - Valores dentro dos ranges esperados\n")
})

# Teste 2: Análise de decisão de irrigação
executar_teste("Análise de decisão de irrigação", function() {
  dados_teste <- data.frame(
    timestamp = Sys.time() + seq(0, 49) * 3600,
    umidade = runif(50, 45, 55),
    pH = runif(50, 6.0, 7.0),
    temperatura = runif(50, 20, 30),
    nitrogenio = rep(1, 50),
    fosforo = rep(1, 50),
    potassio = rep(1, 50),
    irrigacao_ativada = rep(0, 50)
  )
  
  output <- capture.output({
    resultado <- analisar_decisao_irrigacao(dados_teste)
  })
  stopifnot(is.list(resultado))
  stopifnot("deve_irrigar" %in% names(resultado))
  stopifnot("motivos" %in% names(resultado))
  stopifnot(is.logical(resultado$deve_irrigar))
  
  # Com umidade baixa, deve recomendar irrigação
  stopifnot(resultado$deve_irrigar == TRUE)
  
  cat("  - Estrutura do resultado válida\n")
  cat("  - Decisão de irrigação correta para umidade baixa\n")
})

# Teste 3: Análise com condições ideais
executar_teste("Análise com condições ideais (não deve irrigar)", function() {
  # Criar dados com todas as condições ideais e variabilidade
  dados_ideais <- data.frame(
    timestamp = Sys.time() + seq(0, 49) * 3600,
    umidade = runif(50, 68, 72),  # Umidade ideal com variação
    pH = runif(50, 6.3, 6.7),     # pH ideal com variação
    temperatura = runif(50, 23, 27), # Temperatura ideal com variação
    nitrogenio = rep(1, 50),      # Nutrientes OK
    fosforo = rep(1, 50),
    potassio = rep(1, 50),
    irrigacao_ativada = rep(0, 50)
  )
  
  output <- capture.output({
    resultado <- analisar_decisao_irrigacao(dados_ideais)
  })
  
  # Com condições ideais, não deve irrigar
  stopifnot(resultado$deve_irrigar == FALSE)
  
  cat("  - Sistema não recomenda irrigação com condições ideais\n")
})

# Teste 4: Geração de relatório de tendência
executar_teste("Geração de relatório de tendência", function() {
  dados <- gerar_dados_simulados(50)
  
  output <- capture.output({
    relatorio <- gerar_relatorio_tendencia(dados)
  })
  
  # Verificar estrutura do relatório
  stopifnot(is.list(relatorio))
  stopifnot("tendencia" %in% names(relatorio))
  stopifnot("previsao" %in% names(relatorio))
  stopifnot(relatorio$tendencia %in% c("crescente", "decrescente", "estável"))
  stopifnot(is.numeric(relatorio$previsao))
  
  cat("  - Relatório de tendência gerado com sucesso\n")
  cat("  - Tendência identificada:", relatorio$tendencia, "\n")
  cat("  - Previsão:", round(relatorio$previsao, 1), "%\n")
})

# Teste 5: Validação de nutrientes
executar_teste("Análise de nutrientes insuficientes", function() {
  # Dados com nutrientes faltando e variabilidade
  dados_sem_npk <- data.frame(
    timestamp = Sys.time() + seq(0, 49) * 3600,
    umidade = runif(50, 68, 72),  # Umidade boa com variação
    pH = runif(50, 6.3, 6.7),     # pH bom com variação
    temperatura = runif(50, 23, 27), # Temperatura boa com variação
    nitrogenio = rep(0, 50),      # Sem N
    fosforo = rep(0, 50),         # Sem P
    potassio = rep(0, 50),        # Sem K
    irrigacao_ativada = rep(0, 50)
  )
  
  output <- capture.output({
    resultado <- analisar_decisao_irrigacao(dados_sem_npk)
  })
  
  # Sem NPK, deve recomendar irrigação
  stopifnot(resultado$deve_irrigar == TRUE)
  
  # Verificar se os motivos incluem nutrientes
  motivos_texto <- paste(resultado$motivos, collapse = " ")
  tem_mencao_nutrientes <- any(grepl("Nitrogênio|Fósforo|Potássio", resultado$motivos))
  stopifnot(tem_mencao_nutrientes)
  
  cat("  - Sistema detecta falta de nutrientes corretamente\n")
  cat("  - Recomenda irrigação quando NPK insuficiente\n")
})

# Teste 6: Teste de correlação
executar_teste("Cálculo de correlação umidade-temperatura", function() {
  dados <- gerar_dados_simulados(100)
  
  # Calcular correlação
  correlacao <- cor(dados$umidade, dados$temperatura)
  
  # Verificar que correlação está no range [-1, 1]
  stopifnot(correlacao >= -1 && correlacao <= 1)
  stopifnot(!is.na(correlacao))
  
  cat("  - Correlação calculada:", round(correlacao, 3), "\n")
  cat("  - Valor válido (entre -1 e 1)\n")
})

# Teste 7: Teste estatístico t-test
executar_teste("Teste t para umidade", function() {
  # Dados com umidade consistentemente baixa
  dados_baixa <- data.frame(
    timestamp = Sys.time() + seq(0, 49) * 3600,
    umidade = rnorm(50, mean = 55, sd = 5),  # Média < 60%
    pH = rep(6.5, 50),
    temperatura = rep(25, 50),
    nitrogenio = rep(1, 50),
    fosforo = rep(1, 50),
    potassio = rep(1, 50),
    irrigacao_ativada = rep(0, 50)
  )
  
  # Executar teste t
  teste_umidade <- t.test(dados_baixa$umidade, mu = 70, alternative = "less")
  
  # Verificar estrutura do teste
  stopifnot(!is.null(teste_umidade))
  stopifnot("p.value" %in% names(teste_umidade))
  stopifnot(teste_umidade$p.value >= 0 && teste_umidade$p.value <= 1)
  
  cat("  - Teste t executado com sucesso\n")
  cat("  - p-value:", round(teste_umidade$p.value, 4), "\n")
})

# Resumo dos testes
cat("\n")
cat(strrep("=", 60), "\n")
cat("RESUMO DOS TESTES\n")
cat(strrep("=", 60), "\n")
cat(sprintf("Total de testes: %d\n", total_testes))
cat(sprintf("✅ Passados: %d (%.1f%%)\n", 
            testes_passados, 
            (testes_passados/total_testes)*100))
cat(sprintf("❌ Falhados: %d (%.1f%%)\n", 
            testes_falhados, 
            (testes_falhados/total_testes)*100))
cat(strrep("=", 60), "\n")

if (testes_falhados == 0) {
  cat("\n🎉 TODOS OS TESTES PASSARAM! 🎉\n")
  cat("O sistema de análise estatística está funcionando corretamente.\n")
} else {
  cat("\n⚠️  ALGUNS TESTES FALHARAM\n")
  cat("Revise os erros acima para mais detalhes.\n")
}

# Retornar código de saída apropriado
if (testes_falhados > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}

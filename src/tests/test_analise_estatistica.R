#!/usr/bin/env Rscript

# Testes Unitários para análise_estatistica_irrigacao.R
source("../esp32/analise_estatistica_irrigacao.R")

# Função para executar testes
run_tests <- function() {
    cat("Iniciando testes unitários para análise estatística...\n")
    cat("================================================\n\n")
    
    # Teste 1: Geração de dados simulados
    cat("Teste 1: Geração de dados simulados\n")
    dados_teste <- gerar_dados_simulados(10)
    test_dados_simulados <- function() {
        if (nrow(dados_teste) != 10) {
            stop("Erro: Número incorreto de amostras geradas")
        }
        if (!all(dados_teste$umidade >= 0 & dados_teste$umidade <= 100)) {
            stop("Erro: Valores de umidade fora do range válido")
        }
        if (!all(dados_teste$pH >= 0 & dados_teste$pH <= 14)) {
            stop("Erro: Valores de pH fora do range válido")
        }
        if (!all(dados_teste$temperatura >= 5 & dados_teste$temperatura <= 40)) {
            stop("Erro: Valores de temperatura fora do range válido")
        }
        cat("✓ OK: Dados simulados gerados corretamente\n")
    }
    tryCatch(test_dados_simulados(), error = function(e) cat("❌ FALHA:", e$message, "\n"))
    
    # Teste 2: Análise de decisão de irrigação
    cat("\nTeste 2: Análise de decisão de irrigação\n")
    test_decisao_irrigacao <- function() {
        dados_criticos <- data.frame(
            timestamp = Sys.time() + 1:5,
            umidade = c(30, 25, 20, 15, 10),
            pH = c(6.5, 6.5, 6.5, 6.5, 6.5),
            temperatura = c(25, 25, 25, 25, 25),
            nitrogenio = c(0, 0, 0, 0, 0),
            fosforo = c(0, 0, 0, 0, 0),
            potassio = c(0, 0, 0, 0, 0),
            irrigacao_ativada = c(0, 0, 0, 0, 0)
        )
        resultado <- analisar_decisao_irrigacao(dados_criticos)
        cat("✓ OK: Análise de decisão executada com sucesso\n")
    }
    tryCatch(test_decisao_irrigacao(), error = function(e) cat("❌ FALHA:", e$message, "\n"))

    cat("\nTestes concluídos!\n")
}

# Executar testes
run_tests()
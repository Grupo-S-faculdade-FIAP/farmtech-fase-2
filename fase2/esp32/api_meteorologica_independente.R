#!/usr/bin/env Rscript

# FarmTech Solutions - API Meteorológica Independente (Fase 2)
# Script autônomo para obter dados meteorológicos para o ESP32

# Configurar mirror do CRAN
r <- getOption("repos")
r["CRAN"] <- "https://cloud.r-project.org/"
options(repos = r)

# Carregar bibliotecas necessárias
if (!require("httr")) install.packages("httr")
if (!require("jsonlite")) install.packages("jsonlite")

library(httr)
library(jsonlite)

consultar_clima_independente <- function(cidade = "São Paulo", pais = "BR", dias = 3) {
  # API key para WeatherAPI (mesma da Fase 1)
  api_key <- "69c06b5e946f4906ba6200400251309"

  # Construir URL
  query <- paste0(cidade, ",", pais)
  query_encoded <- URLencode(query)
  url <- paste0("https://api.weatherapi.com/v1/forecast.json?key=",
               api_key, "&q=", query_encoded, "&days=", dias)

  # Fazer requisição
  response <- tryCatch({
    GET(url)
  }, error = function(e) {
    cat("ERRO: Falha na conexão com API\n")
    return(NULL)
  })

  if (is.null(response) || status_code(response) != 200) {
    cat("ERRO: API não respondeu corretamente\n")
    return(NULL)
  }

  # Processar dados
  dados <- fromJSON(content(response, "text", encoding = "UTF-8"))

  # Extrair dados relevantes para ESP32
  resultado <- list(
    chance_chuva = 0,
    temp_max = 25,
    temp_min = 15,
    condicao = "Indefinido"
  )

  tryCatch({
    # Chance de chuva (média dos próximos dias)
    if (!is.null(dados$forecast$forecastday)) {
      forecastday <- dados$forecast$forecastday
      if (is.data.frame(forecastday) && nrow(forecastday) > 0) {
        # Usar a maior chance de chuva dos próximos dias
        chances <- numeric(0)
        for (i in 1:min(nrow(forecastday), dias)) {
          if ("day" %in% names(forecastday)) {
            day_row <- forecastday$day[i,]
            if ("daily_chance_of_rain" %in% names(day_row)) {
              chances <- c(chances, day_row$daily_chance_of_rain)
            }
          }
        }
        if (length(chances) > 0) {
          resultado$chance_chuva <- max(chances)  # Maior chance de chuva
        }
      }
    }

    # Temperaturas
    if (!is.null(dados$forecast$forecastday)) {
      forecastday <- dados$forecast$forecastday
      if (is.data.frame(forecastday) && nrow(forecastday) > 0) {
        temps_max <- numeric(0)
        temps_min <- numeric(0)

        for (i in 1:min(nrow(forecastday), dias)) {
          if ("day" %in% names(forecastday)) {
            day_row <- forecastday$day[i,]
            if ("maxtemp_c" %in% names(day_row)) {
              temps_max <- c(temps_max, day_row$maxtemp_c)
            }
            if ("mintemp_c" %in% names(day_row)) {
              temps_min <- c(temps_min, day_row$mintemp_c)
            }
          }
        }

        if (length(temps_max) > 0) resultado$temp_max <- max(temps_max)
        if (length(temps_min) > 0) resultado$temp_min <- min(temps_min)
      }
    }

    # Condição atual
    if (!is.null(dados$current$condition$text)) {
      resultado$condicao <- dados$current$condition$text
    }

  }, error = function(e) {
    cat("AVISO: Erro ao processar dados, usando valores padrão\n")
  })

  return(resultado)
}

# Função principal
main <- function() {
  cat("FarmTech Solutions - API Meteorológica (Fase 2)\n")
  cat("Obtendo dados para integração com ESP32...\n\n")

  # Consultar clima
  dados <- consultar_clima_independente()

  if (is.null(dados)) {
    cat("ERRO: Não foi possível obter dados meteorológicos\n")
    # Dados de fallback para teste
    dados <- list(
      chance_chuva = 25.0,
      temp_max = 28.0,
      temp_min = 18.0,
      condicao = "Parcialmente nublado"
    )
    cat("Usando dados de exemplo para teste...\n")
  }

  # Formatar saída para ESP32
  linha_esp32 <- sprintf("CHUVA:%.1f;TEMP_MAX:%.1f;TEMP_MIN:%.1f;CONDICAO:%s",
                        dados$chance_chuva,
                        dados$temp_max,
                        dados$temp_min,
                        dados$condicao)

  # Exibir informações
  cat("Dados meteorológicos obtidos:\n")
  cat(sprintf("  Chance de chuva: %.1f%%\n", dados$chance_chuva))
  cat(sprintf("  Temperatura: %.1f°C - %.1f°C\n", dados$temp_min, dados$temp_max))
  cat(sprintf("  Condição: %s\n", dados$condicao))
  cat("\n")

  # Saída formatada para ESP32
  cat("LINHA PARA ESP32 (copie e cole no Serial Monitor):\n")
  cat("==================================================\n")
  cat(linha_esp32, "\n")
  cat("==================================================\n")

  cat("\nInstruções:\n")
  cat("1. Copie a linha acima\n")
  cat("2. Abra o Serial Monitor do ESP32 no Wokwi\n")
  cat("3. Cole a linha e pressione Enter\n")
  cat("4. O ESP32 irá ajustar a irrigação automaticamente!\n")
}

# Executar se chamado diretamente
if (!interactive()) {
  main()
}

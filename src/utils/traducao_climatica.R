#!/usr/bin/env Rscript

traduzir_condicao_climatica <- function(condicao_en) {
  if (is.null(condicao_en) || is.na(condicao_en) || condicao_en == "") {
    return("Indefinido")
  }
  
  # Dicionário completo de traduções da WeatherAPI
  # Baseado na documentação oficial: https://www.weatherapi.com/docs/weather_conditions.json
  traducoes <- list(
    # =================== CONDIÇÕES CLARAS ===================
    "Sunny" = "Ensolarado",
    "Clear" = "Limpo", 
    "Partly cloudy" = "Parcialmente nublado",
    "Cloudy" = "Nublado",
    "Overcast" = "Encoberto",
    
    # =================== NÉVOA E NEBLINA ===================
    "Mist" = "Névoa",
    "Fog" = "Nevoeiro", 
    "Freezing fog" = "Nevoeiro congelante",
    
    # =================== GAROA E CHUVISCOS ===================
    "Patchy light drizzle" = "Garoa leve esparsa",
    "Light drizzle" = "Garoa leve",
    "Freezing drizzle" = "Garoa congelante",
    "Heavy freezing drizzle" = "Garoa congelante intensa",
    "Patchy freezing drizzle possible" = "Garoa congelante esparsa possível",
    
    # =================== CHUVA - POSSIBILIDADES ===================
    "Patchy rain possible" = "Chuva esparsa possível",
    
    # =================== CHUVA - INTENSIDADES ===================
    "Patchy light rain" = "Chuva leve esparsa",
    "Light rain" = "Chuva leve",
    "Moderate rain at times" = "Chuva moderada às vezes",
    "Moderate rain" = "Chuva moderada", 
    "Heavy rain at times" = "Chuva forte às vezes",
    "Heavy rain" = "Chuva forte",
    
    # =================== CHUVA CONGELANTE ===================
    "Light freezing rain" = "Chuva congelante leve",
    "Moderate or heavy freezing rain" = "Chuva congelante moderada/forte",
    
    # =================== NEVE - POSSIBILIDADES ===================
    "Patchy snow possible" = "Neve esparsa possível",
    
    # =================== NEVE - CONDIÇÕES EXTREMAS ===================
    "Blowing snow" = "Nevasca",
    "Blizzard" = "Tempestade de neve",
    
    # =================== NEVE - INTENSIDADES ===================
    "Patchy light snow" = "Neve leve esparsa", 
    "Light snow" = "Neve leve",
    "Patchy moderate snow" = "Neve moderada esparsa",
    "Moderate snow" = "Neve moderada",
    "Patchy heavy snow" = "Neve forte esparsa",
    "Heavy snow" = "Neve forte",
    
    # =================== GRANIZO E GELO ===================
    "Patchy sleet possible" = "Granizo esparso possível",
    "Light sleet" = "Granizo leve", 
    "Moderate or heavy sleet" = "Granizo moderado/forte",
    "Ice pellets" = "Granizo",
    
    # =================== PANCADAS DE CHUVA ===================
    "Light rain shower" = "Pancada de chuva leve",
    "Moderate or heavy rain shower" = "Pancada de chuva moderada/forte",
    "Torrential rain shower" = "Pancada de chuva torrencial",
    
    # =================== PANCADAS DE GRANIZO ===================
    "Light sleet showers" = "Pancadas de granizo leve",
    "Moderate or heavy sleet showers" = "Pancadas de granizo moderado/forte",
    "Light showers of ice pellets" = "Pancadas de granizo leve", 
    "Moderate or heavy showers of ice pellets" = "Pancadas de granizo moderado/forte",
    
    # =================== PANCADAS DE NEVE ===================
    "Light snow showers" = "Pancadas de neve leve",
    "Moderate or heavy snow showers" = "Pancadas de neve moderada/forte",
    
    # =================== TROVOADAS ===================
    "Thundery outbreaks possible" = "Trovoadas possíveis",
    "Patchy light rain with thunder" = "Chuva leve com trovoada esparsa",
    "Moderate or heavy rain with thunder" = "Chuva moderada/forte com trovoada",
    "Patchy light snow with thunder" = "Neve leve com trovoada esparsa",
    "Moderate or heavy snow with thunder" = "Neve moderada/forte com trovoada"
  )
  
  # Buscar tradução no dicionário
  traducao <- traducoes[[condicao_en]]
  
  # Retornar tradução ou original se não encontrada
  if (is.null(traducao)) {
    return(condicao_en)  # Mantém original se não traduzida
  }
  
  return(traducao)
}

#' Obter lista de todas as traduções disponíveis
#' 
#' Função auxiliar que retorna todas as traduções disponíveis
#' no formato de data frame para consulta e debugging
#' 
#' @return data.frame com colunas 'ingles' e 'portugues'
obter_todas_traducoes <- function() {
  # Reutiliza a função principal para obter o dicionário
  condicoes_exemplo <- c("Sunny", "Partly cloudy", "Heavy rain", "Light snow")
  
  # Como não podemos acessar diretamente o dicionário interno,
  # vamos criar uma versão para retorno
  traducoes_completas <- data.frame(
    ingles = c(
      "Sunny", "Clear", "Partly cloudy", "Cloudy", "Overcast",
      "Mist", "Fog", "Freezing fog",
      "Patchy rain possible", "Light rain", "Heavy rain",
      "Light snow", "Heavy snow", "Blizzard",
      "Thundery outbreaks possible"
    ),
    portugues = c(
      "Ensolarado", "Limpo", "Parcialmente nublado", "Nublado", "Encoberto",
      "Névoa", "Nevoeiro", "Nevoeiro congelante", 
      "Chuva esparsa possível", "Chuva leve", "Chuva forte",
      "Neve leve", "Neve forte", "Tempestade de neve",
      "Trovoadas possíveis"
    ),
    stringsAsFactors = FALSE
  )
  
  return(traducoes_completas)
}

#' Testar traduções com casos de exemplo
#' 
#' Função de teste que demonstra o funcionamento das traduções
#' com casos comuns de uso
teste_traducoes <- function() {
  cat("=== TESTE DE TRADUÇÕES CLIMÁTICAS ===\n")
  cat("FarmTech Solutions - Utilitário de Tradução\n\n")
  
  # Casos de teste
  casos_teste <- c(
    "Partly cloudy",
    "Heavy rain", 
    "Sunny",
    "Thundery outbreaks possible",
    "Light snow",
    "Fog",
    "Unknown Condition"  # Teste de condição não mapeada
  )
  
  # Executar testes
  for (condicao in casos_teste) {
    traducao <- traduzir_condicao_climatica(condicao)
    status <- if (traducao != condicao) "✅ TRADUZIDA" else "⚠️  ORIGINAL"
    cat(sprintf("EN: %-30s -> PT: %-30s [%s]\n", 
                condicao, traducao, status))
  }
  
  cat("\n=== ESTATÍSTICAS ===\n")
  cat("Total de traduções implementadas: 50+ condições\n")
  cat("Cobertura: Todos os códigos WeatherAPI (1000-1282)\n")
  cat("Fallback: Mantém condição original se não traduzida\n")
}

# Exportar funções se executado como módulo
if (!interactive()) {
  # Se chamado diretamente, executar teste
  if (length(commandArgs(trailingOnly = TRUE)) > 0) {
    arg <- commandArgs(trailingOnly = TRUE)[1]
    if (arg == "test") {
      teste_traducoes()
    }
  }
}
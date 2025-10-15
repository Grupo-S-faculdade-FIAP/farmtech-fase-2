#!/usr/bin/env python3
"""
FarmTech Solutions - Utilitário de Tradução Climática (Python)
============================================================================
Módulo Python equivalente ao módulo R para tradução das condições climáticas 
da WeatherAPI para português brasileiro. Permite reutilização da funcionalidade
de tradução em diferentes contextos e linguagens do projeto.

Autor: FarmTech Solutions
Data: 2025
Versão: 1.0
============================================================================
"""

from typing import Dict, List, Tuple, Optional
import logging

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TradutorClimatico:
    """
    Classe para tradução de condições climáticas da WeatherAPI
    para português brasileiro.
    """
    
    def __init__(self):
        """Inicializa o tradutor com o dicionário completo de traduções."""
        self._traducoes = self._criar_dicionario_traducoes()
        logger.debug(f"Tradutor inicializado com {len(self._traducoes)} traduções")
    
    def _criar_dicionario_traducoes(self) -> Dict[str, str]:
        """
        Cria o dicionário completo de traduções da WeatherAPI.
        
        Baseado na documentação oficial:
        https://www.weatherapi.com/docs/weather_conditions.json
        
        Returns:
            Dict[str, str]: Dicionário com traduções inglês -> português
        """
        return {
            # =================== CONDIÇÕES CLARAS ===================
            "Sunny": "Ensolarado",
            "Clear": "Limpo", 
            "Partly cloudy": "Parcialmente nublado",
            "Cloudy": "Nublado",
            "Overcast": "Encoberto",
            
            # =================== NÉVOA E NEBLINA ===================
            "Mist": "Névoa",
            "Fog": "Nevoeiro", 
            "Freezing fog": "Nevoeiro congelante",
            
            # =================== GAROA E CHUVISCOS ===================
            "Patchy light drizzle": "Garoa leve esparsa",
            "Light drizzle": "Garoa leve",
            "Freezing drizzle": "Garoa congelante",
            "Heavy freezing drizzle": "Garoa congelante intensa",
            "Patchy freezing drizzle possible": "Garoa congelante esparsa possível",
            
            # =================== CHUVA - POSSIBILIDADES ===================
            "Patchy rain possible": "Chuva esparsa possível",
            
            # =================== CHUVA - INTENSIDADES ===================
            "Patchy light rain": "Chuva leve esparsa",
            "Light rain": "Chuva leve",
            "Moderate rain at times": "Chuva moderada às vezes",
            "Moderate rain": "Chuva moderada", 
            "Heavy rain at times": "Chuva forte às vezes",
            "Heavy rain": "Chuva forte",
            
            # =================== CHUVA CONGELANTE ===================
            "Light freezing rain": "Chuva congelante leve",
            "Moderate or heavy freezing rain": "Chuva congelante moderada/forte",
            
            # =================== NEVE - POSSIBILIDADES ===================
            "Patchy snow possible": "Neve esparsa possível",
            
            # =================== NEVE - CONDIÇÕES EXTREMAS ===================
            "Blowing snow": "Nevasca",
            "Blizzard": "Tempestade de neve",
            
            # =================== NEVE - INTENSIDADES ===================
            "Patchy light snow": "Neve leve esparsa", 
            "Light snow": "Neve leve",
            "Patchy moderate snow": "Neve moderada esparsa",
            "Moderate snow": "Neve moderada",
            "Patchy heavy snow": "Neve forte esparsa",
            "Heavy snow": "Neve forte",
            
            # =================== GRANIZO E GELO ===================
            "Patchy sleet possible": "Granizo esparso possível",
            "Light sleet": "Granizo leve", 
            "Moderate or heavy sleet": "Granizo moderado/forte",
            "Ice pellets": "Granizo",
            
            # =================== PANCADAS DE CHUVA ===================
            "Light rain shower": "Pancada de chuva leve",
            "Moderate or heavy rain shower": "Pancada de chuva moderada/forte",
            "Torrential rain shower": "Pancada de chuva torrencial",
            
            # =================== PANCADAS DE GRANIZO ===================
            "Light sleet showers": "Pancadas de granizo leve",
            "Moderate or heavy sleet showers": "Pancadas de granizo moderado/forte",
            "Light showers of ice pellets": "Pancadas de granizo leve", 
            "Moderate or heavy showers of ice pellets": "Pancadas de granizo moderado/forte",
            
            # =================== PANCADAS DE NEVE ===================
            "Light snow showers": "Pancadas de neve leve",
            "Moderate or heavy snow showers": "Pancadas de neve moderada/forte",
            
            # =================== TROVOADAS ===================
            "Thundery outbreaks possible": "Trovoadas possíveis",
            "Patchy light rain with thunder": "Chuva leve com trovoada esparsa",
            "Moderate or heavy rain with thunder": "Chuva moderada/forte com trovoada",
            "Patchy light snow with thunder": "Neve leve com trovoada esparsa",
            "Moderate or heavy snow with thunder": "Neve moderada/forte com trovoada"
        }
    
    def traduzir(self, condicao_en: Optional[str]) -> str:
        """
        Traduz uma condição climática do inglês para o português.
        
        Args:
            condicao_en: Condição climática em inglês da WeatherAPI
            
        Returns:
            str: Condição traduzida para português, ou original se não traduzida
            
        Examples:
            >>> tradutor = TradutorClimatico()
            >>> tradutor.traduzir("Partly cloudy")
            'Parcialmente nublado'
            >>> tradutor.traduzir("Heavy rain")
            'Chuva forte'
        """
        # Validação de entrada
        if not condicao_en or condicao_en.strip() == "":
            return "Indefinido"
        
        # Buscar tradução
        traducao = self._traducoes.get(condicao_en.strip())
        
        # Retornar tradução ou original
        if traducao:
            logger.debug(f"Traduzido: '{condicao_en}' -> '{traducao}'")
            return traducao
        else:
            logger.debug(f"Sem tradução para: '{condicao_en}' (mantendo original)")
            return condicao_en
    
    def obter_todas_traducoes(self) -> List[Tuple[str, str]]:
        """
        Retorna todas as traduções disponíveis.
        
        Returns:
            List[Tuple[str, str]]: Lista de tuplas (inglês, português)
        """
        return list(self._traducoes.items())
    
    def obter_estatisticas(self) -> Dict[str, int]:
        """
        Retorna estatísticas do tradutor.
        
        Returns:
            Dict[str, int]: Estatísticas com total de traduções
        """
        return {
            "total_traducoes": len(self._traducoes),
            "cobertura_aproximada": 95  # Baseado nos códigos da WeatherAPI
        }


def traduzir_condicao_climatica(condicao_en: str) -> str:
    """
    Função standalone para tradução (compatibilidade com código existente).
    
    Args:
        condicao_en: Condição climática em inglês
        
    Returns:
        str: Condição traduzida para português
    """
    tradutor = TradutorClimatico()
    return tradutor.traduzir(condicao_en)


def testar_traducoes():
    """
    Executa testes de demonstração das traduções.
    """
    print("=== TESTE DE TRADUÇÕES CLIMÁTICAS (Python) ===")
    print("FarmTech Solutions - Utilitário de Tradução")
    print()
    
    # Criar instância do tradutor
    tradutor = TradutorClimatico()
    
    # Casos de teste
    casos_teste = [
        "Partly cloudy",
        "Heavy rain", 
        "Sunny",
        "Thundery outbreaks possible",
        "Light snow",
        "Fog",
        "Unknown Condition"  # Teste de condição não mapeada
    ]
    
    # Executar testes
    for condicao in casos_teste:
        traducao = tradutor.traduzir(condicao)
        status = "✅ TRADUZIDA" if traducao != condicao else "⚠️  ORIGINAL"
        print(f"EN: {condicao:<30} -> PT: {traducao:<30} [{status}]")
    
    # Estatísticas
    stats = tradutor.obter_estatisticas()
    print(f"\n=== ESTATÍSTICAS ===")
    print(f"Total de traduções implementadas: {stats['total_traducoes']} condições")
    print(f"Cobertura estimada: {stats['cobertura_aproximada']}% dos códigos WeatherAPI")
    print("Códigos suportados: 1000-1282 (WeatherAPI.com)")
    print("Fallback: Mantém condição original se não traduzida")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        testar_traducoes()
    else:
        # Uso básico se executado diretamente
        print("FarmTech Solutions - Tradutor Climático Python")
        print("Use 'python traducao_climatica.py test' para executar testes")
        print("\nExemplo de uso:")
        print(">>> from traducao_climatica import traduzir_condicao_climatica")
        print(">>> traduzir_condicao_climatica('Partly cloudy')")
        print("'Parcialmente nublado'")
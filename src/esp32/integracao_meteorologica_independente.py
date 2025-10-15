#!/usr/bin/env python3
"""
FarmTech Solutions - Integração Meteorológica Independente
Sistema de integração entre ESP32 e API meteorológica via script R

Este módulo fornece funções para:
- Executar script R de API meteorológica
- Processar dados meteorológicos
- Formatar dados para envio ao ESP32
- Decidir sobre necessidade de irrigação baseado no clima

Autor: FarmTech Solutions
Data: 2025
"""

import subprocess
import os
import sys
import json
from datetime import datetime
import logging

# Adicionar o diretório utils ao path para importar o módulo de tradução
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "utils"))

try:
    from traducao_climatica import traduzir_condicao_climatica
    TRADUTOR_DISPONIVEL = True
    logger = logging.getLogger(__name__)
    logger.info("Módulo de tradução climática carregado com sucesso")
except ImportError:
    TRADUTOR_DISPONIVEL = False
    logger = logging.getLogger(__name__)
    logger.warning("Módulo de tradução não disponível, usando script R para tradução")

# Configuração de logging aprimorada
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


def validar_coordenadas(latitude: float, longitude: float) -> None:
    """
    Valida se as coordenadas geográficas estão dentro dos limites válidos.
    
    Args:
        latitude (float): Latitude em graus decimais (-90 a 90)
        longitude (float): Longitude em graus decimais (-180 a 180)
    
    Raises:
        ValueError: Se as coordenadas estiverem fora dos limites válidos
    """
    if not -90 <= latitude <= 90:
        logger.error(f"Latitude {latitude} inválida. Deve estar entre -90 e 90.")
        raise ValueError(f"Latitude {latitude} inválida. Deve estar entre -90 e 90.")
    if not -180 <= longitude <= 180:
        logger.error(f"Longitude {longitude} inválida. Deve estar entre -180 e 180.")
        raise ValueError(f"Longitude {longitude} inválida. Deve estar entre -180 e 180.")
    
    logger.debug(f"Coordenadas válidas: lat={latitude}, lon={longitude}")


def obter_dados_meteorologicos(latitude: float, longitude: float) -> dict:
    """
    Obtém dados meteorológicos simulados para as coordenadas fornecidas.
    
    Em produção, esta função se conectaria a uma API meteorológica real.
    Para testes, retorna dados simulados realistas.
    
    Args:
        latitude (float): Latitude da localização
        longitude (float): Longitude da localização
    
    Returns:
        dict: Dicionário com dados meteorológicos contendo:
            - temperatura: Temperatura em °C
            - umidade: Umidade relativa do ar em %
            - chance_chuva: Probabilidade de chuva em %
            - condicao: Descrição textual da condição climática
            - precipitacao_mm: Precipitação prevista em milímetros
    
    Raises:
        ValueError: Se as coordenadas forem inválidas
    """
    logger.info(f"Obtendo dados meteorológicos para lat={latitude}, lon={longitude}")
    
    # Validar coordenadas antes de prosseguir
    validar_coordenadas(latitude, longitude)
    
    # Dados simulados para demonstração
    # Em produção, aqui seria feita uma chamada à API real
    dados = {
        "temperatura": 25.0,
        "umidade": 65.0,
        "chance_chuva": 30.0,
        "condicao": "Parcialmente nublado",
        "precipitacao_mm": 0.0
    }
    
    logger.info(f"Dados obtidos: temp={dados['temperatura']}°C, umidade={dados['umidade']}%")
    return dados


def processar_previsao(dados: dict) -> bool:
    """
    Processa dados meteorológicos e decide se deve irrigar.
    
    Lógica de decisão baseada em parâmetros agrícolas para cultura do milho:
    - NÃO irrigar se: alta chance de chuva (>70%), precipitação prevista (>5mm) ou solo já úmido (>80%)
    - IRRIGAR se: solo muito seco (<60%) ou temperatura alta (>30°C)
    
    Args:
        dados (dict): Dicionário com dados meteorológicos contendo pelo menos:
                     temperatura, umidade e chance_chuva
    
    Returns:
        bool: True se deve irrigar, False caso contrário
    
    Raises:
        ValueError: Se os dados estiverem incompletos
    """
    logger.info("Processando previsão meteorológica para decisão de irrigação")
    
    # Validar dados de entrada
    campos_necessarios = ["temperatura", "umidade", "chance_chuva"]
    if not all(k in dados for k in campos_necessarios):
        campos_faltando = [k for k in campos_necessarios if k not in dados]
        logger.error(f"Dados meteorológicos incompletos. Faltando: {campos_faltando}")
        raise ValueError(f"Dados meteorológicos incompletos. Campos necessários: {campos_necessarios}")
    
    # Critérios para NÃO irrigar (condições desfavoráveis)
    if dados["chance_chuva"] > 70:
        logger.info(f"Não irrigar: Alta chance de chuva ({dados['chance_chuva']}%)")
        return False
    
    if dados.get("precipitacao_mm", 0) > 5:
        logger.info(f"Não irrigar: Previsão de chuva significativa ({dados['precipitacao_mm']}mm)")
        return False
    
    if dados["umidade"] > 80:
        logger.info(f"Não irrigar: Solo já está úmido ({dados['umidade']}%)")
        return False
    
    # Critérios para IRRIGAR (necessidade detectada)
    if dados["umidade"] < 60:
        logger.info(f"Irrigar: Solo muito seco ({dados['umidade']}%)")
        return True
    
    if dados["temperatura"] > 30:
        logger.info(f"Irrigar: Temperatura alta ({dados['temperatura']}°C)")
        return True
    
    logger.info("Condições normais: irrigação não necessária")
    return False


def executar_api_r_independente() -> str:
    """
    Executa o script R de API meteorológica e retorna sua saída.
    
    O script R consulta a API WeatherAPI e retorna dados formatados.
    Esta função gerencia a execução do processo externo e captura sua saída.
    
    Returns:
        str: Saída do script R contendo dados meteorológicos formatados,
             ou None em caso de erro
    
    Raises:
        FileNotFoundError: Se Rscript não estiver instalado
        subprocess.TimeoutExpired: Se o script R demorar mais de 30 segundos
    """
    logger.info("Iniciando execução do script R de API meteorológica")
    
    try:
        # Determinar caminho absoluto do script R
        script_path = os.path.join(
            os.path.dirname(__file__), 
            "api_meteorologica_independente.R"
        )
        
        if not os.path.exists(script_path):
            logger.error(f"Script R não encontrado em: {script_path}")
            return None
        
        logger.debug(f"Executando script R: {script_path}")
        
        # Executar Rscript com timeout de 30 segundos
        result = subprocess.run(
            ["Rscript", script_path],
            capture_output=True,
            text=True,
            timeout=30,
            encoding='utf-8',
            errors='ignore'  # Ignorar erros de encoding para maior compatibilidade
        )
        
        # Verificar código de retorno
        if result.returncode == 0:
            logger.info("Script R executado com sucesso")
            logger.debug(f"Saída do script R: {result.stdout[:200]}...")  # Log primeiros 200 chars
            return result.stdout
        else:
            logger.error(f"Script R falhou com código {result.returncode}")
            logger.error(f"Erro: {result.stderr}")
            return None
    
    except subprocess.TimeoutExpired:
        logger.error("Timeout ao executar script R (limite: 30 segundos)")
        return None
    
    except FileNotFoundError:
        logger.error("Rscript não encontrado. Verifique se o R está instalado e no PATH")
        return None
    
    except Exception as e:
        logger.error(f"Erro inesperado ao executar API R: {e}", exc_info=True)
        return None


def extrair_dados_formatados(saida_r: str) -> str:
    """
    Extrai a linha formatada para ESP32 da saída do script R.
    
    Procura pela linha no formato:
    CHUVA:xx.x;TEMP_MAX:yy.y;TEMP_MIN:zz.z;CONDICAO:texto
    
    Args:
        saida_r (str): Saída completa do script R
    
    Returns:
        str: Linha formatada para ESP32, ou None se não encontrada
    """
    logger.info("Extraindo dados formatados da saída do R")
    
    if not saida_r:
        logger.warning("Saída do R está vazia")
        return None
    
    linhas = saida_r.split('\n')
    
    for i, linha in enumerate(linhas):
        linha = linha.strip()
        
        # Procurar pela linha que contém todos os campos esperados
        if (linha.startswith("CHUVA:") and 
            "TEMP_MAX:" in linha and 
            "TEMP_MIN:" in linha and
            "CONDICAO:" in linha):
            
            logger.info(f"Dados formatados encontrados na linha {i+1}")
            logger.debug(f"Dados: {linha}")
            return linha
    
    logger.warning("Linha formatada não encontrada na saída do R")
    return None


def validar_dados_formatados(dados_formatados: str) -> bool:
    """
    Valida se os dados formatados estão no formato esperado.
    
    Args:
        dados_formatados (str): Linha formatada para validar
    
    Returns:
        bool: True se válido, False caso contrário
    """
    try:
        partes = dados_formatados.split(";")
        if len(partes) < 4:
            logger.warning(f"Dados formatados incompletos: {len(partes)} partes encontradas, esperado >= 4")
            return False
        
        # Verificar se cada parte tem formato chave:valor
        for parte in partes:
            if ":" not in parte:
                logger.warning(f"Parte sem formato chave:valor: {parte}")
                return False
        
        return True
    except Exception as e:
        logger.error(f"Erro ao validar dados formatados: {e}")
        return False


def main():
    """
    Função principal do módulo.
    
    Fluxo de execução:
    1. Executa script R para obter dados meteorológicos
    2. Extrai e valida dados formatados
    3. Exibe informações processadas
    4. Fornece instruções para uso no ESP32
    """
    print("\n" + "="*70)
    print("FarmTech Solutions - Integração Meteorológica Independente")
    print("Sistema de Irrigação Inteligente para Cultura de Milho")
    print("="*70 + "\n")
    
    logger.info("Iniciando processo de integração meteorológica")
    
    # Executar API R independente
    logger.info("Etapa 1/3: Consultando API meteorológica via script R...")
    saida_r = executar_api_r_independente()
    
    # Determinar dados a usar (API ou fallback)
    if saida_r is None:
        logger.warning("Falha ao obter dados da API meteorológica")
        print("⚠️  Falha ao obter dados meteorológicos da API.")
        print("📋 Usando dados de exemplo para demonstração...\n")
        
        # Dados de fallback para demonstração/teste
        dados_formatados = "CHUVA:25.0;TEMP_MAX:28.0;TEMP_MIN:18.0;CONDICAO:Parcialmente nublado"
    else:
        logger.info("Etapa 2/3: Extraindo dados formatados...")
        dados_formatados = extrair_dados_formatados(saida_r)
        
        if dados_formatados is None:
            logger.warning("Não foi possível extrair dados formatados da saída do R")
            print("⚠️  Não foi possível processar a saída da API.")
            print("📋 Usando dados de exemplo para demonstração...\n")
            dados_formatados = "CHUVA:25.0;TEMP_MAX:28.0;TEMP_MIN:18.0;CONDICAO:Parcialmente nublado"
        else:
            print("✅ Dados meteorológicos obtidos com sucesso!\n")
    
    # Validar dados formatados
    if not validar_dados_formatados(dados_formatados):
        logger.error("Dados formatados falharam na validação")
        print("❌ ERRO: Dados formatados inválidos")
        return
    
    # Exibir informações extraídas de forma amigável
    logger.info("Etapa 3/3: Processando e exibindo dados...")
    try:
        print("📊 DADOS METEOROLÓGICOS PROCESSADOS:")
        print("-" * 50)
        
        partes = dados_formatados.split(";")
        dados_dict = {}
        
        for parte in partes:
            if ":" in parte:
                chave, valor = parte.split(":", 1)
                dados_dict[chave] = valor
        
        # Exibir cada campo de forma formatada
        chance_chuva = dados_dict.get('CHUVA', 'N/A')
        temp_min = dados_dict.get('TEMP_MIN', 'N/A')
        temp_max = dados_dict.get('TEMP_MAX', 'N/A')
        condicao = dados_dict.get('CONDICAO', 'N/A')
        
        print(f"  🌧️  Chance de chuva: {chance_chuva}%")
        print(f"  🌡️  Temperatura: {temp_min}°C - {temp_max}°C")
        print(f"  ☁️  Condição: {condicao}")
        print("-" * 50)
        
        # Análise de irrigação
        try:
            chance_num = float(chance_chuva)
            if chance_num > 70:
                print("\n💡 RECOMENDAÇÃO: Não irrigar (alta probabilidade de chuva)")
            elif chance_num < 30:
                print("\n💡 RECOMENDAÇÃO: Considerar irrigação (baixa probabilidade de chuva)")
            else:
                print("\n💡 RECOMENDAÇÃO: Monitorar condições (probabilidade moderada de chuva)")
        except:
            pass
        
    except Exception as e:
        logger.error(f"Erro ao processar dados para exibição: {e}", exc_info=True)
        print(f"❌ Erro ao processar dados: {e}")
    
    # Instruções para ESP32
    print("\n" + "="*70)
    print("📤 ENVIAR PARA ESP32 (WOKWI SERIAL MONITOR)")
    print("="*70)
    print(dados_formatados)
    print("="*70)
    
    print("\n📝 INSTRUÇÕES DE USO:")
    print("  1. Abra o Serial Monitor no Wokwi.com")
    print("  2. Copie a linha acima (CHUVA:...)")
    print("  3. Cole no campo de entrada do Serial Monitor")
    print("  4. Pressione Enter")
    print("  5. O ESP32 processará automaticamente e ajustará a irrigação!")
    
    print("\n✅ Processo concluído com sucesso!")
    logger.info("Processo de integração meteorológica finalizado")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Processo interrompido pelo usuário")
        logger.info("Execução interrompida pelo usuário")
    except Exception as e:
        print(f"\n❌ ERRO FATAL: {e}")
        logger.critical(f"Erro fatal na execução: {e}", exc_info=True)

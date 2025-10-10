#!/usr/bin/env python3
"""
FarmTech Solutions - Integração Meteorológica Independente (Fase 2)

Script Python autônomo para obter dados meteorológicos e formatar para ESP32.
Não depende de nenhum código da Fase 1.
"""

import subprocess
import sys
import os
import json
from datetime import datetime

def executar_api_r_independente():
    """Executa o script R independente da Fase 2"""
    try:
        # Caminho para o script R independente da Fase 2
        script_path = os.path.join(os.path.dirname(__file__), "api_meteorologica_independente.R")

        print("Executando API meteorológica independente (Fase 2)...")

        # Executar Rscript
        result = subprocess.run(
            ["Rscript", script_path],
            capture_output=True,
            text=True,
            timeout=30,
            encoding='utf-8',
            errors='ignore'  # Ignorar erros de encoding
        )

        if result.returncode == 0:
            return result.stdout
        else:
            print(f"Erro ao executar script R: {result.stderr}")
            return None

    except subprocess.TimeoutExpired:
        print("Timeout ao executar script R")
        return None
    except FileNotFoundError:
        print("Rscript não encontrado. Instale o R primeiro.")
        return None
    except Exception as e:
        print(f"Erro ao executar API: {e}")
        return None

def extrair_dados_formatados(saida_r):
    """Extrai a linha formatada para ESP32 da saída do R"""
    linhas = saida_r.split('\n')

    for linha in linhas:
        linha = linha.strip()
        # Procurar pela linha que começa com "CHUVA:"
        if linha.startswith("CHUVA:") and "TEMP_MAX:" in linha and "TEMP_MIN:" in linha:
            return linha

    return None

def main():
    print("FarmTech Solutions - Integração Meteorológica Independente")
    print("=" * 50)

    # Executar API R independente
    saida_r = executar_api_r_independente()

    if saida_r is None:
        print("Falha ao obter dados meteorológicos.")
        # Dados de fallback para teste
        dados_formatados = "CHUVA:25.0;TEMP_MAX:28.0;TEMP_MIN:18.0;CONDICAO:Parcialmente nublado"
        print("Usando dados de exemplo para demonstração:")
    else:
        # Extrair linha formatada
        dados_formatados = extrair_dados_formatados(saida_r)

        if dados_formatados is None:
            print("Não foi possível extrair dados formatados.")
            dados_formatados = "CHUVA:25.0;TEMP_MAX:28.0;TEMP_MIN:18.0;CONDICAO:Parcialmente nublado"

    # Exibir informações extraídas
    try:
        partes = dados_formatados.split(";")
        dados_dict = {}
        for parte in partes:
            if ":" in parte:
                chave, valor = parte.split(":", 1)
                dados_dict[chave] = valor

        print("\nDados meteorológicos processados:")
        print(f"  Chance de chuva: {dados_dict.get('CHUVA', 'N/A')}%")
        print(f"  Temperatura: {dados_dict.get('TEMP_MIN', 'N/A')}°C - {dados_dict.get('TEMP_MAX', 'N/A')}°C")
        print(f"  Condição: {dados_dict.get('CONDICAO', 'N/A')}")
    except:
        print("Erro ao processar dados para exibição")

    print("\n" + "=" * 50)
    print("COPIE ESTA LINHA E COLE NO SERIAL MONITOR DO ESP32:")
    print("=" * 50)
    print(dados_formatados)
    print("=" * 50)

    print("\nInstruções para ESP32:")
    print("1. Abra o Serial Monitor no Wokwi.com")
    print("2. Copie a linha acima")
    print("3. Cole no campo de entrada")
    print("4. Pressione Enter")
    print("\nO ESP32 irá processar os dados automaticamente!")

if __name__ == "__main__":
    main()

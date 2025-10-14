import requests
import json
import serial
import time
from datetime import datetime

# Configurações da API OpenWeather
API_KEY = "sua_chave_api_aqui"  # Substitua pela sua chave da API
CIDADE = "Sao Paulo,BR"
BASE_URL = "http://api.openweathermap.org/data/2.5/forecast"

# Configurações do Serial (ajuste a porta COM conforme necessário)
SERIAL_PORT = "COM3"
BAUD_RATE = 115200

def obter_previsao_tempo():
    """Obtém previsão do tempo da API OpenWeather"""
    params = {
        "q": CIDADE,
        "appid": API_KEY,
        "units": "metric"
    }
    
    try:
        response = requests.get(BASE_URL, params=params)
        data = response.json()
        
        # Processa próximas 24h de previsão
        previsoes = data['list'][:8]  # 8 previsões de 3h = 24h
        
        # Calcula médias
        temp_max = max(prev['main']['temp_max'] for prev in previsoes)
        temp_min = min(prev['main']['temp_min'] for prev in previsoes)
        chance_chuva = sum(
            prev.get('pop', 0) * 100 for prev in previsoes
        ) / len(previsoes)
        
        # Determina condição predominante
        condicoes = [prev['weather'][0]['main'].lower() for prev in previsoes]
        chuva_prevista = any(
            cond in ['rain', 'shower', 'thunderstorm'] for cond in condicoes
        )
        
        return {
            'temp_max': temp_max,
            'temp_min': temp_min,
            'chance_chuva': chance_chuva,
            'chuva_prevista': chuva_prevista,
            'condicao': condicoes[0]
        }
    except Exception as e:
        print(f"Erro ao obter previsão: {e}")
        return None

def enviar_dados_serial(dados):
    """Envia dados formatados para o ESP32 via Serial"""
    try:
        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:
            # Formato: CHUVA:XX;TEMP_MAX:XX;TEMP_MIN:XX;CONDICAO:XXX
            msg = (f"CHUVA:{dados['chance_chuva']:.1f};"
                  f"TEMP_MAX:{dados['temp_max']:.1f};"
                  f"TEMP_MIN:{dados['temp_min']:.1f};"
                  f"CONDICAO:{dados['condicao']}")
            
            ser.write(msg.encode())
            print(f"Dados enviados: {msg}")
            
            # Aguarda resposta do ESP32
            response = ser.readline().decode().strip()
            print(f"Resposta ESP32: {response}")
            
    except Exception as e:
        print(f"Erro na comunicação serial: {e}")

def main():
    print("=== Sistema de Integração Meteorológica ===")
    print(f"Monitorando condições para: {CIDADE}")
    
    while True:
        print("\nObtendo previsão do tempo...")
        dados = obter_previsao_tempo()
        
        if dados:
            print("\nPrevisão obtida:")
            print(f"Temperatura: {dados['temp_min']:.1f}°C - {dados['temp_max']:.1f}°C")
            print(f"Chance de chuva: {dados['chance_chuva']:.1f}%")
            print(f"Condição: {dados['condicao']}")
            
            enviar_dados_serial(dados)
        
        # Aguarda 30 minutos antes da próxima atualização
        time.sleep(1800)

if __name__ == "__main__":
    main()
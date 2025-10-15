# FarmTech Solutions - Fase 2
## Instruções Rápidas para Sistema de Irrigação ESP32

### 🚀 Início Rápido
1. **Acesse o Wokwi.com** e crie um novo projeto ESP32
2. **Adicione os componentes**:
	- 3 Botões NPK (GPIO 25, 26, 27)
	- Sensor LDR (GPIO 34 analógico, GPIO 32 digital)
	- Sensor DHT22 (GPIO 21)
	- Relé azul (GPIO 23)
	- LED de status (GPIO 2)

3. **Cole o código** do arquivo `sistema_irrigacao_inteligente.ino`
4. **Clique em "Start Simulation"**
### 🎮 Como Testar

#### Cenário 1: Irrigação por Umidade Baixa
- Deixe umidade < 60% (ajuste o DHT22 no simulador)
- Observe a bomba ligar automaticamente

#### Cenário 2: Irrigação por pH
- Ajuste o LDR para pH fora da faixa 5.8-7.0
- Sistema ativa irrigação

#### Cenário 3: Irrigação por NPK
- Pressione os botões N, P, K para simular nutrientes ausentes
- Sistema ativa irrigação

#### Cenário 4: Integração Climática
- Execute: `python integracao_api_meteorologica.py`
- Copie a linha gerada para o Serial Monitor do ESP32
- Sistema ajusta parâmetros baseado no clima

### 📊 Scripts de Análise

```bash
# Análise estatística da irrigação
Rscript analise_estatistica_irrigacao.R

# API meteorológica (dados para ESP32)
python integracao_api_meteorologica.py
```

### 🔧 Parâmetros do Sistema

**Cultura:** MILHO
- **pH ideal:** 6.0 - 7.0 (ajustado pela presença de NPK)
- **Umidade limite:** < 45% ativa irrigação
- **NPK:** Todos devem estar presentes (N, P, K)
- **Lógica de pH:**
  - Com NPK completo: pH neutro (6.5-7.5)
  - Sem NPK: pH ácido (4.5-5.5)
  - NPK parcial: pH intermediário (5.5-6.5)

### 📡 Formato de Dados Meteorológicos

```
CHUVA:75.5;TEMP_MAX:28;TEMP_MIN:18;CONDICAO:Chuvoso
```

### ⚡ Funcionalidades Avançadas

- **Ajuste dinâmico** baseado na temperatura
- **Suspensão por chuva** (>50% de chance)
- **Correlações estatísticas** entre variáveis
- **Previsão de tendências** usando regressão linear

---

**FarmTech Solutions © 2025** - Sistema de Irrigação Inteligente
(Conteúdo original será movido da pasta fase2/docs)
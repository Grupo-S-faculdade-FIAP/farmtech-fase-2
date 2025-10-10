# FarmTech Solutions - Sistema de Irrigação Inteligente ESP32

## 🌾 Sobre o Projeto

Sistema embarcado IoT para controle automatizado de irrigação agrícola inteligente baseado em sensores simulados no ESP32.

### 🎯 Características Principais
- **Sistema independente** - Não requer instalação de outros componentes
- **Sensores simulados** - Botões, LDR e DHT22 representando sensores agrícolas
- **Lógica inteligente** - Decisão baseada em parâmetros da cultura do milho
- **Integração meteorológica** - Ajustes automáticos baseados em dados climáticos
- **Análise estatística** - Scripts R para tomada de decisão inteligente

## 🚀 Funcionalidades

- ✅ **Sistema embarcado IoT** no ESP32 para controle de irrigação inteligente
- ✅ **Sensores simulados**: 3 botões para NPK, LDR para pH, DHT22 para umidade
- ✅ **Relé azul** para controle da bomba de irrigação
- ✅ **Lógica inteligente** baseada em parâmetros da cultura do milho
- ✅ **Integração meteorológica** - Ajustes automáticos via dados climáticos
- ✅ **Análise estatística em R** para tomada de decisão
- ✅ **Monitoramento em tempo real** via Serial Monitor

## 📋 Pré-requisitos

### Para ESP32 (Obrigatório):
- **Wokwi.com** (simulador online gratuito) - [Acesse aqui](https://wokwi.com)
- ESP32 board no simulador
- Componentes simulados: 3 botões, LDR, DHT22, relé azul

### Para Integração Meteorológica (Opcional):
- **Python 3.8+** para script de integração
- **R 3.6+** para API meteorológica - [Download R](https://cran.r-project.org/)
- Conexão com internet para dados climáticos reais

## 🛠️ Instalação

### 1. Configurar o circuito no Wokwi.com
1. Acesse [Wokwi.com](https://wokwi.com)
2. Crie um novo projeto com **ESP32**
3. Adicione os componentes necessários:
   - **3 Botões** (para N, P, K)
   - **Sensor LDR** (para pH)
   - **Sensor DHT22** (para umidade)
   - **Relé azul** (para bomba d'água)
   - **LED** (status)

### 2. Conexões dos pinos ESP32:
```
Botão Nitrogênio (N)    → GPIO 12
Botão Fósforo (P)      → GPIO 14
Botão Potássio (K)     → GPIO 27
Sensor LDR (pH)        → GPIO 34 (ADC)
Sensor DHT22 (umidade) → GPIO 26
Relé (bomba)           → GPIO 25
LED Status             → GPIO 2
```

## ▶️ Como executar

### Passo 1: Sistema Básico
1. Abra o arquivo `fase2/esp32/sistema_irrigacao_inteligente.ino`
2. Cole o código no editor do **Wokwi**
3. Clique em **"Start Simulation"**
4. Observe o sistema funcionando automaticamente

### Passo 2: Teste dos Sensores
- **Botões NPK**: Pressione para simular nutrientes presentes/ausentes
- **LDR**: Ajuste a luminosidade para simular pH (escuro = ácido, claro = básico)
- **DHT22**: Modifique umidade no simulador
- **Relé**: Observe ligando/desligando automaticamente

### Passo 3: Integração Meteorológica (Opcional)
```bash
# Opção 1: Script Python (recomendado)
python fase2/esp32/integracao_meteorologica_independente.py

# Opção 2: Script R direto
Rscript fase2/esp32/api_meteorologica_independente.R

# Resultado: linha formatada como:
# CHUVA:75.5;TEMP_MAX:28;TEMP_MIN:18;CONDICAO:Chuvoso
```

### Passo 4: Análise Estatística (Opcional)
```bash
# Análise estatística para decisão de irrigação
Rscript fase2/esp32/analise_estatistica_irrigacao.R
```

## 📁 Estrutura do Projeto

```
trabalho1/
├── 📁 fase2/                          # Sistema de Irrigação ESP32
│   ├── 📁 esp32/                      # Código fonte
│   │   ├── sistema_irrigacao_inteligente.ino    # Código principal ESP32
│   │   ├── integracao_meteorologica.h          # Biblioteca auxiliar
│   │   ├── integracao_meteorologica_independente.py  # Integração clima (Python)
│   │   ├── api_meteorologica_independente.R    # API meteorológica (R)
│   │   └── analise_estatistica_irrigacao.R     # Análise estatística (R)
│   ├── 📁 imagens/                    # Capturas de tela do circuito
│   ├── 📁 videos/                     # Vídeos demonstrativos
│   └── 📁 docs/                       # Documentação adicional
└── README.md                          # Documentação completa
```

## 🎯 Lógica de Irrigação Inteligente

### Cultura Alvo: MILHO

O sistema foi desenvolvido especificamente para a cultura do **MILHO** com parâmetros ideais baseados em recomendações agrícolas:

| Parâmetro | Faixa Ideal | Unidade | Sensor Simulado |
|-----------|-------------|---------|-----------------|
| **pH do Solo** | 5.8 - 7.0 | - | LDR (escuro=ácido, claro=básico) |
| **Umidade** | 60 - 80 | % | DHT22 |
| **Nitrogênio (N)** | Presente | - | Botão (pressionado = presente) |
| **Fósforo (P)** | Presente | - | Botão (pressionado = presente) |
| **Potássio (K)** | Presente | - | Botão (pressionado = presente) |

### 🤖 Algoritmo de Decisão Inteligente

O sistema ativa a bomba de irrigação quando **qualquer** das condições for verdadeira:

1. **🚨 Umidade baixa**: Umidade atual < 60% (teste estatístico t-test)
2. **🚨 pH inadequado**: pH fora da faixa 5.8-7.0 (solo ácido/alcalino demais)
3. **🚨 NPK insuficiente**: Qualquer nutriente não estiver presente
4. **⛈️ Previsão de chuva**: Sistema **suspende** irrigação se chance > 50%

### 🌡️ Ajustes Dinâmicos por Clima

O sistema se adapta automaticamente às condições meteorológicas:

- **☀️ Temperatura > 30°C**: Umidade ideal = 70-85% (mais água para compensar evaporação)
- **❄️ Temperatura < 15°C**: Umidade ideal = 55-75% (menos água, crescimento lento)
- **🌤️ Temperatura normal**: Umidade ideal = 60-80% (padrão para milho)

### 📊 Análise Estatística em R

O script `analise_estatistica_irrigacao.R` implementa análise estatística avançada:

- **📈 Teste t**: Verifica se umidade está significativamente abaixo do ideal
- **🔗 Correlação**: Analisa relação entre umidade e temperatura
- **📉 Regressão linear**: Previsão de tendências de umidade
- **📊 Distribuição**: Análise estatística dos níveis de nutrientes

## 📦 Entregáveis

### Arquivos Principais
- ✅ **Código ESP32**: `fase2/esp32/sistema_irrigacao_inteligente.ino`
- ✅ **Biblioteca auxiliar**: `fase2/esp32/integracao_meteorologica.h`
- ✅ **Integração Python independente**: `fase2/esp32/integracao_meteorologica_independente.py`
- ✅ **API R independente**: `fase2/esp32/api_meteorologica_independente.R`
- ✅ **Análise R**: `fase2/esp32/analise_estatistica_irrigacao.R`
- ✅ **README.md**: Documentação completa

### Funcionalidades Implementadas
- ✅ **Sensores NPK**: 3 botões simulando níveis de nutrientes
- ✅ **Sensor pH**: LDR representando pH do solo (0-14)
- ✅ **Sensor umidade**: DHT22 medindo umidade do solo
- ✅ **Atuador**: Relé azul controlando bomba de irrigação
- ✅ **Lógica inteligente**: Decisão baseada em parâmetros do milho
- ✅ **Integração climática**: Dados meteorológicos via Serial
- ✅ **Análise estatística**: Scripts R para tomada de decisão

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

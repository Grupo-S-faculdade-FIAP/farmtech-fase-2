# Sistema de Irrigação Inteligente - Documentação Técnica Completa

## 1. Visão Geral
O sistema de irrigação inteligente é baseado em ESP32 e utiliza diversos sensores para monitorar e controlar automaticamente a irrigação, com foco especial no monitoramento de NPK (Nitrogênio, Fósforo e Potássio), umidade e pH do solo.

## 2. Componentes de Hardware

### 2.1 Pinos e Conexões
| Componente | Pino GPIO | Descrição |
|------------|-----------|-----------|
| Botão N | GPIO25 | Nitrogênio (INPUT_PULLUP) |
| Botão P | GPIO26 | Fósforo (INPUT_PULLUP) |
| Botão K | GPIO27 | Potássio (INPUT_PULLUP) |
| Relé | GPIO23 | Controle da bomba d'água |
| DHT22 | GPIO21 | Sensor de umidade |
| LDR Analógico | GPIO34 | Sensor para simulação de pH |
| LDR Digital | GPIO32 | Sensor auxiliar (opcional) |

### 2.2 Configurações Importantes
- **Relé**: Configurável para ativo em HIGH ou LOW através da constante `RELAY_ACTIVE_HIGH`
- **Pull-up**: Os botões NPK usam pull-up interno (pressionado = LOW)
- **DHT22**: Funciona com ou sem pull-up externo

### 2.3 Diagrama de Conexões Elétricas

#### Alimentação:
- ESP32 Vin → 5V
- ESP32 GND → GND comum
- ESP32 3.3V → Para sensores que necessitam

#### Botões NPK:
```
Botão N (GPIO25): Pino 1 → GPIO25, Pino 2 → GND
Botão P (GPIO26): Pino 1 → GPIO26, Pino 2 → GND  
Botão K (GPIO27): Pino 1 → GPIO27, Pino 2 → GND
```

#### Sensores:
```
LDR (pH): Analógico → GPIO34, Digital → GPIO32
DHT22: DATA → GPIO21, VCC → 3.3V, GND → GND
```

#### Atuadores:
```
Relé: IN → GPIO23, VCC → 5V, GND → GND
LED Status: Ânodo → GPIO2 + Resistor 220Ω → 3.3V
```

## 3. Parâmetros do Sistema

### 3.1 Temporização
- Intervalo mínimo entre leituras do DHT22: 2000ms (ajustável)
- Debounce dos botões: 25ms
- Log periódico: a cada 1000ms
- Delay de estabilização: 5ms por ciclo

### 3.2 Thresholds e Limites
- **Umidade limite para irrigação**: 45.0%
- **pH ideal**: 6.0 - 7.0
- **Contagem máxima de falhas DHT22**: 5 tentativas
- **Cultura alvo**: MILHO

### 3.3 Ajustes de pH por NPK
```cpp
// Com todos nutrientes: pH neutro (6.5-7.5)
// Sem nutrientes: solo ácido (4.5-5.5)  
// Parcial: intermediário (5.5-6.5)
```

## 4. Funcionalidades Principais

### 4.1 Sistema de Debounce
Implementa um sistema de debounce para os botões NPK:
- Monitoramento de estado bruto
- Estado estável após período de debounce
- Registro de última mudança de estado
- Identificação por nome do pino

### 4.2 Controle do Relé
- Compatibilidade com relés ativos em HIGH ou LOW
- Controle baseado em múltiplos fatores (umidade + pH + NPK)
- Feedback detalhado via Serial para mudanças de estado

### 4.3 Monitoramento DHT22
- Sistema de retry em caso de falha
- Reconfiguração automática após 5 falhas consecutivas
- Respeito ao intervalo mínimo entre leituras
- Validação de dados (temperatura e umidade)

### 4.4 Sistema de Logs Avançado
**Dois níveis de log:**

1. **Log de Eventos Imediatos**:
   - Mudanças no estado dos botões NPK
   - Variações significativas do pH
   - Mudanças no estado do relé
   - Erros e reconfigurações do DHT22

2. **Log Periódico Consolidado** (a cada segundo):
   - Timestamp em segundos
   - Estado completo NPK com símbolos ✓/✗
   - pH com classificação (ácido/neutro/básico)
   - Temperatura e umidade
   - Status da irrigação

## 5. Integração Meteorológica

### 5.1 Funcionalidade
O sistema possui integração avançada com dados meteorológicos para otimizar o uso de recursos hídricos.

### 5.2 Recebimento de Dados via Serial Monitor
O sistema monitora continuamente o Serial Monitor aguardando dados meteorológicos no formato:
```
CHUVA:XX.X;TEMP_MAX:XX.X;TEMP_MIN:XX.X;CONDICAO:texto
```

### 5.3 Processamento Automático
Quando dados meteorológicos são recebidos:
1. **Parsing automático** dos valores de chuva, temperatura e condição
2. **Validação** e armazenamento dos dados
3. **Feedback visual** com emojis e formatação
4. **Integração na lógica de irrigação**

### 5.4 Impacto na Decisão de Irrigação
- **Chance de chuva > 50%**: Irrigação **SUSPENSA** automaticamente
- **Chance de chuva ≤ 50%**: Irrigação segue lógica normal (NPK + pH + umidade)
- **Mensagens informativas** no Serial Monitor indicando o status

### 5.5 Exemplo de Uso
```cpp
// Entrada no Serial Monitor:
CHUVA:87.0;TEMP_MAX:32.7;TEMP_MIN:15.8;CONDICAO:Partly cloudy

// Saída do sistema:
📡 Dados meteorológicos recebidos!
🌧️ Chance de chuva: 87.0%
🌡️ Temperatura: 15.8°C - 32.7°C  
☁️ Condição: Partly cloudy
💧 IRRIGAÇÃO SUSPENSA (alta chance de chuva)
```

## 6. Protocolo de Inicialização
1. Configuração da comunicação Serial (115200 baud)
2. Inicialização dos pinos com estados padrão
3. Configuração do DHT22 com warm-up de 2 segundos
4. Verificação do intervalo mínimo do sensor
5. Impressão das informações de mapeamento de pinos

## 7. Ciclo Principal de Operação
1. **Leitura e debounce** dos botões NPK com feedback
2. **Leitura dos sensores** LDR com conversão para pH
3. **Ajuste do pH** baseado nos níveis de NPK
4. **Leitura do DHT22** (respeitando intervalo mínimo)
5. **Lógica de irrigação** considerando todos os fatores
6. **Geração de logs** formatados e organizados
7. **Pequeno delay** para estabilidade do sistema

## 8. Lógica de Decisão de Irrigação

### 8.1 Prioridade de Decisão:
1. **Primeira verificação**: Dados meteorológicos
   - Se chance de chuva > 50% → **SUSPENDER irrigação**
   - Se não há dados ou chance ≤ 50% → Continuar análise

2. **Segunda verificação**: Condições locais
   - **Umidade baixa**: < 45%
   - **pH adequado**: Entre 5.5 e 7.5
   - **NPK presente**: Pelo menos um nutriente disponível

### 8.2 Condições para Ativar Irrigação:
- ✅ **Dados meteorológicos**: Chance de chuva ≤ 50% (ou sem dados)
- ✅ **Umidade baixa**: < 45%
- ✅ **pH adequado**: Entre 5.5-7.5
- ✅ **NPK disponível**: Pelo menos N, P ou K presente

### 7.2 Feedback do Sistema:
```
[IRRIGAÇÃO ATIVADA]
Motivos: Umidade baixa (42.5%) | pH inadequado (4.5) | NPK insuficiente (✗ P✓ K✓)
```

## 9. Tratamento de Erros
- **Retry imediato** para falhas do DHT22
- **Reconfiguração automática** após 5 falhas consecutivas
- **Validação de dados** antes do uso
- **Sistema de contagem** de falhas com logging

## 10. Interface de Usuário

### 9.1 Monitor Serial
- **Baud rate**: 115200
- **Feedback completo** via Serial Monitor
- **Logs formatados** em estrutura de árvore
- **Símbolos visuais** (✓/✗) para estados
- **Timestamp** para rastreamento temporal

### 9.2 Exemplo de Saída:
```
[0045 seg] Status do Sistema:
├─ NPK: N✓ P✗ K✓
├─ pH: 5.5 (ÁCIDO)  
├─ Temperatura: 24.0°C
├─ Umidade: 42.5%
└─ Irrigação: ATIVA ✓

[NPK ATUALIZADO]
Nitrogênio: ✓ | Fósforo: ✓ | Potássio: ✗

[pH ATUALIZADO]: 6.2 (NEUTRO)
```

## 10. Integração com Recursos Opcionais

### 10.1 API Meteorológica (Python)
- **Arquivo**: `integracao_meteorologica_independente.py`
- **API**: OpenWeather
- **Comunicação**: Serial com ESP32
- **Formato**: `CHUVA:XX;TEMP_MAX:XX;TEMP_MIN:XX;CONDICAO:XXX`

### 10.2 Análise Estatística (R)
- **Arquivo**: `analise_estatistica_irrigacao.R`
- **Funcionalidades**: Correlações, visualizações, recomendações
- **Saídas**: Gráficos PDF e relatório TXT

## 11. Instruções de Teste Rápido

### 11.1 Cenário 1: Irrigação por Umidade
- Ajuste DHT22 para umidade < 45%
- Observe bomba ligar automaticamente

### 11.2 Cenário 2: Irrigação por pH
- Ajuste LDR para pH fora da faixa 5.5-7.5
- Sistema ativa irrigação

### 11.3 Cenário 3: Irrigação por NPK
- Pressione/solte botões N, P, K
- Sistema responde à ausência de nutrientes

### 11.4 Cenário 4: Dados Meteorológicos
- Envie via Serial: `CHUVA:75.0;TEMP_MAX:32.5;TEMP_MIN:18.2;CONDICAO:Chuvoso`
- Sistema suspende irrigação (chuva > 50%)

### 11.5 Cenário 5: Teste Integrado
- Combine condições (umidade baixa + pH adequado + NPK presente + chuva ≤ 50%)
- Observe resposta completa do sistema

## 12. Manutenção e Configuração

### 12.1 Principais Pontos de Configuração:
```cpp
const float HUM_THRESHOLD = 45.0;       // Limiar de umidade
const float PH_MIN = 5.5;               // pH mínimo
const float PH_MAX = 7.5;               // pH máximo
const float CHANCE_CHUVA_LIMITE = 50.0; // Limite para suspender irrigação
const uint32_t DEBOUNCE_MS = 25;        // Debounce botões
const bool RELAY_ACTIVE_HIGH = true;    // Polaridade do relé
```

### 12.2 Troubleshooting:
- **DHT22 não responde**: Verificar conexões e pull-up
- **Botões não funcionam**: Verificar pull-up interno
- **Relé não aciona**: Verificar RELAY_ACTIVE_HIGH
- **pH não varia**: Verificar conexão do LDR

## 13. Especificações Técnicas

### 13.1 Hardware:
- **Microcontrolador**: ESP32
- **Tensão de operação**: 3.3V
- **Comunicação**: Serial 115200 baud
- **Sensores**: Digital e analógicos

### 13.2 Software:
- **IDE**: Arduino IDE ou Wokwi.com
- **Linguagem**: C/C++
- **Bibliotecas**: DHTesp, Arduino.h
- **Recursos**: Timers, interrupts, ADC
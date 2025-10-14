# Sistema de Irrigação Inteligente - Documentação Técnica

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

## 3. Parâmetros do Sistema

### 3.1 Temporização
- Intervalo mínimo entre leituras do DHT22: 2000ms (ajustável)
- Debounce dos botões: 25ms
- Log periódico: a cada 1000ms
- Delay de estabilização: 5ms por ciclo

### 3.2 Thresholds e Limites
- Umidade limite para irrigação: 45.0%
- Contagem máxima de falhas DHT22: 5 tentativas

## 4. Funcionalidades Principais

### 4.1 Sistema de Debounce
Implementa um sistema de debounce para os botões NPK com:
- Monitoramento de estado bruto
- Estado estável após período de debounce
- Registro de última mudança de estado
- Identificação por nome do pino

### 4.2 Controle do Relé
- Compatibilidade com relés ativos em HIGH ou LOW
- Controle baseado no nível de umidade
- Feedback via Serial para mudanças de estado

### 4.3 Monitoramento DHT22
- Sistema de retry em caso de falha
- Reconfiguração automática após 5 falhas consecutivas
- Respeito ao intervalo mínimo entre leituras
- Validação de dados (temperatura e umidade)

### 4.4 Sistema de Logs
O sistema mantém dois níveis de log:
1. **Log de Eventos**:
   - Mudanças no estado do relé
   - Erros do DHT22
   - Reconfigurações do sistema

2. **Log Periódico Consolidado**:
   - Estado dos botões NPK
   - Leituras do LDR (analógico e digital)
   - Temperatura e umidade do DHT22

## 5. Protocolo de Inicialização
1. Configuração da comunicação Serial (115200 baud)
2. Inicialização dos pinos com estados padrão
3. Configuração do DHT22 com warm-up de 2 segundos
4. Verificação do intervalo mínimo do sensor
5. Impressão das informações de mapeamento de pinos

## 6. Ciclo Principal de Operação
1. Leitura e debounce dos botões NPK
2. Leitura dos sensores LDR
3. Leitura do DHT22 (respeitando intervalo mínimo)
4. Controle automático do relé baseado na umidade
5. Geração de logs periódicos
6. Pequeno delay para estabilidade do sistema

## 7. Tratamento de Erros
- Retry imediato para falhas do DHT22
- Reconfiguração automática após falhas consecutivas
- Validação de dados antes do uso
- Sistema de contagem de falhas

## 8. Interface de Usuário
- Feedback completo via Monitor Serial
- Indicação clara de estados e mudanças
- Logs formatados para fácil leitura
- Informações de debug em caso de erro

## 9. Manutenção
Para ajustar o sistema, os principais pontos de configuração são:
- Thresholds de umidade em `HUM_THRESHOLD`
- Intervalos de leitura em `DHT_MIN_INTERVAL_MS`
- Tempo de debounce em `DEBOUNCE_MS`
- Polaridade do relé em `RELAY_ACTIVE_HIGH`
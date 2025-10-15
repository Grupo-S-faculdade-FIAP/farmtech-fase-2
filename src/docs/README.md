# Documentação do Sistema de Irrigação Inteligente

## 📚 Índice da Documentação

### 📋 Arquivos Principais

| Arquivo | Descrição | Uso |
|---------|-----------|-----|
| `documentacao_tecnica_completa.md` | **Documentação técnica completa** | Referência completa do sistema |
| `instrucoes_rapidas.md` | **Guia de início rápido** | Primeiros passos e testes |
| `diagrama_circuito.txt` | **Diagrama das conexões** | Montagem do circuito |

### 🔧 Documentos por Categoria

#### 🚀 Para Começar Rapidamente:
- `instrucoes_rapidas.md` - Configuração em 5 minutos

#### 🛠️ Para Implementar:
- `diagrama_circuito.txt` - Todas as conexões GPIO
- `documentacao_tecnica_completa.md` - Especificações detalhadas

#### 📊 Para Entender o Sistema:
- `documentacao_tecnica_completa.md` - Lógica de funcionamento, algoritmos e tratamento de erros

### 📝 Resumo dos Componentes

#### Hardware Obrigatório:
- **ESP32** - Microcontrolador principal
- **3 Botões** - Simulação NPK (GPIO 25, 26, 27)
- **LDR** - Simulação pH (GPIO 34 analógico, 32 digital)
- **DHT22** - Sensor umidade (GPIO 21)
- **Relé** - Controle bomba (GPIO 23)

#### Software Implementado:
- **Arduino C/C++** - Código principal do ESP32
- **Python** - Integração API meteorológica (opcional)
- **R** - Análise estatística (opcional)

### 🎯 Funcionalidades Principais

#### Sistema Base:
- ✅ Monitoramento NPK via botões
- ✅ Simulação pH baseada em LDR + NPK
- ✅ Controle umidade via DHT22
- ✅ Automação da irrigação via relé
- ✅ Logs detalhados no Serial Monitor

#### Recursos Avançados:
- ✅ Sistema de debounce para botões
- ✅ Retry automático para sensores
- ✅ Feedback visual com símbolos ✓/✗
- ✅ Timestamp para rastreamento
- ✅ Lógica de pH dinâmica baseada em NPK

### 📖 Como Usar Esta Documentação

1. **Primeiro acesso**: Comece com `instrucoes_rapidas.md`
2. **Montagem**: Use `diagrama_circuito.txt` para conexões
3. **Desenvolvimento**: Consulte `documentacao_tecnica_completa.md`
4. **Troubleshooting**: Seção 12 da documentação completa

### 📞 Informações do Projeto

- **Empresa**: FarmTech Solutions
- **Fase**: 2 - Sistema de Irrigação Inteligente  
- **Plataforma**: ESP32 via Wokwi.com
- **Linguagem**: C/C++ (Arduino IDE)
- **Cultura**: MILHO (parâmetros otimizados)
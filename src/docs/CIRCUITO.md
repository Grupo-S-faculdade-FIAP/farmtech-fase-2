# 🔌 Diagrama de Conexões - ESP32 FarmTech

## ⚡ **Conexões Essenciais**

### **Alimentação**
```
ESP32 Vin → 5V
ESP32 GND → GND comum  
ESP32 3.3V → Sensores
```

### **Botões NPK (Pull-up interno)**
```
Botão N → GPIO 25 ↔ GND
Botão P → GPIO 26 ↔ GND
Botão K → GPIO 27 ↔ GND
```

### **Sensores**
```
LDR (pH):
├─ Pino S → GPIO 34 (ADC)
├─ Pino + → 3.3V
└─ Pino - → GND + Resistor 10kΩ

DHT22 (Umidade):
├─ Pino 1 (VCC) → 3.3V
├─ Pino 2 (DATA) → GPIO 21 + Pull-up 4.7kΩ
└─ Pino 4 (GND) → GND
```

### **Atuadores**
```
Relé (Bomba):
├─ IN → GPIO 23
├─ VCC → 5V  
└─ GND → GND

LED Status:
├─ Ânodo → GPIO 2
├─ Resistor → 220Ω
└─ Cátodo → GND
```

## 🎯 **Mapeamento GPIO**
| GPIO | Componente | Tipo |
|------|------------|------|
| 25 | Botão N | INPUT_PULLUP |
| 26 | Botão P | INPUT_PULLUP |  
| 27 | Botão K | INPUT_PULLUP |
| 34 | LDR pH | ANALOG_INPUT |
| 21 | DHT22 | DIGITAL_IO |
| 23 | Relé | OUTPUT |
| 2 | LED | OUTPUT |

---
**Use no Wokwi.com** - Todas as outras informações estão no README principal.
#include <Arduino.h>
#include <DHTesp.h>

// --- Pinos (ajuste conforme seu hardware) ---
const int BTN_K = 27;    // Botão K (INPUT_PULLUP: pressionado=LOW)
const int BTN_P = 26;    // Botão P (INPUT_PULLUP: pressionado=LOW)
const int BTN_N = 25;    // Botão N (INPUT_PULLUP: pressionado=LOW)
const int RELAY_PIN = 23;               // Relé da bomba
const bool RELAY_ACTIVE_HIGH = true;    // false se o relé for ativo em LOW
const int DHT_PIN = 21;                 // DHT22 (DATA)
const int LDR_AO  = 34;                 // LDR analógico
const int LDR_DO  = 32;                 // LDR digital (opcional)

// --- Parâmetros ---
DHTesp dht;
uint32_t DHT_MIN_INTERVAL_MS = 2000;    // Intervalo mínimo entre leituras do DHT
const float HUM_THRESHOLD = 45.0;       // Liga a bomba se umidade < limiar
const uint32_t DEBOUNCE_MS = 25;        // Debounce dos botões

// --- Estrutura simples de botão com debounce ---
struct Btn {
  int pin;
  int lastStable;
  int lastRaw;
  uint32_t lastChange;
  const char* name;
};

Btn btnK = {BTN_K, HIGH, HIGH, 0, "K(GPIO27)"};
Btn btnP = {BTN_P, HIGH, HIGH, 0, "P(GPIO26)"};
Btn btnN = {BTN_N, HIGH, HIGH, 0, "N(GPIO25)"};

// --- Saída para o relé com compatibilidade ativo ALTO/BAIXO ---
inline void relayWrite(bool on) {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_HIGH ? (on ? HIGH : LOW)
                                            : (on ? LOW  : HIGH));
}

// --- Configuração de pinos ---
inline void initPins() {
  pinMode(BTN_K, INPUT_PULLUP);
  pinMode(BTN_P, INPUT_PULLUP);
  pinMode(BTN_N, INPUT_PULLUP);
  pinMode(RELAY_PIN, OUTPUT);
  relayWrite(false);             // inicia bomba desligada
  pinMode(LDR_AO, INPUT);
  pinMode(LDR_DO, INPUT);        // opcional
}

// --- Debounce simples: atualiza estado estável ---
inline void updateButton(Btn& b) {
  int raw = digitalRead(b.pin);
  if (raw != b.lastRaw) { b.lastRaw = raw; b.lastChange = millis(); }
  if (millis() - b.lastChange > DEBOUNCE_MS && b.lastStable != b.lastRaw) {
    b.lastStable = b.lastRaw;
  }
}

void setup() {
  Serial.begin(115200);
  delay(200);
  initPins();

  pinMode(DHT_PIN, INPUT_PULLUP);       // ok com ou sem pull-up externo
  dht.setup(DHT_PIN, DHTesp::DHT22);
  DHT_MIN_INTERVAL_MS = max<uint32_t>(dht.getMinimumSamplingPeriod(), 2000);
  Serial.printf("DHT22: minInterval=%ums\n", DHT_MIN_INTERVAL_MS);
  delay(2000);                          // warm-up rápido

  Serial.println("Irrigador ESP32 pronto");
  Serial.println("N=GPIO25 P=GPIO26 K=GPIO27 | Rele=GPIO23 | DHT22=GPIO21 | LDR AO=34 DO=32");
}

// --- Loop ---
uint32_t lastDhtMs = 0;
uint8_t  dhtFailCount = 0;

void loop() {
  // 1) Debounce e estados NPK (1=pressionado)
  updateButton(btnN);
  updateButton(btnP);
  updateButton(btnK);
  const int N = (btnN.lastStable == LOW) ? 1 : 0;
  const int P = (btnP.lastStable == LOW) ? 1 : 0;
  const int K = (btnK.lastStable == LOW) ? 1 : 0;

  // 2) LDR
  int ldrRaw = analogRead(LDR_AO);
  int ldrDig = digitalRead(LDR_DO);

  // 3) DHT22 com respeito ao intervalo + retry simples
  float hum = NAN, temp = NAN;
  uint32_t now = millis();
  if (now - lastDhtMs >= DHT_MIN_INTERVAL_MS) {
    lastDhtMs = now;
    TempAndHumidity r = dht.getTempAndHumidity();
    int status = dht.getStatus(); // 0=OK
    if (status == 0 && !isnan(r.humidity) && !isnan(r.temperature)) {
      hum  = r.humidity;
      temp = r.temperature;
      dhtFailCount = 0;
    } else {
      dhtFailCount++;
      Serial.printf("[DHT22] Erro(%u): %s\n", dhtFailCount, dht.getStatusString());
      delay(100);
      r = dht.getTempAndHumidity();
      status = dht.getStatus();
      if (status == 0 && !isnan(r.humidity) && !isnan(r.temperature)) {
        hum  = r.humidity;
        temp = r.temperature;
        dhtFailCount = 0;
      } else if (dhtFailCount >= 5) {
        Serial.println("[DHT22] Reconfigurando...");
        dht.setup(DHT_PIN, DHTesp::DHT22);
        dhtFailCount = 0;
        delay(50);
      }
    }
  }

  // 4) Controle do relé por umidade (com log)
  static bool pumpOn = false;
  if (!isnan(hum)) {
    bool shouldOn = hum < HUM_THRESHOLD;
    if (shouldOn != pumpOn) {
      pumpOn = shouldOn;
      relayWrite(pumpOn);
      Serial.printf("[RELE GPIO%02d] %s | H=%.1f%% (limiar=%.1f%%)\n",
                    RELAY_PIN, pumpOn ? "LIGADO" : "DESLIGADO", hum, HUM_THRESHOLD);
    }
  }

  // 5) Log consolidado periódico
  static uint32_t lastLog = 0;
  if (now - lastLog > 1000) {
    lastLog = now;
    Serial.printf("[N=%d P=%d K=%d] [LDR AO=%4d DO=%d] ", N, P, K, ldrRaw, ldrDig);
    int status = dht.getStatus();
    if (status == 0) {
      TempAndHumidity r = dht.getTempAndHumidity();
      Serial.printf("[DHT22 T=%.1fC H=%.1f%%]\n", r.temperature, r.humidity);
    } else {
      Serial.printf("[DHT22 %s]\n", dht.getStatusString());
    }
  }

  delay(5);
}
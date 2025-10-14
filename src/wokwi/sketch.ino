/*
  ESP32 (Wokwi) — Irrigador Automático (DHT22 + LDR módulo + Relé, NPK via Botões)
*/

#include <Arduino.h>
#include <DHTesp.h>

// =================== CONFIG GERAL ===================
#define LOG_MS         1800
#define EMA_ALPHA      0.20f

#define ADC_MIN_CAL    800
#define ADC_MAX_CAL    2500
#define PH_MIN_USE     5.5f
#define PH_MAX_USE     7.5f

// =================== PINOS ===================
const int BTN_K = 27;
const int BTN_P = 26;
const int BTN_N = 25;
const int RELAY_PIN = 23;
const bool RELAY_ACTIVE_HIGH = true;

const int DHT_PIN = 21;
const int LDR_AO  = 34;
const int LDR_DO  = 32;

// =================== PARÂMETROS ===================
DHTesp dht;
uint32_t DHT_MIN_INTERVAL_MS = 2000;
const float HUM_THRESHOLD = 45.0f;
const uint32_t DEBOUNCE_MS = 25;

const float PH_MIN_IDEAL = 5.5f;
const float PH_MAX_IDEAL = 7.5f;

const float PH_OFFSET_N = +0.80f;
const float PH_OFFSET_P = -0.60f;
const float PH_OFFSET_K = +0.40f;

// =================== ESTRUTURAS ===================
struct Btn {
  int pin;
  int lastStable;
  int lastRaw;
  uint32_t lastChange;
};

Btn btnK = {BTN_K, HIGH, HIGH, 0};
Btn btnP = {BTN_P, HIGH, HIGH, 0};
Btn btnN = {BTN_N, HIGH, HIGH, 0};

// =================== ESTADO ===================
float lastHum = NAN, lastTemp = NAN;
int   lastDhtStatus = -1;
String lastDhtStatusStr = "N/A";
uint32_t lastDhtMs = 0;
uint8_t  dhtFailCount = 0;

float ldrEma = NAN;
bool  pumpOn = false;

// =================== HELPERS ===================
inline void relayWrite(bool on) {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_HIGH ? (on ? HIGH : LOW)
                                            : (on ? LOW  : HIGH));
}

inline void updateButton(Btn& b) {
  int raw = digitalRead(b.pin);
  if (raw != b.lastRaw) { b.lastRaw = raw; b.lastChange = millis(); }
  if (millis() - b.lastChange > DEBOUNCE_MS && b.lastStable != b.lastRaw)
    b.lastStable = b.lastRaw;
}

inline float mapLdrToPh(int adc) {
  float t = (float)(adc - ADC_MIN_CAL) / (float)(ADC_MAX_CAL - ADC_MIN_CAL);
  t = constrain(t, 0.0f, 1.0f);
  float ph = PH_MIN_USE + t * (PH_MAX_USE - PH_MIN_USE);
  return constrain(ph, 0.0f, 14.0f);
}

inline float applyNpkOffsets(float phBase, int N, int P, int K) {
  float ph = phBase + N * PH_OFFSET_N + P * PH_OFFSET_P + K * PH_OFFSET_K;
  return constrain(ph, 0.0f, 14.0f);
}

inline bool shouldIrrigate(int N, int P, int K, float ph, float hum) {
  if (isnan(hum)) return false;
  return (hum < HUM_THRESHOLD) && (ph >= PH_MIN_IDEAL && ph <= PH_MAX_IDEAL) && (N || P || K);
}

inline void logResumo(int N, int P, int K, int ldrRaw, int ldrDig,
                      float phBase, float phAdj, float hum, float temp) {
  Serial.printf(
    "N=%d P=%d K=%d | LDR AO=%4d DO=%d | pH=%.2f(%.2f) | T=%.1fC H=%.1f%% | RELÉ=%s\n",
    N, P, K, ldrRaw, ldrDig, phAdj, phBase, temp, hum,
    pumpOn ? "ON" : "OFF"
  );
}

// =================== SETUP ===================
void setup() {
  Serial.begin(115200);
  delay(200);

  pinMode(BTN_K, INPUT_PULLUP);
  pinMode(BTN_P, INPUT_PULLUP);
  pinMode(BTN_N, INPUT_PULLUP);
  pinMode(RELAY_PIN, OUTPUT);
  relayWrite(false);
  pinMode(LDR_AO, INPUT);
  pinMode(LDR_DO, INPUT);

  analogReadResolution(12);
  analogSetPinAttenuation(LDR_AO, ADC_11db);

  pinMode(DHT_PIN, INPUT_PULLUP);
  dht.setup(DHT_PIN, DHTesp::DHT22);
  DHT_MIN_INTERVAL_MS = max<uint32_t>(dht.getMinimumSamplingPeriod(), 2000);

  Serial.printf("DHT22 minInterval=%ums\n", DHT_MIN_INTERVAL_MS);
  delay(2000);

  Serial.println("=== Irrigador Automático Iniciado ===");
  Serial.println("Mapeamento: N=25, P=26, K=27 | Relé=23 | DHT22=21 | LDR AO=34 DO=32");
}

// =================== LOOP ===================
void loop() {
  updateButton(btnN);
  updateButton(btnP);
  updateButton(btnK);
  int N = (btnN.lastStable == LOW);
  int P = (btnP.lastStable == LOW);
  int K = (btnK.lastStable == LOW);

  int ldrRaw = analogRead(LDR_AO);
  int ldrDig = digitalRead(LDR_DO);
  ldrEma = isnan(ldrEma) ? ldrRaw : EMA_ALPHA * ldrRaw + (1.0f - EMA_ALPHA) * ldrEma;

  float phBase = mapLdrToPh((int)roundf(ldrEma));
  float phAdj  = applyNpkOffsets(phBase, N, P, K);

  float hum = NAN, temp = NAN;
  uint32_t now = millis();
  if (now - lastDhtMs >= DHT_MIN_INTERVAL_MS) {
    lastDhtMs = now;
    TempAndHumidity r = dht.getTempAndHumidity();
    int status = dht.getStatus();
    if (status == 0 && !isnan(r.humidity) && !isnan(r.temperature)) {
      hum = r.humidity; temp = r.temperature;
      dhtFailCount = 0;
      lastHum = hum; lastTemp = temp; lastDhtStatus = 0;
    } else {
      dhtFailCount++;
      lastDhtStatus = status;
      if (dhtFailCount >= 5) {
        Serial.println("DHT22: reconfigurando sensor...");
        dht.setup(DHT_PIN, DHTesp::DHT22);
        dhtFailCount = 0;
      }
    }
  }

  float humUse = !isnan(hum) ? hum : lastHum;
  bool shouldOn = shouldIrrigate(N, P, K, phAdj, humUse);
  if (shouldOn != pumpOn) {
    pumpOn = shouldOn;
    relayWrite(pumpOn);
    Serial.printf("Relé -> %s | H=%.1f%% | pH=%.2f | NPK=%d%d%d\n",
                  pumpOn ? "ON" : "OFF", humUse, phAdj, N, P, K);
  }

  static uint32_t lastLog = 0;
  if (now - lastLog > LOG_MS) {
    lastLog = now;
    float hShow = !isnan(hum) ? hum : lastHum;
    float tShow = !isnan(temp) ? temp : lastTemp;
    logResumo(N, P, K, ldrRaw, ldrDig, phBase, phAdj, hShow, tShow);
  }

  delay(5);
}

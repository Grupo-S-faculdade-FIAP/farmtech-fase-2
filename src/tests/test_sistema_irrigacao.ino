#include <unity.h>
#include <Arduino.h>

// Mock das bibliotecas necessárias
#include <DHT.h>
#include <WiFi.h>

// Definições dos pinos (mesmas do arquivo principal)
#define PIN_NITROGENIO 12
#define PIN_FOSFORO 14
#define PIN_POTASSIO 27
#define PIN_LDR 34
#define PIN_DHT 26
#define PIN_RELE 25
#define PIN_LED_STATUS 2

// Variáveis globais para teste
DHT dht(PIN_DHT, DHT22);
bool irrigacaoAtiva = false;

// Funções de teste
void setUp(void) {
    // Configuração inicial antes de cada teste
}

void tearDown(void) {
    // Limpeza após cada teste
}

void test_inicializacao_pinos(void) {
    // Teste de inicialização dos pinos
    pinMode(PIN_NITROGENIO, INPUT_PULLUP);
    pinMode(PIN_FOSFORO, INPUT_PULLUP);
    pinMode(PIN_POTASSIO, INPUT_PULLUP);
    pinMode(PIN_LDR, INPUT);
    pinMode(PIN_RELE, OUTPUT);
    pinMode(PIN_LED_STATUS, OUTPUT);
    
    TEST_ASSERT_EQUAL(INPUT_PULLUP, digitalRead(PIN_NITROGENIO));
    TEST_ASSERT_EQUAL(INPUT_PULLUP, digitalRead(PIN_FOSFORO));
    TEST_ASSERT_EQUAL(INPUT_PULLUP, digitalRead(PIN_POTASSIO));
}

void test_leitura_sensores_npk(void) {
    // Teste de leitura dos botões NPK
    digitalWrite(PIN_NITROGENIO, LOW);
    TEST_ASSERT_EQUAL(LOW, digitalRead(PIN_NITROGENIO));
    
    digitalWrite(PIN_FOSFORO, LOW);
    TEST_ASSERT_EQUAL(LOW, digitalRead(PIN_FOSFORO));
    
    digitalWrite(PIN_POTASSIO, LOW);
    TEST_ASSERT_EQUAL(LOW, digitalRead(PIN_POTASSIO));
}

void test_leitura_ph(void) {
    // Teste de leitura do sensor LDR (pH)
    int valorLDR = analogRead(PIN_LDR);
    TEST_ASSERT_INT_WITHIN(4095, 0, valorLDR);
}

void test_leitura_umidade(void) {
    // Teste de leitura do sensor DHT22
    float umidade = dht.readHumidity();
    TEST_ASSERT_FLOAT_WITHIN(100.0, 0.0, umidade);
}

void test_controle_rele(void) {
    // Teste do controle do relé
    digitalWrite(PIN_RELE, HIGH);
    TEST_ASSERT_EQUAL(HIGH, digitalRead(PIN_RELE));
    
    digitalWrite(PIN_RELE, LOW);
    TEST_ASSERT_EQUAL(LOW, digitalRead(PIN_RELE));
}

void setup() {
    delay(2000);
    UNITY_BEGIN();
    
    RUN_TEST(test_inicializacao_pinos);
    RUN_TEST(test_leitura_sensores_npk);
    RUN_TEST(test_leitura_ph);
    RUN_TEST(test_leitura_umidade);
    RUN_TEST(test_controle_rele);
    
    UNITY_END();
}

void loop() {
    // Nada a fazer aqui
}
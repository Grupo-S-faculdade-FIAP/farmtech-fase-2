#include <WiFi.h>
#include <DHT.h>

// Arquivo auxiliar para integração com dados meteorológicos
// Este arquivo contém funções para processar dados da API WeatherAPI

#include <Arduino.h>

// Estrutura para armazenar dados meteorológicos
struct DadosMeteorologicos {
  bool previsaoChuva;
  float chanceChuvaMedia;
  float temperaturaMaxima;
  float temperaturaMinima;
  String condicaoAtual;
};

// Configurações de WiFi (para integração futura com API)
const char* ssid = "SEU_WIFI_SSID";
const char* password = "SEU_WIFI_PASSWORD";

// Pinos dos componentes
#define PIN_NITROGENIO 12    // Botão para Nitrogênio (N)
#define PIN_FOSFORO 14       // Botão para Fósforo (P)
#define PIN_POTASSIO 27      // Botão para Potássio (K)
#define PIN_LDR 34           // Sensor LDR (simula pH)
#define PIN_DHT 26           // Sensor DHT22 (umidade do solo)
#define PIN_RELE 25          // Relé para bomba d'água
#define PIN_LED_STATUS 2     // LED indicador de status

// Configuração do DHT22
#define DHTTYPE DHT22
DHT dht(PIN_DHT, DHTTYPE);

// Variáveis globais
bool nitrogenioPresente = false;
bool fosforoPresente = false;
bool potassioPresente = false;
float pH = 0.0;
float umidadeSolo = 0.0;
bool bombaLigada = false;

// Parâmetros ideais para milho (cultura escolhida)
const float PH_IDEAL_MIN = 5.8;
const float PH_IDEAL_MAX = 7.0;
const float UMIDADE_IDEAL_MIN = 60.0;
const float UMIDADE_IDEAL_MAX = 80.0;

// Variáveis para controle de tempo
unsigned long ultimoLeituraDHT = 0;
unsigned long ultimoLeituraLDR = 0;
unsigned long ultimoControleIrrigacao = 0;
const unsigned long INTERVALO_DHT = 2000;      // 2 segundos
const unsigned long INTERVALO_LDR = 1000;      // 1 segundo
const unsigned long INTERVALO_IRRIGACAO = 5000; // 5 segundos

// Estrutura para dados meteorológicos
DadosMeteorologicos dadosMeteorologicos;

void setup() {
  Serial.begin(115200);

  // Configuração dos pinos
  pinMode(PIN_NITROGENIO, INPUT_PULLUP);
  pinMode(PIN_FOSFORO, INPUT_PULLUP);
  pinMode(PIN_POTASSIO, INPUT_PULLUP);
  pinMode(PIN_LDR, INPUT);
  pinMode(PIN_RELE, OUTPUT);
  pinMode(PIN_LED_STATUS, OUTPUT);

  // Inicializar DHT22
  dht.begin();

  // Estado inicial da bomba (desligada)
  digitalWrite(PIN_RELE, LOW);
  digitalWrite(PIN_LED_STATUS, LOW);

  Serial.println("=========================================");
  Serial.println("FarmTech Solutions - Sistema de Irrigação");
  Serial.println("=========================================");
  Serial.println("Cultura: MILHO");
  Serial.println("Parâmetros ideais:");
  Serial.printf("  pH: %.1f - %.1f\n", PH_IDEAL_MIN, PH_IDEAL_MAX);
  Serial.printf("  Umidade: %.1f%% - %.1f%%\n", UMIDADE_IDEAL_MIN, UMIDADE_IDEAL_MAX);
  Serial.println("=========================================");

  // Conectar ao WiFi (para futuras integrações)
  conectarWiFi();
}

void loop() {
  unsigned long tempoAtual = millis();

  // Leitura dos botões NPK
  lerBotoesNPK();

  // Leitura dos sensores com intervalos definidos
  if (tempoAtual - ultimoLeituraDHT >= INTERVALO_DHT) {
    lerUmidadeSolo();
    ultimoLeituraDHT = tempoAtual;
  }

  if (tempoAtual - ultimoLeituraLDR >= INTERVALO_LDR) {
    lerPH();
    ultimoLeituraLDR = tempoAtual;
  }

  // Controle da irrigação
  if (tempoAtual - ultimoControleIrrigacao >= INTERVALO_IRRIGACAO) {
    controlarIrrigacao();
    ultimoControleIrrigacao = tempoAtual;
  }

  // Processar dados recebidos via Serial (para integração com API)
  processarDadosSerial();

  // Exibir status no Serial Monitor
  exibirStatus();

  delay(500); // Pequeno delay para estabilidade
}

void conectarWiFi() {
  Serial.print("Conectando ao WiFi...");
  WiFi.begin(ssid, password);

  int tentativas = 0;
  while (WiFi.status() != WL_CONNECTED && tentativas < 10) {
    delay(1000);
    Serial.print(".");
    tentativas++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" Conectado!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(" Falhou! Continuando sem WiFi...");
  }
  Serial.println();
}

void lerBotoesNPK() {
  // Botões com pull-up - LOW quando pressionado
  nitrogenioPresente = !digitalRead(PIN_NITROGENIO);
  fosforoPresente = !digitalRead(PIN_FOSFORO);
  potassioPresente = !digitalRead(PIN_POTASSIO);
}

void lerUmidadeSolo() {
  float h = dht.readHumidity();
  if (!isnan(h)) {
    umidadeSolo = h;
  } else {
    Serial.println("Erro ao ler DHT22!");
  }
}

void lerPH() {
  // Leitura analógica do LDR (0-4095)
  int leituraLDR = analogRead(PIN_LDR);

  // Conversão para pH (0-14)
  // Mapeando leitura analógica para escala de pH
  // 0 = pH 0 (ácido forte), 4095 = pH 14 (básico forte)
  pH = map(leituraLDR, 0, 4095, 0, 140) / 10.0;

  // Ajuste fino para melhor controle
  // Quando NPK muda, deve afetar o pH simulado
  if (nitrogenioPresente && fosforoPresente && potassioPresente) {
    // NPK completo tende a manter pH mais neutro
    pH = constrain(pH, 6.0, 8.0);
  } else if (!nitrogenioPresente && !fosforoPresente && !potassioPresente) {
    // Sem NPK, solo pode ficar mais ácido
    pH = constrain(pH, 4.0, 6.0);
  }
}

void controlarIrrigacao() {
  // Lógica de decisão para irrigação do milho
  bool precisaIrrigar = false;
  String motivoIrrigacao = "";

  // 1. Verificar umidade do solo
  if (umidadeSolo < UMIDADE_IDEAL_MIN) {
    precisaIrrigar = true;
    motivoIrrigacao = "Umidade baixa";
  }

  // 2. Verificar pH
  if (pH < PH_IDEAL_MIN || pH > PH_IDEAL_MAX) {
    precisaIrrigar = true;
    if (motivoIrrigacao != "") motivoIrrigacao += " + ";
    motivoIrrigacao += "pH inadequado";
  }

  // 3. Verificar nutrientes NPK
  if (!nitrogenioPresente || !fosforoPresente || !potassioPresente) {
    precisaIrrigar = true;
    if (motivoIrrigacao != "") motivoIrrigacao += " + ";
    motivoIrrigacao += "NPK insuficiente";
  }

  // 4. Considerar previsão do tempo (se disponível)
  if (!deveIrrigarComDadosMeteorologicos(dadosMeteorologicos)) {
    precisaIrrigar = false;
    motivoIrrigacao = "Condições meteorológicas desfavoráveis";
  }

  // 5. Ajustar parâmetros baseado na temperatura
  float umidadeMinAjustada = UMIDADE_IDEAL_MIN;
  float umidadeMaxAjustada = UMIDADE_IDEAL_MAX;
  ajustarParametrosIrrigacao(dadosMeteorologicos, umidadeMinAjustada, umidadeMaxAjustada);

  // Reavaliar umidade com parâmetros ajustados
  if (precisaIrrigar && umidadeSolo >= umidadeMinAjustada) {
    precisaIrrigar = false; // Condições adequadas após ajuste
  }

  // Controle da bomba
  if (precisaIrrigar && !bombaLigada) {
    ligarBomba();
    Serial.print("BOMBA LIGADA - Motivo: ");
    Serial.println(motivoIrrigacao);
  } else if (!precisaIrrigar && bombaLigada) {
    desligarBomba();
    Serial.println("BOMBA DESLIGADA - Condições adequadas");
  }
}

void ligarBomba() {
  digitalWrite(PIN_RELE, HIGH);
  digitalWrite(PIN_LED_STATUS, HIGH);
  bombaLigada = true;
}

void desligarBomba() {
  digitalWrite(PIN_RELE, LOW);
  digitalWrite(PIN_LED_STATUS, LOW);
  bombaLigada = false;
}

void exibirStatus() {
  static unsigned long ultimoDisplay = 0;
  if (millis() - ultimoDisplay >= 3000) { // Exibir a cada 3 segundos
    Serial.println("\n=== STATUS DO SISTEMA ===");
    Serial.printf("NPK - N:%s P:%s K:%s\n",
                  nitrogenioPresente ? "OK" : "FALTA",
                  fosforoPresente ? "OK" : "FALTA",
                  potassioPresente ? "OK" : "FALTA");
    Serial.printf("pH: %.1f (Ideal: %.1f-%.1f)\n", pH, PH_IDEAL_MIN, PH_IDEAL_MAX);
    Serial.printf("Umidade: %.1f%% (Ideal: %.1f-%.1f%%)\n",
                  umidadeSolo, UMIDADE_IDEAL_MIN, UMIDADE_IDEAL_MAX);
    Serial.printf("Bomba: %s\n", bombaLigada ? "LIGADA" : "DESLIGADA");

    // Exibir dados meteorológicos se disponíveis
    if (dadosMeteorologicos.condicaoAtual != "Desconhecido") {
      Serial.printf("Condição: %s\n", dadosMeteorologicos.condicaoAtual.c_str());
      Serial.printf("Temp: %.1f-%.1f°C, Chuva: %.1f%%\n",
                    dadosMeteorologicos.temperaturaMinima,
                    dadosMeteorologicos.temperaturaMaxima,
                    dadosMeteorologicos.chanceChuvaMedia);
    }

    Serial.println("========================\n");
    ultimoDisplay = millis();
  }
}

// Função para analisar dados da API e determinar se há previsão de chuva
// Recebe dados no formato JSON simplificado da nossa API R/Python
DadosMeteorologicos analisarDadosMeteorologicos(String dadosAPI) {
  DadosMeteorologicos dados;

  // Valores padrão
  dados.previsaoChuva = false;
  dados.chanceChuvaMedia = 0.0;
  dados.temperaturaMaxima = 25.0;
  dados.temperaturaMinima = 15.0;
  dados.condicaoAtual = "Desconhecido";

  // Análise simplificada dos dados recebidos
  // Formato esperado: "CHUVA:75;TEMP_MAX:28;TEMP_MIN:18;CONDICAO:Chuvoso"

  if (dadosAPI.indexOf("CHUVA:") != -1) {
    int posInicio = dadosAPI.indexOf("CHUVA:") + 6;
    int posFim = dadosAPI.indexOf(";", posInicio);
    if (posFim == -1) posFim = dadosAPI.length();

    String chanceStr = dadosAPI.substring(posInicio, posFim);
    dados.chanceChuvaMedia = chanceStr.toFloat();
    dados.previsaoChuva = (dados.chanceChuvaMedia > 30.0); // Chuva se > 30%
  }

  if (dadosAPI.indexOf("TEMP_MAX:") != -1) {
    int posInicio = dadosAPI.indexOf("TEMP_MAX:") + 9;
    int posFim = dadosAPI.indexOf(";", posInicio);
    if (posFim == -1) posFim = dadosAPI.length();

    String tempStr = dadosAPI.substring(posInicio, posFim);
    dados.temperaturaMaxima = tempStr.toFloat();
  }

  if (dadosAPI.indexOf("TEMP_MIN:") != -1) {
    int posInicio = dadosAPI.indexOf("TEMP_MIN:") + 9;
    int posFim = dadosAPI.indexOf(";", posInicio);
    if (posFim == -1) posFim = dadosAPI.length();

    String tempStr = dadosAPI.substring(posInicio, posFim);
    dados.temperaturaMinima = tempStr.toFloat();
  }

  if (dadosAPI.indexOf("CONDICAO:") != -1) {
    int posInicio = dadosAPI.indexOf("CONDICAO:") + 8;
    dados.condicaoAtual = dadosAPI.substring(posInicio);
  }

  return dados;
}

// Função para determinar se deve irrigar baseado em dados meteorológicos
// Retorna true se deve irrigar, false se deve suspender
bool deveIrrigarComDadosMeteorologicos(DadosMeteorologicos dados) {
  // Lógica de decisão baseada em dados meteorológicos:
  // 1. Se há previsão de chuva (>50% chance), não irrigar
  // 2. Se temperatura muito alta (>35°C), pode precisar de mais água
  // 3. Se temperatura muito baixa (<10°C), reduzir irrigação

  if (dados.previsaoChuva && dados.chanceChuvaMedia > 50.0) {
    return false; // Não irrigar se vai chover
  }

  if (dados.temperaturaMaxima > 35.0) {
    return true; // Irrigar mais em dias muito quentes
  }

  if (dados.temperaturaMinima < 10.0) {
    return false; // Reduzir irrigação em dias frios
  }

  // Condições normais
  return true;
}

// Função para ajustar parâmetros de irrigação baseado no clima
void ajustarParametrosIrrigacao(DadosMeteorologicos dados,
                               float& umidadeIdealMin,
                               float& umidadeIdealMax) {
  // Ajustar umidade ideal baseada na temperatura
  if (dados.temperaturaMaxima > 30.0) {
    // Dias quentes: manter solo mais úmido
    umidadeIdealMin = 70.0;
    umidadeIdealMax = 85.0;
  } else if (dados.temperaturaMinima < 15.0) {
    // Dias frios: solo menos úmido
    umidadeIdealMin = 55.0;
    umidadeIdealMax = 75.0;
  } else {
    // Condições normais
    umidadeIdealMin = 60.0;
    umidadeIdealMax = 80.0;
  }
}

// Função para exibir relatório meteorológico
void exibirRelatorioMeteorologico(DadosMeteorologicos dados) {
  Serial.println("\n=== DADOS METEOROLÓGICOS ===");
  Serial.printf("Condição atual: %s\n", dados.condicaoAtual.c_str());
  Serial.printf("Temperatura: %.1f°C - %.1f°C\n",
                dados.temperaturaMinima, dados.temperaturaMaxima);
  Serial.printf("Chance de chuva: %.1f%%\n", dados.chanceChuvaMedia);
  Serial.printf("Previsão de chuva: %s\n",
                dados.previsaoChuva ? "SIM" : "NÃO");
  Serial.println("===========================\n");
}

// Função para receber dados via Serial (para integração manual com API)
void processarDadosSerial() {
  if (Serial.available() > 0) {
    String dadosRecebidos = Serial.readStringUntil('\n');
    dadosRecebidos.trim();

    // Formato esperado: "CHUVA:75.5;TEMP_MAX:28;TEMP_MIN:18;CONDICAO:Chuvoso"
    if (dadosRecebidos.length() > 0) {
      dadosMeteorologicos = analisarDadosMeteorologicos(dadosRecebidos);
      exibirRelatorioMeteorologico(dadosMeteorologicos);
    }
  }
}

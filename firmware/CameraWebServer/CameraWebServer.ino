// 카메라 관련 기능을 사용하기 위한 헤더 파일 포함
#include "esp_camera.h"

// WiFi 기능을 사용하기 위한 헤더 파일 포함
#include <WiFi.h>

// AI Thinker 모델에 해당하는 핀 설정을 적용 (PSRAM 포함)
#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

#include "DHT.h"
#define DHTPIN  15          // DHT22 신호선 연결 핀
#define FLAME_PIN 14 // Flame sensor 신호선 연결 핀
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// 캐시된 센서 값과 갱신 시간
volatile bool allowStreaming = true;
float cachedHumidity   = NAN;
float cachedTemperature = NAN;
int   cachedFlame = -1;

void sensorTask(void *param) {
  dht.begin();
  for (;;) {
    allowStreaming = false;
    delay(120);  // 스트리밍 중단 대기 시간

    float h1 = dht.readHumidity();
    float t1 = dht.readTemperature();
    vTaskDelay(pdMS_TO_TICKS(300));
    float h2 = dht.readHumidity();
    float t2 = dht.readTemperature();

    if (!isnan(h1) && !isnan(t1) && !isnan(h2) && !isnan(t2)) {
      cachedHumidity = (h1 + h2) / 2.0;
      cachedTemperature = (t1 + t2) / 2.0;
    } else {
      Serial.println("DHT read failed");
    }

    cachedFlame = digitalRead(FLAME_PIN);
    allowStreaming = true;

    vTaskDelay(pdMS_TO_TICKS(3000));
  }
}

// WiFi credentials are loaded from wifi_config.h
#include "wifi_config.h"

// ===========================
// WiFi 접속 정보는 wifi_config.h에서 정의된 상수를 사용
// ===========================
const char *ssid = WIFI_SSID;      // WiFi 네트워크 이름(SSID)
const char *password = WIFI_PASSWORD;  // WiFi 비밀번호

// 카메라 서버 시작 함수 선언 (구현은 별도)
void startCameraServer();

// LED 플래시 제어를 위한 초기화 함수 선언 (구현은 별도)
void setupLedFlash(int pin);

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);

  pinMode(FLAME_PIN, INPUT);

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_QQVGA;
  config.pixel_format = PIXFORMAT_JPEG;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 14;
  config.fb_count = 1;
  config.grab_mode = CAMERA_GRAB_LATEST;

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("Camera init failed");
    return;
  }

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  WiFi.setSleep(false);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");

  startCameraServer();
  xTaskCreatePinnedToCore(sensorTask, "Sensor Task", 2048, NULL, 1, NULL, 1);

  Serial.print("Camera Ready! Use 'http://");
  Serial.print(WiFi.localIP());
  Serial.println("' to connect");
}

void loop() {  
  delay(10);  // 다른 작업에 CPU를 양보
}

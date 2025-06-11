// Copyright 2015-2016 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// 사용자는 이 파일을 라이선스 조건에 맞게 사용할 수 있습니다.
// 라이선스 전문은 아래 URL에서 확인할 수 있습니다.
//     http://www.apache.org/licenses/LICENSE-2.0
//
// 법률에 의해 요구되거나 서면으로 합의되지 않는 한, 소프트웨어는 "있는 그대로" 제공되며,
// 어떠한 보증도 제공되지 않습니다.

#include "esp_http_server.h"    // HTTP 서버 기능 제공
#include "esp_timer.h"          // 시간 관련 함수 제공
#include "esp_camera.h"         // ESP32 카메라 기능 제공
#include "img_converters.h"     // 이미지 변환 함수 제공 (예, JPEG, BMP 변환)
#include "fb_gfx.h"             // 프레임버퍼 그래픽 처리 함수 제공
#include "esp32-hal-ledc.h"      // LED PWM 제어 기능 제공
#include "sdkconfig.h"          // SDK 설정 관련 헤더
#include "camera_index.h"       // 웹 서버용 HTML 인덱스 페이지 데이터 포함
#include <Arduino.h>    // isnan(), String 등 Arduino 함수들을 사용하기 위해
#include "DHT.h"        // DHT 클래스 선언
extern DHT dht;         // CameraWebServer.ino 에 정의된 전역 DHT 인스턴스를 참조
#define FLAME_PIN 14    // flame 핀 정의

#if defined(ARDUINO_ARCH_ESP32) && defined(CONFIG_ARDUHAL_ESP_LOG)
#include "esp32-hal-log.h"      // ESP32 Arduino 로그 함수 제공 (정보 출력)
#endif

// LED FLASH 기능을 활성화 (0: 비활성, 1: 활성)
#define CONFIG_LED_ILLUMINATOR_ENABLED 0

// HTTP 응답을 위한 JPEG 청크 정보를 저장하는 구조체
typedef struct {
  httpd_req_t *req;  // HTTP 요청 핸들
  size_t len;        // 전송한 데이터 길이
} jpg_chunking_t;

// 스트림용 경계(boundary) 문자열과 콘텐츠 타입 등 설정
#define PART_BOUNDARY "123456789000000000000987654321"
static const char *_STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char *_STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char *_STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\nX-Timestamp: %d.%06d\r\n\r\n";

// HTTP 서버 핸들러 변수
httpd_handle_t stream_httpd = NULL;   // 스트림 서버
httpd_handle_t camera_httpd = NULL;   // 카메라 제어 서버

// 값 필터링을 위한 구조체 (프레임 간 시간 평균 계산 등에 사용)
typedef struct {
  size_t size;    // 필터에 사용할 샘플 개수
  size_t index;   // 현재 샘플 인덱스
  size_t count;   // 실제 입력된 샘플 수
  int sum;        // 샘플 합계
  int *values;    // 샘플 값을 저장할 배열
} ra_filter_t;

static ra_filter_t ra_filter;   // 전역 필터 변수

// 필터 초기화 함수: sample_size 만큼의 배열을 할당하고 0으로 초기화
static ra_filter_t *ra_filter_init(ra_filter_t *filter, size_t sample_size) {
  memset(filter, 0, sizeof(ra_filter_t));
  filter->values = (int *)malloc(sample_size * sizeof(int));
  if (!filter->values) {
    return NULL;
  }
  memset(filter->values, 0, sample_size * sizeof(int));
  filter->size = sample_size;
  return filter;
}

#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
// 필터를 이용해 새 값(value)을 추가하고 평균값을 계산한다.
static int ra_filter_run(ra_filter_t *filter, int value) {
  if (!filter->values) {
    return value;
  }
  // 이전 값 제거
  filter->sum -= filter->values[filter->index];
  // 현재 인덱스에 새 값 저장
  filter->values[filter->index] = value;
  // 합계 업데이트
  filter->sum += filter->values[filter->index];
  // 인덱스 증가 및 배열 크기만큼 모듈로 연산
  filter->index++;
  filter->index = filter->index % filter->size;
  // 입력된 샘플 개수 업데이트
  if (filter->count < filter->size) {
    filter->count++;
  }
  // 평균값 반환
  return filter->sum / filter->count;
}
#endif

// BMP 포맷 이미지를 HTTP 응답으로 전송하는 핸들러 함수
static esp_err_t bmp_handler(httpd_req_t *req) {
  camera_fb_t *fb = NULL;
  esp_err_t res = ESP_OK;
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
  uint64_t fr_start = esp_timer_get_time();   // 처리 시작 시간 기록
#endif
  // 카메라에서 프레임 버퍼 캡처
  fb = esp_camera_fb_get();
  if (!fb) {
    log_e("Camera capture failed");
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  // HTTP 응답 타입 및 헤더 설정
  httpd_resp_set_type(req, "image/x-windows-bmp");
  httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=capture.bmp");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

  // 타임스탬프 헤더 설정
  char ts[32];
  snprintf(ts, 32, "%lld.%06ld", fb->timestamp.tv_sec, fb->timestamp.tv_usec);
  httpd_resp_set_hdr(req, "X-Timestamp", (const char *)ts);

  // BMP 포맷으로 변환
  uint8_t *buf = NULL;
  size_t buf_len = 0;
  bool converted = frame2bmp(fb, &buf, &buf_len);
  esp_camera_fb_return(fb);
  if (!converted) {
    log_e("BMP Conversion failed");
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  // 변환된 이미지 데이터를 HTTP 응답으로 전송
  res = httpd_resp_send(req, (const char *)buf, buf_len);
  free(buf);
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
  uint64_t fr_end = esp_timer_get_time();   // 처리 종료 시간 기록
#endif
  log_i("BMP: %llums, %uB", (uint64_t)((fr_end - fr_start) / 1000), buf_len);
  return res;
}

// JPEG 인코딩 시 콜백 함수: 인코딩된 데이터를 HTTP 청크 응답으로 전송
static size_t jpg_encode_stream(void *arg, size_t index, const void *data, size_t len) {
  jpg_chunking_t *j = (jpg_chunking_t *)arg;
  if (!index) {
    j->len = 0;
  }
  if (httpd_resp_send_chunk(j->req, (const char *)data, len) != ESP_OK) {
    return 0;
  }
  j->len += len;
  return len;
}

// 단일 캡처(정지된 이미지)를 처리하여 JPEG 이미지로 HTTP 응답 전송하는 핸들러
static esp_err_t capture_handler(httpd_req_t *req) {
  camera_fb_t *fb = NULL;
  esp_err_t res = ESP_OK;
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
  int64_t fr_start = esp_timer_get_time();
#endif

fb = esp_camera_fb_get();  //바로 프레임 캡처


  if (!fb) {
    log_e("Camera capture failed");
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }

  // HTTP 응답 헤더 설정 (JPEG 이미지)
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=capture.jpg");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

  // 타임스탬프 헤더 설정
  char ts[32];
  snprintf(ts, 32, "%lld.%06ld", fb->timestamp.tv_sec, fb->timestamp.tv_usec);
  httpd_resp_set_hdr(req, "X-Timestamp", (const char *)ts);

#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
  size_t fb_len = 0;
#endif
  // 만약 프레임 포맷이 JPEG이면 그대로 전송
  if (fb->format == PIXFORMAT_JPEG) {
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
    fb_len = fb->len;
#endif
    res = httpd_resp_send(req, (const char *)fb->buf, fb->len);
  } else {
    // JPEG가 아니라면 JPEG 인코딩 후 청크 전송
    jpg_chunking_t jchunk = {req, 0};
    res = frame2jpg_cb(fb, 80, jpg_encode_stream, &jchunk) ? ESP_OK : ESP_FAIL;
    // 전송 종료 청크 전송
    httpd_resp_send_chunk(req, NULL, 0);
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
    fb_len = jchunk.len;
#endif
  }
  esp_camera_fb_return(fb);
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
  int64_t fr_end = esp_timer_get_time();
#endif
  log_i("JPG: %uB %ums", (uint32_t)(fb_len), (uint32_t)((fr_end - fr_start) / 1000));
  return res;
}

// 연속 스트리밍 모드에서 캡처한 프레임들을 HTTP 멀티파트 스트림으로 전송하는 핸들러
static esp_err_t stream_handler(httpd_req_t *req) {
  camera_fb_t *fb = NULL;
  struct timeval _timestamp;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t *_jpg_buf = NULL;
  char *part_buf[128];

  // 이전 프레임 시간 초기화 (프레임 간 시간 측정을 위함)
  static int64_t last_frame = 0;
  if (!last_frame) {
    last_frame = esp_timer_get_time();
  }

  // HTTP 응답 타입과 헤더 설정
  res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  if (res != ESP_OK) {
    return res;
  }
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_hdr(req, "X-Framerate", "60");

  // 무한 루프로 프레임을 캡처 및 전송 (스트림 종료 조건은 외부에서 연결 종료)
  while (true) {
    fb = esp_camera_fb_get();
    if (!fb) {
      log_e("Camera capture failed");
      res = ESP_FAIL;
    } else {
      // 프레임 캡처 시간 저장
      _timestamp.tv_sec = fb->timestamp.tv_sec;
      _timestamp.tv_usec = fb->timestamp.tv_usec;
      if (fb->format != PIXFORMAT_JPEG) {
        // JPEG가 아닌 포맷이면 JPEG로 변환
        bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
        esp_camera_fb_return(fb);
        fb = NULL;
        if (!jpeg_converted) {
          log_e("JPEG compression failed");
          res = ESP_FAIL;
        }
      } else {
        // 이미 JPEG 포맷이면 바로 사용
        _jpg_buf_len = fb->len;
        _jpg_buf = fb->buf;
      }
    }
    // 멀티파트 경계 전송
    if (res == ESP_OK) {
      res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
    }
    // 각 파트의 헤더 전송 (Content-Type, Content-Length, Timestamp)
    if (res == ESP_OK) {
      size_t hlen = snprintf((char *)part_buf, 128, _STREAM_PART, _jpg_buf_len, _timestamp.tv_sec, _timestamp.tv_usec);
      res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
    }
    // JPEG 이미지 데이터 전송
    if (res == ESP_OK) {
      res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    }
    // 프레임 버퍼 반환 및 할당 해제
    if (fb) {
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if (_jpg_buf) {
      free(_jpg_buf);
      _jpg_buf = NULL;
    }
    if (res != ESP_OK) {
      log_e("Send frame failed");
      break;
    }
    // 프레임 간 시간 계산 및 평균 프레임 시간 업데이트 (필터 사용)
    int64_t fr_end = esp_timer_get_time();
    int64_t frame_time = fr_end - last_frame;
    last_frame = fr_end;
    frame_time /= 1000;  // 밀리초 단위 변환
#if ARDUHAL_LOG_LEVEL >= ARDUHAL_LOG_LEVEL_INFO
    uint32_t avg_frame_time = ra_filter_run(&ra_filter, frame_time);
#endif
    log_i("MJPG: %uB %ums (%.1ffps), AVG: %ums (%.1ffps)", (uint32_t)(_jpg_buf_len), (uint32_t)frame_time, 1000.0 / (uint32_t)frame_time, avg_frame_time, 1000.0 / avg_frame_time);
  }

  return res;
}

// HTTP GET 방식으로 전달된 쿼리 문자열을 파싱하여 버퍼에 저장하는 함수
static esp_err_t parse_get(httpd_req_t *req, char **obuf) {
  char *buf = NULL;
  size_t buf_len = 0;

  // URL 쿼리 문자열 길이 확인 및 버퍼 할당
  buf_len = httpd_req_get_url_query_len(req) + 1;
  if (buf_len > 1) {
    buf = (char *)malloc(buf_len);
    if (!buf) {
      httpd_resp_send_500(req);
      return ESP_FAIL;
    }
    // URL 쿼리 문자열 복사
    if (httpd_req_get_url_query_str(req, buf, buf_len) == ESP_OK) {
      *obuf = buf;
      return ESP_OK;
    }
    free(buf);
  }
  // 쿼리 문자열이 없으면 404 응답 전송
  httpd_resp_send_404(req);
  return ESP_FAIL;
}

// 카메라 제어 명령 처리 핸들러 (여러 센서 파라미터 제어)
static esp_err_t cmd_handler(httpd_req_t *req) {
  char *buf = NULL;
  char variable[32];
  char value[32];

  // 쿼리 문자열 파싱
  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }
  if (httpd_query_key_value(buf, "var", variable, sizeof(variable)) != ESP_OK ||
      httpd_query_key_value(buf, "val", value, sizeof(value)) != ESP_OK) {
    free(buf);
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  free(buf);

  int val = atoi(value);
  log_i("%s = %d", variable, val);
  sensor_t *s = esp_camera_sensor_get();
  int res = 0;

  // 각각의 센서 파라미터에 따라 처리
  if (!strcmp(variable, "framesize")) {
    if (s->pixformat == PIXFORMAT_JPEG) {
      res = s->set_framesize(s, (framesize_t)val);
    }
  } else if (!strcmp(variable, "quality")) {
    res = s->set_quality(s, val);
  } else if (!strcmp(variable, "contrast")) {
    res = s->set_contrast(s, val);
  } else if (!strcmp(variable, "brightness")) {
    res = s->set_brightness(s, val);
  } else if (!strcmp(variable, "saturation")) {
    res = s->set_saturation(s, val);
  } else if (!strcmp(variable, "gainceiling")) {
    res = s->set_gainceiling(s, (gainceiling_t)val);
  } else if (!strcmp(variable, "colorbar")) {
    res = s->set_colorbar(s, val);
  } else if (!strcmp(variable, "awb")) {
    res = s->set_whitebal(s, val);
  } else if (!strcmp(variable, "agc")) {
    res = s->set_gain_ctrl(s, val);
  } else if (!strcmp(variable, "aec")) {
    res = s->set_exposure_ctrl(s, val);
  } else if (!strcmp(variable, "hmirror")) {
    res = s->set_hmirror(s, val);
  } else if (!strcmp(variable, "vflip")) {
    res = s->set_vflip(s, val);
  } else if (!strcmp(variable, "awb_gain")) {
    res = s->set_awb_gain(s, val);
  } else if (!strcmp(variable, "agc_gain")) {
    res = s->set_agc_gain(s, val);
  } else if (!strcmp(variable, "aec_value")) {
    res = s->set_aec_value(s, val);
  } else if (!strcmp(variable, "aec2")) {
    res = s->set_aec2(s, val);
  } else if (!strcmp(variable, "dcw")) {
    res = s->set_dcw(s, val);
  } else if (!strcmp(variable, "bpc")) {
    res = s->set_bpc(s, val);
  } else if (!strcmp(variable, "wpc")) {
    res = s->set_wpc(s, val);
  } else if (!strcmp(variable, "raw_gma")) {
    res = s->set_raw_gma(s, val);
  } else if (!strcmp(variable, "lenc")) {
    res = s->set_lenc(s, val);
  } else if (!strcmp(variable, "special_effect")) {
    res = s->set_special_effect(s, val);
  } else if (!strcmp(variable, "wb_mode")) {
    res = s->set_wb_mode(s, val);
  } else if (!strcmp(variable, "ae_level")) {
    res = s->set_ae_level(s, val);
  }
#if CONFIG_LED_ILLUMINATOR_ENABLED
  else if (!strcmp(variable, "led_intensity")) {
    // LED 밝기 조절 명령 처리 (스트리밍 중이면 즉시 적용)
    led_duty = val;
    if (isStreaming) {
      enable_led(true);
    }
  }
#endif
  else {
    log_i("Unknown command: %s", variable);
    res = -1;
  }

  if (res < 0) {
    return httpd_resp_send_500(req);
  }

  // CORS 헤더 추가 후 응답 전송
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, NULL, 0);
}

// 센서 레지스터 값을 읽어 문자열 형태로 출력하기 위한 헬퍼 함수
static int print_reg(char *p, sensor_t *s, uint16_t reg, uint32_t mask) {
  return sprintf(p, "\"0x%x\":%u,", reg, s->get_reg(s, reg, mask));
}

// 센서 상태 정보를 JSON 형식으로 생성하여 응답하는 핸들러 함수
static esp_err_t status_handler(httpd_req_t *req) {
  static char json_response[1024];  // JSON 응답 버퍼

  sensor_t *s = esp_camera_sensor_get();
  char *p = json_response;
  *p++ = '{';

  // 센서 종류에 따라 각종 레지스터 값들을 JSON에 추가
  if (s->id.PID == OV5640_PID || s->id.PID == OV3660_PID) {
    for (int reg = 0x3400; reg < 0x3406; reg += 2) {
      p += print_reg(p, s, reg, 0xFFF);  // 12비트 값
    }
    p += print_reg(p, s, 0x3406, 0xFF);
    p += print_reg(p, s, 0x3500, 0xFFFF0);  // 16비트 값
    p += print_reg(p, s, 0x3503, 0xFF);
    p += print_reg(p, s, 0x350a, 0x3FF);    // 10비트 값
    p += print_reg(p, s, 0x350c, 0xFFFF);   // 16비트 값

    for (int reg = 0x5480; reg <= 0x5490; reg++) {
      p += print_reg(p, s, reg, 0xFF);
    }
    for (int reg = 0x5380; reg <= 0x538b; reg++) {
      p += print_reg(p, s, reg, 0xFF);
    }
    for (int reg = 0x5580; reg < 0x558a; reg++) {
      p += print_reg(p, s, reg, 0xFF);
    }
    p += print_reg(p, s, 0x558a, 0x1FF);  // 9비트 값
  } else if (s->id.PID == OV2640_PID) {
    p += print_reg(p, s, 0xd3, 0xFF);
    p += print_reg(p, s, 0x111, 0xFF);
    p += print_reg(p, s, 0x132, 0xFF);
  }

  // 추가 센서 설정 값을 JSON 형식에 추가
  p += sprintf(p, "\"xclk\":%u,", s->xclk_freq_hz / 1000000);
  p += sprintf(p, "\"pixformat\":%u,", s->pixformat);
  p += sprintf(p, "\"framesize\":%u,", s->status.framesize);
  p += sprintf(p, "\"quality\":%u,", s->status.quality);
  p += sprintf(p, "\"brightness\":%d,", s->status.brightness);
  p += sprintf(p, "\"contrast\":%d,", s->status.contrast);
  p += sprintf(p, "\"saturation\":%d,", s->status.saturation);
  p += sprintf(p, "\"sharpness\":%d,", s->status.sharpness);
  p += sprintf(p, "\"special_effect\":%u,", s->status.special_effect);
  p += sprintf(p, "\"wb_mode\":%u,", s->status.wb_mode);
  p += sprintf(p, "\"awb\":%u,", s->status.awb);
  p += sprintf(p, "\"awb_gain\":%u,", s->status.awb_gain);
  p += sprintf(p, "\"aec\":%u,", s->status.aec);
  p += sprintf(p, "\"aec2\":%u,", s->status.aec2);
  p += sprintf(p, "\"ae_level\":%d,", s->status.ae_level);
  p += sprintf(p, "\"aec_value\":%u,", s->status.aec_value);
  p += sprintf(p, "\"agc\":%u,", s->status.agc);
  p += sprintf(p, "\"agc_gain\":%u,", s->status.agc_gain);
  p += sprintf(p, "\"gainceiling\":%u,", s->status.gainceiling);
  p += sprintf(p, "\"bpc\":%u,", s->status.bpc);
  p += sprintf(p, "\"wpc\":%u,", s->status.wpc);
  p += sprintf(p, "\"raw_gma\":%u,", s->status.raw_gma);
  p += sprintf(p, "\"lenc\":%u,", s->status.lenc);
  p += sprintf(p, "\"hmirror\":%u,", s->status.hmirror);
  p += sprintf(p, "\"dcw\":%u,", s->status.dcw);
  p += sprintf(p, "\"colorbar\":%u", s->status.colorbar);
#if CONFIG_LED_ILLUMINATOR_ENABLED
  p += sprintf(p, ",\"led_intensity\":%u", led_duty);
#else
  p += sprintf(p, ",\"led_intensity\":%d", -1);
#endif
  *p++ = '}';  // JSON 닫는 중괄호
  *p++ = 0;    // 문자열 종료
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, json_response, strlen(json_response));
}

// XCLK 주파수를 설정하는 핸들러 함수
static esp_err_t xclk_handler(httpd_req_t *req) {
  char *buf = NULL;
  char _xclk[32];

  // 쿼리 문자열 파싱
  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }
  if (httpd_query_key_value(buf, "xclk", _xclk, sizeof(_xclk)) != ESP_OK) {
    free(buf);
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  free(buf);

  int xclk = atoi(_xclk);
  log_i("Set XCLK: %d MHz", xclk);

  sensor_t *s = esp_camera_sensor_get();
  // 센서의 XCLK 주파수를 설정 (LEDC_TIMER_0 사용)
  int res = s->set_xclk(s, LEDC_TIMER_0, xclk);
  if (res) {
    return httpd_resp_send_500(req);
  }

  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, NULL, 0);
}

// 특정 레지스터 값을 설정하는 핸들러 함수 (레지스터, 마스크, 값 전달)
static esp_err_t reg_handler(httpd_req_t *req) {
  char *buf = NULL;
  char _reg[32];
  char _mask[32];
  char _val[32];

  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }
  if (httpd_query_key_value(buf, "reg", _reg, sizeof(_reg)) != ESP_OK ||
      httpd_query_key_value(buf, "mask", _mask, sizeof(_mask)) != ESP_OK ||
      httpd_query_key_value(buf, "val", _val, sizeof(_val)) != ESP_OK) {
    free(buf);
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  free(buf);

  int reg = atoi(_reg);
  int mask = atoi(_mask);
  int val = atoi(_val);
  log_i("Set Register: reg: 0x%02x, mask: 0x%02x, value: 0x%02x", reg, mask, val);

  sensor_t *s = esp_camera_sensor_get();
  int res = s->set_reg(s, reg, mask, val);
  if (res) {
    return httpd_resp_send_500(req);
  }

  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, NULL, 0);
}

// 특정 레지스터 값을 읽어오는 핸들러 함수
static esp_err_t greg_handler(httpd_req_t *req) {
  char *buf = NULL;
  char _reg[32];
  char _mask[32];

  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }
  if (httpd_query_key_value(buf, "reg", _reg, sizeof(_reg)) != ESP_OK ||
      httpd_query_key_value(buf, "mask", _mask, sizeof(_mask)) != ESP_OK) {
    free(buf);
    httpd_resp_send_404(req);
    return ESP_FAIL;
  }
  free(buf);

  int reg = atoi(_reg);
  int mask = atoi(_mask);
  sensor_t *s = esp_camera_sensor_get();
  int res = s->get_reg(s, reg, mask);
  if (res < 0) {
    return httpd_resp_send_500(req);
  }
  log_i("Get Register: reg: 0x%02x, mask: 0x%02x, value: 0x%02x", reg, mask, res);

  char buffer[20];
  const char *val = itoa(res, buffer, 10);
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, val, strlen(val));
}

// GET 쿼리 문자열에서 정수형 변수 값을 파싱하는 헬퍼 함수
static int parse_get_var(char *buf, const char *key, int def) {
  char _int[16];
  if (httpd_query_key_value(buf, key, _int, sizeof(_int)) != ESP_OK) {
    return def;
  }
  return atoi(_int);
}

// PLL(Phase-Locked Loop) 설정을 처리하는 핸들러 함수
static esp_err_t pll_handler(httpd_req_t *req) {
  char *buf = NULL;

  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }

  // 여러 PLL 파라미터를 GET 변수로부터 파싱
  int bypass = parse_get_var(buf, "bypass", 0);
  int mul = parse_get_var(buf, "mul", 0);
  int sys = parse_get_var(buf, "sys", 0);
  int root = parse_get_var(buf, "root", 0);
  int pre = parse_get_var(buf, "pre", 0);
  int seld5 = parse_get_var(buf, "seld5", 0);
  int pclken = parse_get_var(buf, "pclken", 0);
  int pclk = parse_get_var(buf, "pclk", 0);
  free(buf);

  log_i("Set Pll: bypass: %d, mul: %d, sys: %d, root: %d, pre: %d, seld5: %d, pclken: %d, pclk: %d", bypass, mul, sys, root, pre, seld5, pclken, pclk);
  sensor_t *s = esp_camera_sensor_get();
  int res = s->set_pll(s, bypass, mul, sys, root, pre, seld5, pclken, pclk);
  if (res) {
    return httpd_resp_send_500(req);
  }

  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, NULL, 0);
}

// 윈도우(해상도) 설정을 처리하는 핸들러 함수
static esp_err_t win_handler(httpd_req_t *req) {
  char *buf = NULL;

  if (parse_get(req, &buf) != ESP_OK) {
    return ESP_FAIL;
  }

  // 해상도와 관련된 여러 파라미터 파싱 (시작 좌표, 종료 좌표, 오프셋, 총 해상도, 출력 크기, 스케일링, 바인닝)
  int startX = parse_get_var(buf, "sx", 0);
  int startY = parse_get_var(buf, "sy", 0);
  int endX = parse_get_var(buf, "ex", 0);
  int endY = parse_get_var(buf, "ey", 0);
  int offsetX = parse_get_var(buf, "offx", 0);
  int offsetY = parse_get_var(buf, "offy", 0);
  int totalX = parse_get_var(buf, "tx", 0);
  int totalY = parse_get_var(buf, "ty", 0);  // 전체 높이
  int outputX = parse_get_var(buf, "ox", 0);
  int outputY = parse_get_var(buf, "oy", 0);
  bool scale = parse_get_var(buf, "scale", 0) == 1;
  bool binning = parse_get_var(buf, "binning", 0) == 1;
  free(buf);

  log_i("Set Window: Start: %d %d, End: %d %d, Offset: %d %d, Total: %d %d, Output: %d %d, Scale: %u, Binning: %u",
        startX, startY, endX, endY, offsetX, offsetY, totalX, totalY, outputX, outputY, scale, binning);
  sensor_t *s = esp_camera_sensor_get();
  int res = s->set_res_raw(s, startX, startY, endX, endY, offsetX, offsetY, totalX, totalY, outputX, outputY, scale, binning);
  if (res) {
    return httpd_resp_send_500(req);
  }

  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, NULL, 0);
}

// 인덱스 페이지 (웹 인터페이스 홈) 요청을 처리하는 핸들러 함수
static esp_err_t index_handler(httpd_req_t *req) {
  httpd_resp_set_type(req, "text/html");
  httpd_resp_set_hdr(req, "Content-Encoding", "gzip");  // 압축된 HTML 파일 사용
  sensor_t *s = esp_camera_sensor_get();
  if (s != NULL) {
      return httpd_resp_send(req, (const char *)index_ov2640_html_gz, index_ov2640_html_gz_len);
  } else {
    log_e("Camera sensor not found");
    return httpd_resp_send_500(req);
  }
}

extern float cachedHumidity;
extern float cachedTemperature;

static esp_err_t dht_handler(httpd_req_t *req) {
  if (isnan(cachedHumidity) || isnan(cachedTemperature)) {
    return httpd_resp_send_500(req);
  }
  char buf[64];
  int len = snprintf(buf, sizeof(buf),
                     "{\"temperature\":%.2f,\"humidity\":%.2f}",
                     cachedTemperature, cachedHumidity);
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, buf, len);
}
// 불꽃 센서 상태를 JSON으로 반환 
static esp_err_t flame_handler(httpd_req_t *req) {
  int flame = digitalRead(FLAME_PIN);  // 0: 불꽃 감지, 1: 정상
  char buf[32]; // JSON 포맷으로
  int len = snprintf(buf, sizeof(buf), "{\"flame\":%d}", flame);
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, buf, len);
}

// 카메라 서버 및 스트림 서버를 시작하는 함수
void startCameraServer() {
  // 기본 HTTP 서버 설정 복사 (기본 URI 핸들러 최대 개수 등)
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.max_uri_handlers = 16;

  // 각 URI와 그에 해당하는 핸들러를 정의 (웹 인터페이스, 상태, 제어, 캡처, 스트림, BMP, XCLK, 레지스터, PLL, 해상도)
  httpd_uri_t index_uri = {
    .uri = "/",
    .method = HTTP_GET,
    .handler = index_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t status_uri = {
    .uri = "/status",
    .method = HTTP_GET,
    .handler = status_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t cmd_uri = {
    .uri = "/control",
    .method = HTTP_GET,
    .handler = cmd_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t capture_uri = {
    .uri = "/capture",
    .method = HTTP_GET,
    .handler = capture_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t stream_uri = {
    .uri = "/stream",
    .method = HTTP_GET,
    .handler = stream_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t bmp_uri = {
    .uri = "/bmp",
    .method = HTTP_GET,
    .handler = bmp_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t xclk_uri = {
    .uri = "/xclk",
    .method = HTTP_GET,
    .handler = xclk_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t reg_uri = {
    .uri = "/reg",
    .method = HTTP_GET,
    .handler = reg_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t greg_uri = {
    .uri = "/greg",
    .method = HTTP_GET,
    .handler = greg_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t pll_uri = {
    .uri = "/pll",
    .method = HTTP_GET,
    .handler = pll_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

  httpd_uri_t win_uri = {
    .uri = "/resolution",
    .method = HTTP_GET,
    .handler = win_handler,
    .user_ctx = NULL
#ifdef CONFIG_HTTPD_WS_SUPPORT
    ,
    .is_websocket = true,
    .handle_ws_control_frames = false,
    .supported_subprotocol = NULL
#endif
  };

    // dht_uri 정의
  httpd_uri_t dht_uri = {
    .uri      = "/dht",
    .method   = HTTP_GET,
    .handler  = dht_handler,
    .user_ctx = NULL
  };

  httpd_uri_t flame_uri = {
  .uri      = "/flame",
  .method   = HTTP_GET,
  .handler  = flame_handler,
  .user_ctx = NULL
  };

  // 프레임 간 시간 평균을 위한 필터 초기화 (20개 샘플)
  ra_filter_init(&ra_filter, 20);

  log_i("Starting web server on port: '%d'", config.server_port);
  // 카메라 제어 서버 시작 후 URI 핸들러 등록
  if (httpd_start(&camera_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(camera_httpd, &index_uri);
    httpd_register_uri_handler(camera_httpd, &cmd_uri);
    httpd_register_uri_handler(camera_httpd, &status_uri);
    httpd_register_uri_handler(camera_httpd, &capture_uri);
    httpd_register_uri_handler(camera_httpd, &bmp_uri);
    httpd_register_uri_handler(camera_httpd, &xclk_uri);
    httpd_register_uri_handler(camera_httpd, &reg_uri);
    httpd_register_uri_handler(camera_httpd, &greg_uri);
    httpd_register_uri_handler(camera_httpd, &pll_uri);
    httpd_register_uri_handler(camera_httpd, &win_uri);
    httpd_register_uri_handler(camera_httpd, &dht_uri);
    httpd_register_uri_handler(camera_httpd, &flame_uri);
    httpd_register_uri_handler(camera_httpd, &stream_uri);
  }
}

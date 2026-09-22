// GPath bar sensor firmware for the Waveshare ESP32-S3-LCD-1.47B-M.
//
// Reads the on-board QMI8658 IMU, detects reps with RepDetector, and streams
// one 12-byte packet per rep over BLE to the Flutter app. The LCD shows the
// connection state, rep count and last mean velocity.
//
// Libraries (Arduino Library Manager):
//   - "SensorLib" by Lewis He       (QMI8658 driver)
//   - "GFX Library for Arduino"     (Arduino_GFX, ST7789)
//   - ESP32 Arduino core 3.x        (built-in BLE)
// Board: "ESP32S3 Dev Module", USB CDC On Boot: Enabled, PSRAM: OPI PSRAM,
//        Flash Size: 16MB, Partition: default 16MB.

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Arduino_GFX_Library.h>
#include <SensorQMI8658.hpp>

#include "board_config.h"
#include "rep_detector.h"

// ---- GATT contract (mirror of lib/sensors/gpath_protocol.dart) -----------
static const char* SERVICE_UUID = "7a0c0001-5d8e-4b1f-9c3a-2f1b8e6d4a01";
static const char* REP_CHAR_UUID = "7a0c0002-5d8e-4b1f-9c3a-2f1b8e6d4a01";
static const char* CTRL_CHAR_UUID = "7a0c0003-5d8e-4b1f-9c3a-2f1b8e6d4a01";

enum : uint8_t { CMD_START = 0x01, CMD_STOP = 0x02, CMD_TARE = 0x03 };
enum : uint8_t { PKT_REP = 0x01 };

// ---- globals -------------------------------------------------------------
Arduino_DataBus* bus = new Arduino_ESP32SPI(LCD_DC, LCD_CS, LCD_SCK, LCD_MOSI, GFX_NOT_DEFINED);
Arduino_GFX* gfx = new Arduino_ST7789(bus, LCD_RST, 0 /*rotation*/, true /*IPS*/, LCD_W, LCD_H,
                                      LCD_COL_OFFSET, 0, LCD_COL_OFFSET, 0);

SensorQMI8658 imu;
RepDetector detector;

BLEServer* server = nullptr;
BLECharacteristic* repChar = nullptr;
volatile bool bleConnected = false;

struct SetState {
  bool active = false;
  uint8_t targetReps = 0;
  float weightKg = 0;
  bool concentricFirst = false;
} setState;

float lastMeanVel = 0;
uint32_t lastSampleUs = 0;
uint32_t lastDrawMs = 0;
bool dirty = true;

// ---- BLE callbacks -------------------------------------------------------
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    bleConnected = true;
    dirty = true;
  }
  void onDisconnect(BLEServer* s) override {
    bleConnected = false;
    setState.active = false;
    detector.stopSet();
    dirty = true;
    s->startAdvertising();
  }
};

class ControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String v = c->getValue();
    if (v.length() == 0) return;
    const uint8_t* d = (const uint8_t*)v.c_str();
    switch (d[0]) {
      case CMD_START:
        setState.active = true;
        setState.targetReps = v.length() > 1 ? d[1] : 0;
        setState.weightKg = v.length() > 3 ? (d[2] | (d[3] << 8)) / 10.0f : 0;
        setState.concentricFirst = v.length() > 4 ? d[4] != 0 : false;
        detector.startSet(setState.concentricFirst);
        lastMeanVel = 0;
        break;
      case CMD_STOP:
        setState.active = false;
        detector.stopSet();
        break;
      case CMD_TARE:
        detector.reset();
        break;
    }
    dirty = true;
  }
};

// ---- helpers -------------------------------------------------------------
static void notifyRep(const RepResult& r) {
  uint8_t pkt[12];
  const uint16_t mean = (uint16_t)constrain(r.meanVelocity * 1000.0f, 0, 65535);
  const uint16_t peak = (uint16_t)constrain(r.peakVelocity * 1000.0f, 0, 65535);
  const uint16_t rom = (uint16_t)constrain(r.rangeOfMotion * 1000.0f, 0, 65535);
  pkt[0] = PKT_REP;
  pkt[1] = r.index;
  pkt[2] = mean & 0xFF; pkt[3] = mean >> 8;
  pkt[4] = peak & 0xFF; pkt[5] = peak >> 8;
  pkt[6] = rom & 0xFF;  pkt[7] = rom >> 8;
  pkt[8] = r.sinceStartMs & 0xFF;
  pkt[9] = (r.sinceStartMs >> 8) & 0xFF;
  pkt[10] = (r.sinceStartMs >> 16) & 0xFF;
  pkt[11] = (r.sinceStartMs >> 24) & 0xFF;
  if (bleConnected && repChar) {
    repChar->setValue(pkt, sizeof(pkt));
    repChar->notify();
  }
}

static void draw() {
  gfx->fillScreen(BLACK);
  gfx->setTextColor(bleConnected ? GREEN : DARKGREY);
  gfx->setTextSize(2);
  gfx->setCursor(8, 10);
  gfx->print(bleConnected ? "BLE  ok" : "BLE  --");

  gfx->setTextColor(WHITE);
  gfx->setTextSize(2);
  gfx->setCursor(8, 50);
  gfx->print(setState.active ? "SET LIVE" : "idle");

  gfx->setTextSize(7);
  gfx->setTextColor(setState.active ? GREEN : LIGHTGREY);
  gfx->setCursor(20, 110);
  gfx->print(detector.repCount());
  if (setState.targetReps > 0) {
    gfx->setTextSize(2);
    gfx->setTextColor(DARKGREY);
    gfx->setCursor(20, 175);
    gfx->printf("/ %d", setState.targetReps);
  }

  gfx->setTextSize(3);
  gfx->setTextColor(WHITE);
  gfx->setCursor(8, 220);
  gfx->printf("%.2f", lastMeanVel);
  gfx->setTextSize(2);
  gfx->setTextColor(DARKGREY);
  gfx->setCursor(8, 250);
  gfx->print("m/s mean");

  if (setState.weightKg > 0) {
    gfx->setCursor(8, 290);
    gfx->printf("%.1f kg", setState.weightKg);
  }
}

// ---- setup / loop --------------------------------------------------------
void setup() {
  Serial.begin(115200);
  pinMode(BTN_BOOT, INPUT_PULLUP);

  pinMode(LCD_BL, OUTPUT);
  digitalWrite(LCD_BL, HIGH);
  gfx->begin();
  gfx->fillScreen(BLACK);
  gfx->setTextColor(WHITE);
  gfx->setTextSize(2);
  gfx->setCursor(8, 10);
  gfx->print("GPath sensor");

  if (!imu.begin(Wire, IMU_ADDR, IMU_SDA, IMU_SCL)) {
    gfx->setCursor(8, 50);
    gfx->setTextColor(RED);
    gfx->print("IMU not found");
    Serial.println("QMI8658 not found; check IMU_SDA/IMU_SCL in board_config.h");
    while (true) delay(1000);
  }
  imu.configAccelerometer(SensorQMI8658::ACC_RANGE_8G, SensorQMI8658::ACC_ODR_250Hz,
                          SensorQMI8658::LPF_MODE_0);
  imu.configGyroscope(SensorQMI8658::GYR_RANGE_512DPS, SensorQMI8658::GYR_ODR_224_2Hz,
                      SensorQMI8658::LPF_MODE_3);
  imu.enableAccelerometer();
  imu.enableGyroscope();

  uint64_t mac = ESP.getEfuseMac();
  char name[16];
  snprintf(name, sizeof(name), "GPATH-%04X", (uint16_t)(mac & 0xFFFF));
  BLEDevice::init(name);
  server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService* svc = server->createService(SERVICE_UUID);
  repChar = svc->createCharacteristic(REP_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  repChar->addDescriptor(new BLE2902());
  BLECharacteristic* ctrl = svc->createCharacteristic(
      CTRL_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  ctrl->setCallbacks(new ControlCallbacks());
  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  BLEDevice::startAdvertising();

  lastSampleUs = micros();
  Serial.printf("Advertising as %s\n", name);
}

void loop() {
  // BOOT button: re-zero while the bar is still.
  static uint32_t btnDownMs = 0;
  if (digitalRead(BTN_BOOT) == LOW) {
    if (btnDownMs == 0) btnDownMs = millis();
  } else if (btnDownMs != 0) {
    if (millis() - btnDownMs > 30) {
      detector.reset();
      dirty = true;
    }
    btnDownMs = 0;
  }

  if (imu.getDataReady()) {
    float ax, ay, az;
    if (imu.getAccelerometer(ax, ay, az)) {
      const uint32_t now = micros();
      float dt = (now - lastSampleUs) / 1e6f;
      lastSampleUs = now;
      if (dt <= 0 || dt > 0.05f) dt = 1.0f / IMU_SAMPLE_HZ;

      RepResult rep;
      if (detector.update(ax, ay, az, dt, &rep)) {
        lastMeanVel = rep.meanVelocity;
        notifyRep(rep);
        Serial.printf("rep %u  mean %.2f m/s  peak %.2f  rom %.2f m\n", rep.index,
                      rep.meanVelocity, rep.peakVelocity, rep.rangeOfMotion);
        dirty = true;
        if (setState.targetReps > 0 && rep.index >= setState.targetReps) {
          setState.active = false;
          detector.stopSet();
        }
      }
    }
  }

  if (dirty && millis() - lastDrawMs > 80) {
    draw();
    dirty = false;
    lastDrawMs = millis();
  }
}

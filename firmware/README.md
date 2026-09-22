# GPath bar sensor firmware (ESP32-S3-LCD-1.47B-M)

Waveshare **ESP32-S3-LCD-1.47B-M** 보드를 바/핸들에 붙여 렙과 평균 속도를 측정하고,
BLE로 Flutter 앱(`flutter_app/`)에 보내는 펌웨어입니다.

| 보드 구성 | 값 |
| --- | --- |
| MCU | ESP32-S3R8 (BLE 5, Wi-Fi) |
| IMU | QMI8658 6축 (I²C) |
| LCD | 1.47″ ST7789 172×320 |
| 전원 | USB-C, 배터리 헤더 |

## 폴더

```
firmware/
  gpath_bar_sensor/
    gpath_bar_sensor.ino   BLE 서버 + IMU 루프 + LCD 표시
    rep_detector.h         순수 C++ 렙 감지 알고리즘 (Arduino 의존성 없음)
    board_config.h         핀맵 (LCD SPI, IMU I²C, BOOT 버튼)
  test/
    rep_detector_test.cpp  PC에서 돌리는 알고리즘 테스트
```

## 빌드

1. Arduino IDE에 **ESP32 Arduino core 3.x** 설치.
2. 라이브러리 매니저에서 설치:
   - `SensorLib` (Lewis He) - QMI8658 드라이버
   - `GFX Library for Arduino` (Arduino_GFX) - ST7789
3. 보드 설정: `ESP32S3 Dev Module`, USB CDC On Boot **Enabled**, PSRAM **OPI PSRAM**,
   Flash Size **16MB**.
4. `gpath_bar_sensor.ino` 열고 업로드. 시리얼(115200)에 `Advertising as GPATH-xxxx`가 찍힙니다.

핀은 `board_config.h`에 모여 있습니다. LCD 핀(DC 41, CS 42, SCK 40, MOSI 45, RST 39, BL 48)은
Waveshare 1.47″ 보드 예제 기준이고, IMU I²C(SDA 6, SCL 7, 주소 0x6B)는 1.47B 위키 기준입니다.
IMU를 못 찾으면 LCD에 `IMU not found`가 뜨니 그때 이 값부터 확인하세요.

## 동작

- 부팅 후 `GPATH-xxxx` 이름으로 광고. 앱의 센서 링을 눌러 페어링합니다.
- 앱이 **Start set**을 누르면 `START` 명령(목표 렙, 무게, concentric 방향)이 오고 렙 감지가 켜집니다.
- 렙이 감지될 때마다 12바이트 패킷을 notify 하고, LCD에 렙 수/평균 속도를 표시합니다.
- 목표 렙에 도달하면 자동으로 세트가 끝납니다. **BOOT** 버튼은 바가 정지한 상태에서 영점 재설정(tare)입니다.

## BLE GATT

| 항목 | UUID |
| --- | --- |
| Service | `7a0c0001-5d8e-4b1f-9c3a-2f1b8e6d4a01` |
| Rep (NOTIFY) | `7a0c0002-…` |
| Control (WRITE) | `7a0c0003-…` |

Rep 패킷 (little-endian):

| 바이트 | 내용 |
| --- | --- |
| 0 | 0x01 |
| 1 | 세트 내 렙 번호 (1부터) |
| 2-3 | 평균 concentric 속도, mm/s |
| 4-5 | 최고 속도, mm/s |
| 6-7 | 가동 범위, mm |
| 8-11 | 세트 시작 후 경과, ms |

Control 명령: `0x01 START [targetReps][kg×10 lo][kg×10 hi][concentricFirst]`, `0x02 STOP`, `0x03 TARE`.
앱 쪽 정의는 `flutter_app/lib/sensors/gpath_protocol.dart`에 있고, 두 파일은 항상 같이 바꿔야 합니다.

## 렙 감지 알고리즘

`rep_detector.h`:

1. 정지 구간에서 중력 방향을 학습(저역통과)하고, 중력 축 성분에서 1 g를 빼 선형 가속도를 얻습니다.
2. 이를 적분해 수직 속도를 구합니다.
3. 방향이 바뀌는 순간(속도 부호 반전)과 정지 구간에서 속도를 0으로 재설정해 드리프트를 한 구간으로 제한합니다.
4. 한 방향으로 이어진 움직임을 "phase"로 묶고, 길이·거리·속도가 기준 이상이며 concentric 방향인 phase를 렙으로 셉니다.
   벤치/스쿼트는 위 방향, 풀다운/로우는 아래 방향이 concentric이며 앱이 START 명령에 이 플래그를 실어 보냅니다.

PC에서 확인:

```bash
cd firmware/test
g++ -std=c++17 -I../gpath_bar_sensor rep_detector_test.cpp -o rep_test && ./rep_test
```

합성 벤치프레스 5렙에서 평균 속도 오차 0.005 m/s, 풀다운 방향 구분, 잡음 무시, 비활성 상태 무시를 검증합니다.

## 알려진 한계

- 가속도 단일 적분이라 한 phase 안에서 드리프트가 남습니다. 렙이 길수록(3초 이상) 오차가 커집니다.
- 바가 크게 회전하는 종목(클린 등)은 중력 축 추정이 흔들립니다. 이 보드에는 자이로가 있으니
  다음 단계로 자세 융합(Madgwick)을 넣으면 개선됩니다.
- 상수(`RepDetector::Config`)는 합성 데이터 기준이라 실제 바에서 튜닝이 필요합니다.

// Waveshare ESP32-S3-LCD-1.47B-M pin map.
//
// LCD pins are the ones Waveshare ships in their Arduino_GFX example for the
// 1.47" boards (ST7789, 172x320, 34-px column offset). The IMU I2C pins are
// from the ESP32-S3-LCD-1.47B wiki; double-check both against
// https://www.waveshare.com/wiki/ESP32-S3-LCD-1.47B before flashing.
#pragma once

// ST7789 172x320 over SPI
#define LCD_DC 41
#define LCD_CS 42
#define LCD_SCK 40
#define LCD_MOSI 45
#define LCD_RST 39
#define LCD_BL 48
#define LCD_W 172
#define LCD_H 320
#define LCD_COL_OFFSET 34

// QMI8658 6-axis IMU over I2C (address 0x6B on these boards)
#define IMU_SDA 6
#define IMU_SCL 7
#define IMU_ADDR 0x6B

// BOOT button doubles as "tare"
#define BTN_BOOT 0

// Sampling
#define IMU_SAMPLE_HZ 200

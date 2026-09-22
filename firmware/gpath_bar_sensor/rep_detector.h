// Rep detection from a 3-axis accelerometer mounted on the bar / handle.
//
// Pure C++, no Arduino dependency, so it can be unit-tested on a PC
// (see firmware/test/rep_detector_test.cpp).
//
// Method
//  1. Gravity direction is tracked with a slow low-pass filter that only
//     updates while the bar is still (ZUPT windows).
//  2. Linear acceleration along gravity is integrated into vertical velocity.
//  3. Velocity is reset to zero at every turnaround (sign change) and at
//     every rest, which bounds drift to a single phase.
//  4. A "phase" is one continuous movement in one direction. Phases in the
//     concentric direction that are long enough become reps.
#pragma once

#include <math.h>
#include <stdint.h>

struct RepResult {
  uint8_t index;          // 1-based rep number in the set
  float meanVelocity;     // m/s, mean |v| over the concentric phase
  float peakVelocity;     // m/s
  float rangeOfMotion;    // m
  uint32_t sinceStartMs;  // ms since startSet()
};

class RepDetector {
 public:
  struct Config {
    float g = 9.80665f;
    float gravityAlpha = 0.02f;      // gravity LPF weight while at rest
    float restAccelThresh = 0.10f;   // g, |lin accel| below this = still
    float restVelThresh = 0.05f;     // m/s, |v| below this while still
    uint32_t restHoldMs = 120;       // still this long -> ZUPT
    float minPhaseMs = 150;          // shorter phases are noise
    float minRom = 0.06f;            // m, shorter phases are noise
    float minPeakVel = 0.08f;        // m/s
  };

  RepDetector() : cfg_(Config()) { reset(); }
  explicit RepDetector(const Config& c) : cfg_(c) { reset(); }

  void reset() {
    gx_ = 0; gy_ = 0; gz_ = 1;   // assume z up until we learn better
    v_ = 0; disp_ = 0; velSum_ = 0; velN_ = 0; peak_ = 0;
    phaseMs_ = 0; restMs_ = 0; timeMs_ = 0; reps_ = 0;
    phaseDir_ = 0; armed_ = false; concentricUp_ = true;
    calibrated_ = false;
  }

  // Arm rep counting. concentricFirst=true for pull-downs / rows, where the
  // working (concentric) phase moves the handle DOWN.
  void startSet(bool concentricFirst) {
    concentricUp_ = !concentricFirst;
    reps_ = 0;
    timeMs_ = 0;
    v_ = 0;
    endPhase();
    armed_ = true;
  }

  void stopSet() { armed_ = false; }
  bool isArmed() const { return armed_; }
  uint8_t repCount() const { return reps_; }
  float velocity() const { return v_; }

  // Feed one accelerometer sample in g. Returns true when `out` holds a
  // newly detected rep.
  bool update(float ax, float ay, float az, float dtSec, RepResult* out) {
    const float dtMs = dtSec * 1000.0f;
    timeMs_ += dtMs;

    // Linear acceleration along the current gravity estimate (up positive).
    const float gmag = sqrtf(gx_ * gx_ + gy_ * gy_ + gz_ * gz_);
    const float ux = gx_ / gmag, uy = gy_ / gmag, uz = gz_ / gmag;
    const float along = ax * ux + ay * uy + az * uz;  // g
    const float lin = along - 1.0f;                    // g, gravity removed
    const float aLin = lin * cfg_.g;                   // m/s^2

    // Rest detection + gravity learning.
    const bool quiet = fabsf(lin) < cfg_.restAccelThresh;
    if (quiet) {
      restMs_ += dtMs;
      if (restMs_ >= cfg_.restHoldMs) {
        // Update gravity estimate (fast on first lock, slow afterwards).
        const float a = calibrated_ ? cfg_.gravityAlpha : 0.5f;
        gx_ += (ax - gx_) * a;
        gy_ += (ay - gy_) * a;
        gz_ += (az - gz_) * a;
        calibrated_ = true;
        if (fabsf(v_) < cfg_.restVelThresh || restMs_ >= cfg_.restHoldMs * 3) {
          const bool rep = endPhase(out);
          v_ = 0;
          return rep;
        }
      }
    } else {
      restMs_ = 0;
    }

    if (!calibrated_) return false;

    // Integrate velocity.
    const float vPrev = v_;
    v_ += aLin * dtSec;

    // Turnaround: sign change ends the phase and re-zeroes velocity.
    bool rep = false;
    const int dir = v_ > 0 ? 1 : (v_ < 0 ? -1 : 0);
    if (phaseDir_ != 0 && dir != 0 && dir != phaseDir_) {
      rep = endPhase(out);
      v_ = 0;
    } else if (dir != 0) {
      if (phaseDir_ == 0) phaseDir_ = dir;
      const float vAbs = fabsf(v_);
      disp_ += 0.5f * (fabsf(vPrev) + vAbs) * dtSec;
      velSum_ += vAbs;
      velN_++;
      if (vAbs > peak_) peak_ = vAbs;
      phaseMs_ += dtMs;
    }
    return rep;
  }

 private:
  // Close the current phase; emit a rep if it qualifies.
  bool endPhase(RepResult* out = nullptr) {
    bool rep = false;
    if (armed_ && phaseDir_ != 0 && velN_ > 0 &&
        phaseMs_ >= cfg_.minPhaseMs && disp_ >= cfg_.minRom &&
        peak_ >= cfg_.minPeakVel) {
      const bool isConcentric = (phaseDir_ > 0) == concentricUp_;
      if (isConcentric && out != nullptr) {
        reps_++;
        out->index = reps_;
        out->meanVelocity = velSum_ / velN_;
        out->peakVelocity = peak_;
        out->rangeOfMotion = disp_;
        out->sinceStartMs = (uint32_t)timeMs_;
        rep = true;
      }
    }
    phaseDir_ = 0;
    disp_ = 0;
    velSum_ = 0;
    velN_ = 0;
    peak_ = 0;
    phaseMs_ = 0;
    return rep;
  }

  Config cfg_;
  float gx_, gy_, gz_;
  float v_, disp_, velSum_, peak_;
  uint32_t velN_;
  float phaseMs_, restMs_, timeMs_;
  uint8_t reps_;
  int phaseDir_;
  bool armed_, concentricUp_, calibrated_;
};

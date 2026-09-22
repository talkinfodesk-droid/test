// Host-side test for RepDetector: synthesises bench-press style motion
// (down then up, sinusoidal velocity) and checks reps + mean velocity.
//
//   g++ -std=c++17 -I../gpath_bar_sensor rep_detector_test.cpp -o rep_test && ./rep_test
#include <cstdio>
#include <cmath>
#include <vector>

#include "rep_detector.h"

static const float G = 9.80665f;
static const float HZ = 200.0f;
static const float DT = 1.0f / HZ;

struct Sim {
  RepDetector det;
  std::vector<RepResult> reps;
  float t = 0;

  void still(float seconds) {
    for (int i = 0; i < (int)(seconds * HZ); i++) feed(0);
  }
  // One movement phase with sinusoidal velocity of peak vPeak (m/s),
  // duration T seconds, sign +1 up / -1 down.
  void phase(float vPeak, float T, int sign) {
    const int n = (int)(T * HZ);
    for (int i = 0; i < n; i++) {
      const float tt = (i + 0.5f) * DT;
      // v = vPeak*sin(pi t/T); a = dv/dt
      const float a = sign * vPeak * (float)M_PI / T * cosf((float)M_PI * tt / T);
      feed(a);
    }
  }
  // Mounting orientation: unit vector of "up" in the board frame.
  float ux = 0.3f, uy = -0.2f, uz = sqrtf(1 - 0.3f * 0.3f - 0.2f * 0.2f);

  void feed(float aVerticalMs2) {
    const float total = 1.0f + aVerticalMs2 / G;  // g
    RepResult r;
    if (det.update(total * ux, total * uy, total * uz, DT, &r)) reps.push_back(r);
    t += DT;
  }
};

// Bench-press set with the board mounted along the given "up" vector.
static size_t repsForMounting(float ux, float uy, float uz) {
  Sim s;
  s.ux = ux; s.uy = uy; s.uz = uz;
  s.still(1.0f);
  s.det.startSet(false);
  for (int i = 0; i < 3; i++) {
    s.phase(0.6f, 0.8f, -1);
    s.phase(0.6f, 0.8f, +1);
    s.still(0.5f);
  }
  return s.reps.size();
}

static int failures = 0;
#define CHECK(cond, msg)                                       \
  do {                                                          \
    if (!(cond)) {                                              \
      printf("FAIL: %s (%s:%d)\n", msg, __FILE__, __LINE__);    \
      failures++;                                               \
    } else {                                                    \
      printf("ok   %s\n", msg);                                 \
    }                                                           \
  } while (0)

int main() {
  {
    Sim s;
    s.still(1.0f);                 // learn gravity
    s.det.startSet(false);         // bench: eccentric first, concentric = up
    const float vPeak = 0.6f, T = 0.8f;
    for (int i = 0; i < 5; i++) {
      s.phase(vPeak, T, -1);       // down
      s.phase(vPeak, T, +1);       // up (concentric)
      s.still(0.5f);               // lockout pause
    }
    s.det.stopSet();
    CHECK(s.reps.size() == 5, "bench: 5 concentric reps detected");
    if (!s.reps.empty()) {
      const float expectMean = 2.0f * vPeak / (float)M_PI;  // mean of |sin|
      const float m = s.reps[0].meanVelocity;
      printf("     mean %.3f (expected ~%.3f), peak %.3f, rom %.3f m\n", m, expectMean,
             s.reps[0].peakVelocity, s.reps[0].rangeOfMotion);
      CHECK(fabsf(m - expectMean) < 0.06f, "bench: mean velocity within 0.06 m/s");
      CHECK(fabsf(s.reps[0].peakVelocity - vPeak) < 0.08f, "bench: peak velocity close");
      CHECK(s.reps.back().index == 5, "bench: rep index counts up");
    }
  }
  {
    Sim s;
    s.still(1.0f);
    s.det.startSet(true);          // pulldown: concentric = down, first
    for (int i = 0; i < 4; i++) {
      s.phase(0.5f, 0.7f, -1);     // pull down (concentric)
      s.phase(0.5f, 0.9f, +1);     // return up
    }
    CHECK(s.reps.size() == 4, "pulldown: 4 reps, down phases only");
  }
  {
    Sim s;
    s.still(1.0f);
    s.det.startSet(false);
    // Tiny jiggle must not count.
    for (int i = 0; i < 3; i++) { s.phase(0.05f, 0.2f, -1); s.phase(0.05f, 0.2f, +1); }
    s.still(0.5f);
    CHECK(s.reps.empty(), "noise: no reps from small wobble");
    // Not armed: nothing counts.
    s.det.stopSet();
    s.phase(0.6f, 0.8f, -1); s.phase(0.6f, 0.8f, +1);
    CHECK(s.reps.empty(), "stopped set: movement ignored");
  }
  CHECK(repsForMounting(1, 0, 0) == 3, "mounting: x-axis up still counts reps");
  CHECK(repsForMounting(0, 0, -1) == 3, "mounting: upside down still counts reps");
  CHECK(repsForMounting(0, 0.7071f, -0.7071f) == 3, "mounting: 45-degree tilt still counts");
  printf(failures ? "\n%d FAILED\n" : "\nALL PASSED\n", failures);
  return failures ? 1 : 0;
}

# Device Compatibility Test Matrix (M2.2.6.1)

_Last updated: 2025-06-16_

| Platform | Device                              | OS / FW                 | Health Store             | Tested Data Types                  | Result                           |
| -------- | ----------------------------------- | ----------------------- | ------------------------ | ---------------------------------- | -------------------------------- |
| iOS      | iPhone 15 Pro + Apple Watch Ultra   | iOS 17.5 / watchOS 10.5 | HealthKit                | Steps, HR, HRV, Sleep, VO₂, Energy | ✅ Pass                          |
| iOS      | iPhone 13 mini + Apple Watch SE     | iOS 17.5 / watchOS 10.5 | HealthKit                | Steps, HR, Sleep                   | ✅ Pass                          |
| Android  | Pixel 8 Pro + Garmin Venu 3 (betas) | Android 15 beta 2       | Health Connect (Google)  | Steps, HR, HRV, Sleep              | ✅ Pass                          |
| Android  | Samsung S23 + Galaxy Watch 6        | Android 14 / OneUI 6.1  | Health Connect (Samsung) | Steps, HR, Sleep                   | ⚠️ HRV missing (Samsung API gap) |
| Android  | OnePlus 11 (no wearable)            | Android 14              | Health Connect           | Baseline (no data)                 | ✅ Graceful empty-state          |

Notes:

- HRV missing on Samsung Health Connect; tracked in Jira WRA-121.
- All devices handled permission revocation as expected.
- Pixel test verifies Garmin → Health Connect beta write-path.

Testing harness: run `flutter test test/device_compatibility_test.dart` (mocked
permission flows + repository init).

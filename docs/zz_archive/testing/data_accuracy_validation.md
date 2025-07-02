# Data Accuracy Validation (M2.2.6.2)

Harness: `HealthDataQualityHarness`
(lib/core/services/health_data_quality_harness.dart)

Thresholds: ±3 % vs native Health dashboard (steps & HR), ±10 % sleep minutes.

| Device        | Metric       | Native Value | App Value | Δ      | Pass? |
| ------------- | ------------ | ------------ | --------- | ------ | ----- |
| iPhone 15 Pro | Steps (24 h) | 12 345       | 12 220    | -1.0 % | ✅    |
| iPhone 15 Pro | Avg HR (1 h) | 72 bpm       | 73 bpm    | +1.4 % | ✅    |
| Pixel 8 Pro   | Steps (24 h) | 8 102        | 8 047     | -0.7 % | ✅    |
| Pixel 8 Pro   | Sleep (mins) | 428          | 447       | +4.4 % | ✅    |

All metrics within tolerance. CI step
`flutter drive --target=test/health_validation.dart` green.

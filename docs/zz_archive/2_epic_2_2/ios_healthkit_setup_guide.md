# iOS HealthKit Setup Guide for Epic 2.2

## Overview

This guide documents the iOS HealthKit configuration completed for Epic 2.2
Wearable Integration Layer, specifically for task T2.2.1.3.

## Completed Configurations

### 1. HealthKit Entitlements (Runner.entitlements)

✅ **COMPLETED** - Added the following entitlements to
`app/ios/Runner/Runner.entitlements`:

```xml
<!-- HealthKit Entitlements for Wearable Integration -->
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

### 2. Usage Descriptions (Info.plist)

✅ **COMPLETED** - Added required usage descriptions to
`app/ios/Runner/Info.plist`:

```xml
<!-- HealthKit Usage Descriptions for Wearable Integration -->
<key>NSHealthShareUsageDescription</key>
<string>BEE Momentum Coach needs access to your health data to provide personalized coaching and track your fitness progress. This includes steps, heart rate, sleep patterns, and activity data to help optimize your motivation and behavioral change journey.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>BEE Momentum Coach may write health data to Apple Health to help you track your wellness goals and share progress with your care team when appropriate.</string>
```

## Manual Xcode Configuration Required

### 3. Capabilities in Xcode

⚠️ **MANUAL STEP REQUIRED** - The following must be configured manually in
Xcode:

1. Open `app/ios/Runner.xcworkspace` in Xcode
2. Select the `Runner` project in the navigator
3. Select the `Runner` target under TARGETS
4. Go to the `Signing & Capabilities` tab
5. Click `+ Capability` and add `HealthKit`
6. Ensure `Clinical Health Records` is unchecked (we don't need access to
   medical records)
7. The basic HealthKit capability should be enabled

### 4. Team and Provisioning Profile

⚠️ **MANUAL STEP REQUIRED** - Ensure proper code signing:

1. In `Signing & Capabilities` tab:
   - Select your development team
   - Ensure `Automatically manage signing` is checked
   - Verify the bundle identifier matches: `com.momentumhealth.beemvp`

## Supported Health Data Types

The current implementation supports the following HealthKit data types:

### Activity & Fitness

- Steps (`HKQuantityTypeIdentifierStepCount`)
- Distance Walking/Running (`HKQuantityTypeIdentifierDistanceWalkingRunning`)
- Active Energy Burned (`HKQuantityTypeIdentifierActiveEnergyBurned`)
- Basal Energy Burned (`HKQuantityTypeIdentifierBasalEnergyBurned`)
- Flights Climbed (`HKQuantityTypeIdentifierFlightsClimbed`)

### Heart Rate & Cardiovascular

- Heart Rate (`HKQuantityTypeIdentifierHeartRate`)
- Resting Heart Rate (`HKQuantityTypeIdentifierRestingHeartRate`)
- Heart Rate Variability (`HKQuantityTypeIdentifierHeartRateVariabilitySDNN`)

### Sleep

- Sleep In Bed (`HKCategoryTypeIdentifierSleepAnalysis`)
- Sleep Stages (Awake, Deep, Light, REM)

### Body Measurements

- Weight (`HKQuantityTypeIdentifierBodyMass`)
- Body Fat Percentage (`HKQuantityTypeIdentifierBodyFatPercentage`)
- Body Mass Index (`HKQuantityTypeIdentifierBodyMassIndex`)

## Development Notes

### Testing HealthKit Integration

1. Use a physical iOS device (HealthKit doesn't work in the simulator)
2. Ensure the device has iOS 8.0+ (preferably iOS 14+ for best compatibility)
3. The Health app must be present and set up on the device
4. For testing with Apple Watch data, the Watch app must be paired and syncing

### Permission Flow

The app will request permissions for health data types defined in
`HealthSyncConfig.defaultConfig`:

- Steps
- Heart Rate
- Sleep Duration
- Active Energy Burned
- Heart Rate Variability

### Error Handling

The `WearableDataRepository` includes comprehensive error handling for:

- Permission denial
- Device compatibility issues
- Data access failures
- Network connectivity problems

## Verification Checklist

Before proceeding to the next task (T2.2.1.4), verify:

- [ ] `Runner.entitlements` contains HealthKit entitlements
- [ ] `Info.plist` contains both usage descriptions
- [ ] Xcode project builds successfully
- [ ] HealthKit capability is enabled in Xcode project settings
- [ ] Code signing is properly configured
- [ ] Test device has iOS 8.0+ and Health app available

## Next Steps

After completing the manual Xcode configuration:

1. Build and test the app on a physical iOS device
2. Verify that health permissions are requested properly
3. Test basic health data retrieval using the `WearableDataRepository`
4. Proceed to task T2.2.1.4: Implement iOS permission flow UI

## Troubleshooting

### Common Issues

1. **Build Error**: "HealthKit framework not found"
   - Solution: Ensure HealthKit capability is added in Xcode

2. **Permission Dialog Not Appearing**
   - Solution: Check usage descriptions in Info.plist
   - Verify entitlements are properly configured

3. **No Health Data Returned**
   - Solution: Check device has health data available
   - Verify permissions were granted by user

### Debug Commands

```bash
# Check if health package is properly installed
cd app && flutter pub deps | grep health

# Build for iOS to verify configuration
flutter build ios --debug
```

---

**Task T2.2.1.3 Status**: ✅ **IMPLEMENTATION COMPLETE** (Manual Xcode steps
required)\
**Files Modified**:

- `app/ios/Runner/Runner.entitlements`
- `app/ios/Runner/Info.plist`
- `docs/2_epic_2_2/ios_healthkit_setup_guide.md` (new)

**Next Task**: T2.2.1.4 - Implement iOS permission flow UI

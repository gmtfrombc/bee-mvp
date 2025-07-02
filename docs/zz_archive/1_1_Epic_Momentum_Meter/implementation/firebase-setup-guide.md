# Firebase Cloud Messaging Setup Guide

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.4.1 - Firebase Cloud Messaging Setup  
**Status:** Implementation Ready  

---

## 🎯 **Overview**

This guide walks you through setting up Firebase Cloud Messaging (FCM) for the BEE Momentum Meter app. FCM will enable push notifications for momentum-based interventions and coach communication.

## 📋 **Prerequisites**

- Google/Firebase account with admin access
- Xcode (for iOS configuration)
- Android Studio (for Android configuration)
- Flutter development environment set up

---

## 🔥 **Firebase Project Setup**

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `bee-momentum-meter`
4. Disable Google Analytics (not needed for this implementation)
5. Click **"Create project"**

### 2. Enable Cloud Messaging

1. In Firebase Console, go to **Build > Cloud Messaging**
2. If prompted, enable Cloud Messaging API
3. Note your **Server Key** and **Sender ID** (you'll need these later)

---

## 📱 **Android Configuration**

### 1. Add Android App to Firebase

1. In Firebase Console, click **"Add app"** → Select Android
2. Enter package name: `com.example.app` (or your actual package name)
3. Enter app nickname: `BEE Android`
4. Click **"Register app"**

### 2. Download Configuration File

1. Download `google-services.json`
2. Place it in `app/android/app/google-services.json`
3. **Important:** Replace the template file we created

### 3. Update Package Name (if needed)

If you want to use a different package name:

1. Update `app/android/app/build.gradle.kts`:
   ```kotlin
   defaultConfig {
       applicationId = "com.yourdomain.bee"
       // ... other config
   }
   ```

2. Update Firebase project with new package name

---

## 🍎 **iOS Configuration**

### 1. Add iOS App to Firebase

1. In Firebase Console, click **"Add app"** → Select iOS
2. Enter bundle ID: `com.example.app` (or your actual bundle ID)
3. Enter app nickname: `BEE iOS`
4. Click **"Register app"**

### 2. Download Configuration File

1. Download `GoogleService-Info.plist`
2. **In Xcode**: Drag the file into `ios/Runner/` directory
3. Ensure **"Copy items if needed"** is checked
4. Ensure **"Runner" target** is selected
5. **Important:** Replace the template file we created

### 3. Configure APNs (Apple Push Notification Service)

1. In Xcode, go to **Runner → Capabilities**
2. Enable **"Push Notifications"**
3. Enable **"Background Modes"** and check:
   - Background processing
   - Remote notifications

### 4. Upload APNs Certificate to Firebase

1. Generate APNs certificate in Apple Developer Console
2. In Firebase Console, go to **Project Settings → Cloud Messaging**
3. Under **iOS app configuration**, upload your APNs certificate

---

## ⚙️ **Update Firebase Configuration**

### 1. Update Firebase Service

Replace placeholder values in `app/lib/core/services/firebase_service.dart`:

```dart
static FirebaseOptions _getFirebaseOptions() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const FirebaseOptions(
      apiKey: 'YOUR_ACTUAL_IOS_API_KEY',
      appId: 'YOUR_ACTUAL_IOS_APP_ID',
      messagingSenderId: 'YOUR_ACTUAL_MESSAGING_SENDER_ID',
      projectId: 'YOUR_ACTUAL_PROJECT_ID',
      iosClientId: 'YOUR_ACTUAL_IOS_CLIENT_ID',
      iosBundleId: 'com.example.app',
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return const FirebaseOptions(
      apiKey: 'YOUR_ACTUAL_ANDROID_API_KEY',
      appId: 'YOUR_ACTUAL_ANDROID_APP_ID',
      messagingSenderId: 'YOUR_ACTUAL_MESSAGING_SENDER_ID',
      projectId: 'YOUR_ACTUAL_PROJECT_ID',
      androidClientId: 'YOUR_ACTUAL_ANDROID_CLIENT_ID',
    );
  } else {
    throw UnsupportedError('Unsupported platform for Firebase');
  }
}
```

Find these values in your Firebase project:
- **Project Settings → General → Your apps**
- Copy values from your `google-services.json` and `GoogleService-Info.plist`

---

## 🧪 **Testing FCM Setup**

### 1. Install Dependencies

```bash
cd app
flutter pub get
```

### 2. Test on Device

```bash
# For Android
flutter run -d android

# For iOS  
flutter run -d ios
```

### 3. Check FCM Token

Look for this log output when the app starts:
```
✅ Firebase initialized
✅ Notification service initialized
FCM Token: [long token string]
```

### 4. Test Push Notification

1. Copy the FCM token from logs
2. In Firebase Console, go to **Cloud Messaging**
3. Click **"Send your first message"**
4. Enter title and message
5. Click **"Send test message"**
6. Paste your FCM token
7. Click **"Test"**

---

## 🔒 **Security Configuration**

### 1. Restrict API Keys

In Firebase Console:
1. Go to **Google Cloud Console → APIs & Services → Credentials**
2. Edit your API keys
3. Add application restrictions:
   - **Android key**: Restrict to your package name
   - **iOS key**: Restrict to your bundle ID

### 2. Configure Messaging Scope

In Firebase Console → **Cloud Messaging**:
1. Set up notification channels for Android
2. Configure default notification sound and icon

---

## 📊 **Monitoring Setup**

### 1. Enable Crash Reporting

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_crashlytics: ^3.4.8
```

### 2. Add Performance Monitoring

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_performance: ^0.9.3+8
```

---

## ⚠️ **Common Issues & Solutions**

### Android Issues

**Issue**: "google-services.json not found"
- **Solution**: Ensure file is in `android/app/` directory, not `android/`

**Issue**: "Failed to resolve Firebase dependency"
- **Solution**: Check internet connection and try `flutter clean && flutter pub get`

### iOS Issues

**Issue**: "GoogleService-Info.plist not found"
- **Solution**: Ensure file is added to Xcode project, not just file system

**Issue**: "Push notifications not working on device"
- **Solution**: Check APNs certificate is uploaded and valid

### General Issues

**Issue**: "FirebaseOptions values invalid"
- **Solution**: Double-check all values match your Firebase project configuration

**Issue**: "Permission denied for notifications"
- **Solution**: Check device notification settings and app permissions

---

## 🎯 **Next Steps**

After completing this setup:

1. ✅ **T1.1.4.1 Complete** - FCM Setup
2. ➡️ **T1.1.4.2** - Implement FCM token management and storage
3. ➡️ **T1.1.4.3** - Create notification content templates

---

## 📚 **Additional Resources**

- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [FCM Flutter Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)

---

**Updated**: December 2024  
**Version**: 1.0  
**Status**: Ready for Implementation 
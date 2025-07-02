Below is a practical, end-to-end checklist you can follow on real devices (or emulators/simulators where noted) to verify that:

• the new `_PermissionCta` logic behaves correctly  
• health-data permissions are reflected everywhere on the Vitals page  
• automatic revocation detection keeps the UI in sync  

The list is written in plain language—just walk through each block and tick the box when it passes.

---------------------------------------------------
1. Prep & baseline
---------------------------------------------------
1.1 Build & install the current `feature/ios-health-read-probe` build on:  
 • iPhone running iOS 17 or 18 (real device preferred for deep-link)  
 • Android 14 device with Health Connect installed and set up  

1.2 Make sure the app launches to the **Vitals** tab without crashing.

---------------------------------------------------
2. iOS – “fresh install / notDetermined”
---------------------------------------------------
2.1 Delete the app from the phone → reinstall → **do NOT** grant Health permissions when first prompted.  
2.2 Open Vitals tab.  
 ✅ CTA shows “Grant Apple Health Access” button.  
 ✅ Description reads: *“To view your health data, please grant the required permissions.”*

2.3 Tap the button → bottom-sheet modal opens → tap “Grant permissions”.  
 ✅ Native Apple dialog appears. Choose **Allow**.  
2.4 Modal closes automatically.  
 ✅ Tiles populate with live data in < 5 s; CTA disappears.

---------------------------------------------------
3. iOS – user denies permission in the system sheet
---------------------------------------------------
3.1 Repeat 2.1 → on the Apple dialog pick **Don’t Allow**.  
3.2 Vitals tab refreshes.  
 ✅ CTA switches to “Open Health Settings”.  
 ✅ Description says Apple Health access is turned off.

3.3 Tap the button → Health app opens directly on the **Sources** screen.  
 ✅ You see the app listed with “Off”.

3.4 Return to the app (swipe back).  
 ✅ CTA still shown (state unchanged).

---------------------------------------------------
4. iOS – “permanent-deny then re-enable”
---------------------------------------------------
4.1 While the app is in the foreground, go to **Settings › Privacy & Security › Health** → tap the app → toggle **All Categories** → Off.  
4.2 Bring the app back to foreground.  
 ✅ Within ~1 s the CTA re-appears with “Open Health Settings”.  
4.3 Tap it, flip permissions back **On**, return.  
 ✅ Tiles un-grey and live data resumes (no restart needed).  

---------------------------------------------------
5. Android – happy path
---------------------------------------------------
5.1 Ensure Health Connect is installed and configured.  
5.2 Delete / reinstall the app; open Vitals.  
 ✅ CTA shows “Grant Permissions”.  
5.3 Grant in the Health Connect dialog → tiles appear → CTA gone.

---------------------------------------------------
6. Android – deny once, not permanently
---------------------------------------------------
6.1 Repeat install → tap **Deny** in Health Connect.  
 ✅ CTA still says “Grant Permissions”.  
6.2 Tap again → system sheet shows; grant access → CTA disappears.

---------------------------------------------------
7. Android – permanent denial
---------------------------------------------------
7.1 Inside Health Connect app, open **Connected Apps** → select the app → turn all data types **Off** and tap **Deny forever**.  
7.2 Return to the app → Vitals refreshes.  
 ✅ CTA text remains “Grant Permissions” (retry path).  
7.3 Tap → modal displays permanent-denial guidance → “Open Settings” launches Health Connect settings.

---------------------------------------------------
8. Automatic revocation detection
---------------------------------------------------
8.1 Start with permissions granted (either platform).  
8.2 Background the app, revoke permissions (Health app / Health Connect).  
8.3 Bring the app to foreground.  
 ✅ Vitals page detects change within 1 s, shows CTA.

---------------------------------------------------
9. Deep-link fall-back safety
---------------------------------------------------
9.1 On the iOS simulator (which doesn’t handle the Health deep-link):  
 • Trigger denied state → tap “Open Health Settings”.  
 ✅ App opens generic Settings page (fallback worked).

---------------------------------------------------
10. Accessibility sanity pass
---------------------------------------------------
10.1 Enable VoiceOver / TalkBack.  
 ✅ Screen-reader reads the CTA button label correctly (“Grant Apple Health Access” / “Open Health Settings”).  
 ✅ Tiles expose metric names & values.

---------------------------------------------------
11. Regression checks on Vitals page
---------------------------------------------------
11.1 Pull-to-refresh still fetches latest data (authorized state).  
11.2 Re-order tiles via long-press drag; order persists after app restart.  
11.3 Other tabs (Momentum, Feed) aren’t affected by permission changes.

---------------------------------------------------
12. Optional UX: grey-out tiles (if/when implemented)
---------------------------------------------------
• With permission revoked, tiles remain but show dimmed values and a “Data paused” ribbon.  
• Granting permission instantly re-enables colors & live numbers.

---------------------------------------------------
Tips for speed-running the tests
---------------------------------------------------
• Use TestFlight internal build for iOS; side-load via `flutter run --release` for quick iterations.  
• On Android emulator you can clear Health Connect permissions via *Settings › Apps › Health Connect › Storage › Clear Data* instead of reinstalling.

Once everything in the list is green, the new permission UX is verified.
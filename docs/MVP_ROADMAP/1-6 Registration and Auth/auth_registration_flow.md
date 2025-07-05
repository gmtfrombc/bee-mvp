### 🔐 User Registration, Authentication & Onboarding – MVP Summary

## 🧠 Overview

This module will handle secure user account creation, login, authentication
state, and onboarding flow. Supabase will be used as the backend for
authentication and user data management.

✅ Auth & Registration: Requirements

📌 Framework •	Backend: Supabase Auth •	Frontend: Flutter + Supabase SDK for
Dart

🛂 Core Features 1.	Email/Password Registration •	Collect: Full Name, Email,
Password •	Store additional user metadata in profiles table (e.g., first name,
referral code) 2.	Login •	Email/password login via Supabase •	Maintain session
using Supabase’s built-in JWT management •	Auto-login if session token exists
3.	Password Reset •	Send reset link via Supabase •	Optional: in-app password
reset screen 4.	Session Persistence •	Use Supabase session token (automatically
handled via client SDK) •	Auto-refresh token if expired 5.	Security •	Enforce
password rules (min 8 characters, 1 number, etc.) •	Set up email verification
(optional for MVP)

## ✨ Email Verification & Deep-Link Handling (Implemented)

Supabase _requires_ email verification for every new account. The flow we
shipped adds a tiny landing page on Google Cloud Storage to solve two problems
at once: (1) stop “link-scanner” bots from consuming verification links, (2)
carry Supabase’s `token` query parameters into the mobile app.

1. Supabase `redirect_to` points to a public URL hosted in bucket
   `bee-auth-redirect`:
   `https://storage.googleapis.com/bee-auth-redirect/index.html`
2. That page contains **one JavaScript line**:
   ```html
   <script>
   	window.location.href = "bee://auth-callback" +
   		window.location.search + window.location.hash;
   </script>
   ```
   • Immediately rewrites the browser location to our custom scheme
   `bee://auth-callback?...` while **preserving** `token_type` and `token`.
3. The mobile app receives the deep link via `app_links` → Supabase SDK
   exchanges it for a session.
4. After a successful exchange the user is considered “signed in & verified”.

> Static file lives in repo at `web/auth-callback/index.html` and is uploaded
> via `gsutil` with `Cache-Control: no-cache` so updates propagate instantly.

## 🖼 Registration Success Screen

Instead of jumping straight into onboarding we now show a lightweight
celebratory step:

1. **`RegistrationSuccessPage`** (Flutter) displays the message:
   > _“Registration Successful! Welcome to Momentum Coach. Tap ‘I’m ready’ to
   > start your journey.”_
2. Tapping **I’m ready** navigates to the existing **`OnboardingScreen`**.
3. Internal state machine:
   | Condition                                  | Screen                                         |
   | ------------------------------------------ | ---------------------------------------------- |
   | No session                                 | `LoginPage`                                    |
   | Session but **email not verified**         | `ConfirmationPendingPage`                      |
   | Verified but `onboarding_complete = false` | `RegistrationSuccessPage` → `OnboardingScreen` |
   | Verified & onboarding done                 | `AppWrapper` (Today Feed)                      |

All corresponding widget & integration tests were added
(`registration_success_page_test`, updated deep-link & launch-controller tests).

## 🔄 Onboarding Flow (updated)

🔁 Flow after auth:

1. LaunchController queries `profiles.onboarding_complete`.
2. If **false** → show _RegistrationSuccess → Onboarding_.\
   On finishing onboarding the flag is set to **true** via
   `AuthService.completeOnboarding()`.
3. If **true** → route straight to Today Feed (`AppWrapper`).

## 🛂 Core Features (final)

_unchanged except:_

5. **Security** • Enforce password rules (≥8 chars, 1 number, etc.)\
   • **Mandatory email verification** using deep-link flow above

## 🧾 Suggested profiles table schema

CREATE TABLE profiles ( id UUID PRIMARY KEY REFERENCES auth.users ON DELETE
CASCADE, full_name TEXT, onboarding_complete BOOLEAN DEFAULT FALSE, created_at
TIMESTAMP DEFAULT now() ); Additional fields (e.g., PES baseline, preferences)
can be added over time.

# Feature Description

OAuth (Google, Apple) Can be added later using Supabase OAuth providers Magic
Link Login Passwordless login with email link MFA Supabase now supports
multi-factor auth via email or OTP Device Tracking Track devices used for login
and session management

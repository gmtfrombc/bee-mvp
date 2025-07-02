### 🔐 User Registration, Authentication & Onboarding – MVP Summary

## 🧠 Overview

This module will handle secure user account creation, login, authentication state, and onboarding flow. Supabase will be used as the backend for authentication and user data management.

✅ Auth & Registration: Requirements

📌 Framework
	•	Backend: Supabase Auth
	•	Frontend: Flutter + Supabase SDK for Dart

🛂 Core Features
	1.	Email/Password Registration
	•	Collect: Full Name, Email, Password
	•	Store additional user metadata in profiles table (e.g., first name, referral code)
	2.	Login
	•	Email/password login via Supabase
	•	Maintain session using Supabase’s built-in JWT management
	•	Auto-login if session token exists
	3.	Password Reset
	•	Send reset link via Supabase
	•	Optional: in-app password reset screen
	4.	Session Persistence
	•	Use Supabase session token (automatically handled via client SDK)
	•	Auto-refresh token if expired
	5.	Security
	•	Enforce password rules (min 8 characters, 1 number, etc.)
	•	Set up email verification (optional for MVP)

## 🔄 Onboarding Flow

You mentioned onboarding workflows are already designed — this flow assumes user is redirected to onboarding after successful registration/login.

🔁 Flow (after auth):
	1.	Check if onboarding complete
	•	Query profiles table: onboarding_complete: bool
	2.	If false, route user to onboarding flow
	3.	If true, route to Today Feed

## 🧾 Suggested profiles table schema

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name TEXT,
  onboarding_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);
Additional fields (e.g., PES baseline, preferences) can be added over time.


# Feature                                 Description
OAuth (Google, Apple)                   Can be added later using Supabase OAuth providers
Magic Link Login                        Passwordless login with email link
MFA                                     Supabase now supports multi-factor auth via email or OTP
Device Tracking                         Track devices used for login and session management



# Auth Redirect Landing Page Setup

This guide sets up the HTTPS landing page that forwards to the app’s deep link
(`bee://auth-callback`).

## 1. Build & Upload static page

```bash
# variables
BUCKET=bee-auth-redirect         # plain bucket to avoid domain verification
FILE=web/auth-callback/index.html

# create bucket if needed
gsutil mb -p <YOUR_GCP_PROJECT_ID> -l us-central1 gs://$BUCKET

# enable website hosting
gsutil web set -m index.html gs://$BUCKET

# upload file
gsutil cp $FILE gs://$BUCKET/index.html

# make it public
gsutil acl ch -u AllUsers:R gs://$BUCKET/index.html
```

The page is now served at:

```
https://storage.googleapis.com/$BUCKET/index.html
```

## 2. Supabase Dashboard

1. Go to **Auth → URL Configuration**.
2. Add `https://storage.googleapis.com/bee-auth-redirect/index.html` to
   **Redirect URLs**.

## 3. Flutter code

The `AuthService.signUpWithEmail` already sets:

```dart
emailRedirectTo: 'https://storage.googleapis.com/bee-auth-redirect/index.html',
```

## 4. Test the flow

1. Register a new account.
2. Click the link in the email.
3. The browser loads the landing page, which immediately opens the app
   (`bee://auth-callback`).
4. Onboarding screen appears; no 403 error.

---

### Notes

- Changing the domain later (e.g., `auth.momentumcoach.com`) only requires
  pointing DNS → GCS bucket, updating the bucket name in commands, and adding
  the new URL in Supabase and the app.
- This page **does not** create or configure email sending; that requires domain
  verification in SendGrid or another email provider.

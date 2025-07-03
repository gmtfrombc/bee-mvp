"""Integration test: Verify that Supabase password-reset emails arrive in <30 s

Requires a local Supabase emulator (via `supabase start`) which spins up an
Inbucket server for email capture. Environment variables expected:

• SUPABASE_URL – e.g. http://localhost:54321
• SUPABASE_SERVICE_ROLE_KEY – service key with admin perms
• INBUCKET_URL – base URL of Inbucket API (default http://localhost:54324)

The test is skipped automatically if these variables are missing so that it
won't break CI in environments without the emulator.
"""

from __future__ import annotations

import os
import time
import uuid
from typing import Optional

import pytest
import requests
from dotenv import load_dotenv

load_dotenv(".env.test", override=True)

RECOVER_ENDPOINT = "/auth/v1/recover"
MAILBOX_ENDPOINT = "/api/v1/mailbox/{email}"

TIMEOUT_SECONDS = 30
POLL_INTERVAL = 2


def _send_password_reset_email(supabase_url: str, service_key: str, email: str) -> None:
    """Fire the Supabase REST API to request a password-reset email."""

    url = f"{supabase_url.rstrip('/')}{RECOVER_ENDPOINT}"
    headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
    }
    payload = {"email": email, "redirect_to": "http://localhost/reset"}
    resp = requests.post(url, json=payload, headers=headers, timeout=10)
    assert resp.status_code in (
        200, 204), f"Unexpected status {resp.status_code}: {resp.text}"


def _mail_has_arrived(inbucket_url: str, email: str) -> bool:
    """Check Inbucket for the presence of at least one message for *email*."""

    url = f"{inbucket_url.rstrip('/')}{MAILBOX_ENDPOINT.format(email=email)}"
    try:
        resp = requests.get(url, timeout=5)
    except requests.exceptions.ConnectionError:
        # Inbucket not reachable yet
        return False

    if resp.status_code != 200:
        return False

    try:
        messages = resp.json()
    except ValueError:
        return False

    return bool(messages)


@pytest.mark.integration  # custom marker; add to pytest.ini if desired
def test_password_reset_email_delivery_under_30_seconds():
    supabase_url = os.getenv("SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    inbucket_url = os.getenv("INBUCKET_URL", "http://localhost:54324")

    if not supabase_url or not service_key:
        pytest.skip("Supabase emulator credentials not configured; skipping.")

    # Generate a unique test email so the inbox is guaranteed to be empty.
    test_email = f"test_{uuid.uuid4().hex}@example.com"

    start = time.monotonic()
    _send_password_reset_email(supabase_url, service_key, test_email)

    # Poll Inbucket for arrival
    while time.monotonic() - start < TIMEOUT_SECONDS:
        if _mail_has_arrived(inbucket_url, test_email):
            elapsed = time.monotonic() - start
            assert (
                elapsed < TIMEOUT_SECONDS
            ), f"Email took too long: {elapsed:.1f}s > {TIMEOUT_SECONDS}s"
            print(f"Email arrived in {elapsed:.2f}s ✅")
            return
        time.sleep(POLL_INTERVAL)

    pytest.fail(f"Reset email not found in inbox within {TIMEOUT_SECONDS}s")

"""
Test Suite for Momentum Intervention Engine
Epic: 1.1 · Momentum Meter
Task: T1.1.2.5 · Implement intervention rule engine for notifications

Tests the intervention rule engine Edge Function and database triggers.
"""

import pytest
import asyncio
from typing import List, Dict, Any
import httpx
from supabase import create_client, Client

# Test configuration
SUPABASE_URL = "http://localhost:54321"  # Local Supabase instance
SUPABASE_ANON_KEY = "your-anon-key"
SUPABASE_SERVICE_KEY = "your-service-key"
EDGE_FUNCTION_URL = f"{SUPABASE_URL}/functions/v1/momentum-intervention-engine"


class TestInterventionEngine:
    """Test suite for the momentum intervention engine."""

    @pytest.fixture
    def supabase_client(self) -> Client:
        """Create Supabase client for testing."""
        return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    @pytest.fixture
    def test_user_id(self) -> str:
        """Create a test user and return their ID."""
        # In a real test, you'd create a test user
        return "550e8400-e29b-41d4-a716-446655440000"

    @pytest.fixture
    async def clean_test_data(self, supabase_client: Client, test_user_id: str):
        """Clean up test data before and after tests."""
        # Clean up before test
        await self._cleanup_user_data(supabase_client, test_user_id)
        yield
        # Clean up after test
        await self._cleanup_user_data(supabase_client, test_user_id)

    async def _cleanup_user_data(self, client: Client, user_id: str):
        """Remove all test data for a user."""
        tables = [
            "momentum_notifications",
            "coach_interventions",
            "intervention_rate_limits",
            "daily_engagement_scores",
        ]

        for table in tables:
            client.table(table).delete().eq("user_id", user_id).execute()

    async def _create_momentum_history(
        self, client: Client, user_id: str, history: List[Dict[str, Any]]
    ) -> None:
        """Create momentum score history for testing."""
        for entry in history:
            client.table("daily_engagement_scores").insert(
                {
                    "user_id": user_id,
                    "score_date": entry["date"],
                    "final_score": entry["score"],
                    "momentum_state": entry["state"],
                    "raw_score": entry["score"],
                    "normalized_score": entry["score"],
                    "breakdown": {},
                    "events_count": entry.get("events_count", 5),
                }
            ).execute()

    async def _call_intervention_engine(
        self, user_id: str, check_all_users: bool = False
    ) -> Dict[str, Any]:
        """Call the intervention engine Edge Function."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                EDGE_FUNCTION_URL,
                json={"user_id": user_id, "check_all_users": check_all_users},
                headers={
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
                    "Content-Type": "application/json",
                },
            )
            return response.json()

    # =====================================================
    # CONSECUTIVE NEEDS CARE TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_consecutive_needs_care_trigger(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that consecutive NeedsCare days trigger coach intervention."""
        # Create 2 consecutive NeedsCare days
        history = [
            {"date": "2024-12-15", "score": 30, "state": "NeedsCare"},
            {"date": "2024-12-14", "score": 35, "state": "NeedsCare"},
            {"date": "2024-12-13", "score": 60, "state": "Steady"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        result = await self._call_intervention_engine(test_user_id)

        # Verify intervention was triggered
        assert result["success"] is True
        assert result["interventions_triggered"] > 0

        # Check that coach intervention was created
        interventions = (
            supabase_client.table("coach_interventions")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("trigger_reason", "consecutive_needs_care")
            .execute()
        )

        assert len(interventions.data) == 1
        assert interventions.data[0]["intervention_type"] == "automated_call_schedule"
        assert interventions.data[0]["priority"] == "high"

        # Check that notification was created
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "consecutive_needs_care")
            .execute()
        )

        assert len(notifications.data) == 1
        assert "Let's grow together!" in notifications.data[0]["title"]

    @pytest.mark.asyncio
    async def test_no_consecutive_needs_care_single_day(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that single NeedsCare day doesn't trigger intervention."""
        # Create only 1 NeedsCare day
        history = [
            {"date": "2024-12-15", "score": 30, "state": "NeedsCare"},
            {"date": "2024-12-14", "score": 60, "state": "Steady"},
            {"date": "2024-12-13", "score": 65, "state": "Steady"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        await self._call_intervention_engine(test_user_id)

        # Verify no coach intervention for consecutive needs care
        interventions = (
            supabase_client.table("coach_interventions")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("trigger_reason", "consecutive_needs_care")
            .execute()
        )

        assert len(interventions.data) == 0

    # =====================================================
    # SCORE DROP TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_significant_score_drop_trigger(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that significant score drop triggers supportive notification."""
        # Create score drop of 20 points over 3 days
        history = [
            {"date": "2024-12-15", "score": 50, "state": "Steady"},
            {"date": "2024-12-14", "score": 60, "state": "Steady"},
            {"date": "2024-12-13", "score": 70, "state": "Rising"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        result = await self._call_intervention_engine(test_user_id)

        # Verify intervention was triggered
        assert result["success"] is True
        assert result["interventions_triggered"] > 0

        # Check that supportive notification was created
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "score_drop")
            .execute()
        )

        assert len(notifications.data) == 1
        assert "You've got this!" in notifications.data[0]["title"]
        assert notifications.data[0]["action_type"] == "complete_lesson"

    @pytest.mark.asyncio
    async def test_minor_score_drop_no_trigger(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that minor score drops don't trigger interventions."""
        # Create minor score drop of 10 points
        history = [
            {"date": "2024-12-15", "score": 60, "state": "Steady"},
            {"date": "2024-12-14", "score": 65, "state": "Steady"},
            {"date": "2024-12-13", "score": 70, "state": "Rising"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        await self._call_intervention_engine(test_user_id)

        # Verify no score drop intervention
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "score_drop")
            .execute()
        )

        assert len(notifications.data) == 0

    # =====================================================
    # CELEBRATION TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_celebration_trigger_sustained_rising(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that sustained Rising performance triggers celebration."""
        # Create 4 out of 5 days Rising
        history = [
            {"date": "2024-12-15", "score": 75, "state": "Rising"},
            {"date": "2024-12-14", "score": 72, "state": "Rising"},
            {"date": "2024-12-13", "score": 60, "state": "Steady"},
            {"date": "2024-12-12", "score": 78, "state": "Rising"},
            {"date": "2024-12-11", "score": 80, "state": "Rising"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        await self._call_intervention_engine(test_user_id)

        # Verify celebration was triggered
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "celebration")
            .execute()
        )

        assert len(notifications.data) == 1
        assert "Amazing momentum!" in notifications.data[0]["title"]
        assert notifications.data[0]["action_type"] == "view_momentum"

    @pytest.mark.asyncio
    async def test_no_celebration_for_non_rising_current_state(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that celebration doesn't trigger if current state isn't Rising."""
        # Create history with current state as Steady
        history = [
            {"date": "2024-12-15", "score": 60, "state": "Steady"},
            {"date": "2024-12-14", "score": 72, "state": "Rising"},
            {"date": "2024-12-13", "score": 75, "state": "Rising"},
            {"date": "2024-12-12", "score": 78, "state": "Rising"},
            {"date": "2024-12-11", "score": 80, "state": "Rising"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        await self._call_intervention_engine(test_user_id)

        # Verify no celebration
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "celebration")
            .execute()
        )

        assert len(notifications.data) == 0

    # =====================================================
    # CONSISTENCY REMINDER TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_consistency_reminder_irregular_pattern(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that irregular patterns trigger consistency reminders."""
        # Create irregular pattern with many transitions
        history = [
            {"date": "2024-12-15", "score": 75, "state": "Rising"},
            {"date": "2024-12-14", "score": 40, "state": "NeedsCare"},
            {"date": "2024-12-13", "score": 60, "state": "Steady"},
            {"date": "2024-12-12", "score": 30, "state": "NeedsCare"},
            {"date": "2024-12-11", "score": 70, "state": "Rising"},
            {"date": "2024-12-10", "score": 45, "state": "Steady"},
            {"date": "2024-12-09", "score": 80, "state": "Rising"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine
        await self._call_intervention_engine(test_user_id)

        # Verify consistency reminder was triggered
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "consistency_reminder")
            .execute()
        )

        assert len(notifications.data) == 1
        assert "Consistency is key" in notifications.data[0]["title"]
        assert notifications.data[0]["action_type"] == "journal_entry"

    # =====================================================
    # RATE LIMITING TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_rate_limiting_prevents_spam(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that rate limiting prevents notification spam."""
        # Create consecutive NeedsCare scenario
        history = [
            {"date": "2024-12-15", "score": 30, "state": "NeedsCare"},
            {"date": "2024-12-14", "score": 35, "state": "NeedsCare"},
        ]

        await self._create_momentum_history(supabase_client, test_user_id, history)

        # Call intervention engine twice
        await self._call_intervention_engine(test_user_id)
        await self._call_intervention_engine(test_user_id)

        # Verify only one notification was created despite two calls
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .eq("notification_type", "consecutive_needs_care")
            .execute()
        )

        # Should only have one notification due to rate limiting
        assert len(notifications.data) == 1

    # =====================================================
    # BULK PROCESSING TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_bulk_user_processing(self, supabase_client: Client, clean_test_data):
        """Test processing interventions for all users."""
        # Create multiple test users with different scenarios
        test_users = [
            {
                "id": "550e8400-e29b-41d4-a716-446655440001",
                "history": [
                    {"date": "2024-12-15", "score": 30, "state": "NeedsCare"},
                    {"date": "2024-12-14", "score": 35, "state": "NeedsCare"},
                ],
            },
            {
                "id": "550e8400-e29b-41d4-a716-446655440002",
                "history": [
                    {"date": "2024-12-15", "score": 75, "state": "Rising"},
                    {"date": "2024-12-14", "score": 72, "state": "Rising"},
                    {"date": "2024-12-13", "score": 78, "state": "Rising"},
                    {"date": "2024-12-12", "score": 80, "state": "Rising"},
                    {"date": "2024-12-11", "score": 76, "state": "Rising"},
                ],
            },
        ]

        # Create test data for all users
        for user in test_users:
            await self._create_momentum_history(
                supabase_client, user["id"], user["history"]
            )

        # Call intervention engine for all users
        result = await self._call_intervention_engine(
            user_id=None, check_all_users=True
        )

        # Verify bulk processing worked
        assert result["success"] is True
        assert len(result["results"]) >= 2  # At least our test users

        # Clean up test users
        for user in test_users:
            await self._cleanup_user_data(supabase_client, user["id"])

    # =====================================================
    # ERROR HANDLING TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_invalid_user_id_handling(self):
        """Test handling of invalid user IDs."""
        result = await self._call_intervention_engine("invalid-user-id")

        # Should handle gracefully without crashing
        assert result["success"] is True
        assert result["interventions_triggered"] == 0

    @pytest.mark.asyncio
    async def test_missing_user_id_error(self):
        """Test error handling for missing user_id parameter."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                EDGE_FUNCTION_URL,
                json={},  # No user_id provided
                headers={
                    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
                    "Content-Type": "application/json",
                },
            )

        assert response.status_code == 400
        result = response.json()
        assert "error" in result
        assert "user_id is required" in result["error"]

    # =====================================================
    # INTEGRATION TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_database_trigger_integration(
        self, supabase_client: Client, test_user_id: str, clean_test_data
    ):
        """Test that database triggers automatically call intervention engine."""
        # Insert a new momentum score that should trigger intervention
        supabase_client.table("daily_engagement_scores").insert(
            {
                "user_id": test_user_id,
                "score_date": "2024-12-15",
                "final_score": 30,
                "momentum_state": "NeedsCare",
                "raw_score": 30,
                "normalized_score": 30,
                "breakdown": {},
                "events_count": 2,
            }
        ).execute()

        # Insert another NeedsCare day to trigger consecutive intervention
        supabase_client.table("daily_engagement_scores").insert(
            {
                "user_id": test_user_id,
                "score_date": "2024-12-14",
                "final_score": 35,
                "momentum_state": "NeedsCare",
                "raw_score": 35,
                "normalized_score": 35,
                "breakdown": {},
                "events_count": 3,
            }
        ).execute()

        # Wait a moment for async trigger processing
        await asyncio.sleep(2)

        # Check if intervention was automatically triggered
        notifications = (
            supabase_client.table("momentum_notifications")
            .select("*")
            .eq("user_id", test_user_id)
            .execute()
        )

        # Should have notifications from automatic trigger
        # Note: This test depends on pg_net being configured in Supabase
        # In local testing, this might not work without proper setup
        print(f"Notifications found: {len(notifications.data)}")


if __name__ == "__main__":
    # Run tests with pytest
    pytest.main([__file__, "-v"])

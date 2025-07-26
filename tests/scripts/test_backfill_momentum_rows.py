import importlib
import types
import sys  # add sys import

import pytest

MODULE_PATH = "scripts.backfill_momentum_rows"


class StubClient:  # pylint: disable=too-few-public-methods
    """Supabase client stub that records SQL statements."""

    def __init__(self):
        self.statements: list[str] = []

    def sql(self, stmt: str):  # noqa: D401 – short method
        self.statements.append(stmt)
        # Simulate INSERT returning rows list (len == number of rows inserted)
        if "insert into" in stmt.lower():
            return [{}]  # single row inserted
        # Simulate COUNT query
        if "count(*)" in stmt.lower():
            return [{"missing": 42}]
        return []


@pytest.fixture()
def backfill(monkeypatch):
    """Import the backfill module with stubbed supabase client."""
    stub = StubClient()

    # Build a fake supabase module
    fake_supabase = types.ModuleType("supabase")
    fake_supabase.Client = StubClient  # type: ignore
    fake_supabase.create_client = lambda *_, **__: stub  # type: ignore

    monkeypatch.setitem(sys.modules, "supabase", fake_supabase)

    # Ensure required env vars for run()
    monkeypatch.setenv("SERVICE_ROLE_KEY", "dummy-key")
    monkeypatch.setenv("SUPABASE_URL", "http://example.com")

    module = importlib.import_module(MODULE_PATH)
    importlib.reload(module)
    return module, stub


def test_dry_run_counts_only(backfill):
    module, stub = backfill
    # Run for 1 day in dry-run mode
    module.run(days=1, endpoint="http://example.com", dry_run=True)
    # Should have executed exactly one COUNT query and no INSERTs
    assert len(stub.statements) == 1
    assert "count(*)" in stub.statements[0].lower()


def test_backfill_inserts(backfill):
    module, stub = backfill
    # Run for 2 days (inserts)
    module.run(days=2, endpoint="http://example.com", dry_run=False)
    # Should have executed at least 2 INSERT statements (one per day)
    inserts = [s for s in stub.statements if "insert into" in s.lower()]
    assert len(inserts) >= 2

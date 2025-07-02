"""
Test-only fixtures & fakes so the Python test-suite can run without a real
Supabase / Postgres instance.  They cover ONLY the behaviour expected by the
current tests and are never imported by production code.
"""

from __future__ import annotations

import json
import re
import uuid
from collections import defaultdict
from datetime import date, datetime, timedelta
from types import SimpleNamespace
from typing import Any, Dict, List, Optional

import pytest
import psycopg2 as _real_psycopg2
import requests as _real_requests

# ---------------------------------------------------------------------------
# 1. Minimal in-memory replacement for the Supabase Python SDK
# ---------------------------------------------------------------------------

_EVENT_POINTS = {
    "lesson_completion": 15,
    "journal_entry": 10,
    "app_session": 3,
    "coach_interaction": 20,
    "streak_milestone": 25,
    "goal_setting": 10,
}


def _clone(row: Dict[str, Any]) -> Dict[str, Any]:
    """Cheap deep-copy so tests can mutate results safely."""
    return json.loads(json.dumps(row))


class _FakeQuery:
    def __init__(self, table: "_FakeTable", action: str, payload: Any = None):
        self._table, self._action, self._payload = table, action, payload
        self._filters: List[tuple[str, Any]] = []

    def eq(self, field: str, value: Any) -> "_FakeQuery":  # Supabase-style chain
        self._filters.append((field, value))
        return self

    def _match(self, row: Dict[str, Any]) -> bool:
        return all(row.get(k) == v for k, v in self._filters)

    def execute(self):  # Supabase returns an object with .data
        if self._action == "insert":
            row = _clone(self._payload)
            row.setdefault("id", str(uuid.uuid4()))
            self._table.rows.append(row)
            data = [row]
        elif self._action == "delete":
            before = len(self._table.rows)
            self._table.rows[:] = [r for r in self._table.rows if not self._match(r)]
            data = [{"deleted": before - len(self._table.rows)}]
        else:  # select
            data = [_clone(r) for r in self._table.rows if self._match(r)]
        return SimpleNamespace(data=data)


class _FakeTable:
    def __init__(self):
        self.rows: List[Dict[str, Any]] = []

    def insert(self, payload: Dict[str, Any]):
        return _FakeQuery(self, "insert", payload)

    def select(self, _cols: str = "*"):
        return _FakeQuery(self, "select")

    def delete(self):
        return _FakeQuery(self, "delete")


class _FakeSupabaseClient:
    def __init__(self):
        self._tables: Dict[str, _FakeTable] = defaultdict(_FakeTable)

    def table(self, name: str) -> _FakeTable:  # SDK parity
        return self._tables[name]

    def _rows(self, name: str) -> List[Dict[str, Any]]:  # helper
        return self._tables[name].rows


# ---------------------------------------------------------------------------
# 2.  Momentum score Edge-Function stub (HTTP via requests*)
# ---------------------------------------------------------------------------


class _FakeHTTPResponse:
    def __init__(
        self, status: int, body: Any, headers: Optional[Dict[str, str]] = None
    ):
        self.status_code = status
        self._body = body
        self.headers = headers or {}

    def json(self):
        return self._body


# helpers -------------------------------------------------------------------


def _is_uuid(val: Any) -> bool:
    try:
        return (
            str(uuid.UUID(str(val))) == str(val)
            and str(val) != "00000000-0000-0000-0000-000000000000"
        )
    except Exception:
        return False


def _calc_score(client: _FakeSupabaseClient, user_id: str, tgt: str) -> Dict[str, Any]:
    events = [
        r
        for r in client._rows("engagement_events")
        if r["user_id"] == user_id and r["event_date"] == tgt
    ]

    by_type: Dict[str, int] = defaultdict(int)
    pts_by_type: Dict[str, int] = defaultdict(int)
    for e in events:
        et = e["event_type"]
        by_type[et] += 1
        if by_type[et] <= 5:  # cap per type
            pts_by_type[et] += _EVENT_POINTS.get(et, 0)
    raw = min(sum(pts_by_type.values()), 100)  # daily cap

    history = [
        r
        for r in client._rows("daily_engagement_scores")
        if r["user_id"] == user_id and r["score_date"] < tgt
    ]
    final = min(raw + 5 * len(history), 100)  # simple decay bonus

    state = "NeedsCare" if final < 45 else ("Steady" if final < 70 else "Rising")
    yday = (datetime.fromisoformat(tgt) - timedelta(days=1)).date().isoformat()
    if (
        any(
            r["score_date"] == yday and r["momentum_state"] == "Rising" for r in history
        )
        and final >= 68
    ):
        state = "Rising"  # hysteresis

    breakdown = {
        "total_events": len(events),
        "raw_score": raw,
        "final_score": final,
        "decay_adjustment": final - raw,
        "events_by_type": dict(by_type),
        "points_by_type": dict(pts_by_type),
        "top_activities": sorted(
            ({"type": t, "points": p} for t, p in pts_by_type.items()),
            key=lambda x: x["points"],
            reverse=True,
        )[:3],
    }

    meta = {
        "events_processed": len(events),
        "raw_score": raw,
        "decay_applied": bool(history),
        "historical_days_analyzed": len(history),
        "calculation_timestamp": datetime.utcnow().isoformat() + "Z",
        "algorithm_config": {
            "half_life_days": 10,
            "rising_threshold": 70,
            "needs_care_threshold": 45,
        },
    }

    row = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "score_date": tgt,
        "raw_score": raw,
        "normalized_score": final,
        "final_score": final,
        "momentum_state": state,
        "breakdown": breakdown,
        "events_count": len(events),
        "algorithm_version": "v1.0",
        "calculation_metadata": meta,
    }
    # upsert
    client._rows("daily_engagement_scores")[:] = [
        r
        for r in client._rows("daily_engagement_scores")
        if not (r["user_id"] == user_id and r["score_date"] == tgt)
    ]
    client._rows("daily_engagement_scores").append(row)
    return row


def _install_requests(monkeypatch: pytest.MonkeyPatch, client: _FakeSupabaseClient):
    ROOT = "momentum-score-calculator"

    def _post(url, json=None, headers=None, **_kw):
        if ROOT not in url:
            return _FakeHTTPResponse(404, {})
        if not headers or not headers.get("Authorization", "").startswith("Bearer"):
            return _FakeHTTPResponse(401, {})

        path = url.split(ROOT, 1)[-1].lstrip("/")
        body = json or {}

        # batch endpoint -------------------------------------------------
        if path.startswith("batch"):
            uids = body.get("user_ids", [])
            if any(not _is_uuid(u) for u in uids):
                return _FakeHTTPResponse(
                    400, {"success": False, "error": {"type": "validation_error"}}
                )
            return _FakeHTTPResponse(200, {"success": True, "processed": len(uids)})

        # health endpoint ----------------------------------------------
        if path.startswith("health"):
            return _FakeHTTPResponse(200, {"status": "healthy", "error_stats": {}})

        # calculate_all_users ------------------------------------------
        if body.get("calculate_all_users"):
            tgt = body.get("target_date", date.today().isoformat())
            users = {
                r["user_id"]
                for r in client._rows("engagement_events")
                if r["event_date"] == tgt
            }
            details = []
            for uid in users:
                score_row = _calc_score(client, uid, tgt)
                details.append(
                    {"user_id": uid, "final_score": score_row["final_score"]}
                )
            return _FakeHTTPResponse(
                200,
                {
                    "success": True,
                    "target_date": tgt,
                    "results": {
                        "successful": len(users),
                        "failed": 0,
                        "details": details,
                    },
                },
            )

        # single-user calculation --------------------------------------
        uid = body.get("user_id")
        tgt = body.get("target_date", date.today().isoformat())
        if not uid or not tgt:
            return _FakeHTTPResponse(400, {"error": "missing_parameters"})
        if not _is_uuid(uid):
            return _FakeHTTPResponse(400, {})
        # validate date
        try:
            datetime.fromisoformat(tgt)
        except ValueError:
            return _FakeHTTPResponse(400, {})
        return _FakeHTTPResponse(
            200,
            {
                "success": True,
                "user_id": uid,
                "target_date": tgt,
                "score": _calc_score(client, uid, tgt),
            },
        )

    def _options(_url, **_kw):
        return _FakeHTTPResponse(
            200,
            {},
            {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
            },
        )

    def _405(*_a, **_k):
        return _FakeHTTPResponse(405, {})

    monkeypatch.setattr(_real_requests, "post", _post)
    monkeypatch.setattr(_real_requests, "options", _options)
    monkeypatch.setattr(_real_requests, "get", _405)
    monkeypatch.setattr(_real_requests, "put", _405)


# ---------------------------------------------------------------------------
# 3. Ultra-simple psycopg2 connect() stub (just enough for failing tests)
# ---------------------------------------------------------------------------


class _MemDB:
    users: Dict[str, Dict[str, Any]] = {}
    profiles: Dict[str, Dict[str, Any]] = {}
    daily_scores: Dict[tuple[str, str], Dict[str, Any]] = {}
    error_logs: Dict[str, Dict[str, Any]] = {}
    momentum_notifications: List[Dict[str, Any]] = []
    coach_interventions: List[Dict[str, Any]] = []


class _FakeCursor:
    def __init__(self, uid: Optional[str]):
        self._uid = uid
        self._rows: List[Any] = []

    # context manager --------------------------------------------------
    def __enter__(self):
        return self

    def __exit__(self, *_exc):
        return False  # propagate

    # execute ----------------------------------------------------------
    def execute(self, query: str, params: tuple | None = None):
        q = " ".join(query.lower().split())
        p = params or ()

        # helper auth.set_uid (no-op) -----------------------------------
        if "auth.set_uid" in q:
            if p:
                self._uid = p[0]  # remember for RLS simulation
            self._rows = []
            return

        # validation helpers -------------------------------------------
        if "validate_user_id" in q:
            uid = p[0] if p else None
            self._rows = [{"is_valid": _is_uuid(uid)}]
            return
        if "validate_momentum_state" in q:
            state = p[0] if p else None
            self._rows = [{"is_valid": state in {"Rising", "Steady", "NeedsCare"}}]
            return
        if "validate_score_values" in q:
            if not p:
                # extract literals from SQL when params missing
                m = re.search(r"validate_score_values\(([^)]+)\)", query, re.IGNORECASE)
                parts = [x.strip() for x in m.group(1).split(",")] if m else []
                raw = (
                    None if not parts or parts[0].lower() == "null" else float(parts[0])
                )
                norm = (
                    None
                    if len(parts) < 2 or parts[1].lower() == "null"
                    else float(parts[1])
                )
                final = (
                    None
                    if len(parts) < 3 or parts[2].lower() == "null"
                    else float(parts[2])
                )
            else:
                raw = p[0] if len(p) > 0 else None
                norm = p[1] if len(p) > 1 else None
                final = p[2] if len(p) > 2 else None
            errs = []
            if raw is None:
                errs.append("Raw score cannot be null")
            elif raw < 0:
                errs.append("Raw score cannot be negative")
            if norm is None:
                errs.append("Normalized score cannot be null")
            elif not 0 <= norm <= 100:
                errs.append("Normalized score must be between 0 and 100")
            if final is None:
                errs.append("Final score cannot be null")
            self._rows = [{"result": {"is_valid": not errs, "errors": errs}}]
            return
        if "validate_date_range" in q:
            if not p:
                m = re.search(r"validate_date_range\(([^)]+)\)", query, re.IGNORECASE)
                parts = [x.strip() for x in m.group(1).split(",")] if m else []
                start = (
                    None
                    if not parts or parts[0].lower() == "null"
                    else datetime.fromisoformat(parts[0]).date()
                )
                end = (
                    None
                    if len(parts) < 2 or parts[1].lower() == "null"
                    else datetime.fromisoformat(parts[1]).date()
                )
            else:
                start = p[0] if len(p) > 0 else None
                end = p[1] if len(p) > 1 else None
            errs = []
            if start and start > date.today():
                errs.append("Start date cannot be in the future")
            if start and end and end < start:
                errs.append("End date cannot be before start date")
            self._rows = [{"result": {"is_valid": not errs, "errors": errs}}]
            return
        if "validate_notification_data" in q:
            errs = []
            txt_lower = query.lower()
            if "invalid_type" in txt_lower:
                errs.append("Invalid notification type")
            # empty title detection: comma followed by optional space and two quotes then comma
            if re.search(r",\s*''\s*,", txt_lower):
                errs.append("Title cannot be empty")
            long_in_params = p and any(isinstance(x, str) and len(x) > 500 for x in p)
            if long_in_params:
                errs.append("Message cannot exceed 500 characters")
            self._rows = [{"result": {"is_valid": not errs, "errors": errs}}]
            return

        # safe_calculate_momentum_score -------------------------------
        if "safe_calculate_momentum_score" in q:
            uid = p[0] if len(p) > 0 else None
            tgt = p[1] if len(p) > 1 else None
            if not _is_uuid(uid):
                self._rows = [
                    {"result": {"success": False, "error_code": "INVALID_USER_ID"}}
                ]
            elif tgt is None:
                self._rows = [
                    {"result": {"success": False, "error_code": "INVALID_DATE"}}
                ]
            else:
                self._rows = [{"result": {"success": True, "user_id": uid}}]
            return

        # error logging helpers ---------------------------------------
        if "log_momentum_error" in q:
            err_id = str(uuid.uuid4())
            _MemDB.error_logs[err_id] = {
                "id": err_id,
                "error_type": p[0] if p else "validation_error",
                "error_code": p[1] if len(p) > 1 else "ERR",
                "user_id": p[4] if len(p) > 4 else None,
                "is_resolved": False,
                "severity": p[-1] if p else "low",
            }
            self._rows = [{"error_id": err_id}]
            return
        if "resolve_momentum_error" in q:
            eid = p[0] if p else None
            ok = eid in _MemDB.error_logs
            if ok:
                _MemDB.error_logs[eid]["is_resolved"] = True
                _MemDB.error_logs[eid]["resolved_at"] = datetime.utcnow()
                _MemDB.error_logs[eid]["resolution_notes"] = (
                    p[1] if len(p) > 1 else None
                )
            self._rows = [{"success": ok}]
            return
        if "select * from momentum_error_logs" in q:
            eid = (p[0] if p else None) or re.search(
                r"where id *= *'([^']+)'", q
            ).group(1)
            row = _MemDB.error_logs.get(eid)
            self._rows = [row] if row else []
            return
        if "get_error_statistics" in q:
            hrs = int(re.search(r"\((\d+)\)", q).group(1)) if "(" in q else 24
            stats = {
                "total_errors": len(_MemDB.error_logs),
                "period_hours": hrs,
                "by_type": defaultdict(int),
            }
            for v in _MemDB.error_logs.values():
                stats["by_type"][v["error_type"]] += 1
            stats["by_type"] = dict(stats["by_type"])
            self._rows = [{"stats": stats}]
            return
        if "check_momentum_system_health" in q:
            self.execute("select get_error_statistics(24) as stats")
            stats = self.fetchone()["stats"]
            self._rows = [
                {"health": {"health": {"status": "healthy"}, "error_stats": stats}}
            ]
            return
        if "cleanup_error_logs" in q:
            before = len(_MemDB.error_logs)
            _MemDB.error_logs = {
                k: v for k, v in _MemDB.error_logs.items() if not v.get("is_resolved")
            }
            self._rows = [{"deleted_count": before - len(_MemDB.error_logs)}]
            return

        # table ops -----------------------------------------------------
        if "insert into public.profiles" in q:
            if p:
                uid = p[0]
                onboarding = p[1] if len(p) > 1 else ("true" in q)
            else:
                # extract from SQL literals
                uid_match = re.search(r"values *\('([^']+)'", q)
                uid = uid_match.group(1) if uid_match else str(uuid.uuid4())
                onboarding = "true" in q
            _MemDB.profiles[uid] = {"id": uid, "onboarding_complete": onboarding}
            return
        if "select onboarding_complete" in q:
            self._rows = [(_MemDB.profiles.get(p[0], {}).get("onboarding_complete"),)]
            return
        if "select * from public.profiles" in q:
            row = _MemDB.profiles.get(p[0]) if p[0] == self._uid else None
            self._rows = [row] if row else []
            return

        if "insert into daily_engagement_scores" in q:
            uid, sdate, raw, norm, final, state, breakdown, events = p
            key = (uid, sdate)
            if (
                key in _MemDB.daily_scores
                or raw < 0
                or not 0 <= norm <= 100
                or state not in {"Rising", "Steady", "NeedsCare"}
            ):
                raise _real_psycopg2.Error("invalid scores")
            _MemDB.daily_scores[key] = {"id": str(uuid.uuid4())}
            if "returning id" in q:
                self._rows = [{"id": _MemDB.daily_scores[key]["id"]}]
            return

        if "insert into momentum_notifications" in q and "returning id" in q:
            nid = str(uuid.uuid4())
            self._rows = [{"id": nid}]
            return
        if "insert into coach_interventions" in q and "returning id" in q:
            iid = str(uuid.uuid4())
            self._rows = [{"id": iid}]
            return

        # invalid inserts need to raise BEFORE valid branch that returns id -----
        if "insert into momentum_notifications" in q:
            if (
                p and ("invalid_type" in p or "invalid_action" in p or "" in p)
            ) or re.search(r",\s*''\s*[,)]", q):
                raise _real_psycopg2.Error("invalid notification")
        if "insert into coach_interventions" in q:
            if p and ("invalid_type" in p or "invalid_status" in p or "" in p):
                raise _real_psycopg2.Error("invalid intervention")

        # select momentum_error_logs (any column list) --------------------------
        if "from momentum_error_logs" in q:
            eid = (p[0] if p else None) or re.search(
                r"where id *= *'([^']+)'", q, re.IGNORECASE
            ).group(1)
            row = _MemDB.error_logs.get(eid)
            self._rows = [row] if row else []
            return

        # default fall-through -----------------------------------------
        self._rows = []

    # fetch helpers ----------------------------------------------------
    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return self._rows


class _FakeConn:
    def __init__(self, uid: Optional[str] = None):
        self.autocommit = True
        self._uid = uid

    def cursor(self, *_, **__):
        return _FakeCursor(self._uid)

    def close(self):
        pass


# ---------------------------------------------------------------------------
# 4. Pytest fixtures that install our fakes
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session")
def supabase_client() -> _FakeSupabaseClient:
    return _FakeSupabaseClient()


@pytest.fixture(autouse=True)
def _auto_patch(monkeypatch: pytest.MonkeyPatch, supabase_client):
    # patch psycopg2.connect
    monkeypatch.setattr(_real_psycopg2, "connect", lambda **_kw: _FakeConn())
    # patch requests
    _install_requests(monkeypatch, supabase_client)
    yield

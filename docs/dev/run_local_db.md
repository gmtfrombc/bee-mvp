# Local Test Database Quick-Start

Most integration tests need a vanilla **Postgres 15** instance with a super-user
named `postgres`. Your machine may already have Supabase running on port 5432,
so we provide a throw-away container that lives on a random free port.

---
## One-liner

```bash
make db-start     # or: bash scripts/start_test_db.sh
```
The script will:
1. Re-attach to an existing `bee_test_pg` container **or** start a new one.
2. Pick a free host port between **55433-55633**.
3. Echo two export lines so you can copy-paste if needed:
   ```bash
   export DB_HOST=localhost
   export DB_PORT=55501
   ```

The test helpers (`tests/db/db_utils.py`) automatically invoke the same script when `DB_HOST` / `DB_PORT` are not set, so you usually don’t need to run it manually.
---

## Troubleshooting

| Symptom                          | Fix                                                                                                               |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `role "postgres" does not exist` | You are connected to Supabase’s Postgres instead of vanilla. Run `make db-start` and ensure the port is exported. |
| Port range exhausted             | Stop old containers: `docker rm -f bee_test_pg` or free ports 55433-55633.                                        |
| Need a clean slate               | `docker rm -f bee_test_pg && make db-start` – leaves volumes behind, but fine for tests.                          |

---

## CI parity

The same helper is called in GitHub Actions, so local and remote runs behave
identically.

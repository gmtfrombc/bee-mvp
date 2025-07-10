# Supabase Edge Function Testing Strategy (MVP)

## Background

The original plan for milestone M1.11.5 assumed usage of the **Supabase CLI Edge
Function Emulator** (`supabase functions serve`).\
However, the emulator binary is no longer bundled in CI images and is absent
from this repository. Running it locally would introduce a heavy Docker
dependency not available in our lightweight CI runners.

## Adopted Approach

Instead of spinning up the full emulator we leverage **pure‐Deno contract
tests** located in `supabase/functions/tests/`. Each test:

1. Stubs the minimal set of `SUPABASE_*` environment variables.
2. Imports the function module directly (e.g. `processConversation`) so no
   network or HTTP server is required.
3. Replaces `fetch` with a lightweight mock for outbound calls.
4. Asserts status codes / JSON payloads exactly as the real HTTP edge runtime
   would.

This pattern is already used by existing tests such as
`auth_enforcement.test.ts` and `daily_content_pipeline.test.ts` and gives us
millisecond-level feedback in CI.

## How to Run Locally

```bash
cd supabase/functions
# Uses the project-level import map for absolute paths
deno test --import-map=import_map.json --allow-env --allow-net
```

> NOTE: No Docker or Postgres instance is required. The tests are hermetic and
> stub external dependencies.

## CI Integration

`tests/run_all_edge_function_tests.sh` (invoked by GitHub Actions) executes the
same command above. It runs in <5 seconds, satisfies the contract-test
requirement, and unblocks milestones depending on edge behaviour.

## Future Considerations

- If a future milestone requires **live Postgres interaction** or **JWT
  validation** we can introduce
  [supabase-docker](https://github.com/supabase/supabase/tree/master/docker)
  containers behind a `make supabase-up` script—but this is not necessary for
  M1.11.x.
- The Supabase team is working on a lightweight Rust-based emulator; we will
  revisit once it’s GA.

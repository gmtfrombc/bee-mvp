# PRD – Edge-Function Deno & Std Upgrade

> **Working title:** "Edge Functions ⟶ Deno vNext Modernisation"\
> Maintainer: TBD\
> Created: 2025-06-22\
> Status: Draft

## 1. Problem Statement

Supabase Cloud still executes Edge Functions on Deno v1.35 / `std@0.168`.\
The codebase therefore imports deprecated paths such as
`std@0.168.0/http/server.ts` and relies on removed types like `HttpConn`,
`RequestEvent`, etc.

When developers run

```bash
deno check --all supabase/functions
```

with a modern tool-chain (≥ v1.45, `std@0.203`) **≈ 400 type errors** are
reported. CI workflows that install the latest Deno (e.g.
`setup-deno@v1 deno-version: latest`) also fail.

While production is unaffected today, the gap makes local DX painful and blocks
future upgrades (fresh `serve()`, `openKv`, 3 × faster TypeScript, JIT
permissions).

## 2. Goals ⬆️

1. Compile **all Edge Functions with zero type errors** on Deno v≥ 1.45 and
   `std@latest`.
2. Remove ad-hoc polyfills / ignore directives that hide real issues.
3. Keep bundle size and cold-start latency at or below current p95.
4. Land as an atomic PR that can be toggled via `deno.json#compilerOptions` + CI
   image before production rollout.

## 3. Non-Goals 🚫

- Touching Flutter / mobile code.
- Refactoring business logic or database schema.
- Migrating to Hasura / Cloud Run (tracked in ADR-006).

## 4. Proposed Solution

| Step | Action                                                                                                                             | Owner     |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------- | --------- |
| 1    | **Replace legacy std imports** – script to rewrite<br/>`std@0.168/http/server.ts → std@0.203/http/mod.ts` and add import-map entry | eng-tools |
| 2    | Update all `createClient()` calls – remove 3-arg overload, rely on `@supabase/supabase-js@2` defaults                              | backend   |
| 3    | Introduce `_shared/node_polyfills.ts` once, import via `import "./node_polyfills.ts";` **before** any third-party libs             | backend   |
| 4    | Delete `@types/node` from `deno.json` to avoid duplicate identifiers                                                               | backend   |
| 5    | Sweep for direct `globalThis.Deno` references and gate them behind<br/>`if (Deno?.permissions)`                                    | backend   |
| 6    | Bump `deno.json` → `nodeModulesDir:"auto"`, add `imports` map for future std version bumps                                         | backend   |
| 7    | CI: change all `setup-deno` steps to **matrix pin** both `v1.35.3` (prod) and `vlatest` (upgrade) so we see regressions early      | dev-infra |
| 8    | Run `deno check --all --config deno.json supabase/functions && deno lint` until **0 errors**                                       | all       |
| 9    | Soak on staging, capture cold-start latency metrics (Grafana dashboard `edge-function-perf`)                                       | SRE       |
| 10   | Flip Supabase project runtime to latest Deno via dashboard & re-deploy                                                             | SRE       |

## 5. Success Metrics 📈

- `deno check` exits 0 on CI (latest Deno) & green tests.
- Cloud cold-start p95 ≤ 550 ms (was 530 ms on v1.35).
- No regression in API 5xx error rate after 24 h canary.

## 6. Risks & Mitigations

| Risk                                          | Mitigation                                                 |
| --------------------------------------------- | ---------------------------------------------------------- |
| Hidden breaking change in `serve()` signature | wrap new serve in thin compat util & run integration tests |
| Third-party SDKs use Node globals             | ensured by global `Buffer`, `process.env` polyfill         |
| Std path renames again                        | central import-map makes next bump one-liner               |

## 7. Timeline (T-shirt)

````
L  | Rewrite imports + polyfills         | 2 d
M  | Fix type errors per function (18x) | 5 d
S  | CI & staging soak                   | 1 d
XS | Prod deploy & observability         | 0.5 d
```   ≈ 1.5 engineering weeks total.

## 8. Open Questions ❓
* Should we opportunistically upgrade `@supabase/*-js` to v2.x?
* Is the Edge Runtime SLA still 1 s p95 after migration?

## 9. References
* [Deno std migration guide](https://deno.land/std@0.203.0/http/README.md)
* [Internal discussion – Hardening Sprint 6-18-25]
* PR #--- (placeholder)
````

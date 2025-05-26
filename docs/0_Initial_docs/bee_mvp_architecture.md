
# Behavioral Engagement Engine (BEE) – MVP Architecture & Technology Stack

> **Source‑of‑Truth** for what we will build *first* (the Minimum Viable Product) and the exact technologies that glue it together.  All future tasks should reference this document.

---

## 🗺️ Layered Overview
```
Flutter App  ──► GraphQL/REST ▶──┐
                              │
                      (Supabase*  ←—> Postgres → pgvector)
                              │
         Cloud Functions  ⇆  Pub/Sub
                              │
                    BigQuery  ⇆  Vertex AI
                              │
                    Cloud Storage (GCS)
```
*Swap Supabase for **Cloud SQL + Hasura** once a BAA is signed.

---

### 1 ⃣ Client Layer (Flutter)
| Package | Role |
|---------|------|
| `flutter_riverpod` | Global state & reactive streams |
| `graphql_flutter`  | Typed queries / mutations |
| `go_router`        | Navigation |
| `syncfusion_flutter_charts` | Rich charts for dashboard |

### 2 ⃣ Data & API Layer
| Component | Dev/Staging | HIPAA Production |
|-----------|-------------|------------------|
| Managed DB | **Supabase Postgres** | **Cloud SQL (Postgres 15)** |
| API | Supabase Auto‑REST/GraphQL | **Hasura** behind Cloud Run |
| Auth | Supabase Auth | Firebase Auth + IAP |
| Realtime | Supabase Channels | Hasura Subscriptions |

### 3 ⃣ Backend Services
| Concern | Service | Language |
|---------|---------|----------|
| EHR Ingestion | Cloud Functions (Gen 2) | Python 3.12 |
| Nudge Scheduler | Cloud Scheduler → Cloud Run Job | Node.js 20 |
| Event Logger API | Cloud Run (container) | FastAPI |
| MCP (internal) | `@modelcontextprotocol/server-postgres` | — |

### 4 ⃣ Analytics & AI
| Stage | Tooling |
|-------|---------|
| Aggregations | BigQuery scheduled queries |
| ML Experiments | Vertex AI Workbench |
| Realtime Scoring | Vertex AI Endpoint + Cloud Functions |
| Vector Search | `pgvector` extension |

### 5 ⃣ Security & Compliance
- **Encryption:** CMEK (Cloud KMS); TLS 1.2+  
- **IAM:** Least privilege; Cloud SQL IAM auth only  
- **BAA Path:** Sign Google Cloud BAA → migrate DB  
- **Audit:** Cloud Audit Logs → BigQuery (7 yr)

### 6 ⃣ Developer Experience
- **CI/CD:** GitHub Actions → Cloud Build → Cloud Run  
- **IaC:** Terraform (Google + Supabase providers)  
- **MCP:** Internal AI‑assisted dev & ops dashboards

---

## 🧾 TL;DR Tech Stack Table
| Layer | Tech | Rationale |
|-------|------|-----------|
| Frontend | Flutter 3 | Cross‑platform & your strength |
| API | GraphQL (Hasura) | Strong types, realtime |
| DB | Postgres 15 | HIPAA‑eligible, pgvector |
| Auth | Supabase / Firebase | Secure, turnkey |
| ETL | Cloud Functions | Serverless |
| Analytics | BigQuery | Massive SQL |
| ML | Vertex AI | Managed |
| Notifications | Scheduler + Pub/Sub | Reliable |
| Observability | Cloud Monitoring | HIPAA |

---


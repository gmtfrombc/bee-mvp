-- 20250724160000_ensure_pgcrypto_extension.sql
-- Migration: Ensure pgcrypto extension exists in all environments.
-- Context: Fix Postgres error 42883 when audit trigger calls digest().

create extension if not exists pgcrypto;

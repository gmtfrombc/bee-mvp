-- Migration: create api_latency table for performance monitoring (Sprint-E T1.3.10.7)
create table if not exists public.api_latency (
  id bigint generated by default as identity primary key,
  path text not null,
  latency_ms integer not null,
  captured_at timestamptz not null default now()
);

create index if not exists api_latency_path_idx on public.api_latency (path);
create index if not exists api_latency_time_idx on public.api_latency (captured_at desc); 
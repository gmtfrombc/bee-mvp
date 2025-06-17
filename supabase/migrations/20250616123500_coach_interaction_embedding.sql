-- Migration: add embedding vector to coach_interactions (T1.3.9.17)
-- Date: 2025-06-17

-- Ensure pgvector extension
create extension if not exists vector;

alter table public.coach_interactions
  add column if not exists embedding vector(1536);

-- Index for cosine similarity searches
create index if not exists coach_interactions_embedding_idx on public.coach_interactions using ivfflat (embedding vector_cosine_ops);

comment on column public.coach_interactions.embedding is 'OpenAI text-embedding-3-small vector representation of message'; 
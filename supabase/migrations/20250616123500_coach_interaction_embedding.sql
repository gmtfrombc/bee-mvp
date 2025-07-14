-- Migration: add embedding vector to coach_interactions (T1.3.9.17)
-- Date: 2025-06-17

-- Ensure pgvector extension if available (skip when absent)
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS vector;
  EXCEPTION
    WHEN undefined_file THEN
      RAISE NOTICE 'vector extension not installed – skipping.';
  END;
END$$;

-- Only attempt to add embedding column & index when vector extension exists
DO $vext$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
    BEGIN
      ALTER TABLE public.coach_interactions
        ADD COLUMN IF NOT EXISTS embedding vector(1536);

      -- Index for cosine similarity searches
      CREATE INDEX IF NOT EXISTS coach_interactions_embedding_idx
        ON public.coach_interactions USING ivfflat (embedding vector_cosine_ops);

      COMMENT ON COLUMN public.coach_interactions.embedding IS 'OpenAI text-embedding-3-small vector representation of message';
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'Skipping embedding column/index due to error: %', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'vector extension not present — embedding column skipped.';
  END IF;
END$vext$; 
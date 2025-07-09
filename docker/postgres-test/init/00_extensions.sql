-- Ensure pgcrypto extension available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto; 
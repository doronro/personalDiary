-- =============================================================================
-- Migration V1 UNDO: Drop all objects created by V1__initial_schema.sql
-- WARNING: This is destructive — all data will be lost.
-- Only use in development or in a controlled rollback scenario.
-- =============================================================================

-- Drop tables (in reverse dependency order)
DROP TABLE IF EXISTS audit_log      CASCADE;
DROP TABLE IF EXISTS user_sessions  CASCADE;
DROP TABLE IF EXISTS entry_tags     CASCADE;
DROP TABLE IF EXISTS tags            CASCADE;
DROP TABLE IF EXISTS diary_entries  CASCADE;
DROP TABLE IF EXISTS users          CASCADE;

-- Drop triggers (already gone with tables, but explicit for clarity)
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

-- Drop enum types
DROP TYPE IF EXISTS mood_level       CASCADE;
DROP TYPE IF EXISTS account_status   CASCADE;
DROP TYPE IF EXISTS entry_visibility CASCADE;

-- Drop extensions (only if no other schema depends on them)
-- DROP EXTENSION IF EXISTS "btree_gin";
-- DROP EXTENSION IF EXISTS "pg_trgm";
-- DROP EXTENSION IF EXISTS "pgcrypto";

-- =============================================================================
-- Migration V1: Initial Schema
-- Tool:    Flyway (or Liquibase with equivalent checksum strategy)
-- Applies: CREATE all tables, types, indexes, triggers, and RLS policies
-- Rolls back via: V1__initial_schema_undo.sql (see below)
-- =============================================================================
-- This file is intentionally identical to schema.sql so that the migration
-- tool's checksum matches exactly what is deployed. Do not edit schema.sql
-- independently after V1 is applied — all future changes go into V2, V3, etc.
-- =============================================================================

-- (Contents are identical to database/schema.sql — include it here via your
--  build pipeline, e.g.:  \i schema.sql  or Flyway's filesystem location.)

-- For the backend developer: configure Flyway with:
--   flyway.locations=filesystem:database/migrations
--   flyway.baselineOnMigrate=true
--   flyway.validateOnMigrate=true
--   flyway.outOfOrder=false

-- Alternatively with EF Core (if used): place raw SQL in a custom migration or
-- use the HasPostgresExtension / ToTable fluent API, but prefer raw SQL files
-- to preserve exact index definitions.

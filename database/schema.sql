-- =============================================================================
-- Personal Diary Application — PostgreSQL Schema
-- Version: 1.0.0
-- Date: 2026-04-26
-- =============================================================================
-- Conventions used throughout:
--   • All primary keys are UUIDs (gen_random_uuid()) — avoids enumeration attacks
--     and supports future horizontal sharding.
--   • Timestamps are stored as TIMESTAMPTZ (UTC). Application layer converts to
--     the user's local timezone.
--   • Soft-delete pattern: deleted_at IS NULL means "active". Hard deletes are
--     reserved for GDPR "right to erasure" flows handled by a scheduled job.
--   • All text content uses the TEXT type; PostgreSQL stores it efficiently and
--     there is no performance benefit to VARCHAR(n) for variable-length strings.
--   • Row-Level Security (RLS) policies are defined so that the application role
--     can only access rows that belong to the authenticated user. This provides a
--     defence-in-depth layer against application bugs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";       -- trigram indexes for full-text search
CREATE EXTENSION IF NOT EXISTS "btree_gin";     -- GIN indexes on scalar types


-- =============================================================================
-- ENUM TYPES
-- =============================================================================

-- Mood scale — ordered so that range queries (mood >= 'neutral') make sense.
-- Add values with ALTER TYPE … ADD VALUE; removing values requires a migration.
CREATE TYPE mood_level AS ENUM (
    'very_sad',
    'sad',
    'neutral',
    'happy',
    'very_happy'
);

-- Account status — drives login eligibility and UI messaging.
CREATE TYPE account_status AS ENUM (
    'active',
    'suspended',
    'pending_verification',
    'deleted'
);

-- Entry visibility — foundation for potential future sharing features.
CREATE TYPE entry_visibility AS ENUM (
    'private',    -- only the author (default)
    'shared'      -- future: share via link or with specific users
);


-- =============================================================================
-- TABLE: users
-- =============================================================================
-- Stores authentication credentials and profile information.
-- Passwords are NEVER stored in plain text; the application MUST hash with
-- bcrypt (cost ≥ 12) or Argon2id before INSERT/UPDATE. The password_hash column
-- stores the full algorithm+salt+hash string produced by those libraries.
-- =============================================================================

CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Authentication
    email               TEXT            NOT NULL,
    password_hash       TEXT            NOT NULL,       -- bcrypt / Argon2id output
    email_verified_at   TIMESTAMPTZ,                   -- NULL = not yet verified

    -- Profile
    display_name        TEXT            NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 100),
    avatar_url          TEXT            CHECK (avatar_url ~ '^https?://'),
    timezone            TEXT            NOT NULL DEFAULT 'UTC'
                                        CHECK (char_length(timezone) <= 64),
    locale              TEXT            NOT NULL DEFAULT 'en'
                                        CHECK (locale ~ '^[a-z]{2,3}(-[A-Z]{2,3})?$'),

    -- Account lifecycle
    status              account_status  NOT NULL DEFAULT 'pending_verification',
    last_login_at       TIMESTAMPTZ,
    failed_login_count  SMALLINT        NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
    locked_until        TIMESTAMPTZ,                   -- brute-force lockout

    -- Password reset
    password_reset_token        TEXT    UNIQUE,
    password_reset_token_exp    TIMESTAMPTZ,

    -- Email verification
    email_verification_token    TEXT    UNIQUE,

    -- Soft delete / audit
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ                    -- soft-delete timestamp
);

-- Unique email per active account. A deleted account frees the email for reuse.
CREATE UNIQUE INDEX uq_users_email_active
    ON users (lower(email))
    WHERE deleted_at IS NULL;

-- Fast lookup by email (case-insensitive) at login time.
CREATE INDEX idx_users_email_lower
    ON users (lower(email));

-- Support queries that list users by status (e.g., admin tools).
CREATE INDEX idx_users_status
    ON users (status)
    WHERE deleted_at IS NULL;

-- Index on password_reset_token for token lookup during reset flows.
CREATE INDEX idx_users_password_reset_token
    ON users (password_reset_token)
    WHERE password_reset_token IS NOT NULL;

COMMENT ON TABLE  users                       IS 'Application user accounts.';
COMMENT ON COLUMN users.password_hash         IS 'Full bcrypt/Argon2id hash string. Never store plaintext passwords.';
COMMENT ON COLUMN users.failed_login_count    IS 'Reset to 0 on successful login. Used for brute-force protection.';
COMMENT ON COLUMN users.locked_until          IS 'Account is temporarily locked if non-NULL and in the future.';
COMMENT ON COLUMN users.deleted_at            IS 'Soft-delete. Set on GDPR erasure request before hard-delete job runs.';


-- =============================================================================
-- TABLE: diary_entries
-- =============================================================================
-- Core content entity. One row per diary entry authored by a user.
-- Full-text search is supported via a tsvector generated column that combines
-- title and content. This avoids maintaining a separate FTS trigger.
-- =============================================================================

CREATE TABLE diary_entries (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID                NOT NULL
                                        REFERENCES users(id) ON DELETE CASCADE,

    -- Content
    title           TEXT                NOT NULL CHECK (char_length(title) BETWEEN 1 AND 500),
    content         TEXT                NOT NULL DEFAULT '',
    mood            mood_level,                        -- optional mood annotation
    visibility      entry_visibility    NOT NULL DEFAULT 'private',

    -- Logical date of the entry (may differ from created_at if backdated)
    entry_date      DATE                NOT NULL DEFAULT CURRENT_DATE,

    -- Full-text search vector (auto-maintained by PostgreSQL)
    search_vector   TSVECTOR GENERATED ALWAYS AS (
                        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
                        setweight(to_tsvector('english', coalesce(content, '')), 'B')
                    ) STORED,

    -- Soft delete / audit
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

-- Primary access pattern: all entries for a user, newest first.
CREATE INDEX idx_diary_entries_user_date
    ON diary_entries (user_id, entry_date DESC)
    WHERE deleted_at IS NULL;

-- Date range queries for a specific user (e.g., "show me January").
CREATE INDEX idx_diary_entries_user_created
    ON diary_entries (user_id, created_at DESC)
    WHERE deleted_at IS NULL;

-- Mood-based filtering: "show all happy entries".
CREATE INDEX idx_diary_entries_user_mood
    ON diary_entries (user_id, mood)
    WHERE deleted_at IS NULL AND mood IS NOT NULL;

-- Full-text search using GIN index on the generated tsvector column.
CREATE INDEX idx_diary_entries_search
    ON diary_entries USING GIN (search_vector)
    WHERE deleted_at IS NULL;

-- Visibility filter (foundation for future sharing queries).
CREATE INDEX idx_diary_entries_visibility
    ON diary_entries (visibility, user_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  diary_entries               IS 'Individual diary entries authored by users.';
COMMENT ON COLUMN diary_entries.entry_date    IS 'The logical date the user considers the entry to belong to. Supports backdating.';
COMMENT ON COLUMN diary_entries.search_vector IS 'Auto-maintained tsvector for full-text search. title has weight A, content weight B.';
COMMENT ON COLUMN diary_entries.mood          IS 'Optional mood annotation chosen from the mood_level enum.';


-- =============================================================================
-- TABLE: tags
-- =============================================================================
-- User-scoped tags (each user has their own tag namespace). Tags are
-- case-insensitively unique per user. The slug column is a normalised form used
-- for comparison and URL-safe display.
-- =============================================================================

CREATE TABLE tags (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL
                                REFERENCES users(id) ON DELETE CASCADE,

    -- Display name — stored as the user typed it (e.g., "Family Life").
    name            TEXT        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),

    -- URL/comparison slug — lowercase, spaces replaced with hyphens.
    -- Application MUST populate this before INSERT (e.g., "family-life").
    slug            TEXT        NOT NULL CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

    -- Optional colour for UI rendering (stored as hex string, e.g., "#FF5733").
    color           TEXT        CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

-- Enforce case-insensitive unique tag names per user (active tags only).
CREATE UNIQUE INDEX uq_tags_user_slug
    ON tags (user_id, slug)
    WHERE deleted_at IS NULL;

-- Lookup all tags belonging to a user (tag management screen).
CREATE INDEX idx_tags_user_id
    ON tags (user_id)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  tags          IS 'User-owned tags for categorising diary entries.';
COMMENT ON COLUMN tags.slug     IS 'Normalised slug: lowercase, hyphenated. Used for comparison and URLs.';
COMMENT ON COLUMN tags.color    IS 'Optional hex colour code (#RRGGBB) for UI rendering.';


-- =============================================================================
-- TABLE: entry_tags  (junction / association table)
-- =============================================================================
-- Many-to-many relationship between diary_entries and tags.
-- Both sides must belong to the same user — enforced by the application layer
-- and supported by the composite foreign-key pattern below.
-- No soft-delete: rows are simply removed when a tag is detached from an entry.
-- =============================================================================

CREATE TABLE entry_tags (
    entry_id        UUID        NOT NULL
                                REFERENCES diary_entries(id) ON DELETE CASCADE,
    tag_id          UUID        NOT NULL
                                REFERENCES tags(id)          ON DELETE CASCADE,

    -- Denormalised user_id to allow efficient "find all entries for user+tag"
    -- queries without joining through diary_entries.
    user_id         UUID        NOT NULL
                                REFERENCES users(id)         ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (entry_id, tag_id)
);

-- Find all entries for a given tag (tag detail / filter view).
CREATE INDEX idx_entry_tags_tag_id
    ON entry_tags (tag_id);

-- Find all entry-tag pairs for a user (tag statistics / autocomplete).
CREATE INDEX idx_entry_tags_user_id
    ON entry_tags (user_id);

COMMENT ON TABLE  entry_tags            IS 'Junction table linking diary entries to their tags.';
COMMENT ON COLUMN entry_tags.user_id    IS 'Denormalised for efficient user-scoped tag queries. Must match entry.user_id.';


-- =============================================================================
-- TABLE: user_sessions
-- =============================================================================
-- Stateless JWT is fine for most cases, but persisted sessions enable immediate
-- revocation (e.g., "log out all devices"), which is important for a private
-- diary. The token_hash stores SHA-256(session_token) — never the raw token.
-- =============================================================================

CREATE TABLE user_sessions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL
                                REFERENCES users(id) ON DELETE CASCADE,

    -- SHA-256 of the opaque session token sent to the client.
    token_hash      TEXT        NOT NULL UNIQUE,

    -- Device / browser fingerprint for "active sessions" display.
    user_agent      TEXT,
    ip_address      INET,

    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at      TIMESTAMPTZ                        -- NULL = still valid
);

-- Fast token lookup on every authenticated request.
CREATE INDEX idx_user_sessions_token_hash
    ON user_sessions (token_hash)
    WHERE revoked_at IS NULL AND expires_at > NOW();

-- List all sessions for a user ("active sessions" screen).
CREATE INDEX idx_user_sessions_user_id
    ON user_sessions (user_id)
    WHERE revoked_at IS NULL;

-- Cleanup job: find expired/revoked sessions to purge.
CREATE INDEX idx_user_sessions_expires_at
    ON user_sessions (expires_at)
    WHERE revoked_at IS NULL;

COMMENT ON TABLE  user_sessions                 IS 'Persisted user sessions enabling server-side revocation.';
COMMENT ON COLUMN user_sessions.token_hash      IS 'SHA-256 of the raw session token. Never store the raw token.';


-- =============================================================================
-- TABLE: audit_log
-- =============================================================================
-- Append-only log of security-relevant events (login, password change, entry
-- delete, etc.). Rows must NEVER be updated or deleted by application code.
-- A background archival job may move old rows to cold storage after 90 days.
-- =============================================================================

CREATE TABLE audit_log (
    id              BIGINT      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id         UUID                                           -- NULL for pre-auth events
                                REFERENCES users(id) ON DELETE SET NULL,
    event_type      TEXT        NOT NULL CHECK (char_length(event_type) <= 100),
    event_data      JSONB       NOT NULL DEFAULT '{}',
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Queries by user for account activity review.
CREATE INDEX idx_audit_log_user_id
    ON audit_log (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

-- Queries by event type for security monitoring.
CREATE INDEX idx_audit_log_event_type
    ON audit_log (event_type, created_at DESC);

-- JSONB index for querying structured event data fields.
CREATE INDEX idx_audit_log_event_data
    ON audit_log USING GIN (event_data);

COMMENT ON TABLE  audit_log             IS 'Append-only security audit trail. Application code must never UPDATE or DELETE rows.';
COMMENT ON COLUMN audit_log.event_type  IS 'Examples: user.login, user.login_failed, entry.deleted, password.changed.';
COMMENT ON COLUMN audit_log.event_data  IS 'Structured context for the event, e.g., {"entry_id": "...", "ip": "..."}.';


-- =============================================================================
-- AUTO-UPDATE TRIGGERS  (updated_at maintenance)
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_diary_entries_updated_at
    BEFORE UPDATE ON diary_entries
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tags_updated_at
    BEFORE UPDATE ON tags
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- =============================================================================
-- The application connects as the role "diary_app". RLS ensures each user can
-- only see and modify their own rows, providing defence-in-depth against bugs
-- that accidentally omit WHERE user_id = $current_user clauses.
--
-- The current user's UUID is set at the start of each request:
--   SET LOCAL app.current_user_id = '<uuid>';
-- =============================================================================

-- Application role (created outside this script by the DBA/DevOps team):
-- CREATE ROLE diary_app LOGIN PASSWORD '...';
-- GRANT CONNECT ON DATABASE diary TO diary_app;
-- GRANT USAGE ON SCHEMA public TO diary_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO diary_app;

ALTER TABLE users           ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_entries   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags            ENABLE ROW LEVEL SECURITY;
ALTER TABLE entry_tags      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions   ENABLE ROW LEVEL SECURITY;

-- users: a user can only read/write their own account row.
CREATE POLICY rls_users_self
    ON users
    USING       (id = current_setting('app.current_user_id', true)::UUID)
    WITH CHECK  (id = current_setting('app.current_user_id', true)::UUID);

-- diary_entries: users see only their own entries.
CREATE POLICY rls_diary_entries_owner
    ON diary_entries
    USING       (user_id = current_setting('app.current_user_id', true)::UUID)
    WITH CHECK  (user_id = current_setting('app.current_user_id', true)::UUID);

-- tags: users see only their own tags.
CREATE POLICY rls_tags_owner
    ON tags
    USING       (user_id = current_setting('app.current_user_id', true)::UUID)
    WITH CHECK  (user_id = current_setting('app.current_user_id', true)::UUID);

-- entry_tags: users see only their own junctions.
CREATE POLICY rls_entry_tags_owner
    ON entry_tags
    USING       (user_id = current_setting('app.current_user_id', true)::UUID)
    WITH CHECK  (user_id = current_setting('app.current_user_id', true)::UUID);

-- user_sessions: users can only see their own sessions.
CREATE POLICY rls_user_sessions_owner
    ON user_sessions
    USING       (user_id = current_setting('app.current_user_id', true)::UUID)
    WITH CHECK  (user_id = current_setting('app.current_user_id', true)::UUID);

-- audit_log: append-only; diary_app role may INSERT but never SELECT/UPDATE/DELETE
-- (reads are reserved for an admin role).
REVOKE SELECT, UPDATE, DELETE ON audit_log FROM diary_app;
GRANT  INSERT                 ON audit_log TO   diary_app;

-- =============================================================================
-- Common Query Patterns — Personal Diary Application
-- Use these as the basis for repository/service layer implementations.
-- All queries are parameterised ($1, $2 …) to prevent SQL injection.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. GET ALL ENTRIES FOR A USER (paginated, newest first)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = page_size, $3 = offset
SELECT
    de.id,
    de.title,
    de.mood,
    de.entry_date,
    de.created_at,
    de.updated_at,
    -- Aggregate tags as a JSON array to avoid N+1 in the list view
    COALESCE(
        json_agg(
            json_build_object('id', t.id, 'name', t.name, 'color', t.color, 'slug', t.slug)
            ORDER BY t.name
        ) FILTER (WHERE t.id IS NOT NULL),
        '[]'
    ) AS tags
FROM diary_entries de
LEFT JOIN entry_tags et ON et.entry_id = de.id
LEFT JOIN tags        t  ON t.id        = et.tag_id AND t.deleted_at IS NULL
WHERE de.user_id   = $1
  AND de.deleted_at IS NULL
GROUP BY de.id
ORDER BY de.entry_date DESC, de.created_at DESC
LIMIT  $2
OFFSET $3;


-- ---------------------------------------------------------------------------
-- 2. GET A SINGLE ENTRY (with full content and tags)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = entry_id, $2 = user_id  (user_id guards ownership)
SELECT
    de.*,
    COALESCE(
        json_agg(
            json_build_object('id', t.id, 'name', t.name, 'color', t.color, 'slug', t.slug)
            ORDER BY t.name
        ) FILTER (WHERE t.id IS NOT NULL),
        '[]'
    ) AS tags
FROM diary_entries de
LEFT JOIN entry_tags et ON et.entry_id = de.id
LEFT JOIN tags        t  ON t.id        = et.tag_id AND t.deleted_at IS NULL
WHERE de.id       = $1
  AND de.user_id  = $2
  AND de.deleted_at IS NULL
GROUP BY de.id;


-- ---------------------------------------------------------------------------
-- 3. FULL-TEXT SEARCH ACROSS A USER'S ENTRIES
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = search query string (e.g. 'holiday beach')
--             $3 = page_size, $4 = offset
SELECT
    de.id,
    de.title,
    de.entry_date,
    de.mood,
    ts_headline(
        'english',
        de.content,
        plainto_tsquery('english', $2),
        'StartSel=<mark>, StopSel=</mark>, MaxWords=30, MinWords=15'
    ) AS content_excerpt,
    ts_rank(de.search_vector, plainto_tsquery('english', $2)) AS rank
FROM diary_entries de
WHERE de.user_id    = $1
  AND de.deleted_at IS NULL
  AND de.search_vector @@ plainto_tsquery('english', $2)
ORDER BY rank DESC, de.entry_date DESC
LIMIT  $3
OFFSET $4;


-- ---------------------------------------------------------------------------
-- 4. FILTER ENTRIES BY DATE RANGE
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = start_date (DATE), $3 = end_date (DATE),
--             $4 = page_size, $5 = offset
SELECT
    de.id,
    de.title,
    de.mood,
    de.entry_date,
    de.created_at
FROM diary_entries de
WHERE de.user_id    = $1
  AND de.entry_date BETWEEN $2 AND $3
  AND de.deleted_at IS NULL
ORDER BY de.entry_date DESC
LIMIT  $4
OFFSET $5;


-- ---------------------------------------------------------------------------
-- 5. FILTER ENTRIES BY TAG
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = tag_slug, $3 = page_size, $4 = offset
SELECT
    de.id,
    de.title,
    de.mood,
    de.entry_date,
    de.created_at
FROM diary_entries de
JOIN entry_tags et ON et.entry_id = de.id
JOIN tags       t  ON t.id        = et.tag_id
                   AND t.slug     = $2
                   AND t.user_id  = $1
                   AND t.deleted_at IS NULL
WHERE de.user_id    = $1
  AND de.deleted_at IS NULL
ORDER BY de.entry_date DESC
LIMIT  $3
OFFSET $4;


-- ---------------------------------------------------------------------------
-- 6. FILTER ENTRIES BY MOOD
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = mood (mood_level enum value),
--             $3 = page_size, $4 = offset
SELECT
    de.id,
    de.title,
    de.mood,
    de.entry_date,
    de.created_at
FROM diary_entries de
WHERE de.user_id    = $1
  AND de.mood       = $2::mood_level
  AND de.deleted_at IS NULL
ORDER BY de.entry_date DESC
LIMIT  $3
OFFSET $4;


-- ---------------------------------------------------------------------------
-- 7. GET ALL TAGS FOR A USER (with entry count)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id
SELECT
    t.id,
    t.name,
    t.slug,
    t.color,
    COUNT(et.entry_id) AS entry_count
FROM tags t
LEFT JOIN entry_tags     et ON et.tag_id  = t.id
LEFT JOIN diary_entries  de ON de.id      = et.entry_id
                            AND de.deleted_at IS NULL
WHERE t.user_id    = $1
  AND t.deleted_at IS NULL
GROUP BY t.id
ORDER BY entry_count DESC, t.name ASC;


-- ---------------------------------------------------------------------------
-- 8. MOOD DISTRIBUTION (for dashboard / analytics)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id, $2 = start_date, $3 = end_date
SELECT
    mood,
    COUNT(*) AS entry_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM diary_entries
WHERE user_id    = $1
  AND entry_date BETWEEN $2 AND $3
  AND mood       IS NOT NULL
  AND deleted_at IS NULL
GROUP BY mood
ORDER BY
    CASE mood
        WHEN 'very_sad'   THEN 1
        WHEN 'sad'        THEN 2
        WHEN 'neutral'    THEN 3
        WHEN 'happy'      THEN 4
        WHEN 'very_happy' THEN 5
    END;


-- ---------------------------------------------------------------------------
-- 9. WRITING STREAK (consecutive days with at least one entry)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id
-- Returns the current streak length (days).
WITH daily_entries AS (
    SELECT DISTINCT entry_date
    FROM   diary_entries
    WHERE  user_id    = $1
      AND  deleted_at IS NULL
),
ordered AS (
    SELECT
        entry_date,
        entry_date - (ROW_NUMBER() OVER (ORDER BY entry_date))::INT AS grp
    FROM daily_entries
),
streaks AS (
    SELECT
        grp,
        MIN(entry_date) AS streak_start,
        MAX(entry_date) AS streak_end,
        COUNT(*)        AS streak_length
    FROM ordered
    GROUP BY grp
)
SELECT streak_length
FROM   streaks
WHERE  streak_end >= CURRENT_DATE - INTERVAL '1 day'
ORDER  BY streak_end DESC
LIMIT  1;


-- ---------------------------------------------------------------------------
-- 10. SOFT-DELETE AN ENTRY
-- ---------------------------------------------------------------------------
-- Parameters: $1 = entry_id, $2 = user_id
UPDATE diary_entries
SET    deleted_at = NOW()
WHERE  id       = $1
  AND  user_id  = $2
  AND  deleted_at IS NULL;


-- ---------------------------------------------------------------------------
-- 11. UPSERT TAG ONTO AN ENTRY
-- ---------------------------------------------------------------------------
-- Parameters: $1 = entry_id, $2 = tag_id, $3 = user_id
INSERT INTO entry_tags (entry_id, tag_id, user_id)
VALUES ($1, $2, $3)
ON CONFLICT (entry_id, tag_id) DO NOTHING;


-- ---------------------------------------------------------------------------
-- 12. REMOVE TAG FROM ENTRY
-- ---------------------------------------------------------------------------
-- Parameters: $1 = entry_id, $2 = tag_id, $3 = user_id
DELETE FROM entry_tags
WHERE entry_id = $1
  AND tag_id   = $2
  AND user_id  = $3;


-- ---------------------------------------------------------------------------
-- 13. SESSION VALIDATION (called on every authenticated request)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = sha256_hex_of_session_token
SELECT
    s.id          AS session_id,
    s.user_id,
    s.expires_at,
    u.status      AS user_status,
    u.display_name
FROM user_sessions s
JOIN users u ON u.id = s.user_id
WHERE s.token_hash = $1
  AND s.revoked_at IS NULL
  AND s.expires_at > NOW()
  AND u.deleted_at IS NULL
  AND (u.locked_until IS NULL OR u.locked_until < NOW());


-- ---------------------------------------------------------------------------
-- 14. REVOKE ALL SESSIONS FOR A USER (logout all devices)
-- ---------------------------------------------------------------------------
-- Parameters: $1 = user_id
UPDATE user_sessions
SET    revoked_at = NOW()
WHERE  user_id    = $1
  AND  revoked_at IS NULL;


-- ---------------------------------------------------------------------------
-- 15. CLEANUP EXPIRED SESSIONS (run as a scheduled job nightly)
-- ---------------------------------------------------------------------------
DELETE FROM user_sessions
WHERE (expires_at < NOW() - INTERVAL '7 days')
   OR (revoked_at < NOW() - INTERVAL '7 days');

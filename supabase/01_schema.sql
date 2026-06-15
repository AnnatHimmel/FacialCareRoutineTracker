-- ============================================================
-- Skincare Tracker — Schema
-- Run this first in the Supabase SQL editor.
-- ============================================================

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id          TEXT    PRIMARY KEY,
  name_he     TEXT    NOT NULL,
  name_en     TEXT,
  sort_order  INT     NOT NULL,
  icon        TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

-- Master products
CREATE TABLE IF NOT EXISTS master_products (
  id                   TEXT    PRIMARY KEY,
  brand                TEXT,
  name                 TEXT    NOT NULL,
  image_url            TEXT,
  comment_he           TEXT,
  comment_en           TEXT,
  category_id          TEXT    NOT NULL REFERENCES categories(id),
  morning_order        INT,
  morning_frequency    TEXT,
  morning_max_per_week INT,
  evening_order        INT,
  evening_frequency    TEXT,
  evening_max_per_week INT,
  is_deprecated        BOOLEAN NOT NULL DEFAULT FALSE,
  added_in_version     TEXT    NOT NULL DEFAULT '1.0.0'
);

-- Incompatibility rules
CREATE TABLE IF NOT EXISTS incompatibility_rules (
  id            TEXT PRIMARY KEY,
  entity_a_type TEXT NOT NULL,
  entity_a_id   TEXT NOT NULL,
  entity_b_type TEXT NOT NULL,
  entity_b_id   TEXT NOT NULL,
  scope         TEXT NOT NULL,
  reason_he     TEXT,
  reason_en     TEXT
);

-- Single-row version & changelog store
CREATE TABLE IF NOT EXISTS content_metadata (
  id              INT   PRIMARY KEY DEFAULT 1,
  content_version TEXT  NOT NULL,
  app_version     TEXT  NOT NULL,
  changelog_json  JSONB NOT NULL DEFAULT '[]'
);

-- ── Row Level Security (public read, no anonymous writes) ──────────────────

ALTER TABLE categories            ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_products       ENABLE ROW LEVEL SECURITY;
ALTER TABLE incompatibility_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_metadata      ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_read" ON categories            FOR SELECT TO anon USING (TRUE);
CREATE POLICY "anon_read" ON master_products       FOR SELECT TO anon USING (TRUE);
CREATE POLICY "anon_read" ON incompatibility_rules FOR SELECT TO anon USING (TRUE);
CREATE POLICY "anon_read" ON content_metadata      FOR SELECT TO anon USING (TRUE);

-- ── Single-RPC function ────────────────────────────────────────────────────
-- Returns all content as one JSON object matching the Flutter parser's
-- expected shape. Call via: supabase.client.rpc('get_master_content')

CREATE OR REPLACE FUNCTION get_master_content()
RETURNS JSON
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT json_build_object(
    'contentVersion', m.content_version,
    'appVersion',     m.app_version,
    'changelog',      m.changelog_json,
    'categories', (
      SELECT COALESCE(json_agg(json_build_object(
        'id',    c.id,
        'name',  json_build_object('he', c.name_he, 'en', c.name_en),
        'order', c.sort_order,
        'icon',  c.icon
      ) ORDER BY c.sort_order), '[]'::json)
      FROM categories c WHERE c.is_active = TRUE
    ),
    'products', (
      SELECT COALESCE(json_agg(json_build_object(
        'id',             p.id,
        'brand',          p.brand,
        'name',           p.name,
        'imageAsset',     p.image_url,
        'comment',        json_build_object('he', p.comment_he, 'en', p.comment_en),
        'categoryId',     p.category_id,
        'isDeprecated',   p.is_deprecated,
        'addedInVersion', p.added_in_version,
        'morningConfig',  CASE WHEN p.morning_order IS NOT NULL THEN
          json_build_object(
            'order', p.morning_order,
            'frequency', CASE p.morning_frequency
              WHEN 'weeklyMax' THEN json_build_object('type', 'weeklyMax', 'maxPerWeek', p.morning_max_per_week)
              ELSE json_build_object('type', 'daily')
            END
          )
          ELSE NULL END,
        'eveningConfig',  CASE WHEN p.evening_order IS NOT NULL THEN
          json_build_object(
            'order', p.evening_order,
            'frequency', CASE p.evening_frequency
              WHEN 'weeklyMax' THEN json_build_object('type', 'weeklyMax', 'maxPerWeek', p.evening_max_per_week)
              ELSE json_build_object('type', 'daily')
            END
          )
          ELSE NULL END
      )), '[]'::json)
      FROM master_products p
    ),
    'rules', (
      SELECT COALESCE(json_agg(json_build_object(
        'id',      r.id,
        'entityA', json_build_object('type', r.entity_a_type, 'id', r.entity_a_id),
        'entityB', json_build_object('type', r.entity_b_type, 'id', r.entity_b_id),
        'scope',   r.scope,
        'reason',  json_build_object('he', r.reason_he, 'en', r.reason_en)
      )), '[]'::json)
      FROM incompatibility_rules r
    )
  )
  FROM content_metadata m
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION get_master_content() TO anon;

-- ── Verify ─────────────────────────────────────────────────────────────────
-- After running 02_seed.sql, confirm the RPC works:
-- SELECT get_master_content();

-- ============================================================
-- Skincare Tracker — Migration 05: remove added_in_version
-- Removes the `added_in_version` column from master_products
-- and drops it from the get_master_content() RPC response.
--
-- DEFERRED — run in the Supabase SQL editor at the next app
-- release, AFTER the new app build that no longer requires
-- addedInVersion is live. Running it earlier will soft-degrade
-- existing installed clients to bundled content.
--
-- Safe to re-run (idempotent: CREATE OR REPLACE FUNCTION,
-- DROP COLUMN IF EXISTS).
-- ============================================================

-- 1) RPC — same as 04_add_barcodes.sql, with 'addedInVersion' removed ────────
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
        'ingredients',    COALESCE(p.ingredients, '[]'::jsonb),
        'barcodes',       COALESCE(p.barcodes, '[]'::jsonb),
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

-- 2) Drop column ──────────────────────────────────────────────────────────────
ALTER TABLE master_products DROP COLUMN IF EXISTS added_in_version;

-- ── Verify ─────────────────────────────────────────────────────────────────
-- SELECT get_master_content()->'products'->0;
-- The returned object should have no 'addedInVersion' key.

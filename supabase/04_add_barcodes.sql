-- ============================================================
-- Skincare Tracker — Migration 04: product barcodes
-- Adds the `barcodes` column to master_products, backfills it
-- for 24 confirmed products, and updates get_master_content()
-- to return it.
--
-- Run this in the Supabase SQL editor AFTER 03_add_ingredients.sql.
-- Safe to re-run (idempotent: ADD COLUMN IF NOT EXISTS, UPDATEs
-- overwrite, CREATE OR REPLACE FUNCTION).
-- ============================================================

-- 1) Column ─────────────────────────────────────────────────────────────────
ALTER TABLE master_products
  ADD COLUMN IF NOT EXISTS barcodes JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 2) Backfill ────────────────────────────────────────────────────────────────
-- Barcodes sourced from OpenBeautyFacts, INCI Beauty, Barcode Spider,
-- UPC Item DB, and YesStyle product pages.
UPDATE master_products SET barcodes = '["8809782555508"]'::jsonb WHERE id = 'prod-007';
UPDATE master_products SET barcodes = '["8809481760678"]'::jsonb WHERE id = 'prod-008';
UPDATE master_products SET barcodes = '["8809481760722"]'::jsonb WHERE id = 'prod-009';
UPDATE master_products SET barcodes = '["8806390500050"]'::jsonb WHERE id = 'prod-011';
UPDATE master_products SET barcodes = '["8809563102600"]'::jsonb WHERE id = 'prod-012';
UPDATE master_products SET barcodes = '["8809728080071"]'::jsonb WHERE id = 'prod-014';
UPDATE master_products SET barcodes = '["8809506310406"]'::jsonb WHERE id = 'prod-015';
UPDATE master_products SET barcodes = '["8809875906477"]'::jsonb WHERE id = 'prod-016';
UPDATE master_products SET barcodes = '["8809800940880"]'::jsonb WHERE id = 'prod-017';
UPDATE master_products SET barcodes = '["8809968130277"]'::jsonb WHERE id = 'prod-019';
UPDATE master_products SET barcodes = '["8809655952236"]'::jsonb WHERE id = 'prod-021';
UPDATE master_products SET barcodes = '["030985038514"]'::jsonb   WHERE id = 'prod-025';
UPDATE master_products SET barcodes = '["8809240318126"]'::jsonb WHERE id = 'prod-026';
UPDATE master_products SET barcodes = '["8809581074767"]'::jsonb WHERE id = 'prod-028';
UPDATE master_products SET barcodes = '["8809572891328"]'::jsonb WHERE id = 'prod-029';
UPDATE master_products SET barcodes = '["8809640734526"]'::jsonb WHERE id = 'prod-030';
UPDATE master_products SET barcodes = '["8809525249565"]'::jsonb WHERE id = 'prod-031';
UPDATE master_products SET barcodes = '["8809960356620"]'::jsonb WHERE id = 'prod-032';
UPDATE master_products SET barcodes = '["8809532221707"]'::jsonb WHERE id = 'prod-033';
UPDATE master_products SET barcodes = '["8809968130239"]'::jsonb WHERE id = 'prod-034';
UPDATE master_products SET barcodes = '["8809598455658"]'::jsonb WHERE id = 'prod-035';
UPDATE master_products SET barcodes = '["8800256108053"]'::jsonb WHERE id = 'prod-036';
UPDATE master_products SET barcodes = '["0769915190946"]'::jsonb WHERE id = 'prod-037';
UPDATE master_products SET barcodes = '["8809738316146"]'::jsonb WHERE id = 'prod-038';

-- 3) RPC ─────────────────────────────────────────────────────────────────────
-- Same as 03_add_ingredients.sql's get_master_content(), with 'barcodes' added.
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

-- ── Verify ─────────────────────────────────────────────────────────────────
-- SELECT id, barcodes FROM master_products ORDER BY id;
-- SELECT (get_master_content() -> 'products' -> 0 -> 'barcodes');

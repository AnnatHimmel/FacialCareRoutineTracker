-- ============================================================
-- Skincare Tracker — Migration 03: product ingredients
-- Adds the `ingredients` column to master_products, backfills it
-- for every product (matching assets/data/master_products.json),
-- and updates get_master_content() to return it.
--
-- Run this in the Supabase SQL editor AFTER 01_schema.sql + 02_seed.sql.
-- Safe to re-run (idempotent: ADD COLUMN IF NOT EXISTS, UPDATEs overwrite,
-- CREATE OR REPLACE FUNCTION).
-- ============================================================

-- 1) Column ───────────────────────────────────────────────────────────────────
-- Stored as a JSONB array of strings, e.g. '["Niacinamide","Panthenol"]'.
-- The Flutter parser reads m['ingredients'] as List<dynamic>? and casts to
-- List<String>, defaulting to [] when absent — so NULL/empty is harmless.
ALTER TABLE master_products
  ADD COLUMN IF NOT EXISTS ingredients JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 2) Backfill ─────────────────────────────────────────────────────────────────
-- Generated from assets/data/master_products.json (single source of truth),
-- so the bundled/offline data and the Supabase data stay identical.
UPDATE master_products SET ingredients = '["Glycerin","Cocamidopropyl Betaine","Panthenol","Allantoin","Sodium Hyaluronate"]'::jsonb WHERE id = 'prod-039';
UPDATE master_products SET ingredients = '["Rice Extract","Lactobacillus Ferment","Niacinamide","Zinc Oxide","Panthenol"]'::jsonb WHERE id = 'prod-007';
UPDATE master_products SET ingredients = '["Sunflower Seed Oil","Shea Butter","Vitamin E","Glycerin","Beeswax"]'::jsonb WHERE id = 'prod-008';
UPDATE master_products SET ingredients = '["Glycerin","Cocamidopropyl Betaine","Green Tea Extract","Panthenol","Allantoin"]'::jsonb WHERE id = 'prod-009';
UPDATE master_products SET ingredients = '["Marula Oil (Sclerocarya Birrea)","Vitamin E (Tocopherol)","Oleic Acid","Squalane","Omega-9 Fatty Acids"]'::jsonb WHERE id = 'prod-010';
UPDATE master_products SET ingredients = '["Ceramide NP","Panthenol","Glycerin","Shea Butter","Madecassoside"]'::jsonb WHERE id = 'prod-011';
UPDATE master_products SET ingredients = '["Tinosorb S (Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine)","Uvinul A Plus","Niacinamide","Glycerin","Panthenol"]'::jsonb WHERE id = 'prod-012';
UPDATE master_products SET ingredients = '["Houttuynia Cordata (Heartleaf) Extract","Centella Asiatica Extract","Panthenol","Glycerin","Ceramide NP"]'::jsonb WHERE id = 'prod-013';
UPDATE master_products SET ingredients = '["Tea Tree Leaf Oil","Centella Asiatica Extract","Salicylic Acid","Niacinamide","Panthenol"]'::jsonb WHERE id = 'prod-014';
UPDATE master_products SET ingredients = '["Squalane","Glycerin","Hyaluronic Acid","Panthenol","Ceramide NP"]'::jsonb WHERE id = 'prod-015';
UPDATE master_products SET ingredients = '["Ascorbic Acid (Vitamin C)","Centella Asiatica Extract","Niacinamide","Vitamin E (Tocopherol)","Glycerin"]'::jsonb WHERE id = 'prod-016';
UPDATE master_products SET ingredients = '["Glycolic Acid (AHA)","Salicylic Acid (BHA)","Gluconolactone (PHA)","Lactobionic Acid (LHA)","Niacinamide"]'::jsonb WHERE id = 'prod-017';
UPDATE master_products SET ingredients = '["Centella Asiatica Extract","Madecassoside","Panthenol","Glycerin","Ceramide NP"]'::jsonb WHERE id = 'prod-018';
UPDATE master_products SET ingredients = '["Rice Extract","Panthenol (Vitamin B5)","Niacinamide","Zinc Oxide","Glycerin"]'::jsonb WHERE id = 'prod-019';
UPDATE master_products SET ingredients = '["Azelaic Acid 20%","Glycerin","Panthenol","Niacinamide","Allantoin"]'::jsonb WHERE id = 'prod-020';
UPDATE master_products SET ingredients = '["Niacinamide 20%","Zinc PCA","Panthenol","Glycerin","Hyaluronic Acid"]'::jsonb WHERE id = 'prod-021';
UPDATE master_products SET ingredients = '["L-Glutathione (Liposomal)","Niacinamide","Ascorbic Acid (Vitamin C)","Glycerin","Panthenol"]'::jsonb WHERE id = 'prod-022';
UPDATE master_products SET ingredients = '["Tranexamic Acid 15%","Niacinamide","Glycerin","Panthenol","Hyaluronic Acid"]'::jsonb WHERE id = 'prod-023';
UPDATE master_products SET ingredients = '["PDRN (Polydeoxyribonucleotide) 3%","Adenosine","Hyaluronic Acid","Panthenol","Glycerin"]'::jsonb WHERE id = 'prod-024';
UPDATE master_products SET ingredients = '["Salicylic Acid","Tea Tree Leaf Oil","Niacinamide","Willow Bark Extract","Glycerin"]'::jsonb WHERE id = 'prod-025';
UPDATE master_products SET ingredients = '["Azelaic Acid 15%","Panthenol","Niacinamide","Glycerin","Allantoin"]'::jsonb WHERE id = 'prod-026';
UPDATE master_products SET ingredients = '["Ectoin","Panthenol","Glycerin","Ceramide NP","Allantoin"]'::jsonb WHERE id = 'prod-027';
UPDATE master_products SET ingredients = '["Rice Extract","Niacinamide","Glycerin","Inositol","Ferulic Acid"]'::jsonb WHERE id = 'prod-028';
UPDATE master_products SET ingredients = '["Retinal (Retinaldehyde)","Bakuchiol","Squalane","Vitamin E (Tocopherol)","Panthenol"]'::jsonb WHERE id = 'prod-029';
UPDATE master_products SET ingredients = '["Niacinamide 10%","Tranexamic Acid 4%","Panthenol","Glycerin","Hyaluronic Acid"]'::jsonb WHERE id = 'prod-030';
UPDATE master_products SET ingredients = '["Ginseng Extract","Niacinamide","Glycerin","Honey Extract","Adenosine"]'::jsonb WHERE id = 'prod-031';
UPDATE master_products SET ingredients = '["Retinol (Vitamin A)","Squalane","Vitamin E (Tocopherol)","Panthenol","Hyaluronic Acid"]'::jsonb WHERE id = 'prod-032';
UPDATE master_products SET ingredients = '["Fermented Black Rice Extract","Niacinamide","Zinc Oxide","Glycerin","Panthenol"]'::jsonb WHERE id = 'prod-033';
UPDATE master_products SET ingredients = '["Rice Extract","Niacinamide","Glycerin","Panthenol","Beta-Glucan"]'::jsonb WHERE id = 'prod-034';
UPDATE master_products SET ingredients = '["Retinal (Retinaldehyde)","Ginseng Extract","Niacinamide","Adenosine","Panthenol"]'::jsonb WHERE id = 'prod-038';
UPDATE master_products SET ingredients = '["Copper Tripeptide-1","Hexapeptide-11","Niacinamide","Adenosine","Glycerin"]'::jsonb WHERE id = 'prod-035';
UPDATE master_products SET ingredients = '["PDRN (Polydeoxyribonucleotide)","Copper Tripeptide-1","Niacinamide","Adenosine","Panthenol"]'::jsonb WHERE id = 'prod-036';
UPDATE master_products SET ingredients = '["Argireline (Acetyl Hexapeptide-3) 10%","Leuphasyl","Hyaluronic Acid","Glycerin","Panthenol"]'::jsonb WHERE id = 'prod-037';

-- 3) RPC ──────────────────────────────────────────────────────────────────────
-- Same as 01_schema.sql's get_master_content(), with 'ingredients' added to the
-- product object. The Flutter serializer (_parseProduct) reads this key.
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
-- SELECT id, ingredients FROM master_products ORDER BY id;
-- SELECT (get_master_content() -> 'products' -> 0 -> 'ingredients');

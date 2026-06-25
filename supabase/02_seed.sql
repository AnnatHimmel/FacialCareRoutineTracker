-- ============================================================
-- Skincare Tracker — Seed Data
-- Run this AFTER 01_schema.sql.
-- image_url is NULL here; the upload_images.js script fills it in.
-- ============================================================

-- ── Categories ────────────────────────────────────────────────────────────

INSERT INTO categories (id, name_he, name_en, sort_order, icon, is_active) VALUES
  ('cat-cleanser-step1', 'ניקוי שלב 1',   'Cleanse — Step 1',  1, 'soap',         TRUE),
  ('cat-cleanser-step2', 'ניקוי שלב 2',   'Cleanse — Step 2',  2, 'bubble_chart', TRUE),
  ('cat-toner',          'טונר / אסנס',    'Toner / Essence',   3, 'water_drop',   TRUE),
  ('cat-retinoid',       'רטינואידים',     'Retinoid',          4, 'science',      TRUE),
  ('cat-serum',          'סרום',           'Serum / Active',    5, 'auto_awesome', TRUE),
  ('cat-moisturizer',    'לחות',           'Moisturizer',       6, 'opacity',      TRUE),
  ('cat-oil',            'שמנים',          'Face Oil',          7, 'spa',          TRUE),
  ('cat-spf',            'הגנה',           'Protect (SPF)',     8, 'wb_sunny',     TRUE)
ON CONFLICT (id) DO NOTHING;

-- ── Products ──────────────────────────────────────────────────────────────
-- image_url is NULL — filled in by admin/upload_images.js after image upload.

INSERT INTO master_products
  (id, brand, name, image_url, comment_he, comment_en, category_id,
   morning_order, morning_frequency, morning_max_per_week,
   evening_order, evening_frequency, evening_max_per_week,
   is_deprecated, added_in_version)
VALUES

  ('prod-039', NULL, 'Generic Cleansing Gel', NULL,
   E'ג\'ל ניקוי פנים עדין על בסיס מים לניקוי יסודי של העור, הסרת שאריות לכלוך ורענון מבלי לייבש',
   'Gentle water-based facial cleansing gel for thorough cleansing, removing dirt residue and refreshing without drying',
   'cat-cleanser-step2',
   NULL, NULL, NULL, 0, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-007', 'Beauty of Joseon', 'Relief Sun: Rice + Probiotics', NULL,
   'קרם הגנה קוריאני קל ומרגיע עם אורז ופרוביוטיקה, SPF50+ PA+++',
   'Lightweight, soothing Korean sunscreen with rice and probiotics, SPF50+ PA+++',
   'cat-spf',
   20, 'weeklyMax', 3, NULL, NULL, NULL,
   FALSE, '1.0.0'),

  ('prod-008', 'Heimish', 'All Clean Balm', NULL,
   'באלם ניקוי להסרת איפור ומסנני הגנה',
   'Cleansing balm for removing makeup and sunscreen',
   'cat-cleanser-step1',
   NULL, NULL, NULL, 0, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-009', 'Heimish', 'All Clean Green Foam', NULL,
   'סבון פנים עדין ומאזן לחומציות מומלצת',
   'Gentle, pH-balancing facial cleanser',
   'cat-cleanser-step2',
   NULL, NULL, NULL, 1, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-010', 'MarulaLab', 'Anti-Aging Marula Oil', NULL,
   E'שמן מרולה טהור להזנה מוגברת ואנטי אייג\'ינג',
   'Pure marula oil for intensive nourishment and anti-aging',
   'cat-oil',
   NULL, NULL, NULL, 25, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-011', 'ILLIYOON', 'Ceramide Ato Concentrate Cream', NULL,
   'קרם לחות עשיר בסרמידים לשיקום והרגעת מחסום העור',
   'Ceramide-rich moisturizer for repairing and soothing the skin barrier',
   'cat-moisturizer',
   19, 'daily', NULL, 24, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-012', 'Purito SEOUL', 'Daily Soft Touch Sunscreen', NULL,
   'קרם הגנה לחותי במרקם קל ונעים לשימוש יומיומי',
   'Moisturizing sunscreen with a light, pleasant texture for daily use',
   'cat-spf',
   23, 'daily', NULL, NULL, NULL, NULL,
   FALSE, '1.0.0'),

  ('prod-013', 'AXIS-Y', 'Heartleaf My-Type Calming Cream', NULL,
   'קרם לחות קליל ומרגיע עם הארטליף להפחתת אדמומיות',
   'Light, calming moisturizer with heartleaf extract to reduce redness',
   'cat-moisturizer',
   17, 'daily', NULL, 21, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-014', 'iUNIK', 'Tea Tree Relief Serum', NULL,
   'סרום עץ התה להרגעה, איזון והפחתת פגמים בעור',
   'Tea tree serum for soothing, balancing, and reducing blemishes',
   'cat-serum',
   11, 'daily', NULL, 14, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-015', 'S.NATURE', 'Aqua Squalane Moisturizing Cream', NULL,
   'קרם לחות עשיר בסקוואלן להזנה, ריכוך ושמירה על לחות העור',
   'Squalane-rich moisturizer for nourishing, softening, and maintaining skin hydration',
   'cat-moisturizer',
   18, 'daily', NULL, 22, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-016', 'Beauty of Joseon', 'Light On Serum Centella + Vita C', NULL,
   'סרום ויטמין C וסנטלה להבהרה, האחדת גוון העור והגנה אנטיאוקסידנטית',
   'Vitamin C and centella serum for brightening, evening skin tone, and antioxidant protection',
   'cat-serum',
   4, 'daily', NULL, NULL, NULL, NULL,
   FALSE, '1.0.0'),

  ('prod-017', 'Isntree', 'Hyper Acid 4 AHA BHA PHA LHA 30 Serum', NULL,
   'סרום פילינג עוצמתי המשלב 4 חומצות לחידוש מרקם העור, ניקוי נקבוביות והבהרה',
   'Powerful exfoliating serum combining 4 acids for skin texture renewal, pore cleansing, and brightening',
   'cat-serum',
   NULL, NULL, NULL, 18, 'weeklyMax', 3,
   FALSE, '1.0.0'),

  ('prod-018', 'Dr.Jart+', 'Cicapair Intensive Soothing Repair Treatment Lotion', NULL,
   'תחליב טיפולי אינטנסיבי להרגעה מהירה, שיקום מחסום העור והפחתת אדמומיות עם קומפלקס סינטלה',
   'Intensive treatment lotion for rapid soothing, skin barrier repair, and redness reduction with centella complex',
   'cat-moisturizer',
   14, 'daily', NULL, 23, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-019', 'Beauty of Joseon', 'Relief Sun Aqua Fresh Rice+B5', NULL,
   'קרם הגנה קליל במרקם קל ומרענן, מועשר באורז וויטמין B5 להגנה ולחות מוגברת',
   'Lightweight, refreshing sunscreen enriched with rice and vitamin B5 for protection and enhanced hydration',
   'cat-spf',
   21, 'daily', NULL, NULL, NULL, NULL,
   FALSE, '1.0.0'),

  ('prod-020', 'Kisocare', 'Azelaic Acid Cream 20%', NULL,
   'קרם טיפולי פעיל בריכוז 20% חומצה אזלאית להבהרת כתמים, טיפול בפגמי עור ושיפור מרקם העור',
   'Active treatment cream with 20% azelaic acid for brightening dark spots, treating blemishes, and improving skin texture',
   'cat-serum',
   6, 'daily', NULL, 9, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-021', 'JUMISO', 'Niacinamide 20 Serum', NULL,
   'סרום פעיל בריכוז 20% ניאצינמיד להבהרה, איזון סבום, כיווץ נקבוביות ושיפור מרקם העור',
   'Active serum with 20% niacinamide for brightening, sebum control, pore minimizing, and skin texture improvement',
   'cat-serum',
   9, 'daily', NULL, 12, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-022', 'PURCELL', '88B/mL L-Glutathione Flexible Liposome', NULL,
   'סרום אנטיאוקסידנטי מתקדם עם גלוטתיון ליפוזומלי להבהרה, הגנה מפני רדיקלים חופשיים והאחדת גוון העור',
   'Advanced antioxidant serum with liposomal glutathione for brightening, free radical protection, and evening skin tone',
   'cat-toner',
   0, 'daily', NULL, 4, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-023', 'Cos De BAHA', 'T15 Serum', NULL,
   'סרום טיפולי פעיל בריכוז 15% חומצה טרנקסמית להבהרת פיגמנטציה, טיפול בכתמי עור עקשניים והאחדת גוון העור',
   'Active treatment serum with 15% tranexamic acid for fading pigmentation, treating stubborn dark spots, and evening skin tone',
   'cat-serum',
   8, 'daily', NULL, 11, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-024', 'Genabelle', 'PDRN 3% Hyper Boost Ampoule', NULL,
   'אמפולה טיפולית מרוכזת עם 3% PDRN לשיקום עמוק, שיפור אלסטיות העור, עידוד התחדשות התאים וחיזוק מחסום העור',
   'Concentrated treatment ampoule with 3% PDRN for deep repair, improving skin elasticity, stimulating cell renewal, and strengthening the skin barrier',
   'cat-serum',
   12, 'daily', NULL, 15, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-025', 'DERMA E', 'Acne Blemish Control Treatment Serum', NULL,
   'סרום טיפולי לעור מעורב עד שמן, מסייע במניעה וטיפול בפגמי עור, ניקוי נקבוביות והאיזון בלוטות החלב',
   'Treatment serum for combination to oily skin; helps prevent and treat blemishes, cleanse pores, and balance sebaceous glands',
   'cat-serum',
   NULL, NULL, NULL, 17, 'weeklyMax', 3,
   FALSE, '1.0.0'),

  ('prod-026', 'Cos De BAHA', 'AZ15 Serum', NULL,
   'סרום טיפולי המכיל 15% חומצה אזלאית להרגעת אדמומיות, טיפול בדלקתיות ועור מגורה, והבהרת פגמי עור',
   'Treatment serum with 15% azelaic acid for calming redness, treating inflammation and irritated skin, and brightening blemishes',
   'cat-serum',
   7, 'daily', NULL, 10, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-027', 'boben', 'Ectoin Moisturizing Soothing Sensitivity Repair Cream', NULL,
   'קרם לחות טיפולי משקם להרגעת עור רגיש ומגורה, חיזוק מחסום העור והפחתת רגישות בעזרת אקטואין',
   'Restorative treatment moisturizer for soothing sensitive and irritated skin, strengthening the skin barrier, and reducing sensitivity with ectoin',
   'cat-moisturizer',
   15, 'daily', NULL, 19, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-028', E'I''m from', 'Rice Toner', NULL,
   'טונר אורז עשיר להזנה אינטנסיבית, הבהרה, והענקת מראה חיוני וקורן לעור',
   'Rich rice toner for intensive nourishment, brightening, and a healthy, radiant complexion',
   'cat-toner',
   1, 'daily', NULL, 5, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-029', 'By Wishtrend', 'Vitamin A-mazing Bakuchiol Night Cream', NULL,
   E'קרם לילה טיפולי המשלב רטינאל ובקוצ''יול לחידוש אינטנסיבי של תאי העור, טשטוש קמטוטים ושיפור מוצקות העור ללא גירוי',
   'Treatment night cream combining retinal and bakuchiol for intensive skin cell renewal, softening fine lines, and improving firmness without irritation',
   'cat-retinoid',
   NULL, NULL, NULL, 2, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-030', 'Anua', 'Niacinamide 10% + TXA 4% Serum', NULL,
   'סרום מתקדם המשלב 10% ניאצינמיד ו-4% חומצה טרנקסמית להבהרה עוצמתית של פיגמנטציה, טשטוש כתמים כהים והאחדת גוון העור',
   'Advanced serum combining 10% niacinamide and 4% tranexamic acid for powerful pigmentation brightening, fading dark spots, and evening skin tone',
   'cat-serum',
   10, 'daily', NULL, 13, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-031', 'Beauty of Joseon', 'Dynasty Cream', NULL,
   E'קרם לחות עשיר ומזין המבוסס על רכיבים קוריאניים מסורתיים להזנה עמוקה, הבהרה וחיזוק מחסום הלחות של העור',
   E'Rich, nourishing moisturizer based on traditional Korean ingredients for deep nourishment, brightening, and strengthening the skin''s moisture barrier',
   'cat-moisturizer',
   16, 'daily', NULL, 20, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-032', 'Medicube', 'Deep Vita A Retinol Serum', NULL,
   'סרום אנטי-אייג''ינג מרוכז עם רטינול (ויטמין A) המסייע בצמצום מראה קמטים, מיצוק העור, שיפור האלסטיות וחידוש המרקם יחד עם הזנה עמוקה',
   'Concentrated anti-aging serum with retinol (Vitamin A) that helps reduce the appearance of wrinkles, firm the skin, improve elasticity, and renew texture with deep nourishment',
   'cat-retinoid',
   NULL, NULL, NULL, 3, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-033', 'haruharu wonder', 'Black Rice Moisture Airyfit Sunscreen', NULL,
   'קרם הגנה קליל במרקם אוורירי, מועשר בתמצית אורז שחור מותסס להגנה גבוהה מפני השמש והזנת העור בנוגדי חמצון',
   'Lightweight sunscreen with an airy texture, enriched with fermented black rice extract for high UV protection and antioxidant skin nourishment',
   'cat-spf',
   22, 'daily', NULL, NULL, NULL, NULL,
   FALSE, '1.0.0'),

  ('prod-034', 'Beauty of Joseon', 'Glow Replenishing Rice Milk', NULL,
   'טונר חלבי מזין המבוסס על תמצית אורז להענקת לחות עמוקה, ריכוך מרקם העור ומראה קורן וגלוסי',
   'Nourishing milky toner based on rice extract for deep hydration, skin texture softening, and a radiant, glossy complexion',
   'cat-toner',
   2, 'daily', NULL, 6, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-038', 'Beauty of Joseon', 'Revive Eye Serum Ginseng + Retinal', NULL,
   E'סרום עיניים טיפולי המשלב רטינאל וג''ינסנג לחידוש עדין של עור העיניים, הפחתת מראה קמטוטים ושיפור האלסטיות',
   'Treatment eye serum combining retinal and ginseng for gentle renewal of the eye area, reducing the appearance of fine lines, and improving elasticity',
   'cat-retinoid',
   NULL, NULL, NULL, 0, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-035', 'COSRX', 'The 6 Peptide Skin Booster', NULL,
   'סרום-בוסטר קליל המשלב 6 סוגי פפטידים לשיפור גמישות העור, החלקת מרקם העור, הבהרה והכנת העור לספיגה מיטבית של השלבים הבאים בשגרה',
   'Lightweight serum booster combining 6 types of peptides for improving skin flexibility, smoothing texture, brightening, and preparing skin for optimal absorption of subsequent routine steps',
   'cat-toner',
   3, 'daily', NULL, 7, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-036', 'Medicube', 'PDRN Pink Peptide Serum', NULL,
   'סרום אנטי-אייג''ינג מתקדם המשלב PDRN וקומפלקס פפטידים לשיפור מוצקות וצפיפות העור, הבהרת גוון העור והענקת מראה חיוני וקורן',
   'Advanced anti-aging serum combining PDRN and peptide complex for improving skin firmness and density, brightening skin tone, and a vibrant, radiant appearance',
   'cat-serum',
   13, 'daily', NULL, 16, 'daily', NULL,
   FALSE, '1.0.0'),

  ('prod-037', 'THE ORDINARY', 'Argireline Solution 10%', NULL,
   'תמיסת פפטידים מרוכזת המכילה 10% ארגירלין, המיועדת לטיפול ממוקד במראה קמטי הבעה דינמיים וקמטוטים באזורי המצח ומסביב לעיניים',
   'Concentrated peptide solution containing 10% argireline, designed for targeted treatment of dynamic expression lines and fine wrinkles around the forehead and eyes',
   'cat-serum',
   5, 'daily', NULL, 8, 'daily', NULL,
   FALSE, '1.0.0')

ON CONFLICT (id) DO NOTHING;

-- ── Incompatibility rules ─────────────────────────────────────────────────

INSERT INTO incompatibility_rules
  (id, entity_a_type, entity_a_id, entity_b_type, entity_b_id, scope, reason_he, reason_en)
VALUES
  ('rule-001',
   'product', 'prod-037',
   'product', 'prod-016',
   'withinSlot',
   'שני המוצרים מכילים חומצות פעילות חזקות — שימוש יחד עלול לגרות את העור.',
   'Both products contain strong active acids — using them together may irritate the skin.'),

  ('rule-002',
   'category', 'cat-retinoid',
   'product',  'prod-016',
   'withinSlot',
   'רטינואידים ו-AHA/BHA עלולים לגרום לגירוי יתר ולפגיעה במחסום העור בשימוש יחד.',
   'Retinoids and AHA/BHA may cause over-irritation and damage the skin barrier when used together.')

ON CONFLICT (id) DO NOTHING;

-- ── Content metadata ──────────────────────────────────────────────────────

INSERT INTO content_metadata (id, content_version, app_version, changelog_json)
VALUES (
  1,
  '1.0.0',
  '1.0.0',
  '[{"contentVersion":"1.0.0","changes":["First version"]}]'
)
ON CONFLICT (id) DO UPDATE
  SET content_version = EXCLUDED.content_version,
      app_version     = EXCLUDED.app_version,
      changelog_json  = EXCLUDED.changelog_json;

-- ── Verify ────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM master_products;   -- should be 33
-- SELECT COUNT(*) FROM categories;        -- should be 8
-- SELECT get_master_content();            -- should return full JSON

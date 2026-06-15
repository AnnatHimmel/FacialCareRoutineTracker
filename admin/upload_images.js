/**
 * upload_images.js
 *
 * Uploads all product images to Supabase Storage, then updates the
 * image_url column in master_products for each product.
 *
 * Prerequisites:
 *   - Run 01_schema.sql and 02_seed.sql in Supabase SQL editor first
 *   - Create a public Storage bucket named "product-images" in the
 *     Supabase dashboard (Storage → New bucket → name: product-images, Public: on)
 *
 * Usage:
 *   1. Fill in SUPABASE_URL and SERVICE_ROLE_KEY below
 *   2. cd admin
 *   3. npm install   (first time only)
 *   4. node upload_images.js
 */

const axios = require('axios');
const fs    = require('fs');
const path  = require('path');

// ── Credentials — edit credentials.json at the project root ────────────────
const credsPath = path.join(__dirname, '..', 'credentials.json');
const creds     = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
const SUPABASE_URL     = creds.SUPABASE_URL;
const SERVICE_ROLE_KEY = creds.SUPABASE_SERVICE_ROLE_KEY;
// ────────────────────────────────────────────────────────────────────────────

const BUCKET    = 'product-images';
const IMAGE_DIR = path.join(__dirname, '..', 'assets', 'images', 'products');

// Map each product ID to the filename in assets/images/products/
const PRODUCT_IMAGES = [
  { id: 'prod-039', file: 'generic_cleansing_gel.jpg' },
  { id: 'prod-007', file: 'prod-007.jpg' },
  { id: 'prod-008', file: 'heimish_all_clean_balm.jpg' },
  { id: 'prod-009', file: 'heimish_all_clean_green_foam.jpg' },
  { id: 'prod-010', file: 'marulalab_marula_oil.jpg' },
  { id: 'prod-011', file: 'illiyoon_ceramide_ato_cream.jpg' },
  { id: 'prod-012', file: 'purito_seoul_soft_touch_sunscreen.jpg' },
  { id: 'prod-013', file: 'axis_y_heartleaf_calming_cream.jpg' },
  { id: 'prod-014', file: 'iunik_tea_tree_relief_serum.jpg' },
  { id: 'prod-015', file: 'snature_aqua_squalane_cream.jpg' },
  { id: 'prod-016', file: 'beauty_of_joseon_light_on_serum.jpg' },
  { id: 'prod-017', file: 'isntree_hyper_acid_30_serum.jpg' },
  { id: 'prod-018', file: 'dr_jart_cicapair_treatment_lotion.jpg' },
  { id: 'prod-019', file: 'beauty_of_joseon_relief_sun_aqua_fresh.jpg' },
  { id: 'prod-020', file: 'kisocare_azelaic_acid_cream_20.jpg' },
  { id: 'prod-021', file: 'jumiso_niacinamide_20_serum.jpg' },
  { id: 'prod-022', file: 'purcell_l_glutathione_liposome.jpg' },
  { id: 'prod-023', file: 'cos_de_baha_t15_serum.jpg' },
  { id: 'prod-024', file: 'genabelle_pdrn_hyper_boost_ampoule.jpg' },
  { id: 'prod-025', file: 'derma_e_acne_blemish_control_serum.jpg' },
  { id: 'prod-026', file: 'cos_de_baha_az15_serum.jpg' },
  { id: 'prod-027', file: 'boben_ectoin_sensitivity_repair_cream.jpg' },
  { id: 'prod-028', file: 'im_from_rice_toner.jpg' },
  { id: 'prod-029', file: 'by_wishtrend_vitamin_amazing_bakuchiol_cream.jpg' },
  { id: 'prod-030', file: 'anua_niacinamide_txa_serum.jpg' },
  { id: 'prod-031', file: 'beauty_of_joseon_dynasty_cream.jpg' },
  { id: 'prod-032', file: 'medicube_deep_vita_a_retinol_serum.jpg' },
  { id: 'prod-033', file: 'haruharu_wonder_black_rice_airyfit_sunscreen.jpg' },
  { id: 'prod-034', file: 'beauty_of_joseon_glow_replenishing_rice_milk.jpg' },
  { id: 'prod-035', file: 'cosrx_the_6_peptide_skin_booster.jpg' },
  { id: 'prod-036', file: 'medicube_pdrn_pink_peptide_serum.jpg' },
  { id: 'prod-037', file: 'the_ordinary_argireline_solution_10.jpg' },
  { id: 'prod-038', file: 'beauty_of_joseon_revive_eye_serum.jpg' },
];

const headers = {
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  apikey: SERVICE_ROLE_KEY,
};

async function uploadImage(file) {
  const localPath = path.join(IMAGE_DIR, file);
  if (!fs.existsSync(localPath)) {
    console.warn(`  ⚠️  File not found, skipping: ${file}`);
    return false;
  }
  const data = fs.readFileSync(localPath);
  await axios.post(
    `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${file}`,
    data,
    {
      headers: {
        ...headers,
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
      },
      maxBodyLength: Infinity,
    }
  );
  return true;
}

async function updateImageUrl(productId, file) {
  const url = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${file}`;
  await axios.patch(
    `${SUPABASE_URL}/rest/v1/master_products?id=eq.${productId}`,
    { image_url: url },
    {
      headers: {
        ...headers,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
    }
  );
  return url;
}

async function run() {
  if (SUPABASE_URL.includes('YOUR_PROJECT_REF') || SERVICE_ROLE_KEY.includes('YOUR_SERVICE')) {
    console.error('❌ Please fill in credentials.json at the project root (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY).');
    process.exit(1);
  }

  console.log(`📦 Uploading ${PRODUCT_IMAGES.length} images to Supabase Storage…\n`);

  let ok = 0, skipped = 0, failed = 0;

  for (const { id, file } of PRODUCT_IMAGES) {
    process.stdout.write(`  ${id}  ${file}  → `);
    try {
      const uploaded = await uploadImage(file);
      if (!uploaded) { skipped++; continue; }

      const url = await updateImageUrl(id, file);
      console.log(`✅  ${url}`);
      ok++;
    } catch (err) {
      const msg = err.response?.data?.message ?? err.message;
      console.log(`❌  ${msg}`);
      failed++;
    }
  }

  console.log(`\nDone — ${ok} uploaded, ${skipped} skipped, ${failed} failed.`);
  if (failed > 0) process.exit(1);
}

run();

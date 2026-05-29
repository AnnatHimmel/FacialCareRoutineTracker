const cheerio = require('cheerio');

// Parser for the Korean site: oliveyoung.co.kr
function parseOliveYoung(html) {
  const $ = cheerio.load(html);
  return {
    name: $('p.prd_name').text().trim() || '',
    brand: $('p.prd_brand').text().trim() || '',
    imageUrl: $('div.prd_detail_img img').attr('src') || '',
    description: $('div.prd_desc').text().trim() || '',
  };
}

// Parser for the global English site: global.oliveyoung.com (Vue.js SPA)
// OG meta tags are server-rendered even though the rest of the page is client-rendered.
function parseOliveYoungGlobal(html) {
  const $ = cheerio.load(html);

  // 1. Open Graph meta tags — always server-rendered on this site
  const ogTitle = $('meta[property="og:title"]').attr('content') || '';
  const ogImage = $('meta[property="og:image"]').attr('content') || '';
  const ogDesc  = $('meta[property="og:description"]').attr('content') || '';

  if (ogTitle) {
    // og:title format: "BrandName ProductName | OLIVE YOUNG Global"
    const titleClean = ogTitle.replace(/\s*\|\s*OLIVE YOUNG Global\s*$/i, '').trim();

    // og:description format: "BrandName ProductName | Discover all things K-Beauty..."
    // The part after " | " is the marketing blurb — use it as description.
    const pipeIdx = ogDesc.indexOf(' | ');
    const description = pipeIdx !== -1 ? ogDesc.slice(pipeIdx + 3).trim() : ogDesc.trim();

    // Try to extract brand — multiple strategies, most reliable first.
    let brand = '';

    // Strategy 1: JSON-LD schema.org Product
    const jsonLdResult = extractJsonLd($);
    if (jsonLdResult.brand) brand = jsonLdResult.brand;

    // Strategy 2: scan all inline <script> blocks for any brand key pattern.
    // OliveYoung Global embeds product data in JS objects; keys may be quoted or unquoted.
    if (!brand) {
      const scriptContent = $('script').map((_, el) => $(el).html()).get().join('\n');
      const patterns = [
        /["']?brandName["']?\s*:\s*["']([^"']+)["']/,
        /["']?brandNm["']?\s*:\s*["']([^"']+)["']/,
        /["']?brand["']?\s*:\s*["']([^"']+)["']/,
        /["']?makerName["']?\s*:\s*["']([^"']+)["']/,
      ];
      for (const re of patterns) {
        const m = scriptContent.match(re);
        if (m && m[1].length > 1) { brand = m[1]; break; }
      }
    }

    // Strategy 3: og:description starts with "Brand ProductName | …"
    // og:title (without suffix) == "Brand ProductName"
    // If the description's prefix matches the title, the brand is the leading
    // words that also appear as a prefix of the full title.
    // Heuristic: the brand is the portion of titleClean that precedes the
    // first word that does NOT appear at the same position in the description prefix.
    if (!brand && ogDesc) {
      const descPrefix = ogDesc.split(' | ')[0].trim(); // "Brand ProductName"
      if (descPrefix === titleClean) {
        // Both are identical — can't split automatically; leave for admin.
      } else if (titleClean.startsWith(descPrefix + ' ') || descPrefix.startsWith(titleClean)) {
        // Edge case — still can't split.
      } else {
        // Try: brand = words of descPrefix that are a prefix of titleClean
        // when the descPrefix is shorter than titleClean it may just be the brand.
        if (descPrefix.length < titleClean.length && titleClean.startsWith(descPrefix)) {
          brand = descPrefix;
        }
      }
    }

    return { name: titleClean, brand, imageUrl: ogImage, description };
  }

  // 2. Try JSON-LD structured data (schema.org Product)
  const jsonLdResult = extractJsonLd($);
  if (jsonLdResult.name) return jsonLdResult;

  // 3. Nothing server-rendered — return empty so admin fills in manually
  return { name: '', brand: '', imageUrl: '', description: '' };
}

/**
 * Recursively walk a JSON tree looking for an object that looks like a product.
 * A "product object" has at least one of the known product name keys AND
 * its value is a non-empty string (not another object).
 */
const PRODUCT_NAME_KEYS = ['prdtName', 'productName', 'goodsName', 'itemName', 'name'];
const BRAND_KEYS        = ['brandName', 'brandNm', 'brand', 'makerName'];
const IMAGE_KEYS        = ['mainImgUrl', 'imageUrl', 'prdtImgUrl', 'imgUrl', 'thumbnailUrl'];
const DESC_KEYS         = ['prdtDesc', 'description', 'shortDesc', 'summaryDesc', 'goodsDesc'];

function isProductObject(obj) {
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return false;
  // Must have a name-like key with a non-empty string value
  return PRODUCT_NAME_KEYS.some(k => typeof obj[k] === 'string' && obj[k].length > 2);
}

function findProductInTree(node, depth = 0) {
  if (depth > 12) return null; // guard against infinite recursion
  if (isProductObject(node)) return node;
  if (Array.isArray(node)) {
    for (const item of node) {
      const found = findProductInTree(item, depth + 1);
      if (found) return found;
    }
  } else if (node && typeof node === 'object') {
    for (const val of Object.values(node)) {
      const found = findProductInTree(val, depth + 1);
      if (found) return found;
    }
  }
  return null;
}

function extractFromProductObject(product) {
  const pick = (keys) => {
    for (const k of keys) {
      const v = product[k];
      if (typeof v === 'string' && v.trim()) return v.trim();
      if (Array.isArray(v) && typeof v[0] === 'string') return v[0];
    }
    return '';
  };

  return {
    name: pick(PRODUCT_NAME_KEYS),
    brand: pick(BRAND_KEYS),
    imageUrl: pick(IMAGE_KEYS),
    description: pick(DESC_KEYS),
  };
}

function extractJsonLd($) {
  let result = { name: '', brand: '', imageUrl: '', description: '' };
  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const data = JSON.parse($(el).html());
      const items = Array.isArray(data) ? data : [data];
      for (const item of items) {
        if (item['@type'] === 'Product') {
          result = {
            name: item.name || '',
            brand: item.brand?.name || item.brand || '',
            imageUrl: Array.isArray(item.image) ? item.image[0] : (item.image || ''),
            description: item.description || '',
          };
          return false; // break
        }
      }
    } catch (_) {}
  });
  return result;
}

module.exports = { parseOliveYoung, parseOliveYoungGlobal };

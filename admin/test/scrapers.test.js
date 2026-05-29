/**
 * Tests for product scraper modules
 *
 * Each scraper module exports a parseXxx(html) function that:
 * - Takes raw HTML string as input
 * - Returns a ScrapedProduct object with properties:
 *   { name, brand, imageUrl, description }
 * - Returns empty strings (not null/undefined) for missing fields
 */

const { parseYesStyle } = require('../scrapers/yestyle');
const { parseOliveYoung } = require('../scrapers/oliveyoung');
const { parseIHerb } = require('../scrapers/iherb');

describe('YesStyle Scraper', () => {
  const yestyleHtml = `
    <html>
    <head><title>COSRX Advanced Snail 96 Mucin Power Essence | YesStyle</title></head>
    <body>
      <h1 class="pdp-name">COSRX Advanced Snail 96 Mucin Power Essence</h1>
      <span class="brand-name">COSRX</span>
      <img class="product-image" src="https://img.yesstyle.com/images/prod-001.jpg" />
      <div class="product-description">Lightweight essence with 96% snail mucin</div>
    </body>
    </html>
  `;

  describe('parseYesStyle(html)', () => {
    it('should parse product name from pdp-name class', () => {
      const result = parseYesStyle(yestyleHtml);
      expect(result.name).toBe('COSRX Advanced Snail 96 Mucin Power Essence');
    });

    it('should parse brand from brand-name span', () => {
      const result = parseYesStyle(yestyleHtml);
      expect(result.brand).toBe('COSRX');
    });

    it('should parse image URL from product-image img src attribute', () => {
      const result = parseYesStyle(yestyleHtml);
      expect(result.imageUrl).toBe('https://img.yesstyle.com/images/prod-001.jpg');
    });

    it('should parse description from product-description div', () => {
      const result = parseYesStyle(yestyleHtml);
      expect(result.description).toBe('Lightweight essence with 96% snail mucin');
    });

    it('should return empty string when name selector is missing', () => {
      const htmlWithoutName = `
        <html>
        <body>
          <span class="brand-name">COSRX</span>
          <img class="product-image" src="https://img.yesstyle.com/images/prod-001.jpg" />
          <div class="product-description">Lightweight essence</div>
        </body>
        </html>
      `;
      const result = parseYesStyle(htmlWithoutName);
      expect(result.name).toBe('');
    });

    it('should return empty string when brand selector is missing', () => {
      const htmlWithoutBrand = `
        <html>
        <body>
          <h1 class="pdp-name">COSRX Advanced Snail 96 Mucin Power Essence</h1>
          <img class="product-image" src="https://img.yesstyle.com/images/prod-001.jpg" />
          <div class="product-description">Lightweight essence</div>
        </body>
        </html>
      `;
      const result = parseYesStyle(htmlWithoutBrand);
      expect(result.brand).toBe('');
    });

    it('should return empty string when image selector is missing', () => {
      const htmlWithoutImage = `
        <html>
        <body>
          <h1 class="pdp-name">COSRX Advanced Snail 96 Mucin Power Essence</h1>
          <span class="brand-name">COSRX</span>
          <div class="product-description">Lightweight essence</div>
        </body>
        </html>
      `;
      const result = parseYesStyle(htmlWithoutImage);
      expect(result.imageUrl).toBe('');
    });

    it('should return empty string when description selector is missing', () => {
      const htmlWithoutDescription = `
        <html>
        <body>
          <h1 class="pdp-name">COSRX Advanced Snail 96 Mucin Power Essence</h1>
          <span class="brand-name">COSRX</span>
          <img class="product-image" src="https://img.yesstyle.com/images/prod-001.jpg" />
        </body>
        </html>
      `;
      const result = parseYesStyle(htmlWithoutDescription);
      expect(result.description).toBe('');
    });

    it('should return object with all four required properties', () => {
      const result = parseYesStyle(yestyleHtml);
      expect(result).toHaveProperty('name');
      expect(result).toHaveProperty('brand');
      expect(result).toHaveProperty('imageUrl');
      expect(result).toHaveProperty('description');
    });
  });
});

describe('OliveYoung Scraper', () => {
  const oliveyoungHtml = `
    <html>
    <head><title>SOME BY MI AHA BHA PHA 30 Days Miracle Toner | Olive Young</title></head>
    <body>
      <p class="prd_name">AHA BHA PHA 30 Days Miracle Toner</p>
      <p class="prd_brand">SOME BY MI</p>
      <div class="prd_detail_img"><img src="https://cdn.oliveyoung.co.kr/images/prod-002.jpg" /></div>
      <div class="prd_desc">Triple acid toner for clear skin</div>
    </body>
    </html>
  `;

  describe('parseOliveYoung(html)', () => {
    it('should parse product name from prd_name class', () => {
      const result = parseOliveYoung(oliveyoungHtml);
      expect(result.name).toBe('AHA BHA PHA 30 Days Miracle Toner');
    });

    it('should parse brand from prd_brand p element', () => {
      const result = parseOliveYoung(oliveyoungHtml);
      expect(result.brand).toBe('SOME BY MI');
    });

    it('should parse image URL from img src within prd_detail_img div', () => {
      const result = parseOliveYoung(oliveyoungHtml);
      expect(result.imageUrl).toBe('https://cdn.oliveyoung.co.kr/images/prod-002.jpg');
    });

    it('should parse description from prd_desc div', () => {
      const result = parseOliveYoung(oliveyoungHtml);
      expect(result.description).toBe('Triple acid toner for clear skin');
    });

    it('should return empty string when name selector is missing', () => {
      const htmlWithoutName = `
        <html>
        <body>
          <p class="prd_brand">SOME BY MI</p>
          <div class="prd_detail_img"><img src="https://cdn.oliveyoung.co.kr/images/prod-002.jpg" /></div>
          <div class="prd_desc">Triple acid toner for clear skin</div>
        </body>
        </html>
      `;
      const result = parseOliveYoung(htmlWithoutName);
      expect(result.name).toBe('');
    });

    it('should return empty string when brand selector is missing', () => {
      const htmlWithoutBrand = `
        <html>
        <body>
          <p class="prd_name">AHA BHA PHA 30 Days Miracle Toner</p>
          <div class="prd_detail_img"><img src="https://cdn.oliveyoung.co.kr/images/prod-002.jpg" /></div>
          <div class="prd_desc">Triple acid toner for clear skin</div>
        </body>
        </html>
      `;
      const result = parseOliveYoung(htmlWithoutBrand);
      expect(result.brand).toBe('');
    });

    it('should return empty string when image selector is missing', () => {
      const htmlWithoutImage = `
        <html>
        <body>
          <p class="prd_name">AHA BHA PHA 30 Days Miracle Toner</p>
          <p class="prd_brand">SOME BY MI</p>
          <div class="prd_desc">Triple acid toner for clear skin</div>
        </body>
        </html>
      `;
      const result = parseOliveYoung(htmlWithoutImage);
      expect(result.imageUrl).toBe('');
    });

    it('should return empty string when description selector is missing', () => {
      const htmlWithoutDescription = `
        <html>
        <body>
          <p class="prd_name">AHA BHA PHA 30 Days Miracle Toner</p>
          <p class="prd_brand">SOME BY MI</p>
          <div class="prd_detail_img"><img src="https://cdn.oliveyoung.co.kr/images/prod-002.jpg" /></div>
        </body>
        </html>
      `;
      const result = parseOliveYoung(htmlWithoutDescription);
      expect(result.description).toBe('');
    });

    it('should return object with all four required properties', () => {
      const result = parseOliveYoung(oliveyoungHtml);
      expect(result).toHaveProperty('name');
      expect(result).toHaveProperty('brand');
      expect(result).toHaveProperty('imageUrl');
      expect(result).toHaveProperty('description');
    });
  });
});

describe('iHerb Scraper', () => {
  const iherbHtml = `
    <html>
    <head><title>Pyunkang Yul, Essence Toner, 200 ml - iHerb</title></head>
    <body>
      <h1 id="name">Pyunkang Yul, Essence Toner, 200 ml</h1>
      <span class="brand-name">Pyunkang Yul</span>
      <img id="iherb-product-image" src="https://cloudinary.iherb.com/images/prod-003.jpg" />
      <div id="product-overview"><p>Moisturizing essence toner for dry skin</p></div>
    </body>
    </html>
  `;

  describe('parseIHerb(html)', () => {
    it('should parse product name from h1 with id="name"', () => {
      const result = parseIHerb(iherbHtml);
      expect(result.name).toBe('Pyunkang Yul, Essence Toner, 200 ml');
    });

    it('should parse brand from brand-name span', () => {
      const result = parseIHerb(iherbHtml);
      expect(result.brand).toBe('Pyunkang Yul');
    });

    it('should parse image URL from img with id="iherb-product-image" src attribute', () => {
      const result = parseIHerb(iherbHtml);
      expect(result.imageUrl).toBe('https://cloudinary.iherb.com/images/prod-003.jpg');
    });

    it('should parse description from p inside product-overview div', () => {
      const result = parseIHerb(iherbHtml);
      expect(result.description).toBe('Moisturizing essence toner for dry skin');
    });

    it('should return empty string when name selector is missing', () => {
      const htmlWithoutName = `
        <html>
        <body>
          <span class="brand-name">Pyunkang Yul</span>
          <img id="iherb-product-image" src="https://cloudinary.iherb.com/images/prod-003.jpg" />
          <div id="product-overview"><p>Moisturizing essence toner for dry skin</p></div>
        </body>
        </html>
      `;
      const result = parseIHerb(htmlWithoutName);
      expect(result.name).toBe('');
    });

    it('should return empty string when brand selector is missing', () => {
      const htmlWithoutBrand = `
        <html>
        <body>
          <h1 id="name">Pyunkang Yul, Essence Toner, 200 ml</h1>
          <img id="iherb-product-image" src="https://cloudinary.iherb.com/images/prod-003.jpg" />
          <div id="product-overview"><p>Moisturizing essence toner for dry skin</p></div>
        </body>
        </html>
      `;
      const result = parseIHerb(htmlWithoutBrand);
      expect(result.brand).toBe('');
    });

    it('should return empty string when image selector is missing', () => {
      const htmlWithoutImage = `
        <html>
        <body>
          <h1 id="name">Pyunkang Yul, Essence Toner, 200 ml</h1>
          <span class="brand-name">Pyunkang Yul</span>
          <div id="product-overview"><p>Moisturizing essence toner for dry skin</p></div>
        </body>
        </html>
      `;
      const result = parseIHerb(htmlWithoutImage);
      expect(result.imageUrl).toBe('');
    });

    it('should return empty string when description selector is missing', () => {
      const htmlWithoutDescription = `
        <html>
        <body>
          <h1 id="name">Pyunkang Yul, Essence Toner, 200 ml</h1>
          <span class="brand-name">Pyunkang Yul</span>
          <img id="iherb-product-image" src="https://cloudinary.iherb.com/images/prod-003.jpg" />
        </body>
        </html>
      `;
      const result = parseIHerb(htmlWithoutDescription);
      expect(result.description).toBe('');
    });

    it('should return object with all four required properties', () => {
      const result = parseIHerb(iherbHtml);
      expect(result).toHaveProperty('name');
      expect(result).toHaveProperty('brand');
      expect(result).toHaveProperty('imageUrl');
      expect(result).toHaveProperty('description');
    });
  });
});

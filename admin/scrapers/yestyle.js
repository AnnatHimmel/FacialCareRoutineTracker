const cheerio = require('cheerio');

function parseYesStyle(html) {
  const $ = cheerio.load(html);
  return {
    name: $('h1.pdp-name').text().trim() || '',
    brand: $('span.brand-name').text().trim() || '',
    imageUrl: $('img.product-image').attr('src') || '',
    description: $('div.product-description').text().trim() || '',
  };
}

module.exports = { parseYesStyle };

const cheerio = require('cheerio');

function parseIHerb(html) {
  const $ = cheerio.load(html);
  return {
    name: $('h1#name').text().trim() || '',
    brand: $('span.brand-name').text().trim() || '',
    imageUrl: $('img#iherb-product-image').attr('src') || '',
    description: $('#product-overview p').first().text().trim() || '',
  };
}

module.exports = { parseIHerb };

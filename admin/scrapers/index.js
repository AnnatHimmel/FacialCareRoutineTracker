const axios = require('axios');
const { parseYesStyle } = require('./yestyle');
const { parseOliveYoung, parseOliveYoungGlobal } = require('./oliveyoung');
const { parseIHerb } = require('./iherb');

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'Accept-Language': 'en-US,en;q=0.9',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

async function scrapeUrl(url) {
  try {
    const { hostname } = new URL(url);

    const response = await axios.get(url, {
      headers: HEADERS,
      timeout: 20000,
    });
    const html = response.data;

    let parsed;
    if (hostname.includes('yesstyle.com')) {
      parsed = parseYesStyle(html);
    } else if (hostname.includes('global.oliveyoung.com')) {
      // Vue.js SPA — OG meta tags are server-rendered in the initial HTML
      parsed = parseOliveYoungGlobal(html);
    } else if (hostname.includes('oliveyoung.co')) {
      parsed = parseOliveYoung(html);
    } else if (hostname.includes('iherb.com')) {
      parsed = parseIHerb(html);
    } else {
      parsed = { name: '', brand: '', imageUrl: '', description: '' };
    }

    return { ...parsed, sourceUrl: url };
  } catch (err) {
    return { name: '', brand: '', imageUrl: '', description: '', sourceUrl: url, error: err.message };
  }
}

module.exports = { scrapeUrl };

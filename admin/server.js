const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { scrapeUrl } = require('./scrapers/index');

const app = express();
const PORT = 3001;
const MASTER_PRODUCTS_PATH = path.join(__dirname, '..', 'assets', 'data', 'master_products.json');
const INCOMPATIBILITY_RULES_PATH = path.join(__dirname, '..', 'assets', 'data', 'incompatibility_rules.json');

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));
app.use('/assets', express.static(path.join(__dirname, '..', 'assets')));

app.post('/api/scrape', async (req, res) => {
  const { urls } = req.body;
  if (!Array.isArray(urls)) {
    return res.status(400).json({ error: 'urls must be an array' });
  }
  const results = await Promise.all(urls.map(scrapeUrl));
  res.json({ results });
});

app.get('/api/master-products', (req, res) => {
  try {
    const data = fs.readFileSync(MASTER_PRODUCTS_PATH, 'utf8');
    res.json(JSON.parse(data));
  } catch (err) {
    res.json({ categories: [], products: [] });
  }
});

function formatMasterProducts(data) {
  const entries = Object.entries(data);
  const parts = [];
  entries.forEach(([key, value], i) => {
    const comma = i < entries.length - 1 ? ',' : '';
    if (key === 'categories' && Array.isArray(value)) {
      const lines = ['  ' + JSON.stringify(key) + ': ['];
      value.forEach((cat, j) => {
        lines.push('    ' + JSON.stringify(cat) + (j < value.length - 1 ? ',' : ''));
      });
      lines.push('  ]' + comma);
      parts.push(lines.join('\n'));
    } else {
      const valueStr = JSON.stringify(value, null, 2)
        .split('\n')
        .map((line, idx) => idx === 0 ? line : '  ' + line)
        .join('\n');
      parts.push('  ' + JSON.stringify(key) + ': ' + valueStr + comma);
    }
  });
  return '{\n' + parts.join('\n') + '\n}\n';
}

app.post('/api/export', (req, res) => {
  try {
    fs.writeFileSync(MASTER_PRODUCTS_PATH, formatMasterProducts(req.body), 'utf8');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/incompatibility-rules', (req, res) => {
  try {
    const data = fs.readFileSync(INCOMPATIBILITY_RULES_PATH, 'utf8');
    res.json(JSON.parse(data));
  } catch {
    res.json({ rules: [] });
  }
});

app.post('/api/export-rules', (req, res) => {
  try {
    fs.writeFileSync(INCOMPATIBILITY_RULES_PATH, JSON.stringify(req.body, null, 2), 'utf8');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Admin portal running at http://localhost:${PORT}`);
});

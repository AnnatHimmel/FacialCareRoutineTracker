const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { scrapeUrl } = require('./scrapers/index');

const app = express();
const PORT = 3001;
const MASTER_PRODUCTS_PATH = path.join(__dirname, '..', 'assets', 'data', 'master_products.json');

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

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

app.post('/api/export', (req, res) => {
  const data = JSON.stringify(req.body, null, 2);
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Disposition', 'attachment; filename="master_products.json"');
  res.send(data);
});

app.listen(PORT, () => {
  console.log(`Admin portal running at http://localhost:${PORT}`);
});

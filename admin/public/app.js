let masterData = { categories: [], products: [] };

async function loadMasterProducts() {
  try {
    const res = await fetch('/api/master-products');
    masterData = await res.json();
    if (!masterData.categories) masterData.categories = [];
    if (!masterData.products) masterData.products = [];
    renderSidebar();
    updateCategoryDropdowns();
  } catch (e) {
    console.error('Failed to load master products', e);
  }
}

function renderSidebar() {
  const list = document.getElementById('sidebar-list');
  list.innerHTML = '';

  const byCategory = {};
  for (const p of masterData.products) {
    const cat = p.categoryId || 'uncategorized';
    if (!byCategory[cat]) byCategory[cat] = [];
    byCategory[cat].push(p);
  }

  for (const cat of masterData.categories) {
    const header = document.createElement('div');
    header.className = 'sidebar-category';
    header.textContent = cat.name || cat.id;
    list.appendChild(header);

    for (const p of (byCategory[cat.id] || [])) {
      const row = document.createElement('div');
      row.className = 'sidebar-product';
      const chk = document.createElement('input');
      chk.type = 'checkbox';
      chk.checked = !!p.isDeprecated;
      chk.title = 'Deprecated';
      row.appendChild(chk);
      const lbl = document.createElement('span');
      lbl.textContent = p.name;
      row.appendChild(lbl);
      list.appendChild(row);
    }
  }
}

function updateCategoryDropdowns() {
  const selects = document.querySelectorAll('.cat-select');
  for (const sel of selects) {
    const current = sel.value;
    sel.innerHTML = '<option value="">— בחר קטגוריה —</option>';
    for (const cat of masterData.categories) {
      const opt = document.createElement('option');
      opt.value = cat.id;
      opt.textContent = cat.name || cat.id;
      sel.appendChild(opt);
    }
    if (current) sel.value = current;
  }
}

function categoryOptions() {
  return ['<option value="">— בחר קטגוריה —</option>',
    ...masterData.categories.map(c =>
      `<option value="${esc(c.id)}">${esc(c.name || c.id)}</option>`)
  ].join('');
}

function esc(s) {
  return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
}

function renderCard(product) {
  const card = document.createElement('div');
  card.className = 'product-card';
  card.dataset.id = product.id || `prod-${Date.now()}-${Math.random().toString(36).slice(2)}`;

  const morningCfg = product.morningConfig || null;
  const eveningCfg = product.eveningConfig || null;

  card.innerHTML = `
    <button class="card-delete" title="Remove card">&times;</button>
    ${product.sourceUrl ? `<div class="card-source">${esc(product.sourceUrl)}</div>` : ''}
    ${product.error ? `<span class="error-badge">Error: ${esc(product.error)}</span>` : ''}

    <div class="card-field">
      <label>Name</label>
      <input class="f-name" type="text" value="${esc(product.name || '')}" placeholder="Product name">
    </div>
    <div class="card-field">
      <label>Brand</label>
      <input class="f-brand" type="text" value="${esc(product.brand || '')}" placeholder="Brand">
    </div>
    <div class="card-field">
      <label>Image URL</label>
      <input class="f-imageurl" type="text" value="${esc(product.imageUrl || product.imageAsset || '')}" placeholder="https://...">
      <img class="card-image-preview" src="" alt="preview">
    </div>
    <div class="card-field">
      <label>Category</label>
      <select class="cat-select">${categoryOptions()}</select>
    </div>
    <div class="card-field">
      <label>Comment (Admin Note)</label>
      <textarea class="f-comment" placeholder="הערה לאדמין">${esc(product.comment || '')}</textarea>
    </div>

    <div class="slot-section">
      <h4>Morning Slot</h4>
      <div class="slot-row">
        <input type="checkbox" class="f-morning-enabled" ${morningCfg ? 'checked' : ''}>
        <label>Enabled</label>
        <label>Order</label>
        <input type="number" class="f-morning-order" value="${morningCfg ? morningCfg.order : 0}" min="0">
        <label>Frequency</label>
        <select class="f-morning-freq">
          <option value="daily" ${!morningCfg || morningCfg.frequency.type === 'daily' ? 'selected' : ''}>daily</option>
          <option value="weeklyMax1" ${morningCfg && morningCfg.frequency.type === 'weeklyMax' && morningCfg.frequency.max === 1 ? 'selected' : ''}>weeklyMax 1</option>
          <option value="weeklyMax2" ${morningCfg && morningCfg.frequency.type === 'weeklyMax' && morningCfg.frequency.max === 2 ? 'selected' : ''}>weeklyMax 2</option>
          <option value="weeklyMax3" ${morningCfg && morningCfg.frequency.type === 'weeklyMax' && morningCfg.frequency.max === 3 ? 'selected' : ''}>weeklyMax 3</option>
        </select>
      </div>
    </div>

    <div class="slot-section">
      <h4>Evening Slot</h4>
      <div class="slot-row">
        <input type="checkbox" class="f-evening-enabled" ${eveningCfg ? 'checked' : ''}>
        <label>Enabled</label>
        <label>Order</label>
        <input type="number" class="f-evening-order" value="${eveningCfg ? eveningCfg.order : 0}" min="0">
        <label>Frequency</label>
        <select class="f-evening-freq">
          <option value="daily" ${!eveningCfg || eveningCfg.frequency.type === 'daily' ? 'selected' : ''}>daily</option>
          <option value="weeklyMax1" ${eveningCfg && eveningCfg.frequency.type === 'weeklyMax' && eveningCfg.frequency.max === 1 ? 'selected' : ''}>weeklyMax 1</option>
          <option value="weeklyMax2" ${eveningCfg && eveningCfg.frequency.type === 'weeklyMax' && eveningCfg.frequency.max === 2 ? 'selected' : ''}>weeklyMax 2</option>
          <option value="weeklyMax3" ${eveningCfg && eveningCfg.frequency.type === 'weeklyMax' && eveningCfg.frequency.max === 3 ? 'selected' : ''}>weeklyMax 3</option>
        </select>
      </div>
    </div>

    <div class="card-field" style="flex-direction:row;align-items:center;gap:8px;">
      <input type="checkbox" class="f-deprecated" ${product.isDeprecated ? 'checked' : ''}>
      <label>Deprecated</label>
    </div>
  `;

  // Set category select value
  const catSel = card.querySelector('.cat-select');
  if (product.categoryId) catSel.value = product.categoryId;

  // Image preview
  const imgInput = card.querySelector('.f-imageurl');
  const imgPreview = card.querySelector('.card-image-preview');
  function updatePreview() {
    const src = imgInput.value.trim();
    if (src) { imgPreview.src = src; imgPreview.style.display = 'block'; }
    else { imgPreview.style.display = 'none'; }
  }
  updatePreview();
  imgInput.addEventListener('input', updatePreview);

  // Delete button
  card.querySelector('.card-delete').addEventListener('click', () => card.remove());

  return card;
}

function buildFrequency(val) {
  if (val === 'daily') return { type: 'daily' };
  const max = parseInt(val.replace('weeklyMax', ''), 10);
  return { type: 'weeklyMax', max };
}

function readCard(card) {
  const morningEnabled = card.querySelector('.f-morning-enabled').checked;
  const eveningEnabled = card.querySelector('.f-evening-enabled').checked;

  return {
    id: card.dataset.id,
    name: card.querySelector('.f-name').value.trim(),
    brand: card.querySelector('.f-brand').value.trim(),
    imageAsset: card.querySelector('.f-imageurl').value.trim() || null,
    categoryId: card.querySelector('.cat-select').value || null,
    comment: card.querySelector('.f-comment').value.trim() || null,
    isDeprecated: card.querySelector('.f-deprecated').checked,
    addedInVersion: '1.0.0',
    morningConfig: morningEnabled ? {
      order: parseInt(card.querySelector('.f-morning-order').value, 10) || 0,
      frequency: buildFrequency(card.querySelector('.f-morning-freq').value),
    } : null,
    eveningConfig: eveningEnabled ? {
      order: parseInt(card.querySelector('.f-evening-order').value, 10) || 0,
      frequency: buildFrequency(card.querySelector('.f-evening-freq').value),
    } : null,
  };
}

function collectAllProducts() {
  const cards = document.querySelectorAll('.product-card');
  return Array.from(cards).map(readCard);
}

async function fetchCards(urls) {
  const loading = document.getElementById('loading');
  const btn = document.getElementById('fetch-btn');
  loading.style.display = 'block';
  btn.disabled = true;

  try {
    const res = await fetch('/api/scrape', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ urls }),
    });
    const { results } = await res.json();
    const grid = document.getElementById('cards-grid');
    results.forEach((p, i) => {
      p.id = `prod-${Date.now()}-${i}`;
      grid.appendChild(renderCard(p));
    });
    updateCategoryDropdowns();
  } catch (e) {
    alert('Scrape failed: ' + e.message);
  } finally {
    loading.style.display = 'none';
    btn.disabled = false;
  }
}

async function exportJson() {
  const products = collectAllProducts();
  const payload = { ...masterData, products };

  try {
    const res = await fetch('/api/export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'master_products.json';
    a.click();
    URL.revokeObjectURL(url);
  } catch (e) {
    alert('Export failed: ' + e.message);
  }
}

// Add category form
document.getElementById('add-category-btn').addEventListener('click', () => {
  const form = document.getElementById('add-category-form');
  form.style.display = form.style.display === 'flex' ? 'none' : 'flex';
});

document.getElementById('add-category-confirm').addEventListener('click', () => {
  const idInput = document.getElementById('new-cat-id');
  const nameInput = document.getElementById('new-cat-name');
  const id = idInput.value.trim();
  const name = nameInput.value.trim();
  if (!id || !name) { alert('Both ID and name are required'); return; }
  masterData.categories.push({ id, name });
  renderSidebar();
  updateCategoryDropdowns();
  idInput.value = '';
  nameInput.value = '';
  document.getElementById('add-category-form').style.display = 'none';
});

document.getElementById('fetch-btn').addEventListener('click', () => {
  const raw = document.getElementById('urls-input').value.trim();
  const urls = raw.split('\n').map(s => s.trim()).filter(Boolean);
  if (!urls.length) { alert('Enter at least one URL'); return; }
  fetchCards(urls);
});

document.getElementById('add-blank-btn').addEventListener('click', () => {
  const card = renderCard({});
  document.getElementById('cards-grid').appendChild(card);
  updateCategoryDropdowns();
});

document.getElementById('save-btn').addEventListener('click', exportJson);

loadMasterProducts();

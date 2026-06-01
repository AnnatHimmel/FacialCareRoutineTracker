let masterData = { categories: [], products: [] };
let rulesData = { rules: [] };

// ─── Load ──────────────────────────────────────────────────────────────────

async function loadMasterProducts() {
  try {
    const res = await fetch('/api/master-products');
    masterData = await res.json();
    if (!masterData.categories) masterData.categories = [];
    if (!masterData.products) masterData.products = [];

    // Render existing products as editable cards
    const grid = document.getElementById('cards-grid');
    for (const p of masterData.products) {
      grid.appendChild(renderCard(p));
    }

    updateCategoryDropdowns();
    updateRuleEntitySelectors();
  } catch (e) {
    console.error('Failed to load master products', e);
  }
}

async function loadRules() {
  try {
    const res = await fetch('/api/incompatibility-rules');
    rulesData = await res.json();
    if (!rulesData.rules) rulesData.rules = [];
    renderRules();
  } catch (e) {
    console.error('Failed to load rules', e);
  }
}

// ─── Category dropdowns ────────────────────────────────────────────────────

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

// ─── Product card ──────────────────────────────────────────────────────────

function renderCard(product) {
  const card = document.createElement('div');
  card.className = 'product-card';
  card.dataset.id = product.id || `prod-${Date.now()}-${Math.random().toString(36).slice(2)}`;

  const morningCfg = product.morningConfig || null;
  const eveningCfg = product.eveningConfig || null;

  card.innerHTML = `
    <button class="card-delete" title="Remove card">&times;</button>
    ${product.sourceUrl ? `<div class="card-source" dir="ltr">${esc(product.sourceUrl)}</div>` : ''}
    ${product.error ? `<span class="error-badge">Error: ${esc(product.error)}</span>` : ''}

    <div class="card-field">
      <label>Name</label>
      <input class="f-name" type="text" value="${esc(product.name || '')}" placeholder="Product name">
    </div>
    <div class="card-field">
      <label>Brand</label>
      <input class="f-brand" type="text" dir="ltr" value="${esc(product.brand || '')}" placeholder="Brand">
    </div>
    <div class="card-field">
      <label>Image URL</label>
      <input class="f-imageurl" type="text" dir="ltr" value="${esc(product.imageUrl || product.imageAsset || '')}" placeholder="https://...">
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

  const catSel = card.querySelector('.cat-select');
  if (product.categoryId) catSel.value = product.categoryId;

  const imgInput = card.querySelector('.f-imageurl');
  const imgPreview = card.querySelector('.card-image-preview');
  function updatePreview() {
    const src = imgInput.value.trim();
    if (src) { imgPreview.src = src; imgPreview.style.display = 'block'; }
    else { imgPreview.style.display = 'none'; }
  }
  updatePreview();
  imgInput.addEventListener('input', updatePreview);

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
  return Array.from(document.querySelectorAll('.product-card')).map(readCard);
}

// ─── Fetch / import ────────────────────────────────────────────────────────

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

// ─── Export products ───────────────────────────────────────────────────────

async function exportJson() {
  const products = collectAllProducts();
  const sortedCats = [...masterData.categories].sort((a, b) => (a.order || 0) - (b.order || 0));
  const payload = { ...masterData, categories: sortedCats, products };

  try {
    const res = await fetch('/api/export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!data.ok) throw new Error(data.error);
    flashSaved('save-btn', 'Save master_products.json');
  } catch (e) {
    alert('Save failed: ' + e.message);
  }
}

// ─── Export rules ──────────────────────────────────────────────────────────

async function exportRules() {
  try {
    const res = await fetch('/api/export-rules', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rulesData),
    });
    const data = await res.json();
    if (!data.ok) throw new Error(data.error);
    flashSaved('save-rules-btn', 'Save incompatibility_rules.json');
  } catch (e) {
    alert('Save rules failed: ' + e.message);
  }
}

function flashSaved(btnId, originalLabel) {
  const btn = document.getElementById(btnId);
  btn.textContent = 'Saved ✓';
  btn.style.background = '#28a745';
  setTimeout(() => { btn.textContent = originalLabel; btn.style.background = ''; }, 2000);
}

// ─── Tabs ──────────────────────────────────────────────────────────────────

function switchTab(tabName) {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tabName);
  });
  document.querySelectorAll('.tab-panel').forEach(panel => {
    panel.classList.toggle('active', panel.id === `tab-${tabName}`);
  });

  document.getElementById('add-blank-btn').style.display = tabName === 'products' ? '' : 'none';
  document.getElementById('save-rules-btn').style.display = tabName === 'rules' ? '' : 'none';

  if (tabName === 'ordering') renderOrderingTab();
}

// ─── Ordering tab ──────────────────────────────────────────────────────────

function makeSortable(listEl, onDrop) {
  let dragEl = null;

  listEl.addEventListener('dragstart', e => {
    dragEl = e.target.closest('.sort-item');
    if (!dragEl) return;
    dragEl.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', '');
  });

  listEl.addEventListener('dragover', e => {
    e.preventDefault();
    const target = e.target.closest('.sort-item');
    if (!target || target === dragEl) return;
    const rect = target.getBoundingClientRect();
    if (e.clientY < rect.top + rect.height / 2) {
      listEl.insertBefore(dragEl, target);
    } else {
      listEl.insertBefore(dragEl, target.nextSibling);
    }
    e.dataTransfer.dropEffect = 'move';
  });

  listEl.addEventListener('drop', e => e.preventDefault());

  listEl.addEventListener('dragend', () => {
    if (dragEl) {
      dragEl.classList.remove('dragging');
      dragEl = null;
      onDrop();
    }
  });
}

function createSortItem(id, label, badge) {
  const item = document.createElement('div');
  item.className = 'sort-item';
  item.dataset.id = id;
  item.draggable = true;
  item.innerHTML = `
    <span class="drag-handle" title="Drag to reorder">&#8942;&#8942;</span>
    <span class="sort-label">${esc(label)}</span>
    ${badge ? `<span class="sort-badge">${esc(badge)}</span>` : ''}
  `;
  return item;
}

function renderOrderingTab() {
  // ── Categories ──
  const catList = document.getElementById('cat-order-list');
  catList.innerHTML = '';
  const sortedCats = [...masterData.categories].sort((a, b) => (a.order || 0) - (b.order || 0));
  for (const cat of sortedCats) {
    catList.appendChild(createSortItem(cat.id, cat.name || cat.id));
  }
  makeSortable(catList, syncCategoryOrder);

  // ── Morning & Evening grouped by category ──
  const morningByCat = {};
  const eveningByCat = {};

  for (const card of document.querySelectorAll('.product-card')) {
    const id = card.dataset.id;
    const name = card.querySelector('.f-name').value || id;
    const catId = card.querySelector('.cat-select').value || 'uncategorized';

    if (card.querySelector('.f-morning-enabled').checked) {
      const order = parseInt(card.querySelector('.f-morning-order').value, 10) || 0;
      if (!morningByCat[catId]) morningByCat[catId] = [];
      morningByCat[catId].push({ id, name, order });
    }
    if (card.querySelector('.f-evening-enabled').checked) {
      const order = parseInt(card.querySelector('.f-evening-order').value, 10) || 0;
      if (!eveningByCat[catId]) eveningByCat[catId] = [];
      eveningByCat[catId].push({ id, name, order });
    }
  }

  renderGroupedSlot('morning-order-list', morningByCat, sortedCats, 'morning');
  renderGroupedSlot('evening-order-list', eveningByCat, sortedCats, 'evening');
}

function renderGroupedSlot(containerId, byCat, sortedCats, slot) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';

  for (const cat of sortedCats) {
    const products = byCat[cat.id];
    if (!products || products.length === 0) continue;
    products.sort((a, b) => a.order - b.order);
    appendCatGroup(container, cat.name || cat.id, cat.id, products, slot);
  }

  const uncatProducts = byCat['uncategorized'];
  if (uncatProducts && uncatProducts.length > 0) {
    uncatProducts.sort((a, b) => a.order - b.order);
    appendCatGroup(container, 'ללא קטגוריה', 'uncategorized', uncatProducts, slot);
  }
}

function appendCatGroup(container, catLabel, catId, products, slot) {
  const group = document.createElement('div');
  group.className = 'order-cat-group';
  group.dataset.catId = catId;

  const header = document.createElement('div');
  header.className = 'order-cat-header';
  header.textContent = catLabel;
  group.appendChild(header);

  const subList = document.createElement('div');
  subList.className = 'sortable-list';
  for (const p of products) {
    subList.appendChild(createSortItem(p.id, p.name));
  }
  group.appendChild(subList);
  makeSortable(subList, () => syncSlotOrder(slot));
  container.appendChild(group);
}

function syncCategoryOrder() {
  document.querySelectorAll('#cat-order-list .sort-item').forEach((item, i) => {
    const cat = masterData.categories.find(c => c.id === item.dataset.id);
    if (cat) cat.order = i + 1;
  });
}

function syncSlotOrder(slot) {
  const listId = slot === 'morning' ? 'morning-order-list' : 'evening-order-list';
  document.querySelectorAll(`#${listId} .sort-item`).forEach((item, i) => {
    const card = document.querySelector(`.product-card[data-id="${item.dataset.id}"]`);
    if (card) {
      card.querySelector(`.f-${slot}-order`).value = i;
    }
  });
}

// ─── Rules tab ─────────────────────────────────────────────────────────────

function getEntityName(entity) {
  if (entity.type === 'product') {
    const p = masterData.products.find(p => p.id === entity.id);
    if (p) return p.name;
    // Also check cards for newly added products
    const card = document.querySelector(`.product-card[data-id="${entity.id}"]`);
    if (card) return card.querySelector('.f-name').value || entity.id;
    return entity.id;
  } else {
    const c = masterData.categories.find(c => c.id === entity.id);
    return c ? (c.name || c.id) : entity.id;
  }
}

function renderRules() {
  const list = document.getElementById('rules-list');
  const empty = document.getElementById('rules-empty');
  const countBadge = document.getElementById('rules-count');
  list.innerHTML = '';

  countBadge.textContent = rulesData.rules.length;
  empty.style.display = rulesData.rules.length === 0 ? 'block' : 'none';

  for (const rule of rulesData.rules) {
    const nameA = getEntityName(rule.entityA);
    const nameB = getEntityName(rule.entityB);
    const scopeLabel = rule.scope === 'withinSlot' ? 'Same slot' : 'Same day';

    const row = document.createElement('div');
    row.className = 'rule-row';
    row.innerHTML = `
      <span class="rule-entity rule-entity-${rule.entityA.type}" title="${esc(rule.entityA.type)}: ${esc(rule.entityA.id)}">${esc(nameA)}</span>
      <span class="rule-arrow">&#8596;</span>
      <span class="rule-entity rule-entity-${rule.entityB.type}" title="${esc(rule.entityB.type)}: ${esc(rule.entityB.id)}">${esc(nameB)}</span>
      <span class="rule-scope-badge">${esc(scopeLabel)}</span>
      <span class="rule-id-label">${esc(rule.id)}</span>
      <button class="rule-delete" data-rule-id="${esc(rule.id)}" title="Delete rule">&times;</button>
    `;
    row.querySelector('.rule-delete').addEventListener('click', () => {
      rulesData.rules = rulesData.rules.filter(r => r.id !== rule.id);
      renderRules();
    });
    list.appendChild(row);
  }
}

function updateRuleEntitySelectors() {
  populateEntitySelector(
    document.getElementById('rule-a-type').value,
    document.getElementById('rule-a-id')
  );
  populateEntitySelector(
    document.getElementById('rule-b-type').value,
    document.getElementById('rule-b-id')
  );
}

function populateEntitySelector(type, selectEl) {
  const current = selectEl.value;
  selectEl.innerHTML = '';
  const items = type === 'product'
    ? masterData.products.map(p => ({ id: p.id, label: p.name }))
    : masterData.categories.map(c => ({ id: c.id, label: c.name || c.id }));
  for (const item of items) {
    const opt = document.createElement('option');
    opt.value = item.id;
    opt.textContent = item.label;
    selectEl.appendChild(opt);
  }
  if (current && items.find(i => i.id === current)) selectEl.value = current;
}

function addRule() {
  const aType = document.getElementById('rule-a-type').value;
  const aId = document.getElementById('rule-a-id').value;
  const bType = document.getElementById('rule-b-type').value;
  const bId = document.getElementById('rule-b-id').value;
  const scope = document.getElementById('rule-scope').value;

  if (!aId || !bId) { alert('Please select both entities.'); return; }
  if (aType === bType && aId === bId) { alert('Entities A and B must be different.'); return; }

  const isDuplicate = rulesData.rules.some(r =>
    (r.entityA.type === aType && r.entityA.id === aId && r.entityB.type === bType && r.entityB.id === bId && r.scope === scope) ||
    (r.entityA.type === bType && r.entityA.id === bId && r.entityB.type === aType && r.entityB.id === aId && r.scope === scope)
  );
  if (isDuplicate) { alert('This rule already exists.'); return; }

  rulesData.rules.push({
    id: `rule-${String(Date.now()).slice(-6)}`,
    entityA: { type: aType, id: aId },
    entityB: { type: bType, id: bId },
    scope,
  });
  renderRules();
}

// ─── Add category ──────────────────────────────────────────────────────────

document.getElementById('add-category-btn').addEventListener('click', () => {
  const form = document.getElementById('add-category-form');
  form.style.display = form.style.display === 'flex' ? 'none' : 'flex';
  if (form.style.display === 'flex') document.getElementById('new-cat-id').focus();
});

document.getElementById('add-category-confirm').addEventListener('click', () => {
  const idInput = document.getElementById('new-cat-id');
  const nameInput = document.getElementById('new-cat-name');
  const id = idInput.value.trim();
  const name = nameInput.value.trim();
  if (!id || !name) { alert('Both ID and name are required'); return; }
  const maxOrder = masterData.categories.reduce((m, c) => Math.max(m, c.order || 0), 0);
  masterData.categories.push({ id, name, order: maxOrder + 1 });
  updateCategoryDropdowns();
  updateRuleEntitySelectors();
  idInput.value = '';
  nameInput.value = '';
  document.getElementById('add-category-form').style.display = 'none';
});

// ─── Tabs ──────────────────────────────────────────────────────────────────

document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

// ─── Rule selectors ────────────────────────────────────────────────────────

document.getElementById('rule-a-type').addEventListener('change', e => {
  populateEntitySelector(e.target.value, document.getElementById('rule-a-id'));
});
document.getElementById('rule-b-type').addEventListener('change', e => {
  populateEntitySelector(e.target.value, document.getElementById('rule-b-id'));
});

document.getElementById('add-rule-btn').addEventListener('click', addRule);

// ─── Footer ────────────────────────────────────────────────────────────────

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
document.getElementById('save-rules-btn').addEventListener('click', exportRules);

// ─── Init ──────────────────────────────────────────────────────────────────

loadMasterProducts().then(() => loadRules());

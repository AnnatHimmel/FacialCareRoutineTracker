const { test, expect } = require('@playwright/test');

// Wait for the page to finish loading master products and rules before each test.
async function waitForLoad(page) {
  await page.goto('/');
  // Products are loaded when at least one card appears in the grid.
  await expect(page.locator('.product-card').first()).toBeVisible({ timeout: 8000 });
}

// ─── Tab navigation ────────────────────────────────────────────────────────

test.describe('Tab navigation', () => {
  test('Products tab is active by default', async ({ page }) => {
    await waitForLoad(page);
    await expect(page.locator('#tab-products')).toBeVisible();
    await expect(page.locator('#tab-ordering')).not.toBeVisible();
    await expect(page.locator('#tab-rules')).not.toBeVisible();
    await expect(page.locator('[data-tab="products"]')).toHaveClass(/active/);
  });

  test('Clicking Ordering tab shows ordering panel', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="ordering"]');
    await expect(page.locator('#tab-ordering')).toBeVisible();
    await expect(page.locator('#tab-products')).not.toBeVisible();
    await expect(page.locator('[data-tab="ordering"]')).toHaveClass(/active/);
  });

  test('Clicking Incompatibilities tab shows rules panel', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="rules"]');
    await expect(page.locator('#tab-rules')).toBeVisible();
    await expect(page.locator('#tab-products')).not.toBeVisible();
    await expect(page.locator('[data-tab="rules"]')).toHaveClass(/active/);
  });

  test('Can switch back to Products tab', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="ordering"]');
    await page.click('[data-tab="products"]');
    await expect(page.locator('#tab-products')).toBeVisible();
    await expect(page.locator('#tab-ordering')).not.toBeVisible();
  });
});

// ─── Footer button visibility ──────────────────────────────────────────────

test.describe('Footer buttons', () => {
  test('Add Blank Card is visible on Products tab', async ({ page }) => {
    await waitForLoad(page);
    await expect(page.locator('#add-blank-btn')).toBeVisible();
  });

  test('Add Blank Card is hidden on Ordering tab', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="ordering"]');
    await expect(page.locator('#add-blank-btn')).not.toBeVisible();
  });

  test('Add Blank Card is hidden on Rules tab', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="rules"]');
    await expect(page.locator('#add-blank-btn')).not.toBeVisible();
  });

  test('Save Rules button is hidden on Products tab', async ({ page }) => {
    await waitForLoad(page);
    await expect(page.locator('#save-rules-btn')).not.toBeVisible();
  });

  test('Save Rules button is visible on Rules tab', async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="rules"]');
    await expect(page.locator('#save-rules-btn')).toBeVisible();
  });

  test('Save master_products.json is always visible', async ({ page }) => {
    await waitForLoad(page);
    await expect(page.locator('#save-btn')).toBeVisible();
    await page.click('[data-tab="ordering"]');
    await expect(page.locator('#save-btn')).toBeVisible();
    await page.click('[data-tab="rules"]');
    await expect(page.locator('#save-btn')).toBeVisible();
  });
});

// ─── Products tab ──────────────────────────────────────────────────────────

test.describe('Products tab', () => {
  test('Loads existing products as editable cards', async ({ page }) => {
    await waitForLoad(page);
    const cards = page.locator('.product-card');
    const count = await cards.count();
    expect(count).toBeGreaterThan(0);
  });

  test('Each card has a name field with content', async ({ page }) => {
    await waitForLoad(page);
    const firstCardName = page.locator('.product-card').first().locator('.f-name');
    const name = await firstCardName.inputValue();
    expect(name.length).toBeGreaterThan(0);
  });

  test('Add Blank Card appends an empty card', async ({ page }) => {
    await waitForLoad(page);
    const before = await page.locator('.product-card').count();
    await page.click('#add-blank-btn');
    await expect(page.locator('.product-card')).toHaveCount(before + 1);
  });

  test('Card delete button removes the card', async ({ page }) => {
    await waitForLoad(page);
    // Add a blank card then delete it
    await page.click('#add-blank-btn');
    const before = await page.locator('.product-card').count();
    await page.locator('.product-card').last().locator('.card-delete').click();
    await expect(page.locator('.product-card')).toHaveCount(before - 1);
  });

  test('Category dropdown is populated', async ({ page }) => {
    await waitForLoad(page);
    const options = await page.locator('.product-card').first().locator('.cat-select option').count();
    // At least 1 "placeholder" + some real categories
    expect(options).toBeGreaterThan(1);
  });
});

// ─── Ordering tab ─────────────────────────────────────────────────────────

test.describe('Ordering tab', () => {
  test.beforeEach(async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="ordering"]');
  });

  test('Category list is populated', async ({ page }) => {
    const items = page.locator('#cat-order-list .sort-item');
    await expect(items.first()).toBeVisible();
    const count = await items.count();
    expect(count).toBeGreaterThan(0);
  });

  test('Morning routine list is populated', async ({ page }) => {
    const items = page.locator('#morning-order-list .sort-item');
    await expect(items.first()).toBeVisible();
    const count = await items.count();
    expect(count).toBeGreaterThan(0);
  });

  test('Evening routine list is populated', async ({ page }) => {
    const items = page.locator('#evening-order-list .sort-item');
    await expect(items.first()).toBeVisible();
    const count = await items.count();
    expect(count).toBeGreaterThan(0);
  });

  test('Each sort item has a drag handle', async ({ page }) => {
    const handle = page.locator('#morning-order-list .sort-item').first().locator('.drag-handle');
    await expect(handle).toBeVisible();
  });

  test('Each sort item shows a category badge', async ({ page }) => {
    const badge = page.locator('#morning-order-list .sort-item').first().locator('.sort-badge');
    await expect(badge).toBeVisible();
    const text = await badge.innerText();
    expect(text.length).toBeGreaterThan(0);
  });

  test('Drag reorder updates card order input', async ({ page }) => {
    const items = page.locator('#morning-order-list .sort-item');
    const count = await items.count();
    if (count < 2) test.skip(); // need at least 2 items

    const firstId = await items.nth(0).getAttribute('data-id');
    const secondId = await items.nth(1).getAttribute('data-id');

    const firstCard = page.locator(`.product-card[data-id="${firstId}"]`);
    const secondCard = page.locator(`.product-card[data-id="${secondId}"]`);

    // Drag item 0 below item 1 — item 0 should end up at a later position than item 1
    await items.nth(0).dragTo(items.nth(1));

    const orderAfter0 = parseInt(await firstCard.locator('.f-morning-order').inputValue(), 10);
    const orderAfter1 = parseInt(await secondCard.locator('.f-morning-order').inputValue(), 10);

    // After drag, the formerly-first product should have a higher order number than item 1
    expect(orderAfter0).toBeGreaterThan(orderAfter1);
  });
});

// ─── Incompatibilities tab ────────────────────────────────────────────────

test.describe('Incompatibilities tab', () => {
  test.beforeEach(async ({ page }) => {
    await waitForLoad(page);
    await page.click('[data-tab="rules"]');
  });

  test('Shows existing rules with entity names (not raw IDs)', async ({ page }) => {
    const rows = page.locator('.rule-row');
    const count = await rows.count();
    if (count === 0) test.skip(); // no rules in file

    const text = await rows.first().innerText();
    // Should not show a bare product ID like "prod-037" as the primary label
    expect(text).not.toMatch(/^\s*prod-\d+/);
  });

  test('Rule count badge matches number of rule rows', async ({ page }) => {
    const badge = await page.locator('#rules-count').innerText();
    const rowCount = await page.locator('.rule-row').count();
    expect(parseInt(badge, 10)).toBe(rowCount);
  });

  test('Entity type dropdown repopulates entity ID selector', async ({ page }) => {
    await page.selectOption('#rule-a-type', 'category');
    const options = await page.locator('#rule-a-id option').allTextContents();
    // Categories have Hebrew names, not starting with "prod-"
    for (const opt of options) {
      expect(opt).not.toMatch(/^prod-/);
    }

    await page.selectOption('#rule-a-type', 'product');
    const productOptions = await page.locator('#rule-a-id option').allTextContents();
    expect(productOptions.length).toBeGreaterThan(0);
  });

  test('Can add a product-to-category rule', async ({ page }) => {
    const before = await page.locator('.rule-row').count();

    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'category');
    // Pick a product and a category that don't already form a rule together
    const productId = await page.locator('#rule-a-id option').last().getAttribute('value');
    const categoryId = await page.locator('#rule-b-id option').last().getAttribute('value');
    await page.selectOption('#rule-a-id', productId);
    await page.selectOption('#rule-b-id', categoryId);
    await page.selectOption('#rule-scope', 'sameDayAcrossBoth');

    await page.click('#add-rule-btn');

    await expect(page.locator('.rule-row')).toHaveCount(before + 1);
    // Badge should also update
    const badge = await page.locator('#rules-count').innerText();
    expect(parseInt(badge, 10)).toBe(before + 1);
  });

  test('Can add a product-to-product rule', async ({ page }) => {
    const before = await page.locator('.rule-row').count();

    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'product');

    const aId = await page.locator('#rule-a-id option').nth(0).getAttribute('value');
    const bId = await page.locator('#rule-b-id option').nth(2).getAttribute('value');
    await page.selectOption('#rule-a-id', aId);
    await page.selectOption('#rule-b-id', bId);
    await page.selectOption('#rule-scope', 'withinSlot');

    await page.click('#add-rule-btn');
    await expect(page.locator('.rule-row')).toHaveCount(before + 1);
  });

  test('Duplicate rule shows alert and is not added', async ({ page }) => {
    // Add a rule first
    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'product');
    const aId = await page.locator('#rule-a-id option').nth(3).getAttribute('value');
    const bId = await page.locator('#rule-b-id option').nth(4).getAttribute('value');
    await page.selectOption('#rule-a-id', aId);
    await page.selectOption('#rule-b-id', bId);
    await page.selectOption('#rule-scope', 'withinSlot');
    await page.click('#add-rule-btn');

    const countAfterFirst = await page.locator('.rule-row').count();

    // Attempt to add the exact same rule again — don't await click; let dialog race
    const dialogPromise = page.waitForEvent('dialog');
    page.click('#add-rule-btn');
    const dialog = await dialogPromise;
    expect(dialog.message().toLowerCase()).toContain('already exists');
    await dialog.dismiss();

    // Count must not have changed
    await expect(page.locator('.rule-row')).toHaveCount(countAfterFirst);
  });

  test('Self-reference rule shows alert and is not added', async ({ page }) => {
    const before = await page.locator('.rule-row').count();

    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'product');
    const sameId = await page.locator('#rule-a-id option').first().getAttribute('value');
    await page.selectOption('#rule-a-id', sameId);
    await page.selectOption('#rule-b-id', sameId);

    const dialogPromise = page.waitForEvent('dialog');
    page.click('#add-rule-btn');
    const dialog = await dialogPromise;
    expect(dialog.message().toLowerCase()).toContain('different');
    await dialog.dismiss();

    await expect(page.locator('.rule-row')).toHaveCount(before);
  });

  test('Can delete a rule', async ({ page }) => {
    // Add a rule so we always have something to delete
    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'category');
    const productId = await page.locator('#rule-a-id option').nth(1).getAttribute('value');
    const categoryId = await page.locator('#rule-b-id option').first().getAttribute('value');
    await page.selectOption('#rule-a-id', productId);
    await page.selectOption('#rule-b-id', categoryId);
    await page.click('#add-rule-btn');

    const countBefore = await page.locator('.rule-row').count();
    await page.locator('.rule-row').last().locator('.rule-delete').click();
    await expect(page.locator('.rule-row')).toHaveCount(countBefore - 1);

    const badge = await page.locator('#rules-count').innerText();
    expect(parseInt(badge, 10)).toBe(countBefore - 1);
  });

  test('Empty state message shown when all rules deleted', async ({ page }) => {
    // Delete all rules
    let count = await page.locator('.rule-row').count();
    for (let i = 0; i < count; i++) {
      await page.locator('.rule-row').first().locator('.rule-delete').click();
    }
    await expect(page.locator('#rules-empty')).toBeVisible();
  });

  test('Added rule shows entity names not raw IDs in the row', async ({ page }) => {
    await page.selectOption('#rule-a-type', 'product');
    await page.selectOption('#rule-b-type', 'product');
    const aId = await page.locator('#rule-a-id option').nth(5).getAttribute('value');
    const bId = await page.locator('#rule-b-id option').nth(6).getAttribute('value');
    const aName = await page.locator('#rule-a-id option').nth(5).innerText();
    const bName = await page.locator('#rule-b-id option').nth(6).innerText();
    await page.selectOption('#rule-a-id', aId);
    await page.selectOption('#rule-b-id', bId);
    await page.click('#add-rule-btn');

    const lastRow = page.locator('.rule-row').last();
    await expect(lastRow).toContainText(aName);
    await expect(lastRow).toContainText(bName);
  });
});

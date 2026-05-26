# /screenshot - Capture UI Screenshot

## Purpose
Take a screenshot of the current browser state without loading it into context. Useful for documentation, debugging reference, or manual review when structured validation isn't sufficient.

## Usage
```
/screenshot                    # Capture current viewport
/screenshot fullpage           # Capture full scrollable page
/screenshot element <selector> # Capture specific element
/screenshot review             # Capture AND load into context for review
```

## Instructions

When this command is invoked:

### Step 1: Verify Playwright Plugin

```
1. ATTEMPT to use browser_snapshot to verify browser is ready

2. IF "browser not installed" error:
   → Call mcp__plugin_playwright_playwright__browser_install
   → Retry

3. IF plugin not available (PluginNotFound):
   → STOP with message:

   "❌ Playwright MCP plugin not available.

   Screenshot capture requires the Playwright plugin.
   Install from: https://github.com/anthropics/claude-code/tree/main/plugins/playwright

   Alternative: Take screenshot manually and share the file path."

4. IF no browser tab open:
   → STOP with message:

   "❌ No browser page open.

   First navigate to a URL using:
   - mcp__plugin_playwright_playwright__browser_navigate
   - Or ask me to open a specific URL"
```

### Step 2: Generate Filename

```
Format: screenshot-{timestamp}-{type}.png

Examples:
- screenshot-20250129-143052-viewport.png
- screenshot-20250129-143052-fullpage.png
- screenshot-20250129-143052-element.png

Save to: .\screenshots\ directory (create if not exists)
```

### Step 3: Capture Screenshot

**Default (viewport only):**
```
Use mcp__plugin_playwright_playwright__browser_take_screenshot with:
- type: "png"
- filename: [generated filename]
```

**Full page:**
```
Use mcp__plugin_playwright_playwright__browser_take_screenshot with:
- type: "png"
- fullPage: true
- filename: [generated filename]
```

**Specific element:**
```
1. First get page snapshot to find element ref
2. Use mcp__plugin_playwright_playwright__browser_take_screenshot with:
   - type: "png"
   - ref: [element reference]
   - element: [element description]
   - filename: [generated filename]
```

### Step 4: Report Result

**Standard capture (NOT loaded into context):**
```markdown
## 📸 Screenshot Captured

**File**: .\screenshots\[filename]
**Type**: [viewport/fullpage/element]
**Size**: [dimensions if available]

Screenshot saved. NOT loaded into context to preserve token budget.

**To review in context**, use:
- `/screenshot review` - capture new and load
- Or: "Read the screenshot at [filepath]"
```

**Review mode (loaded into context):**
```markdown
## 📸 Screenshot Captured & Loaded

**File**: .\screenshots\[filename]
**Type**: [viewport/fullpage/element]

[Screenshot is now visible in context for analysis]

⚠️ Note: Large images consume significant context tokens.
```

## Context Management

### Why NOT Auto-Load
- Screenshots are 50-200KB typically
- Loading into context consumes ~1000-4000 tokens
- Multiple screenshots can quickly exhaust context
- Structured validation (accessibility tree, computed styles) is more actionable

### When to Load into Context
Use `/screenshot review` when:
- Structured validation passed but something still looks wrong
- Need to verify visual layout/alignment
- Documenting a specific visual state for human review
- Debugging CSS issues that don't appear in computed styles

### Recommended Workflow
```
1. Run structured validation first (ui-tester)
2. If issues found → fix using actionable data
3. If validation passes but visual issue suspected:
   → /screenshot review
   → Analyze visual output
   → Identify issue manually
```

## Error Handling

| Error | Response |
|-------|----------|
| Plugin not installed | Provide installation link |
| Browser not installed | Run browser_install |
| No page open | Instruct to navigate first |
| Element not found | Report and suggest alternatives |
| Screenshot fails | Retry once, then report error |

## Integration with UI Testing

This command is SEPARATE from ui-tester's validation:

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `ui-tester` | Structured validation | Primary testing method |
| `/screenshot` | Visual capture | Documentation, manual review |

**Do NOT use /screenshot for automated testing** - use ui-tester's 5-layer validation instead.

## Examples

```
User: /screenshot
Claude: [Captures viewport, saves file, reports location]

User: /screenshot fullpage
Claude: [Captures full scrollable page]

User: /screenshot element ".main-header"
Claude: [Captures just the header element]

User: /screenshot review
Claude: [Captures AND loads into context for visual analysis]

User: The button looks misaligned
Claude: Let me capture a screenshot for review.
        [Uses /screenshot review to load and analyze]
```

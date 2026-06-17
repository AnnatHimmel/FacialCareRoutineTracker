# Functionality Specification
Project: Skincare Routine Tracker
Created: 2026-05-26
Completeness: 100%

---

## 1. Core Purpose
**Problem Statement:** Skincare users don't know the correct order, frequency, or safe combinations of products to use. An expert (admin) should encode that knowledge once, and each user should get a correctly-ordered, personalized routine derived from that expertise.

**Solution Summary:** A personal skincare routine tracker where an admin curates a master product list (with ordering, frequency, and incompatibility rules) bundled into the app; users select the products they own and receive a personalized, correctly-ordered daily routine with optional lightweight tracking.

---

## 2. Project Type
- [x] **UI** — Flutter app (Graphical User Interface, phone-first)
- [x] **Cross-platform** — Single Flutter codebase → Android (sideloaded APK) + Web (for iPhone/Safari and any browser)

The Admin authors content at **build time** (bundled data, not a runtime UI). The User app is the primary UI target.

---

## 3. Target Users

**Primary Users:**
- **Admin:** The app author. One person. Authors the master product list, deprecates products, issues optional premium license keys — all at build/config time, not within the running app.
- **User:** Hebrew-speaking individuals (personal network of admin) who follow a skincare routine. Non-technical general users. Use the app on their own Android phone or iPhone (via Web build).

**Technical Level:** General user (non-technical). App must be intuitive enough for someone who simply wants to know what to put on their face today.

**Use Context:**
- Daily: open app, see what products to use today (Morning and/or Evening), optionally tap to record what was used.
- Periodic: review history (calendar), browse skin photo journal, manage product selections.
- Setup: once at start, and when routine changes.
- Both platforms are phone-sized touch interfaces (Web used primarily on iPhone).

---

## 4. Inputs

| Input | Format | Source | Validation / Rules |
|-------|--------|--------|------------|
| Master product list | Bundled JSON/config at build time | Admin (authored out of band) | Stable IDs; name, optional image, optional comment, category, slot(s), order, frequency rule, deprecated flag |
| Incompatibility rules | Bundled config at build time | Admin | Product↔product or category↔category pair + scope (within Morning / within Evening / same-day across both) |
| User product selection | Toggle per product per slot | User tap | Deprecated products not selectable; empty selection is valid |
| Schedule (weekday toggles) | Days of week per occasional product | User tap, Sunday-first | Soft cap: warn if over admin's "max N/week" limit (non-blocking) |
| Order override | Drag-to-reorder within a slot | User gesture | Optional; defaults to admin order; "Reset" action discards override |
| Daily record ("done") | Toggle per product per day | User tap | Reversible; optional; credited to the calendar day active at time of tap, respecting 6am boundary |
| Skin log text | Free text (Hebrew expected) | User keyboard input | Optional per day; can coexist with or without photos |
| Skin log photos | Image files | Camera or gallery (Android) / browser file/camera picker (Web) | Stored locally at bounded resolution; multiple photos per day |
| Import archive | Portable archive file (user's prior export) | User file picker | Must be a valid previously-exported archive; triggers Replace or Merge flow |
| License key (deferred, Web only) | Text string | User entry (key issued by admin out-of-band) | Validated against admin-issued key; unlocks premium cloud backup & restore (post-v1.0) |

---

## 5. Outputs

| Output | Format | Destination | Notes |
|--------|--------|-------------|-------|
| Resolved daily routine | Screen display (S4 Daily Home) | User, on device | Morning + Evening per slot; only products scheduled for today; in effective order |
| Streak display | Screen display (S10, embedded in S4) | User, on device | Current streak + longest streak; optional weekly-miss budget |
| Calendar history | Monthly grid (S6) + day detail (S7) | User, on device | Four completion states: complete / partial / missed / future; colorblind-safe |
| Skin journal | Chronological photo gallery (S9) | User, on device | Past skin-log photos for visual comparison over time |
| Incompatibility warnings | Soft inline/banner warnings | User, in-app | Advisory only; never blocks; names both conflicting products verbatim |
| Deprecation notices | Inline row marker (S4/S5/S7) | User, in-app | "No longer recommended" on products admin has deprecated |
| Backup reminder | Dismissible in-app nudge (S16) | User, in-app | Gentle, non-blocking; shown when no recent export exists |
| Export archive | Single portable, open-format archive | User file system / share sheet | Contains all user data (selections, schedules, overrides, day records, skin log + photos); master list excluded |
| Update review | First-run screen after version change (S14) | User, in-app | New unselected products; newly deprecated flagged; data-intact confirmation; export offer |
| Version + changelog | Screen (S13 About/What's New) | User, in-app | Current version ID and per-version changelog of master-list changes |

---

## 6. Core Features (Priority Order)

### Setup & Personalization
1. **Product Selection (UC-4, S1 — setup wizard):** Step-by-step per-category flow for first-time setup. User marks owned products per slot (Morning/Evening). Daily incompatibility conflicts surface here with mutable soft warnings.
2. **My Products Tab (S1b — browse mode):** Persistent bottom-nav tab (`/products`). Flat searchable product list grouped by category. Search bar + slot filter chips (All / Morning / Evening). Same toggle/timing controls as S1. Selected-count badge. "Add custom product" CTA at bottom. Barcode scan FAB on Android.
3. **Barcode Scan (S1c — Android only):** Camera-based barcode scanner bottom sheet (`BarcodeScanSheet`). On barcode detection: (1) checks master product list by `barcodes` field — if matched, shows "Recognized product" card with product name/brand/slots and a one-tap "Add to Routine" CTA; if already in all applicable slots, shows "Already in your routine" badge. (2) If no master match: queries 5 external APIs in parallel (OpenBeautyFacts, OpenFoodFacts, UPCItemDB, InciBeauty, BarcodeSpider), merges results by priority (OBF wins), pre-fills AddCustomProductSheet. (3) If all APIs return nothing: "Not found" state with manual entry CTA. Requires `CAMERA` permission on Android; FAB hidden on Web (`kIsWeb` guard). Barcode field is present on all master products (24/33 have confirmed barcodes as of v1.0.1).
4. **Custom Products:** User can add their own products (name, slot, timing) via the Add Custom Product sheet, accessible from S1, S1b, and post-barcode-scan. Custom products are stored locally, not in the admin master list.
5. **Schedule Setup (UC-5, S2):** For "max N/week" products, user assigns specific weekdays (Sunday-first toggles). Soft over-cap warning; day-dependent incompatibility conflicts surface here.
6. **Order Customization (UC-6, S3):** Optional drag-to-reorder within a slot. "Reset to recommended order" action. Personal override stored locally.

### Daily Use
4. **Daily Home / Today's Routine (UC-8, UC-9, S4):** Primary screen. Shows today's Morning + Evening resolved routine (all daily products + occasional products scheduled today), in effective order. Users optionally record each product as "done" — reversible, never required. 6am day boundary governs which day it's credited to.
5. **Product Detail Expand (UC-10, S5):** Routine item row expands to reveal admin-authored product image and persistent comment. Same comment displayed identically everywhere the product appears.

### History & Motivation
6. **Calendar History (UC-11, S6/S7):** Monthly RTL grid showing past days as complete / partial / missed / future. Tap a day for the Day Detail — the routine as it was that day, which items were recorded, and the skin log. Past records are editable.
7. **Streak Tracking (UC-13, S10):** Continuously computed current streak and longest streak. Slot done = ≥1 product recorded. Complete day = both slots done. Miss = one empty scheduled slot. 3 slot-misses forgiven per Sun–Sat week; 4th resets streak; unused grace does not carry over. Unscheduled slots never count as misses.
8. **Skin Log Entry (UC-14, S8):** Per-day optional free-text notes and/or photos (camera or gallery; browser picker on Web). Photos stored locally at bounded resolution.
9. **Skin Journal (UC-15, S9):** Chronological gallery of past skin-log photos for visual review over time.

### Data Portability & Updates
10. **Export (UC-16, S12):** On user request, produces a single portable archive of all user data including photos. Manual only — no auto-backup in the free product.
11. **Import / Restore (UC-17, S12):** User picks a prior export and chooses Replace (overwrite all) or Merge (sequential per-conflict chooser for each differing record).
12. **Backup Reminder (UC-20, S16):** Gentle, non-blocking, dismissible in-app nudge when no recent backup exists. Critical for Web users whose browser storage can be evicted.
13. **Update Review (UC-18, S14):** After a master-list version change, presents new unselected products, newly deprecated products the user has selected, and a data-intact confirmation with an export offer.
14. **Version & Changelog (UC-19, S13):** Displays current version ID and a per-version changelog.
15. **Incompatibility Feedback (UC-4b):** Advisory warnings when two products that an admin rule marks as incompatible appear in the same daily routine context (within the rule's scope). Daily↔daily clashes mutable by user; day-dependent clashes shown at scheduling and on daily view.
16. **Deprecation Handling (UC-12):** Deprecated products not offered for new selection; if user already uses one, it's marked "no longer recommended" everywhere it appears, but continues to function until removed. History preserved regardless.

### Admin Authoring (at build time — not a runtime UI)
17. **Master List Authoring (UC-1):** Admin defines products (stable ID, name, optional image, optional comment, category, slot membership, canonical order, frequency rule) and bundles them into the release.
18. **Incompatibility Rule Authoring (UC-1b):** Admin defines advisory product/category pair rules with scope. Bundled into the release.
19. **Product Deprecation (UC-2):** Admin marks a product deprecated. Ships in next release. Product remains in data forever (never deleted).
20. **Release (UC-3):** Admin assigns version ID and master-list content version; records changelog. Distributed as APK (Android) or updated web host.

### Admin Portal (web-only, separate tool — UC-AP)
A standalone local web app (`admin/`) that the admin runs on their machine to build and maintain the master product list without hand-editing JSON.

**UC-AP1 — Bulk URL Import:** Admin pastes one or more product page URLs (YesStyle, OliveYoung, iHerb) into an import panel. The portal's server-side scraper fetches each page and auto-extracts: product name, brand, image URL, and any available description. One card is created per URL. Graceful fallback if scraping fails — card is created in blank/manual-entry mode with the URL saved as reference.

**UC-AP2 — Product Card Editing:** Each scraped or manually-created product is displayed as an editable card with fields: name (pre-filled from scrape), category (dropdown from existing categories), morning slot (on/off, order, frequency), evening slot (on/off, order, frequency), comment (Hebrew text, admin-authored), image asset path, deprecated flag. Category list and current products are loaded from the live `assets/data/master_products.json`.

**UC-AP3 — Category Management:** Admin can add new categories (id + Hebrew name) directly in the portal. New categories appear immediately in product card dropdowns.

**UC-AP4 — Product List Review:** A sidebar shows all current products (from the bundled JSON), grouped by category, with inline deprecation toggle. Admin can reorder products within a category by drag-and-drop to set canonical `order` values.

**UC-AP5 — Export JSON:** "Save to file" button downloads the updated `master_products.json` ready to drop into `assets/data/`. The admin then commits and rebuilds the Flutter app. The portal never auto-writes to the file system — download is always explicit.

**Access model:** Local only — runs as `node admin/server.js`, opens on `localhost:3001`. No authentication needed (local-machine tool). Not deployed to any public URL in v1.0.

### Deferred Premium (post-v1.0, Web only)
21. **License Activation (UC-21, S15):** Web-only. User enters admin-issued license key to unlock cloud backup & on-demand restore. Not sync. Restore reuses UC-17's Replace/Merge logic. No in-app purchasing — key issued by invitation out of band.

---

## 7. Edge Cases & Error Handling

| Scenario | Expected Behavior |
|----------|-------------------|
| Empty slot today | Graceful "nothing scheduled" rest state; not counted as a missed slot for streak purposes (UC-8, UC-13) |
| Empty overall selection | Permitted; user can proceed with an empty routine |
| Daily product + daily product incompatibility | Soft warning at selection time (S1); persists as quiet marker on daily view; user may mute that specific conflict pair (UC-4b) |
| Day-dependent incompatibility | Soft warning at scheduling (S2) and on daily view (S4) for affected days; never blocks (UC-4b) |
| Over-cap scheduling | Soft, non-blocking warning shown at scheduling (S2); user may proceed regardless (UC-5) |
| Deprecated product in active routine | Marked "no longer recommended" in S4/S5/S7; still usable; not offered for new selection; history preserved (UC-12) |
| Same product in both Morning and Evening slots | Independent selection, order, frequency rule, and daily record per slot; one shared image and admin comment (UC-4) |
| 6am day boundary | Activity before 6am credits to the prior calendar day. Home screen's "today," day records, and streak all respect this (UC-8, UC-13) |
| Streak: blank day (no recording at all) | Counts as 2 misses if both slots were scheduled; 1 miss if only one slot was scheduled; 0 if no slots were scheduled |
| Streak: grace exhausted | After 3 slot-misses in a Sun–Sat week, the 4th miss resets streak to zero; unused grace resets each Sunday (UC-13) |
| Post-update reconciliation | On first run after master-list version change: matching products keep selection/schedule/order; new products appear unselected; deprecated products flagged; user data intact; export offered (UC-18) |
| Import: Replace | Overwrites all local data with archive; irreversible action (UC-17) |
| Import: Merge conflict | For each record present in both archive and local data with differing content, sequential per-conflict chooser is presented — one conflict at a time (UC-17) |
| Web browser storage eviction | iOS Safari may clear browser storage after periods of non-use. Risk surfaced to web users; mitigated by backup reminders (UC-20) and manual export (UC-16); deferred premium cloud backup is the durable solution (UC-21) |
| Android signing key change | A key change forces uninstall/reinstall and destroys local data — unacceptable. Same signing key must be used for all releases with strictly increasing versionCode (NFR-M5) |
| Large master list | Selection remains scannable via category grouping; day view resolves promptly with up to ~100 products (PRD §10) |
| Bidirectional text | Latin-script brand names (LTR) embedded in Hebrew lines (RTL) must render correctly — e.g., in routine rows, category headers, changelog, admin comments (NFR-L2) |
| Order override vs. admin default | Effective order = personal override if set, else admin order. Occasional products sit in their admin position. Override state indicated; "Reset" action available (UC-6) |
| Muted incompatibility conflict that no longer exists | If the user's selection/schedule changes so that the conflicting pair no longer coexists, any mute for that pair is cleared (UC-7) |

---

## 8. Constraints

- **Platform:** Android (≥ API 29 / Android 10) and Web (current mobile browsers, primarily iPhone/Safari). Single Flutter codebase for both targets.
- **Distribution:** Android via directly-shared sideloaded APK (no app store); Web via admin-hosted URL. No automatic update delivery; users install/refresh manually.
- **Language & Layout:** Entire interface in Hebrew, RTL. Product names and category names displayed verbatim (admin-authored, bidirectional-safe). No translation or localization of admin content.
- **Offline-First:** Free product requires no network at runtime on either platform. No backend, no accounts, no sync.
- **Privacy:** No analytics, telemetry, or third-party data collection in v1.0.
- **Storage:** All user data and bundled images stored locally on-device/in-browser. User-captured photos stored at bounded resolution.
- **Performance:** Day view resolves promptly with up to ~100 master products. Typical routine ~10 products per slot; monthly history opens promptly.
- **Data durability:** User data must survive app updates. Schema versioned independently of master-list content. Products referenced by stable IDs (never by name/position). Products never deleted — only deprecated.
- **Android signing:** Same signing key across all releases; strictly increasing versionCode. Key loss = data loss for all users (unacceptable).
- **Premium-readiness (for v1.0 data model):** Local data structured so a full dataset can be serialized/restored as a unit; records carry stable IDs and last-modified metadata. Free-product behavior must never depend on any backend.
- **No reminders/push notifications** in v1.0.
- **No multiple user profiles** on a single device.
- **Custom products are local only** — users may add their own products via the Add Custom Product sheet; these are stored only on-device and are not part of the admin master list. Custom products are not subject to incompatibility rules or frequency validation.
- **Design system:** "Radiant Dew" — warm golden-hour aesthetic; soft minimalism + glassmorphism; Quicksand + Plus Jakarta Sans (both must render Hebrew well); pill buttons, extreme roundness; cream surface (#FFF8F6); primary Vibrant Peach (#9E412C).

---

## 9. Open Questions (TBD)

*(None — the PRD v4.0 and UX brief fully specify all functional requirements for v1.0.)*

Post-v1.0 items explicitly deferred:
- Premium cloud backup & restore for Web users (UC-21) — data model designed for, implementation deferred.
- In-app / backend-fed master-list updates.
- Per-user tailored master lists.
- Push notifications / reminders.
- Adherence statistics beyond streaks.
- Before/after skin-log comparison.
- Additional languages.

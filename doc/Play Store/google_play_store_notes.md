# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Contact us, override order indication & bug fixes

**Version:** `1.4.0+8` (from `1.3.1+7`). Minor bump — two new user-facing capabilities, several bug fixes, no schema changes.

### What changed since `1.3.1+7`

New features:
- **"Contact us" option in Settings** — users can now reach the developer directly from within the app.
- **Manual order override indicator on My Day screen** — when a product's order has been manually overridden, a visual chip now appears on the daily routine to make the override visible.
- **Manual order notification moved to order screens** — the chip/notification for overridden order now appears in the Order Customization and related screens, improving discoverability.

Bug fixes (also in this build, from the earlier `1.3.1+7` prep):
- **Routine summary not appearing during onboarding** — write-race condition fixed.
- **Flipped chevron icons in LTR (English) layout** — fixed across all affected screens.
- **Vertical day headers in Weekly Glance (Hebrew)** — day labels now display correctly.
- **Products order bug with removed manually-overridden products** — order is now stable when overridden products are removed.
- **Home icon in app bar when navigating from My Shelf** — tapping the Weekly Glance card from My Shelf now correctly shows a home icon instead of a back arrow.

**No new Android permissions.** No `AndroidManifest.xml` changes.

**No new external network calls.** All changes are local.

---

### App description update

Updated `doc/Play Store/full_description.md` to add "contact us" capability to the feature list.

---

### Screenshots

Refreshed screenshot set in place under `assets/for_play_store/screenshots/` (EN + HE). Consider updating My Day screen screenshot if the override chip is visually prominent.

---

### What's New (250-char limit)

**Hebrew:**
> עכשיו ניתן ליצור קשר מתוך האפליקציה. שגרת היום מציגה אינדיקציה על מוצרים שסדרם שונה ידנית. תיקוני באגים ושיפורי ממשק.

**English (if maintained):**
> New: contact us from the app. Manual order overrides are now shown on the daily screen. Bug fixes and UI improvements.

---

### Data safety section

**No change required.** No new data types, recipients, or network calls.

---

### Privacy policy

**No change required.** No new data flows.

---

### Internal checklist before submission

- [ ] `version` in `pubspec.yaml` updated to `1.4.0+8` (versionCode 7 → 8)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test: "Contact us" visible in Settings; override chip appears on My Day screen for overridden products; onboarding summary screen appears; chevrons correct in both Hebrew and English
- [ ] Screenshots updated if the override chip is visually prominent on My Day
- [ ] `doc/Play Store/full_description.md` updated — copy the new "contact us" bullet into Play Console
- [ ] `doc/Play Store/short_description.md` — no change this release
- [ ] No Data safety / permissions / privacy-policy actions needed this release

---

## Release history

### Released as `1.3.1+7` — Bug fixes (onboarding summary & chevron icons)

Patch over `1.3.0+6` (which was never submitted standalone). Bug fixes only — routine summary write-race, flipped chevrons in English UI, miscellaneous UI tweaks. No schema changes, no new permissions, no new features. Superseded immediately by `1.4.0+8` before submission.

### Drafted `1.3.0+6` — Weekly skin reminder, routine summary & product wizard (never submitted — superseded by `1.3.1+7`)

User-facing features added over `1.2.0+5`:
- **Weekly skin-tracking reminder** — dismissible home-screen card; inline photo+note capture; auto-hides when a skin-log photo exists in the last 7 days; toggle in Settings.
- **Routine summary screen** — auto-built routine preview (ordered, morning/evening) shown after product selection, used in onboarding and the new product wizard.
- **Product wizard for returning users** — streamlined re-entry flow to add/remove products without redoing full onboarding.

Bug fixes: reverted to system photo picker (`image_picker`); `subCategoryId` carried correctly; assorted UI fixes.

Data: new local settings flags for weekly-reminder state; no schema break. No new permissions, no new network calls.

### Shipped `1.2.0+5` — Custom products, manual editing & much wider product lookup

Minor bump from `1.1.0+4`. Consolidated all changes since the last shipped build into a single submission.

User-facing features:
- **Custom products** — users can add their own products and **manually enter or edit** product details (name, category, image), not just pick from the master list.
- **Automatic detail fill on scan** — scanning a barcode auto-populates product fields where a match is found.
- **Much wider product lookup** — lookup queries a broad set of external product databases and retailer/ingredient sites, matching by **product name** as well as barcode.
- **Smarter routine completion** on the daily screen.
- Also new at the time: redesigned onboarding, two-tier smart routine ordering, conflict detection & resolution, streak-first home screen, weekly product overview, Radiant Dew daily-tracking screen.

Data / storage:
- New **local** `user_custom_products` table plus sub-category / category-override support. Additive migration only.

Network / data safety (declared at submission):
- `lib/data/remote/barcode_lookup_service.dart` fans a **barcode number and/or product name** out to **nine** external product-lookup services: Open Beauty Facts, Open Food Facts, UPC Item DB, INCI Beauty, Barcode Spider, iHerb, YesStyle, Olive Young Global, InciDecoder. The product **name** being sent off-device was new in this release. Declared in the Play Console **Data safety** form (product identifier / search query, user-initiated, no personal data, no image stored or transmitted).

Permissions:
- **No new Android permissions.** `CAMERA` + `INTERNET` shipped in earlier cycles. CAMERA used for barcode scanning (core functionality; no image stored or transmitted).

Privacy policy:
- Updated to state that the barcode number **and/or product name** are sent to external product-lookup services (Hebrew + English, generic wording, no service names listed).

### Drafted `1.2.0+5` — superseded

> An earlier draft of `1.2.0+5` listed only five barcode-lookup services and was never submitted on its own; its scope was folded into the shipped `1.2.0+5` above.

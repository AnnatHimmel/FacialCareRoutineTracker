# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Sub-category display fix, custom products in order screen & bug fixes

**Version:** `1.5.0+9` (from `1.4.0+8`). Minor bump — custom products now appear in Order Customization screen (new capability), plus several bug fixes.

### What changed since `1.4.0+8`

New capability:
- **Custom products in Order Customization screen** — custom (user-added) products now appear alongside master-list products in the drag-to-reorder screen. Previously they were missing from that screen and could not be reordered.

Bug fixes:
- **Sub-category shown correctly in product details** — the sub-category dropdown in the product detail/edit sheet was always empty due to a stale offline bundle. Now displays the correct value.
- **Daily frequency restored for certain products** — one sunscreen product was incorrectly capped at 3×/week in the offline bundle and in any stored schedule derived from it. The bundle is corrected and a one-time startup migration heals existing installations automatically.
- **Stale offline cache cleared** — cache key bumped so existing devices discard any outdated bundle and load fresh content on next launch.

Internal / tooling:
- `flutter analyze` warnings resolved.
- e2e test runner configuration fixed.
- Bundled master JSON is now a generated artifact (regenerated from Supabase at every release); `_generated` header added to both bundle files.

**No new Android permissions.** No `AndroidManifest.xml` changes.

**No new external network calls.** All changes are local (bundle regeneration is a build-time step, not a runtime call).

---

### App description update

No change to `doc/Play Store/full_description.md` — custom products were already in the feature list; the Order screen fix is an enhancement to that existing capability, not a new feature.

---

### Screenshots

No screenshot update needed — no visible UI changes on the main screens.

---

### What's New (250-char limit)

**Hebrew:**
> תיקוני באגים: תת-קטגוריית המוצר מוצגת כעת בצורה נכונה; מוצרים מותאמים אישית מופיעים כעת במסך התאמת הסדר; תדירות מוצרים הוקפאה בגרסה הישנה — תוקנה אוטומטית.

**English (if maintained):**
> Bug fixes: product sub-category now displays correctly; custom products now appear in the order screen; a product's frequency cap from an older version is auto-corrected on launch.

---

### Data safety section

**No change required.** No new data types, recipients, or network calls.

---

### Privacy policy

**No change required.** No new data flows.

---

### Internal checklist before submission

- [ ] `version` in `pubspec.yaml` updated to `1.5.0+9` (versionCode 8 → 9)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test: open a product in the detail sheet → sub-category shows correctly; open Order Customization → custom products are present and draggable; prod-007 (Relief Sun) shows 7 days in Schedule Setup after first launch
- [ ] `doc/Play Store/full_description.md` — no change this release
- [ ] `doc/Play Store/short_description.md` — no change this release
- [ ] No Data safety / permissions / privacy-policy actions needed this release

---

## Release history

### Released as `1.4.0+8` — Contact us, override order indication & bug fixes

Minor bump from `1.3.1+7`. Two new user-facing capabilities, several bug fixes, no schema changes.

New features: "Contact us" option in Settings; manual order override indicator on My Day screen; override notification moved to Order Customization screen.

Bug fixes: routine summary write-race (onboarding); flipped chevrons in English layout; vertical day headers in Weekly Glance (Hebrew); order stability with removed overridden products; home icon from My Shelf entry point.

No new permissions, no new network calls, no privacy policy change.

---

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

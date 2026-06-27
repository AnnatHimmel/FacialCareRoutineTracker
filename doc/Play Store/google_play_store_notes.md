# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Bug fixes — onboarding summary & chevron icons

**Version:** `1.3.1+7` (from `1.3.0+6`). Patch bump — bug fixes only, no new features, no schema changes.

### What changed since `1.3.0+6`

Bug fixes:
- **Routine summary not appearing during onboarding** — a write-race condition caused the summary screen to skip; fixed and covered by a regression test.
- **Flipped chevron icons in LTR (English) layout** — chevrons on list rows and navigation elements were mirrored incorrectly when the UI language was set to English. Fixed across all affected screens.
- Minor UI tweaks to week-glance screen, schedule setup, and shared button widget.

**No new Android permissions.** No `AndroidManifest.xml` changes.

**No new external network calls.** All changes are local UI fixes.

---

### App description update

No change — no new user-facing features.

---

### Screenshots

Refreshed screenshot set already in place under `assets/for_play_store/screenshots/` (7 each, **English + Hebrew**) from the `1.3.0+6` prep. Upload both locales if not already done in Play Console.

---

### What's New (250-char limit)

**Hebrew:**
> תיקוני באגים: מסך הסיכום של השגרה מוצג כהלכה בהטמעה, ואייקוני הניווט מוצגים בכיוון הנכון בממשק האנגלי.

**English (if maintained):**
> Bug fixes: the routine summary screen now shows correctly during onboarding, and navigation chevrons display in the right direction in the English UI.

---

### Data safety section

**No change required.** No new data types, recipients, or network calls.

---

### Privacy policy

**No change required.** No new data flows.

---

### Internal checklist before submission

- [x] `version` in `pubspec.yaml` updated to `1.3.1+7` (versionCode 6 → 7)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test: onboarding summary screen appears; chevrons point correctly in both Hebrew and English
- [x] Refreshed screenshot set ready (EN + HE) under `assets/for_play_store/screenshots/`; upload both locales in Play Console if not yet done
- [ ] `doc/Play Store/full_description.md` — no change this release
- [ ] `doc/Play Store/short_description.md` — no change this release
- [ ] No Data safety / permissions / privacy-policy actions needed this release

---

## Release history

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

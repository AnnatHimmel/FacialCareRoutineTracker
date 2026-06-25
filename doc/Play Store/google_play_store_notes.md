# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Weekly skin reminder, routine summary & product wizard

**Proposed version:** `1.3.0+6` (from `1.2.0+5`). Minor bump — new user-facing screens and capabilities, all local-only, backward compatible, no data-schema break.

### What changed since the last shipped release (`1.2.0+5`)

User-facing features:
- **Weekly skin-tracking reminder** — a gentle, dismissible card near the top of the home screen prompts the user once a week to photograph and note her skin. Capture is inline (one tap appends a photo + note to today's skin log). The card auto-hides once a skin-log photo exists in the last 7 days, and can be turned off entirely from **Settings**.
- **Routine summary screen** — after picking products, a new summary screen shows the auto-built routine (correct order, morning/evening) before the user fine-tunes scheduling. Used in onboarding and the new product wizard.
- **Product wizard for returning users** — a streamlined re-entry flow to add or remove products (and review the resulting routine) without redoing the full onboarding.

Bug fixes:
- Reverted to the system photo picker (`image_picker`) for skin-log capture; removed the experimental in-app camera screen.
- `subCategoryId` correctly carried through product handling; assorted UI fixes.

Data / storage:
- New **local** settings flags for the weekly-reminder enable/dismiss state. No schema break; existing user data is preserved.

Content (master list):
- Minor master-catalog touch-ups, applied to both Supabase and the bundled `assets/data/master_products.json`.

**No new Android permissions.** No `AndroidManifest.xml` changes this release. The weekly reminder uses the existing system photo picker — no new camera/storage permission is introduced.

**No new external network calls.** All new features are local-only. Product lookup is unchanged from `1.2.0+5` (same nine services, same barcode/name flow — already declared).

---

### App description update

See `doc/Play Store/full_description.md`. Added a feature bullet for the weekly skin-tracking reminder (Hebrew + English). No other copy changes.

---

### Screenshots

Consider adding/refreshing screenshots for:
- The weekly skin-tracking reminder card on the home screen.
- The new routine summary screen.

Play Console minimum: 2 screenshots per form factor.

---

### What's New (250-char limit)

**Hebrew:**
> חדש: תזכורת שבועית לתיעוד מצב העור — צילום והערה בלחיצה אחת מהמסך הראשי. נוסף מסך סיכום שמציג את השגרה שנבנתה עבורך, ואשף נוח להוספת והסרת מוצרים בלי להגדיר הכול מחדש. כולל תיקוני ממשק.

**English (if maintained):**
> New: a weekly reminder to track your skin — snap a photo and note in one tap from the home screen. Plus a routine summary screen, and a wizard to add or remove products without redoing setup. Includes UI fixes.

---

### Data safety section

**No change required this release.** No new data types, no new recipients, no new network calls. Product lookup (barcode + product name to nine external services) is unchanged from `1.2.0+5` and remains declared as before. The weekly reminder stores photos and notes **locally only** — nothing is transmitted.

---

### Privacy policy

**No change required.** No new data flows. `web/privacy.html` already covers local photo/note storage and the product-lookup data flow.

---

### Internal checklist before submission

- [ ] Bump `version` in `pubspec.yaml` to `1.3.0+6` (versionCode 5 → 6)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test: weekly reminder appears → capture photo+note → card hides; Settings toggle hides it; routine summary screen renders; product wizard add/remove → routine rebuilds
- [ ] Screenshots updated for the weekly reminder + routine summary (if UI shown to users changed)
- [ ] `doc/Play Store/full_description.md` updated and copy-pasted into Play Console
- [ ] `doc/Play Store/short_description.md` — no change this release
- [ ] No Data safety / permissions / privacy-policy actions needed this release

---

## Release history

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

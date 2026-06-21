# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Custom products, manual editing & much wider product lookup

**Proposed version:** `1.2.0+5` (from `1.1.0+4`). Minor bump — new user-facing capabilities plus an additive local DB table, all backward compatible, no data-schema break.

> **Note:** The previously drafted `1.2.0+5` notes were **never deployed**. This release consolidates *all* changes since the last shipped build (`1.1.0+4`) into a single submission. The archived draft is kept under **Release history** for reference only.

### What changed since the last shipped release (`1.1.0+4`)

User-facing features:
- **Custom products** — users can now add their own products and **manually enter or edit** product details (name, category, image), not just pick from the master list.
- **Automatic detail fill on scan** — scanning a barcode now auto-populates product fields where a match is found.
- **Much wider product lookup** — lookup now queries a broad set of external product databases and retailer/ingredient sites, and matches by **product name** as well as barcode, for far better match rates (see network-calls note below).
- **Smarter routine completion** — enhanced smart-completion behavior on the daily screen.
- Carried forward from the un-shipped draft (also new to users): redesigned onboarding, two-tier smart routine ordering, conflict detection & resolution, streak-first home screen, weekly product overview, Radiant Dew daily-tracking screen.

Bug fixes:
- Assorted UI fixes across setup and the day-detail screen.
- (Carried forward) wrong-day display just after midnight, duplicate conflict messages, undo-button label.

Data / storage:
- New **local** `user_custom_products` table (plus sub-category / category-override support carried forward). Additive migration only — existing user data is preserved.

Content (master list):
- Master catalog re-classification and barcode data, applied to both Supabase and the bundled `assets/data/master_products.json` / `incompatibility_rules.json`.

**No new Android permissions.** `CAMERA` and `INTERNET` already shipped in earlier cycles.

### New external network calls (product lookup) — data-safety relevant

`lib/data/remote/barcode_lookup_service.dart` plus the registered scrapers now fan a **barcode number and/or a product name** out to **nine** external product-lookup services. The product **name** being sent off-device is a **new data flow** this release (previously only the barcode number was transmitted).

| Service | Host | Query type | Status vs. last shipped build |
|---|---|---|---|
| Open Beauty Facts | `world.openbeautyfacts.org` | barcode + name | existing host, now also name |
| Open Food Facts | `world.openfoodfacts.org` | barcode | existing |
| UPC Item DB | `api.upcitemdb.com` | barcode | existing |
| INCI Beauty | `world.incibeauty.com` | barcode | existing |
| Barcode Spider | `www.barcodespider.com` | barcode | existing |
| **iHerb** | `www.iherb.com` | barcode + name | **new** |
| **YesStyle** | `www.yesstyle.com` | barcode + name | **new** |
| **Olive Young Global** | `global.oliveyoung.com` | name | **new** |
| **InciDecoder** | `incidecoder.com` | name | **new** |

The barcode (EAN/UPC) and the product name are user-initiated data sent off-device to third-party services. Under Google Play policy this must be declared in the **Play Console Data safety form** (see Data safety section below). The privacy policy uses generic language ("external product-lookup services") and does not name individual providers.

---

### App description update

Suggested addition to the **long description** (Hebrew):

> **חדש: הוספת מוצרים משלך וזיהוי חכם יותר**
> כעת ניתן להוסיף מוצרים משלך ולערוך את פרטיהם ידנית, וסריקת הברקוד משלימה את הפרטים אוטומטית מתוך מאגרי מוצרים חיצוניים רחבים יותר — לזיהוי טוב יותר לפי ברקוד או לפי שם המוצר.

English (if maintained):

> **New: add your own products and smarter recognition**
> You can now add your own products and edit their details by hand, and barcode scanning fills in the details automatically from a much wider set of external product databases — matching by barcode or by product name.

---

### Screenshots

Consider adding/refreshing screenshots for:
- The add-custom-product / manual edit flow.
- Barcode scan with auto-filled details.
- (If not already updated) onboarding, streak-first home, and weekly product overview.

Play Console minimum: 2 screenshots per form factor.

---

### What's New (250-char limit)

**Hebrew:**
> כעת ניתן להוסיף מוצרים משלך ולערוך את פרטיהם ידנית. סריקת ברקוד משלימה פרטים אוטומטית, וזיהוי המוצרים שופר משמעותית — לפי ברקוד או לפי שם, ממאגרים חיצוניים רבים יותר. בנוסף: השלמת שגרה חכמה יותר ותיקוני ממשק.

**English (if maintained):**
> You can now add your own products and edit their details by hand. Barcode scanning auto-fills details, and product recognition is much wider — matching by barcode or name across more external databases. Plus smarter routine completion and UI fixes.

---

### Data safety section

**Play Console action required this release.**

Product lookup now sends the scanned **barcode number** and, newly, the **product name** to **nine** external product-lookup services (five existing, four new: iHerb, YesStyle, Olive Young Global, InciDecoder). The Data safety form must reflect this.

In Play Console → **App content → Data safety**:

1. Under **Data types** → confirm the lookup action is covered (product identifier / search query, not a personal identifier).
2. Under **Data shared** → declare that the barcode value **and the product name the user enters** are shared with third-party services for product lookup, at the user's explicit initiation. Update the entry to cover **all nine** services.
3. **Data collected:** None beyond prior declarations — no personal data, no device identifiers, no image stored or transmitted.
4. **Location data / Photos / Camera:** no change from prior declaration.

> If the form was worded generically ("third-party product databases"), verify the wording still covers product-name queries. If it named services individually, expand the list to all nine.

---

### Permissions declaration (CAMERA) — carry-over, confirm status

`android.permission.CAMERA` is declared and used for barcode scanning. It was introduced in an earlier cycle, **not** this release. If it was never declared in a published submission (the prior barcode build was never deployed), complete it before submitting:

1. **App content → Permissions declaration** → add `CAMERA`, type: core functionality.
   > "The camera is used to scan the barcode on skincare product packaging so the user can quickly look up a product. No image is stored or transmitted. The camera is only active during a scanning session initiated by the user."

If CAMERA was already declared in a previous submission, no action is needed.

---

### Privacy policy

**Updated this release.** `web/privacy.html` now states that the barcode number **and/or the product name** the user enters are sent to external product-lookup services (Hebrew + English kept in sync). Still uses generic language — no service names listed.

- Action: ensure the hosted privacy policy URL is live and current **before** submitting the build.

---

### Internal checklist before submission

- [ ] Bump `version` in `pubspec.yaml` to `1.2.0+5` (versionCode 4 → 5)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test: add custom product + manual edit, barcode scan auto-fill, name-based lookup, smart completion, onboarding, streak home, week overview
- [ ] Privacy policy URL confirmed live (text updated — product name now disclosed)
- [ ] Play Console **Data safety** form updated for all nine lookup recipients incl. the product-name flow
- [ ] CAMERA permission declaration confirmed in Play Console (carry-over)
- [ ] Screenshots updated for the new custom-product / edit flow

---

## Release history

### Drafted `1.2.0+5` — never deployed (superseded by the consolidated release above)

> Original draft summary: *Smart routine ordering, new onboarding, streak home & wider barcode lookup.* Listed five barcode-lookup services (Open Beauty Facts, UPC Item DB, Open Food Facts, INCI Beauty, Barcode Spider) and proposed the same `1.2.0+5` version. This draft was never submitted to the Play Console; its features are folded into the current "Next release" section, which supersedes it. Retained here only so the original Data safety / CAMERA notes are not lost:
>
> - Barcode lookup expanded to five services (two existing + three new at the time).
> - New local DB tables: `category_overrides`, sub-category support, custom products (additive migration).
> - No new Android permissions; CAMERA carry-over declaration noted.
> - Privacy policy left unchanged at the time (barcode-only, generic wording).

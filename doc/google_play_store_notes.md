# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: Smart routine ordering, new onboarding, streak home & wider barcode lookup

**Proposed version:** `1.2.0+5` (from `1.1.0+4`). Minor bump — several new user-facing features plus additive local DB tables, all backward compatible, no data-schema break.

### What changed since the last release (`1.1.0+4`)

User-facing features:
- **Redesigned onboarding** — new welcome screen, classified add-product flow, category review step, and a spread-default weekly schedule so a starter routine is set up automatically.
- **Two-tier routine ordering** — products are sorted by phase and then by sub-category for a more correct recommended order (PRD §15).
- **Smarter incompatibility handling** — opt-out conflict resolver with UI, sub-category conflict rules, startup auto-resolve, de-duplicated conflict messages, and a fixed undo action.
- **Streak-first home screen** — the streak is now a full widget on the home screen instead of a small chip.
- **Weekly product overview** — a new at-a-glance view of which products run on each day of the week.
- **Wider barcode lookup** — barcode scanning now checks the local/Supabase catalog first and queries three additional external product databases for better match rates (see network-calls note below).
- **Daily tracking screen** realigned to the Radiant Dew design.

Bug fixes:
- Fixed the home screen showing the wrong day's list just after midnight (6am day-boundary handling).
- Fixed duplicate conflict messages and the undo-button label.

Data / storage:
- New **local** DB tables added (`category_overrides`, sub-category support, custom products). Additive migration only — existing user data is preserved.

Content (master list):
- Expanded and re-classified the master product catalog (all products categorized), added new incompatibility rules, and added barcode data for 24 products. Applied to both Supabase and the bundled `assets/data/master_products.json` / `incompatibility_rules.json`.

**No new Android permissions** were introduced in this release. `CAMERA` already shipped in an earlier cycle.

### New external network calls (barcode lookup) — data-safety relevant

`lib/data/remote/barcode_lookup_service.dart` now fans the scanned barcode number out to **five** product-lookup services. Two existed before `1.1.0+4`; **three are new this release**:

| Service | Endpoint | Status |
|---|---|---|
| Open Beauty Facts | `world.openbeautyfacts.org` | existing |
| UPC Item DB | `api.upcitemdb.com` | existing |
| **Open Food Facts** | `world.openfoodfacts.org` | **new** |
| **INCI Beauty** | `world.incibeauty.com` | **new** |
| **Barcode Spider** | `www.barcodespider.com` | **new** |

The barcode number (EAN/UPC) is user-initiated data sent off-device to third-party services. Under Google Play policy this must be declared in the **Play Console Data safety form** (see Data safety section below). The privacy policy uses generic language ("external product-lookup services") and does not need to name each service individually.

---

### Permissions declaration (CAMERA) — carry-over, confirm status

`android.permission.CAMERA` is declared in the manifest and used for barcode scanning. It was introduced in an earlier cycle, **not** in this release. If the CAMERA declaration has not yet been completed in the Play Console (e.g. if the prior barcode build was never published), it must still be done before submitting this build:

1. **App content → Permissions declaration**
   - Add `CAMERA` to the declared permissions list.
   - Justification text (copy verbatim or adapt):
     > "The camera is used to scan the barcode on skincare product packaging so the user can quickly look up a product. No image is stored or transmitted. The camera is only active during a scanning session initiated by the user."
   - Permission type: core functionality.

If CAMERA was already declared in a previous submission, no action is needed here.

---

### Privacy policy

No text update required. `web/privacy.html` uses generic language ("external product-lookup services") for the barcode scanning section — no service names are listed, so adding new lookup providers does not require editing this file.

- Action: ensure the hosted privacy policy URL in the Play Console is live and current **before** submitting the build.

---

### App description update

Suggested addition to the **long description** highlighting the smarter routine ordering (Hebrew):

> **חדש: סדר שגרה חכם יותר**
> השגרה שלך מסודרת אוטומטית לפי שלב הטיפוח ותת-קטגוריה, עם זיהוי התנגשויות בין מוצרים והצעות לפתרון. בנוסף: תהליך התחלה מחודש, מסך רצף (streak) חדש, וסקירה שבועית של המוצרים שלך.

English (if maintained):

> **New: smarter routine ordering**
> Your routine is now ordered automatically by skincare phase and sub-category, with product-conflict detection and resolution suggestions. Plus a redesigned onboarding flow, a new streak home screen, and a weekly overview of your products.

---

### Screenshots

Consider adding/refreshing screenshots for the newly designed surfaces:
- New onboarding/welcome screens.
- Streak-first home screen.
- Weekly product overview.
- Order customization with the two-tier order.

Play Console minimum: 2 screenshots per form factor.

---

### What's New (release notes)

Suggested text for the **What's New** field (250-char limit):

**Hebrew:**
> סדר שגרה חכם יותר לפי שלב ותת-קטגוריה, זיהוי ופתרון התנגשויות בין מוצרים, תהליך התחלה מחודש, מסך רצף חדש וסקירה שבועית של המוצרים. שיפור בזיהוי מוצרים בסריקת ברקוד. תוקן באג של תצוגת היום שגוי אחרי חצות.

**English (if needed):**
> Smarter routine ordering by phase and sub-category, product-conflict detection and resolution, a redesigned onboarding, a new streak home screen, and a weekly product overview. Better barcode product matching. Fixed a wrong-day display after midnight.

---

### Data safety section

**Play Console action required this release.**

Barcode scanning now sends the scanned barcode number to five external product-lookup services (two existing, three new: Open Food Facts, INCI Beauty, Barcode Spider). The Data safety form must reflect this.

In Play Console → **App content → Data safety**:

1. Under **Data types** → confirm "App activity" or the relevant category includes the barcode lookup action.
2. Under **Data shared** → the barcode value (a product identifier, not a personal identifier) is shared with third-party services for the purpose of product lookup, at the user's explicit initiation. Add or update this entry to cover all five services.
3. **Data collected**: None beyond what was previously declared — no personal data, no device identifiers, no image is stored or transmitted.
4. **Location data / Photos / Camera**: no change from prior declaration.

If the form previously covered only the two original services by name, update it to cover five. If it was worded generically ("third-party product databases"), verify the wording still holds.

---

### Internal checklist before submission

- [ ] Bump `version` in `pubspec.yaml` to `1.2.0+5` (versionCode 4 → 5)
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Smoke-test onboarding, routine ordering, conflict resolver, streak home, week overview, and barcode scanning
- [ ] Privacy policy URL confirmed live (no text changes needed)
- [ ] Play Console **Data safety** form updated for the three new barcode-lookup recipients
- [ ] CAMERA permission declaration confirmed in Play Console (carry-over)
- [ ] Screenshots updated for the redesigned screens

# Google Play Store — Update Notes

This document tracks what needs to be done in the Play Console for each release that affects store metadata, permissions, or policy compliance.

---

## Next release: My Products redesign + Barcode scanning

### New Android permission: CAMERA

The app now requests `android.permission.CAMERA` at runtime when the user taps the barcode scan FAB on the My Products tab.

**Play Console action required:**

1. **App content → Permissions declaration**
   - Add `CAMERA` to the declared permissions list.
   - Justification text (copy verbatim or adapt):
     > "The camera is used to scan the barcode on skincare product packaging so the user can quickly look up a product. No image is stored or transmitted. The camera is only active during a scanning session initiated by the user."
   - Permission type: core functionality (not sensitive/dangerous beyond the barcode use case).

2. **Privacy policy update**
   - The `web/privacy.html` file already includes a new "Camera and barcode scanning" section (June 2026 revision).
   - Ensure the privacy policy URL linked in the Play Console points to the updated hosted version before submitting the update.

---

### App description update

The current short/long descriptions do not mention barcode scanning. Suggested addition to the **long description** (Hebrew):

> **חדש: סריקת ברקוד**
> סרקי את ברקוד האריזה של המוצר והוסיפי אותו לרשימה ישירות ממסך "המוצרים שלי".

Suggested addition to the **long description** (English — if you maintain one):

> **New: Barcode scanning**
> Scan the barcode on any product's packaging and add it to your My Products list directly from the app.

---

### Screenshots

Consider replacing or adding a screenshot of the redesigned **My Products** tab (browse mode) showing:
- The search bar at the top
- The slot filter chips (All / Morning / Evening)
- The floating "Scan Barcode" button (bottom-right, Android only)

Play Console minimum: 2 screenshots per form factor. If you have phone screenshots from the previous setup wizard view, add the new browse view alongside them.

---

### What's New (release notes)

Suggested text for the **What's New** field (250-char limit):

**Hebrew:**
> מסך "המוצרים שלי" עוצב מחדש: כעת ניתן לחפש, לסנן לפי בוקר/ערב, ולסרוק ברקוד כדי להוסיף מוצר חדש. כל שאר הנתונים שלך נשמרים ללא שינוי.

**English (if needed):**
> Redesigned My Products tab: search, filter by morning/evening slot, and scan a product barcode to add it. All your existing data is preserved.

---

### Data safety section

The current data safety answers should not require changes (no new data collection), but verify:

- **Location data**: Not collected — correct, no change.
- **Photos/videos**: Only on-device, user-initiated — correct, no change.
- **Camera**: The new permission is used to scan barcodes only, with no image storage or network transmission. This should be reflected as:
  - Data type: **Device or other IDs** — No.
  - Camera access: tick "Camera" under "Device or other IDs" > "Access camera" if Play Console requires it.
  - Data collected: **None** (barcode value is processed in-app only, never sent).

If Play Console flags a new "data access" review for CAMERA, the answer is: access is for app functionality (barcode scan), data is not collected or shared.

---

### Internal checklist before submission

- [ ] `versionCode` incremented in `android/app/build.gradle`
- [ ] Signed with the same keystore (never change the signing key)
- [ ] `flutter build apk --release` completes without errors
- [ ] Barcode scan FAB tested on a physical Android device
- [ ] Camera permission prompt tested (grant and deny flows)
- [ ] Privacy policy URL updated/confirmed live
- [ ] Play Console permissions declaration updated
- [ ] Screenshots updated if capturing new browse-mode UI

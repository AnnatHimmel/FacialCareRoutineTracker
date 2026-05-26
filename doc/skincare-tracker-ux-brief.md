# Skincare Routine Tracker — UX/UI Design Brief

**Source:** Derived from Skincare Routine Tracker PRD v4.0 (cross-platform, use-case form).
**Purpose:** A self-contained UX/UI specification an LLM or designer can use to produce screen designs without reading the PRD. Functional points are traceable to PRD use cases (UC-xx) and non-functional requirements (NFR-xx). Visual-style choices the PRD does not specify are flagged **[OPEN — designer's choice]** rather than invented.
**Platforms:** One cross-platform codebase producing **Android** (primary; sideloaded APK) and **Web** (for iPhone and any browser). Design must work on both; differences are called out per screen.

---

## 1. Design Context & Constraints

- **Hebrew, right-to-left.** The entire interface is in **Hebrew** with an **RTL** layout — a hard v1.0 requirement, not later localization. All system text, navigation, reading order, and progression are RTL. Full treatment in §1a. (NFR-L1–L4.)
- **Cross-platform, one design.** The same screens serve Android and Web. Keep the design responsive and touch-first; assume phone-sized viewports on both (the Web build is used primarily on iPhone). Differences (storage durability, distribution, the premium screen) are noted per screen. (PRD §1, NFR-M4.)
- **Two roles.** The **User** experience is the app. The **Admin** authors content out of band (build/config) and issues premium license keys; *the admin authoring UI is out of scope here.* Design targets the **User** app. (PRD §2.)
- **Free product is offline-first, no accounts, no backend.** No login, registration, or network/sync UI in the free product on either platform. Do not design sign-in or cloud screens except the single deferred license-activation screen (S15), which is post-v1.0. (PRD §3, NFR-M4.)
- **Optional tracking.** Recording use is never mandatory; the UI must never block, nag, or gate the day on completion. (UC-9.)
- **No reminders/notifications** as a feature in v1.0 — with the sole exception of the gentle in-app backup reminder (UC-20, S16). Do not design push-notification settings. (PRD §3.)
- **Single shared master list, read-only to users.** Users select from it; they never create or edit products. There is no "add product" affordance in the user app. (PRD §2.)
- **Routine size.** A user's routine is ~10 products per slot in the typical case; design and test around that, without breaking for larger selections. (UC-8, PRD §10.)

### 1a. Language & Layout Direction (applies to every screen)
- **Hebrew interface, RTL layout.** Every system-authored string is in Hebrew: navigation, slot labels (Morning/Evening), actions, instructions, empty states, warnings (frequency-cap, deprecation, storage-eviction), changelog, and status text. Layout direction is RTL throughout — lists, headers, progression, and any wizard flow read right-to-left. (NFR-L1.)
- **Exception — admin content shown verbatim.** **Product names** and **category names** are displayed exactly as authored and are **not** translated. They frequently contain Latin-script brand names. (NFR-L2.)
- **Bidirectional text is the norm.** Latin product/brand names are LTR islands embedded in RTL Hebrew lines (e.g., a routine row that is RTL overall but contains "CeraVe" or "The Ordinary"). Keep these legible and correctly ordered within Hebrew sentences, lists, and labels. Treat product names, category headers, and any mixed Hebrew+Latin list as bidi contexts. (NFR-L2.)
- **Admin comments shown as written** (expected in Hebrew; may be bidi if they mention brands). The app does not translate them. (NFR-L3.)
- **Mirror layout, not media.** Directional UI mirrors for RTL (reading order, alignment, directional affordances). **Do not mirror** product images or skin-log photos. (NFR-L4.)

### Visual style — all OPEN, designer's choice
The PRD specifies no brand, palette, typography, iconography, theme, or illustration style. Sensible defaults: clean, calm, skincare/beauty aesthetic; photo-friendly (product images and skin photos feature heavily); light and dark both reasonable. Typeface must render Hebrew well and coexist with inline Latin brand names. **[OPEN — designer's choice]**

---

## 2. Screen Inventory

| # | Screen | Purpose | Traceability |
|---|---|---|---|
| S1 | **Product Selection** | Pick which master products you own, per slot, grouped by category | UC-4, UC-7 |
| S2 | **Schedule Setup** | Assign weekdays to "max N/week" products under the soft cap | UC-5 |
| S3 | **Order Customization** | Optionally reorder selected products within a slot | UC-6 |
| S4 | **Daily Home** | Today's resolved Morning + Evening routine; record use | UC-8, UC-9 |
| S5 | **Routine Item** (component) | Repeating row; expands to image + comment; deprecation state | UC-9, UC-10, UC-12 |
| S6 | **Calendar / History** | Month grid of past days with completion status | UC-11 |
| S7 | **Day Detail** | A single day's routine, recorded state, skin log | UC-11 |
| S8 | **Skin Log Entry** | Add/edit notes + photos for a day | UC-14 |
| S9 | **Skin Journal** | Chronological browse of skin-log photos | UC-15 |
| S10 | **Streak Display** | Current + longest streak; optional weekly-miss budget | UC-13 |
| S11 | **Settings / Manage** | Re-open selection/schedule/order; export/import; about | UC-7, UC-16, UC-17, UC-19 |
| S12 | **Export / Import** | Produce a backup; restore via Replace/Merge with per-conflict resolution | UC-16, UC-17 |
| S13 | **About / What's New** | Version identifier + changelog | UC-19 |
| S14 | **Update Review** | After an update: new (unselected) products; newly deprecated flagged; data-intact confirmation | UC-18 |
| S15 | **License Activation** *(deferred, Web only)* | Enter admin-issued key to unlock cloud backup & restore | UC-21 |
| S16 | **Backup Reminder** (surface) | Gentle, dismissible nudge when no recent backup exists | UC-20 |

Primary navigation could be a phone-style bar (**Today / Calendar / Journal / Settings**), mirrored RTL. **[OPEN — designer's choice]** on exact pattern.

---

## 3. Global UI Concepts

- **Slot** = Morning or Evening; recurs on S1–S4, S7. Consistent identity (sun/moon motif is the obvious metaphor). **[OPEN]**
- **Category** = admin label (e.g., Cleanser, Serum/Active, Moisturizer, SPF). Used as section headers in selection (S1) **and** as a target for incompatibility rules — so it is functional, not cosmetic. Open-ended set; tolerate arbitrary names/counts. Names shown verbatim (bidi). (UC-4, UC-1b, NFR-L2.)
- **Incompatibility conflict** = two products (directly, or via their categories) that an admin rule says shouldn't share a daily routine, within the rule's scope (Morning / Evening / same-day across both). Always advisory — a soft warning, never a block. Daily↔daily conflicts are mutable by the user. (UC-1b, UC-4b.)
- **Effective order** = personal override if set, else admin order; occasional items in admin position. Used wherever a routine renders (S4, S7). (UC-6, UC-8.)
- **Deprecated product** = admin-retired; usable if already selected, flagged "no longer recommended," not offered for new selection. (UC-2, UC-12.)
- **Persistent comment** = admin's note; identical everywhere the product appears; shown on expand. (UC-10.)
- **Recording vs. owning** = two distinct mark actions: "I own this" (selection, S1) and "I did this today" (daily record, S4/S7). Design them so they aren't visually confused.

---

## 4. Screen-by-Screen Specifications

### S1 — Product Selection — Setup Step 1 (UC-4, UC-4b, UC-7)
**Purpose:** First-run setup, step 1 of 2: select all owned products. Also reachable later from Settings (UC-7).
**Content:** Two slots (Morning, Evening), configured independently. Within a slot, products grouped under **category headers** in admin order. Each product offers a select ("I own this") action plus enough info to identify it — name (verbatim, bidi-safe), and ideally a thumbnail / a way to peek the comment (reuse S5 expansion).
**States:** empty selection allowed; deprecated products **not shown** (can't be newly selected); long lists scannable via category grouping.
**Conflict feedback (UC-4b):** if the user selects two **daily** products that an incompatibility rule marks as clashing (within the rule's scope), surface a **soft, non-blocking warning** here — these would clash every day. Name both products (verbatim). The warning is **mutable**: the user can dismiss that specific conflict permanently. Never blocks selection.
**Transitions:** → S2 (step 2) if any selected product has a "max N/week" rule; else may go to S4.

### S2 — Schedule Setup — Setup Step 2 (UC-5, UC-4b)
**Purpose:** Step 2 of 2: for each selected occasional product, choose which weekdays to use it.
**Content:** Per product, 7 weekday toggles; **Sunday-first** to match the Sun–Sat cap week. Daily products do not appear (implicitly every day). Show the admin's cap (e.g., "Recommended: up to 3×/week").
**States:** within cap (neutral); **over cap** → soft, non-blocking warning, still saveable. (UC-5.)
**Conflict feedback (UC-4b):** if the chosen weekdays cause two incompatible products to coincide on the same day (occasional+occasional on overlapping days, or occasional+daily on the occasional's days), surface a **soft, non-blocking warning** for the affected day(s), naming both products. Allowed regardless. (Daily+daily clashes are handled in S1, not here.)

### S3 — Order Customization (UC-6)
**Purpose:** Optional personal reordering within a slot.
**Content:** Per slot, a reorderable list of selected products; a **"Reset to recommended order"** action.
**States:** default = admin order (no override); override active = indicated so reset is discoverable. Personal/local only.

### S4 — Daily Home (UC-8, UC-9) — primary screen
**Purpose:** Today's routine; record what you did.
**Content:** Header with today's date and the **streak display** (S10). Two sections — Morning, Evening — each listing only products **scheduled today** (all owned daily products + occasional ones whose weekday is today), in effective order. Per-section expand-all/collapse-all.
**States:**
- Default: items collapsed (S5).
- Recorded/unrecorded: toggling is free, optional, reversible. (UC-9.)
- **Empty slot today:** graceful "nothing scheduled" rest state; not a streak miss. (UC-8, UC-13.)
- **Deprecated item present:** row carries warning (S5). (UC-12.)
- **Incompatible products today:** if two of today's scheduled products trigger a rule (in scope), show a quiet, non-blocking conflict marker for the day, unless the user muted that conflict. (UC-4b.)
- **6am rollover:** "today" runs until 6:00am next morning; a pre-6am record applies to the prior day. The screen's notion of "today" honors this. (UC-8.)

### S5 — Routine Item Component (UC-9, UC-10, UC-12)
Repeating row used in S1, S4, S7.
- **Collapsed (default):** record-action + product name (bidi-safe).
- **Expanded:** adds product **image** and **persistent comment**. (UC-10.)
- **Deprecated:** collapsed shows a "no longer recommended" marker; expanded shows an explanatory notice. (UC-12.)
- **Reorder context (S3):** draggable affordance.

### S6 — Calendar / History (UC-11)
**Content:** Monthly grid (RTL; Hebrew month/day labels), navigable into the past, forward to today. Each past day shows a completion status with four distinct, colorblind-safe treatments: **complete** (both slots done), **partial** (one slot), **missed** (neither), **future/neutral**. (UC-11.) Visual encoding **[OPEN]**.
**Transition:** tap a day → S7.

### S7 — Day Detail (UC-11)
**Content:** That day's routine **as it was then** (Morning + Evening, products/order scheduled that day), which items were recorded, and the day's skin log if present (entry to S8).
**Editability:** recorded-state and skin log editable for past days; past **routine content** reflects what was scheduled then, not today's. Deprecated products used historically still render. (UC-11, UC-12.)

### S8 — Skin Log Entry (UC-14)
**Content:** Free-text notes (Hebrew) + one or more **photos** (camera or gallery). Photos stored at bounded resolution. (UC-14, PRD §10.)
**States:** empty, text-only, one/multiple photos.
**Cross-platform note:** photo capture is smooth on Android; on Web it uses the browser file/camera picker — design for both.

### S9 — Skin Journal (UC-15)
**Content:** Chronological gallery of past skin-log photos for visual comparison. Grid vs. timeline **[OPEN]**. Before/after comparison tooling is a *future* feature — do not build it. (UC-15, PRD §13.)

### S10 — Streak Display (UC-13)
**Placement:** an element on S4, not a standalone screen.
**Content:** **current** and **longest** streak. Optionally surface the **weekly miss budget** ("misses this week: 1 of 3") since the rule is generous and stateful — *suggested, not required.*
**Rules the display must respect:** slot done = ≥1 product recorded; complete day = both slots; a miss = one empty *scheduled* slot (morning-only = 1, blank day = 2); **3 slot-misses forgiven per Sun–Sat week, 4th resets, no carry-over**; unscheduled slots can't be missed; 6am day boundary. (UC-13.)

### S11 — Settings / Manage (UC-7, UC-16, UC-17, UC-19)
**Content:** entry points to re-run Selection (S1), Schedule (S2), Order (S3); Export/Import (S12); About/What's New (S13). On the **Web build only**, also the License Activation entry (S15, deferred) and any backup/restore controls it unlocks.

### S12 — Export / Import (UC-16, UC-17)
**Export:** a manual action producing one portable archive (data + photos), open format. No scheduled/auto backup in the free product. (UC-16.)
**Import:** pick an archive → choose **Replace** (overwrite all) or **Merge**. On Merge, when a record exists in both with differing content, present a **per-conflict chooser** (imported vs. existing), one conflict at a time — design as a sequential resolver ("Conflict 3 of 12"). (UC-17.)

### S13 — About / What's New (UC-19)
**Content:** current **version identifier** and a **changelog** of master-list changes per version (added, reordered, frequency changes, deprecations). Changelog text in Hebrew; referenced product names verbatim (bidi). No in-app updater on either platform — do not design "update now." (UC-19, NFR-M4.)

### S14 — Update Review (UC-18)
**Trigger:** first run after the master-list content version changes across an update.
**Content:**
- **New products** since the prior version — shown **unselected**, inviting review; never auto-added. (UC-18.)
- **Newly deprecated** products the user has selected — flagged "no longer recommended," with the option (not requirement) to remove. (UC-12, UC-18.)
- **Data-intact confirmation** + an offer to export a backup now (links to S12), as the post-update safety net. (UC-18.)

### S15 — License Activation *(DEFERRED, Web only)* (UC-21)
**Status:** post-v1.0; design so it can slot in without disturbing the free flows.
**Purpose:** Web/iPhone users enter a **admin-issued license key** to unlock **cloud backup & on-demand restore** (not sync).
**Content:** a key-entry action; on success, backup/restore controls appear (likely within S11/S12). No purchase UI — keys are issued by invitation out of band. Absent on Android and for non-invited users. (UC-21.)

### S16 — Backup Reminder Surface (UC-20)
**Purpose:** Keep a recent backup on hand, independent of when an update arrives.
**Behavior:** when a meaningful period has passed since the last export (or none ever), show a **gentle, non-blocking, dismissible** nudge suggesting a backup; links to S12. Never shown if a recent backup exists; never blocks use. Especially important on **Web** (evictable storage). (UC-20, NFR-M6.)

---

## 5. Shared Component Library

| Component | Where | Notes |
|---|---|---|
| **Routine item row (S5)** | S1, S4, S7 | Collapsed ↔ expanded (image+comment); deprecated variant; drag variant (S3). Bidi-safe names. (UC-9/10/12.) |
| **Own-toggle vs. done-toggle** | S1 vs. S4/S7 | Two different meanings — distinct visual treatment to avoid confusion. |
| **Slot section header** | S1, S3, S4, S7 | Morning/Evening identity + expand-all/collapse-all (S4). |
| **Category header** | S1 | Admin label, verbatim/bidi. (UC-4.) |
| **Weekday picker** | S2 | 7 toggles, Sunday-first; over-cap soft-warning state. (UC-5.) |
| **Soft warning (banner/inline)** | S2 (cap), S4/S5 (deprecated), S1/S2/S4 (incompatibility), S6/Web (storage) | Advisory, non-blocking; never prevents the action. Incompatibility warnings name both products; daily↔daily ones offer a per-conflict **mute**. (UC-5, UC-12, UC-4b, NFR.) |
| **Completion indicator** | S6 (and possibly S4) | Four states; colorblind-safe. (UC-11.) |
| **Streak widget** | S4 | Current + longest; optional weekly-miss readout. (UC-13.) |
| **Photo add/picker** | S8 | Camera/gallery (native) or browser picker (Web); multi-photo. (UC-14.) |
| **Conflict chooser** | S12 | Imported-vs-existing, sequential. (UC-17.) |
| **Dismissible nudge** | S16 | Gentle reminder pattern; reused for backup reminder. (UC-20.) |
| **Key-entry (deferred)** | S15 | Web-only license activation. (UC-21.) |

---

## 6. Key States & Edge Cases the Design Must Handle

1. **Empty routine / empty slot** — graceful empty state; not a streak miss. (UC-8, UC-13.)
2. **Optional recording** — never required; no blocking modals. (UC-9.)
3. **Deprecated-but-in-use** — warned, still usable, history preserved; appears S4/S5/S7/S14. (UC-12.)
4. **Over-cap scheduling** — soft, non-blocking warning. (UC-5.)
5. **Same product in both slots** — independent selection/order/frequency/record per slot; one shared image+comment. (UC-4.)
5b. **Incompatibility conflicts** — soft warnings when clashing products meet in a rule's scope. Surface at S1 (daily↔daily, mutable), S2 (day-dependent), and S4 (quiet daily marker). Never blocks. Re-evaluated whenever selection/schedule changes (UC-7). (UC-4b.)
6. **Order override vs. admin default** — indicate override; offer reset. (UC-6.)
7. **6am day rollover** — affects which day a late record lands on and the home screen's "today." (UC-8, UC-13.)
8. **Post-update review** — new items unselected; deprecated flagged; data-intact confirmation. (UC-18, S14.)
9. **Merge conflicts on import** — sequential per-conflict resolution. (UC-17.)
10. **Large master list** — selection stays scannable via category grouping. (UC-4, PRD §10.)
11. **Bidirectional text** — Hebrew RTL with Latin brand names as LTR islands across rows, headers, changelog, comments. (NFR-L2.)
12. **RTL layout correctness** — reading order/alignment/affordances mirror; images/photos do not. (NFR-L4.)
13. **Web storage eviction** — on iOS web, browser may clear local data after periods of non-use. Surface this risk to web users and lean on backup reminders (S16) + export (S12); durable fix is the deferred premium backup (S15). This is the sharpest rough edge — make the warning prominent for free web users. (NFR re: web storage, UC-20, UC-21.)
14. **Platform parity** — same screens on Android and Web; account for native vs. browser photo capture and the absence of S15 on Android. (PRD §1.)

---

## 7. Explicit Non-Goals for the Designer (do NOT design in v1.0)
- Login, account, registration, or any network state in the **free** product. (PRD §3.)
- In-app purchasing / billing / store screens — premium is invitation-only via key, no purchase UI. (PRD §3, UC-21.)
- Cross-device **sync** UI — the premium feature is backup + restore only, **not** sync. (UC-21.)
- Reminders/notifications settings (the only nudge is the in-app backup reminder, S16). (PRD §3.)
- Barcode scanning, ingredient lists, product database, expiry tracking. (PRD §3.)
- User add/create/edit product flows — users never author products. (PRD §2.)
- In-app updater / "update now" on either platform. (NFR-M4.)
- Before/after skin comparison tooling. (PRD §13.)
- Multiple user profiles on one device — the model is one curated master per build, each device/browser one user, independent local data. No profile switcher. (PRD §2.)
- Admin authoring UI — out of scope for the user app. (PRD §2.)

---

## 8. Open Visual Decisions (flagged for the designer)
- Overall visual style, palette, typography, iconography, light/dark. **[OPEN]**
- Morning/Evening motif (sun/moon or otherwise). **[OPEN]**
- Primary navigation pattern (RTL-mirrored). **[OPEN]**
- Completion-indicator encoding on the calendar. **[OPEN]**
- Onboarding: two slots as steps, tabs, or stacked sections. **[OPEN]**
- Skin journal: grid vs. timeline. **[OPEN]**
- Whether the streak widget surfaces the weekly miss budget (suggested, not required).

**Fixed (not open):** Hebrew + RTL are required (§1a). Cross-platform Android+Web parity is required. Typography is open only within the constraint of strong Hebrew rendering alongside inline Latin brand names.

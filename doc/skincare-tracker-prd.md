# Skincare Routine Tracker — Product Requirements Document

**Platform:** Cross-platform — Android (primary, sideloaded APK) and Web (for iPhone and any browser)
**Type:** Personal project, offline-first, curated content model
**Version:** 4.0 (Draft — cross-platform, use-case form)
**Date:** May 2026

> **Scope of this document.** This PRD defines *functionality* — what the system does and why — expressed as formal use cases. It deliberately avoids prescribing controls, layout, or visual design; those belong in the separate UX/UI brief. Where a behavior has a precise rule (e.g., streak math), the rule is stated as part of the use case, not as a screen detail.

---

## 1. Purpose

A skincare routine app built around a **curated master list**. A single admin (the app author) maintains a canonical, ordered library of skincare products with recommended sequencing and usage frequency. End users install the app, indicate which products they personally own, and obtain a correctly-ordered personal routine derived from the admin's expertise. Daily use is a lightweight, optional record of what was done.

The app is **offline-first** and delivered on two platforms from a single cross-platform codebase:
- **Android** — distributed as a directly-shared signed APK (no app store). Fully offline; the master list is bundled in the build.
- **Web** — a browser-based version, primarily so iPhone users can participate without an Apple developer account or payment. Also offline-capable, but subject to browser storage limits (see §10, §11). The master list is bundled into the web build.

Both platforms run the same logic and the same bundled master list; new content reaches users when they install/load a newer build. A separate, **optional, invitation-only premium capability** (cloud backup & on-demand restore, Web only) is designed for but not built in v1.0 (see UC-21, §12).

---

## 2. Actors

| Actor | Description |
|---|---|
| **Admin** | The app author. Authors the master list (products, ordering, frequency rules, deprecations) before release. Acts at authoring/build time, not at runtime within a user's app. Also, for the optional premium capability, **issues license keys by invitation** to specific users (see UC-21). |
| **User** | A person who installs the app (Android or Web) to follow and track a routine. Selects owned products, personalizes schedule and order, and records daily use. Cannot author or edit master products. May, if invited and on the Web build, activate the premium cloud backup & restore capability with a license key. |
| **System** | The app itself (running on Android or in a browser), enforcing rules (frequency caps, streak logic, migration) and presenting the user's resolved routine. |

There is one shared master list for all users in v1.0. In the free product each device/browser holds its own independent local data; the optional premium capability (UC-21) gives invited Web users a durable off-device backup they can restore on demand.

---

## 3. Goals & Non-Goals

### Goals
- Let the admin encode skincare expertise once: product set, correct order, sane frequency limits.
- Let each user self-serve a personalized routine by indicating what they own.
- Preserve the admin's recommended order as the default while allowing personal adjustment.
- Protect users from overusing actives via a soft weekly cap.
- Keep daily tracking frictionless and entirely optional.
- Reach both Android and iPhone users for free, from one codebase, without an app store.
- Keep the free product offline-first with no required infrastructure.

### Non-Goals (v1.0)
- Any required backend or server for the free product; the free app needs no network at runtime (with the noted nuance that the Web build is browser-hosted).
- Cloud backup in the free product, and any cross-device sync at all (cloud backup & on-demand restore is the deferred, optional, invitation-only, Web-only premium capability — UC-21, §12; live multi-device sync is explicitly not planned).
- App-store distribution or any in-app purchase / billing mechanism (premium access is granted by admin-issued license key, not sold).
- Per-user tailored master lists (one shared master only).
- User-authored products or user editing of master content.
- Reminders or notifications.
- ~~Barcode scanning, ingredient analysis, product database lookup.~~ *(Implemented post-v1.0 — see UC-22)*
- Product expiry / open-date tracking.
- Hard enforcement of frequency limits (soft warnings only).
- Multiple user profiles on a single device.

---

## 4. Domain Concepts

| Concept | Owner | Description |
|---|---|---|
| **Master Product** | Admin (bundled) | A skincare item with a stable identity: name, optional image, optional persistent comment, category, per-slot membership, per-slot order, per-slot frequency rule, and a deprecated flag. Read-only to users; never deleted. |
| **Slot** | Admin | Morning or Evening. A product may belong to one or both, with independent order and frequency in each. |
| **Master List** | Admin (bundled) | The ordered set of products for a slot plus their frequency rules. Two lists exist: Morning and Evening. |
| **Category** | Admin | A grouping label for products (e.g., Cleanser, Serum/Active, Moisturizer, SPF). Used both to organize the selection screen **and** as a unit that incompatibility rules can target (see Incompatibility Rule). Because rules can reference categories, a product's category is a **functional** attribute, not merely cosmetic: miscategorizing a product changes which conflicts are detected. |
| **Incompatibility Rule** | Admin (bundled) | An admin-authored rule declaring that two products, or two categories, should not appear together in the same daily routine. Each rule has a **scope**: *within Morning*, *within Evening*, or *same-day across both slots*. Rules are advisory (produce soft warnings, never blocks). See UC-1b and UC-4b. |
| **Frequency Rule** | Admin | Per product per slot: either *Daily* or *Up to N times per week* (a maximum). |
| **Selection** | User (local) | The set of master products a user marks as owned/used, per slot. |
| **Order Override** | User (local) | A user's optional personal reordering within a slot; defaults to admin order. |
| **Schedule** | User (local) | For occasional products, the specific weekdays the user intends to use them, bounded by the admin's cap. |
| **Resolved Routine** | System | The products that actually apply for a given day and slot, after applying selection, schedule, and effective order. |
| **Day Record** | User (local) | A given date's resolved routine plus which items were recorded as done. |
| **Skin Log** | User (local) | Optional per-day notes and/or photos. |
| **Streak** | System | A measure of consecutive consistency, computed per the rules in UC-13. |
| **Effective Order** | System | The order products appear for a user: personal override if present, otherwise admin order. |

**Key separation:** master content is shipped and read-only; everything a user produces (selections, overrides, schedules, daily records, skin logs) is local data that must survive app updates.

---

## 5. Use Cases — Admin

### UC-1 — Author the master list
- **Actor:** Admin
- **Goal:** Define the canonical set of products, their slots, ordering, categories, and frequency rules.
- **Preconditions:** Admin has access to the authoring mechanism for a build.
- **Main flow:**
  1. Admin defines products, each with a stable identity, name, optional image, optional comment, and a category.
  2. Admin assigns each product to the Morning slot, the Evening slot, or both.
  3. Admin sets the canonical order of products within each slot.
  4. Admin sets a frequency rule for each product per slot: Daily, or Up to N times per week.
  5. The authored master list is bundled into an app release.
- **Alternate flows:**
  - *Product in both slots:* the product shares one image and one comment across slots but may have a different order position and frequency in each.
- **Postcondition:** A versioned master list is embedded in the app build.

### UC-1b — Author incompatibility rules
- **Actor:** Admin
- **Goal:** Advise users which products should not be combined in the same daily routine.
- **Preconditions:** The relevant products and/or categories exist in the master list.
- **Main flow:**
  1. Admin creates a rule identifying **two products**, or **two categories**, that should not appear together in the same daily routine. (A product-to-category or mixed form may also be expressed; the essential unit is "this set should not meet that set.")
  2. Admin sets the rule's **scope**: *within Morning*, *within Evening*, or *same-day across both slots*.
  3. The rules are bundled into the app release alongside the master list.
- **Notes:**
  - Rules are **advisory only** — they generate soft warnings for users and never prevent a selection or schedule (consistent with the frequency cap).
  - Because rules can target categories, category assignment is functional: a product inherits all category-level rules of its category.
- **Postcondition:** A versioned set of incompatibility rules ships with the build and drives user-side warnings (UC-4b).
- **Actor:** Admin
- **Goal:** Retire a product from recommendation without losing historical accuracy.
- **Preconditions:** The product exists in the master list and may already be selected by users.
- **Main flow:**
  1. Admin marks the product as deprecated.
  2. The deprecation ships in the next app release.
  3. For users who install that release, the product is withdrawn from new selection.
- **Alternate flows:**
  - *User already uses it:* the user retains it until they choose to remove it, and is informed it is no longer recommended (see UC-12).
- **Postcondition:** The product remains in the data (never deleted), is unavailable for new selection, and all history referencing it stays intact.

### UC-3 — Release a new version
- **Actor:** Admin
- **Goal:** Deliver master-list changes to users.
- **Preconditions:** An updated master list exists.
- **Main flow:**
  1. Admin assigns the release a version identifier and a master-list content version.
  2. Admin records a changelog describing what changed (added, reordered, frequency changes, deprecations).
  3. The release is distributed through the normal Android channel.
- **Postcondition:** Users who install the release receive the updated master list and changelog. No live/over-the-air content update occurs in v1.0.

---

## 6. Use Cases — User: Setup & Personalization

> **Setup is a two-step task.** Step 1 — select all owned products (UC-4). Step 2 — schedule weekdays for products that are not daily (UC-5). Incompatibility feedback (UC-4b) is woven through both steps: clashes between two **daily** products surface in step 1 (they would recur every day); clashes that depend on chosen days surface in step 2.

### UC-4 — Select owned products (step 1)
- **Actor:** User
- **Goal:** Build a personal routine by indicating which master products they own/use.
- **Preconditions:** App installed with a bundled master list.
- **Main flow:**
  1. System presents the master list per slot, organized by category.
  2. User marks products they own, independently per slot.
  3. System forms the user's routine for each slot from the selected products.
- **Alternate flows:**
  - *Same product in both slots:* selecting it in one slot does not select it in the other; they are independent.
  - *Empty selection:* permitted; the user may proceed with an empty routine.
  - *Deprecated products:* not offered for selection.
  - *Daily incompatibility detected:* if the user selects two products that an incompatibility rule marks as conflicting **and both are daily** (so they would clash every day in the rule's scope), the System raises the conflict feedback of UC-4b at selection time.
- **Postcondition:** The user has a per-slot selection that persists locally; any always-on conflicts have been surfaced.

### UC-5 — Schedule occasional products (step 2)
- **Actor:** User
- **Goal:** Decide which weekdays to use products that have a "max N times per week" rule.
- **Preconditions:** At least one selected product has a "max N/week" frequency rule.
- **Main flow:**
  1. For each such product, user chooses the specific weekdays to use it.
  2. System records the schedule. Daily products implicitly apply every day and need no scheduling.
- **Alternate flows:**
  - *Over the cap:* if the user schedules more weekdays than N within a calendar week (Sunday–Saturday), the System presents a soft, non-blocking warning indicating the recommended maximum, but allows the choice.
  - *Day-dependent incompatibility detected:* if the chosen schedule causes two incompatible products (per a rule, in its scope) to coincide on the same day — whether occasional+occasional on overlapping days, or occasional+daily on the occasional's chosen days — the System raises the conflict feedback of UC-4b for the affected day(s), but allows the choice.
- **Postcondition:** Each occasional product has a user-defined weekday schedule; any day-dependent conflicts have been surfaced.

### UC-4b — Receive incompatibility feedback
- **Actor:** System (presented to User)
- **Goal:** Warn the user when their selection/schedule places incompatible products together, without preventing their choice.
- **Preconditions:** Admin-authored incompatibility rules exist in the build; the user's selection/schedule triggers one.
- **Rules — when a conflict exists:** two products conflict on a given day and slot context when an incompatibility rule (UC-1b) matches them — directly (product↔product) or via category (a product inherits its category's rules) — and the rule's **scope** is satisfied:
  - *within Morning:* both appear in the Morning routine on the same day.
  - *within Evening:* both appear in the Evening routine on the same day.
  - *same-day across both slots:* one appears in either slot and the other in either slot on the same day.
- **Main flow:**
  1. System detects a triggered rule at the appropriate point: at **selection** (UC-4) for two daily products that would always clash, or at **scheduling** (UC-5) and on the **daily view** (UC-8) for day-dependent clashes.
  2. System presents a **soft, non-blocking warning** naming the conflicting products (verbatim names) and the nature of the clash. The user may proceed unchanged.
- **Alternate flows:**
  - *Always-on (two daily products) — mutable warning:* because this clash recurs every day, the warning is shown at selection and persists as a quiet marker on the daily view; the user may **mute that specific conflict warning**, after which it is no longer surfaced for that pair/scope. Muting is per-conflict and local to the user.
  - *Never blocking:* in all cases the user retains the conflicting selection/schedule if they choose.
- **Postcondition:** The user is informed of conflicts; no choice is prevented; muted conflicts stay silent.

### UC-6 — Personalize routine order
- **Actor:** User
- **Goal:** Adjust the order of products within a slot to personal preference.
- **Preconditions:** User has selected products in the slot.
- **Main flow:**
  1. User changes the order of their selected products within a slot.
  2. System stores this as a personal order override for that slot.
- **Alternate flows:**
  - *Reset:* user restores the admin's recommended order, discarding the override.
- **Postcondition:** The slot's effective order reflects the user's override; the change is local and affects no one else.

### UC-7 — Revise setup at any time
- **Actor:** User
- **Goal:** Change selections, schedules, or order after initial setup.
- **Preconditions:** Setup previously completed.
- **Main flow:** User re-enters step 1 selection (UC-4), step 2 scheduling (UC-5), or ordering (UC-6) and saves changes.
- **Alternate flows:**
  - *Conflicts re-evaluated:* any change re-runs incompatibility checking (UC-4b); newly created conflicts are surfaced, and a previously muted conflict that no longer exists is cleared.
- **Postcondition:** Updated personalization applies to current and future days; past day records are unaffected.

### UC-22 — Scan a barcode to identify a product *(post-v1.0)*
- **Actor:** User (Android only)
- **Goal:** Identify a product by scanning its packaging barcode instead of manually searching.
- **Preconditions:** Camera permission granted; app running on Android.
- **Main flow:**
  1. User opens the barcode scanner from the product selection screen.
  2. System captures the barcode value.
  3. System checks the master product list for a matching barcode. If found: shows the recognized master product with its name, brand, slots, and admin comment; user taps "Add to Routine" to add it to all applicable slots in one tap. If the product is already in all applicable slots, shows "Already in your routine" — no action needed.
  4. If no master match: System queries 5 external databases in parallel (OpenBeautyFacts, OpenFoodFacts, UPCItemDB, InciBeauty, BarcodeSpider), merges results, and pre-fills the Add Custom Product sheet with name, brand, and ingredients. User completes any remaining fields and saves.
  5. If no match anywhere: user proceeds to manual entry via Add Custom Product.
- **Alternate flows:**
  - *Web:* barcode scanner is not available; FAB is hidden on the Web build.
- **Postcondition:** Product is added to the user's routine (master product) or custom product list (external/unknown).

---

## 7. Use Cases — User: Daily Use

### UC-8 — View today's routine
- **Actor:** User
- **Goal:** See what to do today, per slot, in the right order.
- **Preconditions:** A selection exists (possibly empty).
- **Main flow:**
  1. System resolves today's routine for each slot: all owned Daily products, plus owned occasional products whose schedule includes today.
  2. System presents Morning and Evening routines in effective order.
- **Alternate flows:**
  - *Empty slot today:* if no products are scheduled for a slot, System presents that slot as having nothing to do today.
  - *Deprecated product in routine:* System indicates it is no longer recommended while still presenting it (see UC-12).
  - *Incompatible products today:* if two products scheduled today trigger an incompatibility rule (in its scope), System shows a quiet, non-blocking conflict marker for that day (see UC-4b), unless the user has muted that specific conflict.
- **Definition — day boundary:** a day is considered to end at 6:00am the following morning; activity recorded before 6:00am counts toward the previous calendar day.
- **Assumption — routine size:** a slot's routine typically contains around 10 products. This is an expected size for design and testing, not an enforced limit; larger selections remain valid.
- **Postcondition:** The user sees an accurate, ordered view of today's routine.

### UC-9 — Record use of a product
- **Actor:** User
- **Goal:** Note that a product was used today.
- **Preconditions:** The product is part of today's resolved routine.
- **Main flow:** User marks the product as done; System records it against today (honoring the 6:00am boundary). The action is reversible.
- **Alternate flows:**
  - *Optional by design:* recording is never required; the System never blocks the day or compels completion.
- **Postcondition:** The day record reflects what the user marked.

### UC-10 — Inspect product details
- **Actor:** User
- **Goal:** See a product's image and the admin's note.
- **Preconditions:** Product is present in a routine or selection context.
- **Main flow:** User opens a product's detail; System presents its image and persistent comment.
- **Note:** The comment is authored once by the admin and is identical wherever the product appears.
- **Postcondition:** User has seen the product's image and comment.

---

## 8. Use Cases — User: History, Logging, Motivation

### UC-11 — Review history via calendar
- **Actor:** User
- **Goal:** Understand past consistency and revisit specific days.
- **Preconditions:** One or more past days exist.
- **Main flow:**
  1. System presents a monthly view in which each past day conveys a completion status: complete (both slots done), partial (one slot done), or missed (neither).
  2. User opens a specific day to see its routine *as it was on that day*, which items were done, and any skin log.
- **Alternate flows:**
  - *Correcting the past:* user may amend a past day's done-state and skin log (e.g., forgot to record). The past day's routine content continues to reflect what was actually scheduled then.
- **Postcondition:** History accurately reflects recorded and corrected activity.

### UC-12 — Be warned about a deprecated product
- **Actor:** User / System
- **Goal:** Keep the user's routine current without abruptly removing a product.
- **Preconditions:** A product the user has selected has been deprecated in an installed release.
- **Main flow:**
  1. System indicates, wherever the product appears, that it is no longer recommended.
  2. User may remove it from their selection.
- **Alternate flows:**
  - *User keeps it:* the product remains usable and continues to appear until removed.
- **Postcondition:** The user is informed; history remains intact regardless of choice.

### UC-13 — Track a consistency streak
- **Actor:** System (presented to User)
- **Goal:** Encourage consistency by measuring consecutive successful days.
- **Preconditions:** Daily records exist.
- **Rules:**
  - **Slot done:** a slot counts as done for a day when at least one product in that slot's scheduled routine is recorded as used. The user need not complete every product.
  - **Complete day:** both Morning and Evening slots are done.
  - **Miss:** one scheduled slot left with nothing recorded. A day with only one slot done is 1 miss; a fully blank day is 2 misses.
  - **Unscheduled slot:** a slot with nothing scheduled that day cannot be missed and never counts against the user.
  - **Grace:** up to 3 slot-misses are forgiven per calendar week (Sunday–Saturday). The 4th slot-miss in the same week resets the streak to zero. Unused grace does not carry to the next week.
  - **Day boundary:** the 6:00am rule (UC-8) governs which day activity is credited to.
- **Main flow:** System continuously computes the current streak and the longest streak achieved, and makes both available to the user.
- **Postcondition:** Streak figures reflect the rules above.

### UC-14 — Keep a skin log
- **Actor:** User
- **Goal:** Record skin condition over time.
- **Preconditions:** None.
- **Main flow:** For a given day, user records free-text notes and/or one or more photos (captured or chosen from the device).
- **Postcondition:** The day's skin log is stored locally.

### UC-15 — Browse the skin journal
- **Actor:** User
- **Goal:** Compare skin condition across time.
- **Preconditions:** One or more skin-log photos exist.
- **Main flow:** System presents past skin-log photos in chronological order for browsing.
- **Postcondition:** User can visually review change over time.

---

## 9. Use Cases — User: Data Portability & Updates

### UC-16 — Export personal data
- **Actor:** User
- **Goal:** Back up all local data.
- **Preconditions:** Local data exists.
- **Main flow:** On user request, System produces a single portable archive containing the user's selections, overrides, schedules, day records, and skin logs (including photos) in an open, platform-independent format.
- **Alternate flows:** The bundled master list is not included; only user data is exported.
- **Postcondition:** A portable backup archive exists.

### UC-17 — Import / restore personal data
- **Actor:** User
- **Goal:** Restore data from a backup.
- **Preconditions:** A valid export archive is available.
- **Main flow:**
  1. User chooses to import and selects Replace or Merge.
  2. *Replace:* System overwrites all local user data with the archive.
  3. *Merge:* System combines archive and local data; for each record present in both with differing content, System asks the user to choose which version to keep, one conflict at a time.
- **Postcondition:** Local data reflects the user's restore choices.

### UC-18 — Receive a master-list update
- **Actor:** User / System
- **Goal:** Adopt admin changes safely without losing personal data.
- **Preconditions:** User installs a release whose master-list content version differs from the prior one.
- **Main flow:**
  1. System reconciles the user's existing personalization against the new master list using stable product identities: matching products keep their selection, schedule, and order; newly added products appear unselected; newly deprecated products are flagged (UC-12).
  2. System makes the changelog and the set of new/deprecated products available for the user to review.
  3. The user's selections, schedules, overrides, day records, and skin logs are preserved.
  4. On first run after a version change, System confirms that local data is intact and offers the user the chance to export a backup now (linking to UC-16), as a safety net going forward.
- **Alternate flows:**
  - *New products:* never auto-enter a routine; they remain unselected until the user opts in.
- **Postcondition:** The user runs the new master list with personalization and history intact, and is reminded that a fresh backup is available to take.
- **Note — distribution context:** the app is distributed by sharing a signed APK directly with users (sideloading), not through an app store. In-place upgrades preserve local data only when each release is signed with the same key and carries an increasing version. There is no automatic update delivery in v1.0; users install each new APK manually. Because the app cannot know an update is imminent (the new build arrives from outside), the pre-update safeguard is realized as periodic backup reminders (UC-20) plus this post-update confirmation, rather than a prompt at the moment of updating.

### UC-19 — View version and changelog
- **Actor:** User
- **Goal:** Understand what version is installed and what changed.
- **Preconditions:** None.
- **Main flow:** System presents the current version identifier and a per-version changelog of master-list changes.
- **Postcondition:** The user is informed of version and history of content changes.

### UC-20 — Be reminded to back up
- **Actor:** System (presented to User)
- **Goal:** Ensure a recent backup exists, so an upgrade or device loss never costs the user their local data.
- **Preconditions:** Local data exists; the app tracks when the last export was performed.
- **Main flow:**
  1. System tracks the date of the user's most recent export (UC-16).
  2. When a meaningful period has passed since the last export (or none has ever been taken), System surfaces a gentle, non-blocking reminder suggesting a backup.
  3. User may export now (UC-16) or dismiss.
- **Alternate flows:**
  - *Never blocking:* the reminder never prevents normal use and can always be dismissed.
  - *Recently backed up:* if a recent export exists, no reminder is shown.
- **Postcondition:** The user is periodically nudged to maintain a current backup, keeping pre-update safety independent of when updates actually arrive.

### UC-21 — Premium cloud backup & restore for Web users (DEFERRED — design for, build post-v1.0)
- **Status:** Not implemented in v1.0. The v1.0 data model and architecture must not preclude it. Described here so the foundations are laid correctly.
- **Scope:** **Web build only.** This capability targets web/iPhone users, whose browser storage can be evicted. It is **backup and on-demand restore — not sync.** There is no live, automatic, or cross-device data sharing.
- **Actors:** Web User (with a license key), Admin (issues keys), System.
- **Goal:** Give invited web users a durable, off-device copy of their data that they can restore on demand, addressing the risk that iOS browser storage can be cleared after periods of non-use.
- **Preconditions:** The user is on the Web build and has received a **license key issued by the admin** (by invitation; there is no purchase flow in the app) and activated it.
- **Main flow:**
  1. Admin issues a license key to a specific invited web user out of band.
  2. User enters the key; System validates it and unlocks the capability for that user.
  3. With the capability active, the user can, on demand, back up their full local dataset (selections, schedules, personalization, day records, skin logs) to durable off-device storage.
  4. The user can, on demand, restore that dataset — for example after the browser has evicted local data, or on a new browser — bringing their data back.
- **Alternate flows:**
  - *No key / free user:* the capability is absent; the user relies on manual export (UC-16) and backup reminders (UC-20). The free product is fully usable without it.
  - *Restore over existing data:* restore reuses the Replace/Merge handling of UC-17, including per-conflict resolution on merge, so an on-demand restore behaves consistently with manual import.
  - *Offline:* the user works offline as normal; backup and restore occur when connectivity is available.
- **Postcondition:** Invited web users have a durable, restorable copy of their data; the free, offline-first product is unchanged for everyone else, and Android is unaffected.
- **Architectural implications to honor in v1.0 (so this is buildable later without rework):**
  - Local data is modeled so an entire user dataset can be serialized and restored as a unit (the export format of UC-16 is the natural seed).
  - Records carry stable IDs and last-modified metadata so restore-time merge can reuse UC-17's conflict handling.
  - The premium layer is **strictly optional and additive** — no free-product behavior depends on a backend, an account, or network availability.

> **Note on scope.** This is deliberately **backup + restore, not sync.** Live multi-device sync would introduce continuous conflict resolution and an off-device source of truth — a much larger departure from the per-device independence of the free product — and is not planned. The capability is web-only, invitation-gated via a admin-issued key, with no in-app purchasing. v1.0 ships free, offline-first, and store-free; this is a later addition.

---

## 10. Non-Functional Requirements

| Area | Requirement |
|---|---|
| **Offline (free product)** | Fully functional with no network on both platforms. No data leaves the device except via user-initiated export — or, for invited Web premium users only, the optional cloud backup & restore of UC-21. The free product requires no backend. |
| **Storage** | All user data and bundled images stored locally on-device/in-browser. User-captured photos stored at a reasonable bounded resolution to manage space. |
| **Web storage durability** | On the Web build, local data lives in browser storage, which the browser may evict (notably, iOS browsers can clear web-app data after periods of non-use). The free product mitigates this through backup reminders (UC-20) and manual export (UC-16); durable protection is the premium capability (UC-21). This risk and mitigation must be made clear to web users. |
| **Performance** | The day view resolves promptly with a master list of up to ~100 products. A typical user's routine contains roughly 10 products per slot (Morning, Evening); the day view and interactions should be designed and tested around this expected size, while not breaking for larger selections. Monthly history opens promptly. |
| **Privacy** | No analytics, telemetry, or third-party data collection in v1.0. |
| **Data durability** | All local user data must survive app updates (see §11). |
| **Compatibility** | Single cross-platform codebase targeting a modern Android baseline (≈ Android 10 / API 29 and above) and current mobile browsers (for iPhone/Safari and others). |
| **Language & direction** | The entire application interface is presented in **Hebrew** with a **right-to-left (RTL)** layout in v1.0. This applies to all system-generated text, labels, messages, dates, and navigation. **Exception:** admin-authored **product names** and **category names** are displayed exactly as authored (not translated and not forced RTL), since they are typically brand names. See NFR-L1. |
| **Portability** | Exported data uses an open, structured, platform-independent format. |
| **UI implementation** | The user interface must visually match the HTML design references in `docs/design-reference/screens/`, but must be **implemented natively in Flutter** (rebuilt as Flutter widgets), **not** by embedding the HTML (e.g., no WebView for app screens). The HTML is a **design reference only** — it is not shipped, not built, and is **subordinate to this PRD**: where any HTML detail conflicts with a requirement here, this PRD prevails. See §14 for implementation guidance. |

---

## 11. Data Durability & Migration

- **NFR-M1 — Stable identity:** User data references products by stable identifiers, not by name or position, so admin renames/reorders never corrupt selections or history.
- **NFR-M2 — Safe reconciliation:** On update, personalization is reconciled against the new master list; matches are preserved, additions appear unselected, deprecations are flagged. Because products are never deleted, no user reference is ever orphaned.
- **NFR-M3 — Independent schema versioning:** Local user-data schema is versioned independently of master-list content, so app-logic and content can evolve separately.
- **NFR-M4 — Distribution per platform:** v1.0 is distributed without an app store. **Android:** a directly-shared signed APK; upgrades are performed by installing a newer APK over the existing one. **Web:** hosted at a URL the admin controls; users get the newer version on next load. There is no automatic push-update on either platform.
- **NFR-M5 — Stable Android signing identity:** Every Android release must be signed with the same signing key and carry a strictly increasing version, so in-place upgrades preserve all local user data. (A key change would force uninstall/reinstall, destroying local data — unacceptable in the free product, which has no cloud backup.) The signing key must be securely retained.
- **NFR-M6 — Backup independent of update timing:** Because neither platform can reliably detect an impending update before it lands, the pre-update safeguard is delivered through periodic backup reminders (UC-20) and post-update confirmation (UC-18), not a prompt at update time. This matters most on Web, where storage is evictable.
- **NFR-M7 — Premium-ready data model:** Local data is structured so a full user dataset can be serialized and reconciled as a unit, and records carry stable IDs and last-modified metadata, so the deferred premium cloud backup & restore (UC-21) can be built later without reworking the v1.0 schema. No free-product behavior may depend on this.

---

## 11a. Language & Layout Direction

- **NFR-L1 — Hebrew RTL interface:** The entire application interface is in Hebrew and laid out right-to-left. This covers all system-generated content: navigation, labels, buttons, instructions, warnings (e.g., the frequency-cap and deprecation messages), status text, empty states, the changelog wording, and any date/number presentation appropriate to the locale.
- **NFR-L2 — Untranslated admin content:** Product names and category names are admin-authored and displayed verbatim — neither translated nor altered. They commonly contain Latin-script brand names, so the layout must correctly handle these left-to-right runs embedded within the right-to-left interface (bidirectional text), preserving their legibility and correct ordering within Hebrew sentences and lists.
- **NFR-L3 — Admin comments:** The admin's persistent product comments are authored content; the system presents them as written. (The admin is expected to author them in Hebrew where appropriate, but the system does not translate them.)
- **NFR-L4 — Mirroring:** Directional UI elements and flows follow standard RTL conventions (e.g., reading order and progression are right-to-left), while media such as product images and skin-log photos are not mirrored.

---

## 12. Resolved Design Decisions

1. **Streak completion** — measured per slot; a slot is done with ≥1 product recorded; a complete day needs both slots. (UC-13)
2. **Day boundary** — a day ends at 6:00am the next morning. (UC-8, UC-13)
3. **Misses & grace** — a miss is one empty scheduled slot; 3 slot-misses forgiven per Sun–Sat week; the 4th resets; no carry-over; unscheduled slots can't be missed. (UC-13)
4. **Import merge conflicts** — resolved by the user per individual conflict. (UC-17)
5. **New-day order** — effective order = personal override if set, else admin order; occasional items sit in admin position. (UC-6, UC-8)
6. **Selection organization** — products organized by category during selection. (UC-4)
7. **Weekly cap window** — calendar week, Sunday–Saturday. (UC-5)
8. **Phasing out products** — deprecation, never deletion. (UC-2, UC-12)
9. **Language & direction** — entire interface in Hebrew, right-to-left; product names and categories shown as authored (not translated, bidirectional-safe). (NFR-L1–L4)
10. **Platforms** — one cross-platform codebase; Android (sideloaded APK) and Web (for iPhone and any browser); master list bundled into both. (§1, NFR-M4)
11. **Premium capability** — optional Web-only cloud backup & on-demand restore (not sync), invitation-only via admin-issued license key, no in-app purchasing; deferred to post-v1.0 but designed-for now. (UC-21, NFR-M7)
12. **Two-step setup** — step 1 select all owned products; step 2 schedule weekdays for non-daily products. (UC-4, UC-5)
13. **Incompatibility rules** — admin authors advisory (soft-warning) rules between two products or two categories, each scoped to within-Morning, within-Evening, or same-day-across-both. Daily↔daily clashes warn at selection and are user-mutable; day-dependent clashes warn at scheduling and on the daily view. Category is therefore a functional attribute. (UC-1b, UC-4b)

---

## 13. Future Considerations (post-v1.0)

- ~~**Barcode scanning** (UC-22)~~ — Implemented. Camera-based barcode scan; checks master product list first (by barcode field), then queries 5 external APIs in parallel (OpenBeautyFacts, OpenFoodFacts, UPCItemDB, InciBeauty, BarcodeSpider). Master matches show "Recognized product" UI with one-tap add; external matches pre-fill the Add Custom Product sheet.
- **Premium cloud backup & restore for Web users (UC-21)** — the primary planned post-v1.0 capability. Live multi-device sync remains out of scope.
- In-app or backend-fed master-list updates.
- Per-user or per-skin-type tailored master lists.
- Reminders and notifications.
- Adherence statistics and trends beyond streaks.
- Optional hard enforcement of frequency limits.
- Before/after skin-log comparison.
- Additional languages beyond Hebrew.
---

## 14. UI Implementation Notes

The user screens have HTML design references in `docs/design-reference/screens/`. These define the intended visual design — layout, structure, spacing, color, and the look of each screen. They are **reference material, not source code**: they are not part of the build or the shipped app, and they do not override any requirement in this document.

The UI is built as a **native Flutter implementation** that reproduces the look of these references. Implementing the UI therefore involves **converting** the HTML/CSS designs into Flutter widgets, not embedding or rendering the HTML at runtime. The following guidance applies:

- **Rebuild, don't embed.** Each design reference is reconstructed using Flutter widgets. App screens must not be served via a WebView or any embedded-HTML mechanism; the HTML exists only to specify appearance.
- **Extract a single design system first.** Before building screens, derive the design tokens implied by the HTML/CSS — colors, typography (sizes, weights), spacing scale, corner radii, and elevation — into one shared Flutter theme. Screens consume these tokens rather than hard-coding values, so the look stays consistent and matches the references. (Note: the visual style was previously unspecified; the HTML references are the authority for visual style, within the constraints of this PRD.)
- **Map interactions to native widgets.** Behaviors the static HTML can only suggest are implemented with real Flutter interactions — e.g., drag-to-reorder for personal ordering (UC-6), expand/collapse for routine items (UC-10), the monthly grid for history (UC-11), and the soft-warning surfaces for the frequency cap, deprecation, and incompatibility feedback (UC-5, UC-12, UC-4b).
- **Hebrew RTL at the app root.** Right-to-left layout and Hebrew locale are configured globally (app-level directionality/locale), so screens mirror automatically, rather than being handled per screen. Bidirectional text — Latin-script product and category names embedded in Hebrew (NFR-L2) — must render correctly; verify this early on routine rows and lists, where it is most visible.
- **One codebase, both platforms.** The same Flutter widgets render on Android and on the Web build (for iPhone and other browsers), so a native Flutter reconstruction — rather than reusing the HTML for the web target — keeps a single implementation across both platforms (see Compatibility, §10).
- **Reference precedence.** If a design reference and this PRD disagree on behavior, the PRD governs; the reference governs only appearance, and only where this PRD is silent on visual detail.

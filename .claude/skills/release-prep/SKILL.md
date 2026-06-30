---
name: release-prep
description: >
  Prepare a release of The Glow Protocol Android app for Google Play. Use this skill whenever the user
  says they want to release the app, prepare a build, ship to Google Play, create a deployment build,
  "time to release", "prepare a release", "create a release build", "ready to ship", "bump and build",
  or any similar phrasing indicating they want to package a new production release. This skill does
  everything end-to-end: analyzes what changed, updates Play Store documentation, checks the privacy
  policy, bumps the version (with user confirmation), and builds the release AAB. Invoke proactively
  any time the conversation is clearly heading toward a release — don't wait for the user to list all steps.
---

# Release Prep Skill

End-to-end release preparation for The Glow Protocol. Phases, in order:

0. **Bundle sync & drift guard** — regenerate the bundled master JSON from Supabase so the offline fallback can't ship stale
1. **Analyze** — what changed since the last version bump
2. **Play Store files** — update `doc/Play Store/google_play_store_notes.md`, `full_description.md`, and `short_description.md`
3. **Privacy policy** — update `web/privacy.html` only if new data flows require it
4. **Version bump** — propose and confirm with user, then apply to `pubspec.yaml`
5. **Build** — `flutter build appbundle --release`

---

## Phase 0: Bundle Sync & Drift Guard

The bundled `assets/data/*.json` are the offline-first fallback and are a **generated artifact —
never hand-edited**. Supabase (`ddrxzzeplokmkzizailn`) is the source of truth. Every release must
regenerate them so a stale bundle (e.g. missing per-product `subCategoryId`, an outdated frequency)
can't ship.

```bash
SUPABASE_URL="https://ddrxzzeplokmkzizailn.supabase.co" \
SUPABASE_ANON_KEY="<anon/publishable key>" \
dart scripts/sync_from_supabase.dart
```

Get the anon key from the Supabase project (publishable/anon API key); never commit it into the
repo. The script is **field-preserving** (Supabase wins each shared key; bundle-local keys like
subcategory `keywords` survive) and **idempotent**.

Then enforce the guard:

```bash
git diff --exit-code assets/data/
```

- **Exit 0 (no diff):** bundle already matches Supabase — proceed.
- **Non-zero (diff):** the bundle was stale. Review the diff (expect only legitimate Supabase
  content), then **include the regenerated `assets/data/*.json` in this release commit**. After
  regenerating, run `flutter test` once — the classifier and serializer tests are the canary for a
  bad bundle (e.g. lost `keywords`).

---

## Phase 1: Analyze Changes

Find the last version bump commit:

```bash
git log --oneline -- pubspec.yaml
```

Take the most recent commit hash that touched pubspec.yaml, then:

```bash
git log --oneline <last-version-commit>..HEAD
git diff --name-only <last-version-commit>..HEAD
```

From these, identify:
- **New Android permissions** — check `android/app/src/main/AndroidManifest.xml` diffs
- **New user-visible features** — new screens, new capabilities users will see
- **New external network calls** — services the app now contacts (especially ones that receive user-triggered data)
- **Notable UI changes** — would new Play Store screenshots help?
- **Removed or deprecated features** — affects store descriptions

Record your findings clearly. Everything in phases 2 and 3 flows from this analysis.

---

## Phase 2: Update Play Store Files

Three files live under `doc/Play Store/`. Update all three that are relevant to this release:

### 2a. `doc/Play Store/google_play_store_notes.md`

Find the existing "Next release" section and **replace it entirely** with a new one reflecting the current release. Archive the old section by moving it to a `## Release history` section at the bottom of the file (or if one already exists, append to it).

Use this template — include only sections where something actually changed; omit empty ones:

```markdown
## Next release: <one-line summary of main changes>

### New Android permissions
- **`android.permission.EXAMPLE`** — what it does and why the app needs it
- Play Console action: App content → Permissions declaration → add justification:
  > "The permission is used to [user-visible purpose]. No data is stored or transmitted."

### App description update
See `doc/Play Store/full_description.md` for the updated long description. Summarise what changed here.

### Screenshots
Consider updating/adding screenshots showing [describe what has changed visually].
Minimum: 2 screenshots per form factor in Play Console.

### What's New (250-char limit)

**Hebrew:**
> ...

**English (if maintained):**
> ...

### Data safety section
[Only include if the answer to any Play Console data safety question changes.]
...

### Internal checklist before submission

- [ ] `versionCode` incremented (the `+N` part of the version in pubspec.yaml)
- [ ] Signed with the same keystore — never change the signing key
- [ ] `flutter build appbundle --release` completes without errors
- [ ] [any feature-specific testing: e.g., "Camera permission grant and deny flows tested on physical Android device"]
- [ ] Privacy policy URL live and updated (if policy changed)
- [ ] Play Console permissions declaration updated (if new permissions)
- [ ] Screenshots updated (if UI changed significantly)
- [ ] `doc/Play Store/full_description.md` updated and copy-pasted into Play Console
- [ ] `doc/Play Store/short_description.md` updated and copy-pasted into Play Console
```

**What's New writing guide:**
- Lead with the user benefit, not the technical change
- Hebrew first
- Warm tone: "כעת ניתן ל…" / "You can now…"
- Hard 250-char limit — count before writing
- If the release is purely internal/fix, a single sentence is fine

### 2b. `doc/Play Store/full_description.md`

Read the current file. If this release added new user-facing features (new capabilities, new screens, new behaviours), **update the Hebrew and English feature lists** to reflect them. Keep the copy accurate to what is actually in the shipped build — do not add promises for future features.

Update only if something meaningfully changed for users. Bug fixes and internal refactors do not warrant a description change.

### 2c. `doc/Play Store/short_description.md`

Read the current file. Update only if the one-line positioning of the app has changed (rare). The short description rarely changes between releases — most releases leave it untouched.

---

## Phase 3: Privacy Policy Check

Read `web/privacy.html`. The policy has Hebrew and English sections that must stay in sync.

**Update only if** something in Phase 1 introduced a new data flow:
- A new runtime Android permission was added
- The app now sends user-initiated data to a new external service
- A new type of user data is stored or processed

**Do not update** for: refactors, database schema changes with no new data collection, bug fixes, or UI tweaks.

**How to write updates:**
- Use generic descriptions throughout — both for backend infrastructure and for external feature services. Say "external product-lookup services" rather than naming individual providers. Say "our content server" rather than naming cloud providers.
- **Do not name specific third-party services** in the privacy policy text, even when data is transmitted to them. The Play Console Data safety form is where specific third parties are declared, not the privacy policy prose.
- If new external services are added to a feature (e.g., more barcode lookup providers), name them explicitly in the **Play Store notes** under "Data safety" with step-by-step Play Console instructions — that is where declarations belong. Do not add service names to `web/privacy.html`.
- Keep Hebrew and English in sync. Update the `<p class="updated">` date in both sections to the current month and year.

If no update is needed, state that explicitly and move on.

---

## Phase 4: Version Bump

### Classify

| Signal | Bump |
|---|---|
| Data schema incompatibility, feature removal, BREAKING CHANGE | MAJOR |
| New screen added, new user capability, additive DB migration | MINOR |
| Bug fix, UI tweak, refactor, test, docs, dependency update | PATCH |

Tie-break: if uncertain between MINOR and PATCH, ask — did a user gain a new capability? Yes → MINOR. No → PATCH.

### Compute

Parse `version: major.minor.patch+buildNumber` from `pubspec.yaml`.

```
PATCH:  major.minor.(patch+1)+(buildNumber+1)
MINOR:  major.(minor+1).0+(buildNumber+1)
MAJOR:  (major+1).0.0+(buildNumber+1)
```

### Present to user — STOP and wait for confirmation

```
Current version:  1.1.0+4
Last bump commit: abc1234 — "..."
Commits since:    N

Changes classified:
  • <commit message>  → MINOR/PATCH/MAJOR
  ...

Highest signal: MINOR
Proposed version: 1.2.0+5

Apply? (yes / or specify: major / minor / patch)
```

Do not touch pubspec.yaml until the user responds with "yes" (or a level override).

If the user specifies a different level, recalculate and confirm once more before applying.

### Apply (after confirmation only)

1. Read `pubspec.yaml`
2. Find the line matching `^version: .*`
3. Replace it with the confirmed new version string
4. Verify the change by re-reading that line

---

## Phase 5: Build

After the version bump is applied, run:

```bash
flutter build appbundle --release
```

The keystore is configured in `android/app/build.gradle`. Never change it — a key change forces uninstall/reinstall and destroys user data.

On success, the AAB is at:
```
build/app/outputs/bundle/release/app-release.aab
```

Report the path on success. On failure, show the flutter error output in full.

**Do not upload to Play Console automatically.** The AAB must be uploaded manually via the Play Console UI.

---

## Phase 6: Summary

After all phases complete, print:

```
Release prep complete
════════════════════════════════════════════
Version:     1.1.0+4  →  1.2.0+5
AAB:         build/app/outputs/bundle/release/app-release.aab

Files updated:
  • doc/Play Store/google_play_store_notes.md
  • doc/Play Store/full_description.md   ← or: "no changes needed"
  • doc/Play Store/short_description.md  ← or: "no changes needed"
  • pubspec.yaml
  • web/privacy.html                     ← or: "no changes needed"

Play Console actions still needed:
  • [list the checklist items from the notes file that require manual Play Console steps]
════════════════════════════════════════════
```

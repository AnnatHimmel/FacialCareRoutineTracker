---
name: bump-version
description: Bump the Flutter app version in pubspec.yaml. Inspects git commits since the last version bump, classifies changes as major/minor/patch using semver rules, proposes the new version, and applies it after confirmation. TRIGGER when: user says "bump version", "increment version", "new version", "release version", or asks to update the version number.
---

# bump-version Skill

## Core Identity
Inspect changes since the last version bump → classify → propose → apply.

Flutter version format: `major.minor.patch+buildNumber`  
The `buildNumber` (after `+`) is the Android `versionCode` and **always increments by 1**, regardless of bump level.

---

## Phase 1: FIND LAST VERSION BUMP

Run this to locate the commit where `pubspec.yaml` version was last changed:

```bash
git log --oneline --follow -p pubspec.yaml | grep -m1 "^+version:" 
```

Or more reliably — find the most recent commit that touched the version line:

```bash
git log --oneline -- pubspec.yaml
```

Then diff from that commit to HEAD to get the full change set:

```bash
git log --oneline <last-version-commit-hash>..HEAD
```

If no prior version bump commit exists (first release), use all commits:

```bash
git log --oneline
```

**Record**:
- Current version (read from `pubspec.yaml`)
- Hash of last version bump commit (or repo root)
- Number of commits since last bump

---

## Phase 2: ANALYZE CHANGES

Collect the evidence needed to classify the bump level.

### Step 1 — Commit message scan

```bash
git log --oneline <hash>..HEAD
```

Look for these signals in commit messages:

| Signal | Bump |
|--------|------|
| `BREAKING CHANGE`, `breaking:`, removes a feature | MAJOR |
| `feat:`, `feature:`, new screen added, new capability | MINOR |
| `fix:`, `bug:`, `patch:`, typo, refactor, test, docs, chore | PATCH |

### Step 2 — File change scan

```bash
git diff --name-only <hash>..HEAD
```

Classify changed files:

| File pattern | Bump signal |
|---|---|
| `lib/features/*/` **new directory** | MINOR — new feature area |
| New `*_screen.dart` added | MINOR — new screen |
| `lib/core/database/` migration added | Check carefully — MAJOR if old data becomes incompatible, MINOR if additive |
| `pubspec.yaml` (deps only) | PATCH usually |
| `test/` only | PATCH |
| `lib/core/l10n/` only | PATCH |
| Existing screens edited | PATCH (fix) or MINOR (new capability) |
| `docs/` only | PATCH |

### Step 3 — Apply semver rules for a Flutter mobile app

```
MAJOR (x.0.0):
  - Data schema change that would corrupt or lose existing user data
    without a migration path (e.g. renamed drift tables, removed columns)
  - Complete removal of a user-facing feature
  - Commit message contains "BREAKING CHANGE"

MINOR (0.x.0):
  - New screen added (new *_screen.dart in lib/features/)
  - New user-visible feature or capability
  - New product collection feature, new widget that adds functionality
  - Additive database migration (new table/column, backward compatible)

PATCH (0.0.x):
  - Bug fixes
  - UI tweaks on existing screens
  - Refactors with no behavior change
  - Test additions or fixes
  - Localization string changes
  - Documentation updates
  - Dependency version bumps (minor/patch dep bumps)
  - Performance improvements
```

**Tie-break rule**: When uncertain between MINOR and PATCH, check whether a **new user capability** was added. If yes → MINOR. If it's only improvement/correction of existing capability → PATCH.

---

## Phase 3: PROPOSE NEW VERSION

Parse current version from `pubspec.yaml`:

```
current: major.minor.patch+buildNumber
```

Compute proposed version:

```
PATCH bump:  major.minor.(patch+1)+(buildNumber+1)
MINOR bump:  major.(minor+1).0+(buildNumber+1)
MAJOR bump:  (major+1).0.0+(buildNumber+1)
```

Present findings to the user **before making any changes**:

```
Current version:  1.0.2+3
Last bump commit: abc1234 — "add barcode scanning stub"
Commits since:    5

Changes classified:
  • feat: implement api access after barcode scanning  → MINOR
  • fix errors on start up                             → PATCH
  • move the products table to supabase                → MINOR (new infra capability)
  • add unit tests                                     → PATCH
  • add barcode scanning stub                          → MINOR

Highest signal: MINOR

Proposed version: 1.1.0+4

Apply? (yes to proceed, or specify a different level: major / minor / patch)
```

**STOP here and wait for user confirmation.**

If the user specifies a different level, recalculate and confirm again before applying.

---

## Phase 4: APPLY THE VERSION BUMP

Only after user confirms.

1. Read `pubspec.yaml`
2. Find the line matching `^version: .*`
3. Replace it with the new version string
4. Write back to `pubspec.yaml`
5. Verify the change with a quick read

Example edit target:
```yaml
version: 1.0.2+3   →   version: 1.1.0+4
```

---

## Phase 5: CONFIRM & REPORT

After applying, show:

```
Version bumped:  1.0.2+3  →  1.1.0+4
File updated:    pubspec.yaml (line N)

Next steps (optional):
  • git commit -m "chore: bump version to 1.1.0+4"
  • flutter build apk  (Android)
  • flutter build web  (Web)
```

Do NOT commit automatically — leave that to the user.

---

## Quick Reference

```
/bump-version

Phase 1  Find last version bump in git log
Phase 2  Scan commits + changed files since then
Phase 3  Propose bump level + new version → WAIT for user
Phase 4  Apply to pubspec.yaml (after confirmation)
Phase 5  Report result + remind of next steps
```

---

## Edge Cases

| Situation | Handling |
|---|---|
| No prior version bump commit | Use all commits; treat as first release |
| Both MINOR and MAJOR signals present | Use MAJOR |
| Only merge commits, no useful messages | Fall back to file-change scan only |
| User overrides proposed level | Respect it, recalculate, confirm once more |
| pubspec.yaml not found | Report error — must be at repo root |
| Already on a clean version (no commits since last bump) | Report "nothing to bump — no commits since last version bump" |

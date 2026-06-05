# /fix-tests - Run & Fix Unit Tests

## Purpose
Run all Flutter unit tests, automatically fix **test bugs** (the test code itself is wrong), and produce a consolidated **Debug Diagnosis Report** for **code bugs** that requires explicit user approval before any production code is touched.

## Agents Used
| Phase | Agent | Job |
|-------|-------|-----|
| Run tests | `test-runner` | Execute `flutter test`, return raw output |
| Classify failures | `test-analyst` | Determine CODE_BUG vs TEST_BUG for each failure |
| Fix bad tests | `test-writer` | Rewrite incorrect test(s) so they correctly capture the requirement |
| Re-verify | `test-runner` | Re-run after test fixes to confirm green |
| Fix code bugs | (blocked by user approval) | `/Fix-Code` per approved bug |

---

## Execution Flow

```
┌──────────────────────────────────────────────────────────────┐
│                      /fix-tests FLOW                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  PHASE 1 — RUN ALL TESTS                            │     │
│  │  Spawn test-runner → flutter test --reporter        │     │
│  │  expanded                                           │     │
│  └────────────────────────┬────────────────────────────┘     │
│                           │                                  │
│              ┌────────────┴────────────┐                     │
│         ALL PASS                  FAILURES EXIST             │
│              │                         │                     │
│              ▼                         ▼                     │
│        ✅ DONE                 ┌───────────────┐             │
│                                │  PHASE 2      │             │
│                                │  ANALYZE      │             │
│                                │  Spawn test-  │             │
│                                │  analyst per  │             │
│                                │  failure      │             │
│                                └───────┬───────┘             │
│                                        │                     │
│               ┌────────────────────────┤                     │
│          TEST_BUG                 CODE_BUG                   │
│               │                        │                     │
│               ▼                        ▼                     │
│        ┌─────────────┐         ┌──────────────┐              │
│        │  PHASE 3    │         │  Collect for │              │
│        │  FIX TESTS  │         │  bug report  │              │
│        │  test-writer│         └──────┬───────┘              │
│        └──────┬──────┘                │                      │
│               │                       │                      │
│               ▼                       ▼                      │
│        ┌─────────────┐         ┌──────────────┐              │
│        │  PHASE 4    │         │  PHASE 5     │              │
│        │  RE-RUN     │         │  BUG REPORT  │              │
│        │  test-runner│         │  (Debug fmt) │              │
│        └──────┬──────┘         └──────┬───────┘              │
│               │                       │                      │
│               ▼                       ▼                      │
│        ✅ Tests fixed          ⏸ WAIT FOR USER               │
│                                       │                      │
│                                  approved?                   │
│                               ┌───────┴────────┐             │
│                              YES               NO            │
│                               │                │             │
│                               ▼                ▼             │
│                        PHASE 6: Fix        🛑 STOP           │
│                        via /Fix-Code       Report only       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Phase Instructions

### Phase 1 — Run All Tests

Spawn `test-runner` agent with this exact prompt:

```
This is a Flutter project. Run ALL unit tests using:

  flutter test --reporter expanded

Capture the full output. Report:
- Total tests: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]
- For each failure: test name, file path, line number, exact error message, stack trace excerpt

Do NOT run Python or pytest. Do NOT use .venv. This is Flutter only.
```

If ALL tests pass → print success summary and STOP (do not continue to Phase 2).

---

### Phase 2 — Analyze Failures

For each failing test, spawn `test-analyst` with this prompt (one call per failure, or batch if they share the same file):

```
Analyze this Flutter test failure and classify it as exactly one of:
  - CODE_BUG   → the production code is wrong; the test correctly describes expected behavior
  - TEST_BUG   → the test assertion or setup is wrong; the production code is likely correct

Failure details:
  Test: [test name]
  File: [test file path : line]
  Error: [exact error message]
  Stack trace: [relevant excerpt]

Source files context: [paste the relevant test file content and the production file it tests]

Output format:
  Classification: CODE_BUG | TEST_BUG
  Reason: [one sentence — WHY]
  If TEST_BUG: what the test SHOULD assert instead
  If CODE_BUG: what behavior the code produces vs what the test expects
```

Collect all results:
- `TEST_BUGS[]` — list of test files + what to fix
- `CODE_BUGS[]` — list of failures + analyst findings

If no failures → skip all remaining phases.

---

### Phase 3 — Fix Test Bugs (automatic, no user approval needed)

For each entry in `TEST_BUGS[]`, spawn `test-writer` with this prompt:

```
A test in this Flutter project has an incorrect assertion and needs to be rewritten.
Do NOT write a NEW test — correct the EXISTING test so it properly verifies the
intended behavior described below.

Test file: [path]
Failing test name: [test name]
What it currently does: [current assertion]
What it SHOULD assert: [analyst finding from Phase 2]

Rewrite ONLY the failing test(s) within the file. Do not change any passing tests.
After editing, run:
  flutter test [test file path]
and confirm the test now passes. Report the result.
```

Wait for each `test-writer` to complete before proceeding.

---

### Phase 4 — Re-run After Test Fixes

If any TEST_BUG was fixed in Phase 3, spawn `test-runner` again:

```
This is a Flutter project. Re-run ALL unit tests to confirm no regressions
after test file edits:

  flutter test --reporter expanded

Report pass/fail summary and any remaining failures.
```

If new failures appear that were not in the original run → classify them (return to Phase 2 for those only).

---

### Phase 5 — Consolidated Bug Report (Code Bugs)

If `CODE_BUGS[]` is non-empty, generate the following report and present it to the user.
**Do not touch any production code until the user approves.**

```markdown
## 🔍 Test Failure — Code Bug Report

### Summary
[N] test(s) are failing due to bugs in production code.
[N] test(s) were fixed automatically (test code was incorrect).

---

### Bug #1: [Test Name]

**Symptoms**
[What the test observes — the actual failure message]

**Expected Behavior** (per the test)
[What the test asserts should happen]

**Actual Behavior** (what the code does)
[From analyst findings]

**Location**
- Test file: [path:line]
- Production file(s): [path:line — where the bug likely lives]
- Function/Widget: [name]

**Root Cause**
[Analyst's one-sentence explanation]

**Problem Classification**
- [ ] Typo/Simple Error
- [ ] Logic Error (code doesn't match intent)
- [ ] Design Gap (design doesn't cover this case)
- [x] [whichever applies]

**Suggested Fix**
[Specific recommended change]

**Confidence**: HIGH | MEDIUM | LOW

---

### Bug #2: ...

[Repeat for each CODE_BUG]

---

### Test Fix Summary
| Test File | Fix Applied |
|-----------|-------------|
| [file] | [what was corrected] |

---

**Next Step**: Reply **"fix"** or **"fix all"** to apply the code fixes above via /Fix-Code.
Reply **"skip"** or **"skip #N"** to leave specific bugs unfixed.
```

---

### Phase 6 — Fix Code Bugs (after user approval)

When the user approves (replies "fix", "fix all", "yes", "go ahead", or approves specific bug numbers):

For each approved bug, invoke `/Fix-Code` with a self-contained prompt containing:
- The exact bug location (file, line, function)
- The expected behavior (from the test)
- The actual behavior (from the analyst)
- The suggested fix from the report
- Instruction to run `flutter test` after fixing to verify

After all fixes, spawn `test-runner` one final time to confirm all tests pass.

Print final status:
```
═══════════════════════════════════════════════════════════════
              /fix-tests COMPLETE ✅
═══════════════════════════════════════════════════════════════

Tests run:       [N]
Initially failed: [N]
  └─ Test bugs fixed automatically: [N]
  └─ Code bugs fixed (approved):    [N]
  └─ Code bugs skipped:             [N]
Final result:    ✅ [N] passing / ❌ [N] still failing
═══════════════════════════════════════════════════════════════
```

---

## Rules

- **Never modify production code without user approval.** Test code can be fixed automatically.
- If `flutter test` cannot run (missing flutter, build errors, etc.) — stop immediately and report the setup issue to the user. Do not attempt to infer test results.
- If `test-analyst` cannot confidently classify a failure (ambiguous), treat it as **CODE_BUG** (safer — report rather than silently change code).
- If a test-writer fix causes a previously passing test to fail, revert it and include that test in the code bug report instead.
- Run the full suite (not just changed files) in Phase 4 to catch regressions.

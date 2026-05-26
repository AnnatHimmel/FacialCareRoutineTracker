# /5-Review - Final Review & Verification

## Purpose
Comprehensive verification that ALL functionality requirements are implemented and tested. Loop until all checks pass.

## Prerequisites
```
REQUIRED:
- .\doc\FUNCTIONALITY.md exists
- .\doc\ARCHITECTURE.md exists
- .\doc\WORKPLAN.md exists
- .\doc\PROGRESS.md shows all tasks complete

IF tasks incomplete:
    → "Tasks still pending. Running /4-Execution to complete..."
    → AUTO-EXECUTE /4-Execution
```

## Behavior: Review Loop Until Perfect

```
┌─────────────────────────────────────────────────────────────────┐
│                      REVIEW LOOP                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │    RUN       │────▶│   CHECK      │────▶│  ALL PASS?   │    │
│  │  All Tests   │     │ Requirements │     │              │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                              ▲                     │             │
│                              │   FAILURES FOUND    │             │
│                              │   → FIX & RETEST    │             │
│                              └─────────────────────┘             │
│                                          │ ALL PASS              │
│                                          ▼                       │
│                              ┌──────────────────────┐           │
│                              │  Generate Final      │           │
│                              │  REVIEW_REPORT.md    │           │
│                              │                      │           │
│                              │  PROJECT COMPLETE!   │           │
│                              └──────────────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Review Process

### Step 1: Run Full Test Suite
```
1. Execute ALL tests
2. Capture results
3. If any fail → fix immediately (don't stop to ask)
4. Re-run until all pass
```

### Step 2: Requirements Traceability Check
```
FOR each feature in FUNCTIONALITY.md:
    CHECK:
    - [ ] Feature implemented? (code exists)
    - [ ] Feature tested? (test exists)
    - [ ] Test passes? (green)

    IF any check fails:
        → Write a test capturing the failure — confirm it FAILS
        → Fix the code
        → Verify the test passes, then re-check
```

### Step 3: Code Quality Verification
```
CHECK:
- [ ] No hardcoded secrets/credentials
- [ ] Error handling in place
- [ ] Input validation where needed
- [ ] Logging implemented
- [ ] No obvious security vulnerabilities

IF issues found:
    → Fix immediately
    → Re-verify
```

### Step 4: UI Verification (if UI/Hybrid project)
```
FOR each screen in UI_DESIGN.md:
    CHECK:
    - [ ] Screen implemented?
    - [ ] All elements present?
    - [ ] States handled (loading/empty/error)?
    - [ ] Responsive breakpoints work?
    - [ ] Accessibility requirements met?

IF issues found:
    → Write a test capturing the issue — confirm it FAILS
    → Fix the code
    → Verify the test passes, then re-verify
```

### Step 5: Edge Case Verification
```
FOR each edge case in FUNCTIONALITY.md:
    CHECK:
    - [ ] Edge case handled in code?
    - [ ] Edge case has test?
    - [ ] Test passes?

IF issues found:
    → Write a test capturing the issue — confirm it FAILS
    → Fix the code
    → Verify the test passes, then re-verify
```

### Step 6: Documentation Check
```
CHECK:
- [ ] update_team.bat / update_team.sh exist and work
- [ ] clone_sprint.bat / clone_sprint.sh exist and work
- [ ] requirements.txt is complete
- [ ] README or usage instructions exist
- [ ] .venv setup documented
```

## Validation Checklist

```
FINAL REVIEW VALIDATION:
═══════════════════════════════════════════════════════════════

TEST RESULTS:
✅/❌ All unit tests pass?
✅/❌ All integration tests pass?
✅/❌ No regressions from previous tasks?

REQUIREMENTS COVERAGE:
✅/❌ All FUNCTIONALITY features implemented?
✅/❌ All features have tests?
✅/❌ All tests pass?

CODE QUALITY:
✅/❌ No security vulnerabilities?
✅/❌ Error handling complete?
✅/❌ Input validation present?
✅/❌ Logging implemented?

UI (if applicable):
✅/❌ All screens implemented?
✅/❌ All states handled?
✅/❌ Accessibility met?

DOCUMENTATION:
✅/❌ update_team.bat / update_team.sh work?
✅/❌ clone_sprint.bat / clone_sprint.sh work?
✅/❌ requirements.txt complete?
✅/❌ Usage documented?

RESULT: [X/X checks passed]
═══════════════════════════════════════════════════════════════
```

## Loop Until All Pass

```
WHILE any check fails:
    1. Identify failure
    2. Write a test capturing the failure — confirm it FAILS
    3. Fix the code (no asking - just fix)
    4. Verify the test now passes
    5. Re-run full test suite
    6. Re-verify checklist

WHEN all checks pass:
    → CHECK ERROR LIST:
      IF .\doc\ErrorList.md exists AND has PENDING entries:
          → Display: "Found [N] pending error reports. Processing before finalizing..."
          → FOR each PENDING entry (HIGH priority first):
              a. Update status → IN_PROGRESS
              b. Run /6-ModifyLoop with error description
              c. Update status → RESOLVED
          → Re-run review checks (loop back)
      IF no PENDING entries:
          → Generate REVIEW_REPORT.md
          → Display completion summary
```

## Generate Final Report

Create `.\doc\REVIEW_REPORT.md`:

```markdown
# Final Review Report
Project: [Name]
Date: [Date]
Status: ✅ COMPLETE

## Executive Summary
[One paragraph summary of what was built]

## Requirements Verification

| Requirement (from FUNCTIONALITY.md) | Implemented | Tested | Status |
|-------------------------------------|-------------|--------|--------|
| [Feature 1] | ✅ Yes | ✅ Yes | ✅ Pass |
| [Feature 2] | ✅ Yes | ✅ Yes | ✅ Pass |
| ... | | | |

**Coverage**: [N/N] requirements (100%)

## Test Results

```
[Full test output]
```

| Category | Passed | Failed | Skipped |
|----------|--------|--------|---------|
| Unit Tests | [N] | 0 | 0 |
| Integration | [N] | 0 | 0 |
| **Total** | **[N]** | **0** | **0** |

## Code Quality

| Check | Status | Notes |
|-------|--------|-------|
| Security | ✅ Pass | No vulnerabilities found |
| Error Handling | ✅ Pass | All error paths covered |
| Input Validation | ✅ Pass | All inputs validated |
| Logging | ✅ Pass | app.log and error.log configured |

## Architecture Compliance

| Component (from ARCHITECTURE.md) | Implemented | Tested |
|----------------------------------|-------------|--------|
| [Component 1] | ✅ Yes | ✅ Yes |
| [Component 2] | ✅ Yes | ✅ Yes |
| ... | | |

## UI Compliance (if applicable)

| Screen (from UI_DESIGN.md) | Implemented | States | Accessibility |
|----------------------------|-------------|--------|---------------|
| [Screen 1] | ✅ Yes | ✅ All | ✅ AA |
| ... | | | |

## Edge Cases Verified

| Edge Case | Tested | Behavior |
|-----------|--------|----------|
| [Case 1] | ✅ Yes | [Expected behavior confirmed] |
| ... | | |

## Project Deliverables

| Deliverable | Location | Status |
|-------------|----------|--------|
| Source Code | src/ | ✅ Complete |
| Tests | test/ | ✅ Complete |
| Documentation | doc/ | ✅ Complete |
| Run Script (Windows) | update_team.bat | ✅ Works |
| Run Script (Ubuntu) | update_team.sh | ✅ Works |
| Clone Script (Windows) | clone_sprint.bat | ✅ Works |
| Clone Script (Ubuntu) | clone_sprint.sh | ✅ Works |
| Dependencies | requirements.txt | ✅ Complete |
| Virtual Env | .venv/ | ✅ Configured |

## Decisions Made During Development

[Summary from DECISIONS.md]

## Lessons Learned

[Summary from LEARNINGS.md]

## How to Run

```bash
# Setup (first time)
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Run (Windows)
.\update_team.bat
.\update_team.bat --team algo
# Run (Ubuntu)
bash update_team.sh
bash update_team.sh --team algo

# Test
.venv\Scripts\pytest.exe test/
```

## Sign-Off

- [x] All requirements implemented
- [x] All tests passing
- [x] Code quality verified
- [x] Documentation complete

**Project Status: COMPLETE** ✅
```

## Completion Display

```
═══════════════════════════════════════════════════════════════
                    🎉 PROJECT COMPLETE 🎉
═══════════════════════════════════════════════════════════════

All phases completed successfully:

✅ Phase 1: Functionality    - FUNCTIONALITY.md
✅ Phase 2a: Architecture    - ARCHITECTURE.md
✅ Phase 2b: UI Design       - UI_DESIGN.md (if applicable)
✅ Phase 3: Work Planning    - WORKPLAN.md
✅ Phase 4: Execution        - All [N] tasks complete
✅ Phase 5: Review           - REVIEW_REPORT.md

Final Statistics:
- Requirements covered: [N/N] (100%)
- Tests passing: [N/N] (100%)
- Code quality: All checks pass

Project is ready for use!

To run (Windows): update_team.bat  |  To run (Ubuntu): bash update_team.sh
To test: .venv\Scripts\pytest.exe test/

═══════════════════════════════════════════════════════════════
```

## Do NOT:
- Mark complete with failing tests
- Skip any requirement verification
- Leave issues unfixed
- Ask permission to fix issues (just fix them)
- Stop until ALL checks pass

---
name: Fix-Code
description: Systematic bug fixing and code modification with design-first approach. Ensures fixes align with SRS documentation to prevent spaghetti code.
---

# Fix-Code Skill

## Core Principle
> "Fixing without knowing exactly WHERE, WHAT, and the DESIRED OUTCOME is like patching a hole on the wrong side of the wall."

**NEVER patch locally just to make it work. Every fix MUST align with design documents (SRS).**

---

## Phase 0: PREREQUISITES CHECK

### Step 0: Verify SRS Exists
```
IF SRS document exists:
    → Proceed to Phase 1
ELSE:
    → STOP - Cannot fix without design reference
    → Create preliminary SRS from existing code:
      1. Analyze current code structure
      2. Document what each module SHOULD do
      3. Write basic SRS_<project>.md
      4. Ask user to review/approve
    → THEN proceed to Phase 1
```

**Why this matters**: Without SRS, any fix is guesswork. Even a quick preliminary SRS prevents spaghetti.

---

## Phase 1: DIAGNOSE

### Step 1: Read Logs
```
IF log files exist:
    → Read all log files to identify the problem
ELSE:
    → Add logging to relevant code sections
    → Rerun to reproduce and capture the problem
```

### Step 2: Define the Problem
Answer these questions BEFORE touching code:
- [ ] What is the exact error/unexpected behavior?
- [ ] Which module(s) or file(s) contain the problem?
- [ ] Is this a BUG (code doesn't match design) or DESIGN GAP (design doesn't cover this case)?

---

## Phase 2: CLASSIFY & ROUTE

```
┌─────────────────────────────────────────────────────────────┐
│                    PROBLEM CLASSIFICATION                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│  │   TYPO /    │     │   LOGIC     │     │   DESIGN    │   │
│  │  SIMPLE     │     │   ERROR     │     │    GAP      │   │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘   │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│  │ FIX NOW     │     │ FIX WITH    │     │ PLAN MODE   │   │
│  │ (1 location)│     │ VERIFICATION│     │ (redesign)  │   │
│  └─────────────┘     └─────────────┘     └─────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Route A: Typo/Simple Error
- Single location fix
- Does NOT change behavior/logic
- **Action**:
  1. Write a test that reproduces the issue — **confirm it FAILS**
  2. Fix the code
  3. Verify the test passes

### Route B: Logic Error
- Code doesn't match SRS specification
- Fix stays within existing design scope
- **Action**:
  1. Locate exact code section
  2. Verify fix aligns with SRS
  3. Write a test that reproduces the issue — **confirm it FAILS**
  4. Fix the code
  5. Verify the test passes, update test docs if needed

### Route C: Design Gap (CRITICAL PATH)
- Problem reveals missing/wrong design concept
- Fix would require changes across multiple files
- Fix contradicts or is outside SRS scope
- **Action**:
  1. STOP - Do not code
  2. Document problem in code comment
  3. Enter Plan Mode (`/plan` or Shift+Tab)
  4. Think hard on architectural solution
  5. Update SRS design documents FIRST
  6. Update test specifications
  7. THEN implement following new design

### Route D: External Dependency Issue
- Bug is in 3rd party library, API, or system outside our control
- Cannot fix the source directly
- **Action**:
  1. STOP - Do NOT implement workaround yet
  2. Document the external issue clearly
  3. Propose workaround solution with pros/cons
  4. **ESCALATE to user/supervisor** for decision
  5. Only implement after approval
  6. Update SRS to document the workaround and why

**Why escalate?** Workarounds add technical debt. Human must approve.

### Route E: Performance Issue
- Code is functionally correct but slow/resource-heavy
- Not a logic error, not a typo
- **Action**:
  1. Profile to identify bottleneck (use profiling tools)
  2. Propose optimization solution
  3. **ESCALATE with findings** - do not implement yet
  4. After approval: Update SRS with performance requirements
  5. Implement optimization
  6. Benchmark before/after

**Why escalate?** Performance fixes often have trade-offs (memory vs speed, complexity vs performance).

### Route F: Hard to Reproduce (Intermittent/Race Condition)
- Bug appears randomly or under specific conditions
- Standard logging doesn't capture it
- **Action**:
  1. Create **DEBUG MODE** with enhanced logging:
     ```
     - Add LOG TRAPS at suspected locations
     - Log ALL relevant state variables
     - Log timestamps for timing issues
     - Log thread/process IDs for race conditions
     ```
  2. Enable debug mode and wait for reproduction
  3. Once captured, analyze logs
  4. Classify into Route A/B/C and fix
  5. **CRITICAL: Remove all debug log traps after fix**
  6. Verify debug code is fully cleaned

**Log Trap Checklist**:
- [ ] Debug logs added with clear `[DEBUG-TRAP]` prefix
- [ ] All traps documented in code comments
- [ ] After fix: Search for `[DEBUG-TRAP]` and remove ALL
- [ ] Verify no debug code in production

---

## Phase 3: FIX

### Pre-Fix Checklist
- [ ] Problem is clearly defined
- [ ] Fix location is identified
- [ ] Fix aligns with SRS documentation
- [ ] If design change needed → SRS updated FIRST
- [ ] Failing test written that reproduces the issue

### Fix Execution (RED → GREEN)
```
RED:
  1. Write a test that reproduces the exact issue
  2. Run the test — it MUST fail before proceeding
     (a passing test means the issue isn't captured yet)

GREEN:
  3. Make the minimal change required
  4. Verify change matches SRS specification
  5. Run the test — it MUST now pass
  6. Run full test suite to check for regressions
  7. Update test documentation if behavior changed
```

### Post-Fix Verification
- [ ] Tests pass
- [ ] Code matches SRS 100%
- [ ] No orphan fixes (changes outside design scope)
- [ ] Test documentation updated if applicable
- [ ] All debug/trap logs removed

---

## Phase 4: FIX FAILED - ROLLBACK PROTOCOL

### When Fix Doesn't Work
```
Fix attempt #1 failed:
    → STOP - Do not try random variations
    → Analyze WHY it failed:
      - Wrong root cause identified?
      - Fix approach incorrect?
      - Side effects not considered?
    → UNDO the fix completely (git revert or manual)
    → Re-diagnose with new information

Fix attempt #2 failed:
    → STOP - Do not continue
    → UNDO the fix completely
    → Document:
      1. What was tried
      2. Why each attempt failed
      3. Current hypothesis
    → **ESCALATE to supervisor/user**
```

### Rollback Checklist
- [ ] Fix code reverted to pre-fix state
- [ ] Any test changes reverted
- [ ] Any SRS changes reverted (if made)
- [ ] Debug logs removed
- [ ] System is back to "broken but stable" state

### Root Cause Analysis Template
```markdown
## Fix Failure Report

### Attempt 1:
- Hypothesis: [What we thought was wrong]
- Fix applied: [What we changed]
- Result: [What happened]
- Why it failed: [Analysis]

### Attempt 2:
- Revised hypothesis: [Updated theory]
- Fix applied: [What we changed]
- Result: [What happened]
- Why it failed: [Analysis]

### Current State:
- All fixes reverted: YES/NO
- New hypothesis: [If any]
- Recommended action: ESCALATE TO [supervisor/user]
```

---

## Anti-Pattern: Spaghetti Prevention

### ❌ WRONG Approach
```
Bug found → Patch locally → "It works now" → Move on
Result: Code drifts from design, becomes unmaintainable
```

### ✅ CORRECT Approach
```
Bug found → Diagnose → Check SRS alignment →
  IF design gap: Update SRS first
  THEN: Write failing test that reproduces the bug (RED)
  THEN: Fix code to match SRS (GREEN)
  VERIFY: Test passes, no regressions
Result: Code stays 100% aligned with design, fix is proven by a test
```

---

## Quick Reference

| Problem Type | Action | Enter Plan Mode? | Escalate? |
|--------------|--------|------------------|-----------|
| No SRS exists | Write preliminary SRS first | **YES** | No |
| Typo | Fix immediately | No | No |
| Logic (1 file) | Fix + verify vs SRS | No | No |
| Logic (multi-file) | Document + review SRS | Maybe | No |
| Design gap | Update SRS first | **YES** | No |
| New feature | Update SRS first | **YES** | No |
| External dependency | Propose solution only | No | **YES** |
| Performance issue | Profile + propose | No | **YES** |
| Hard to reproduce | Add debug traps, wait | No | After capture |
| Fix failed twice | Undo all, document | No | **YES** |

---

## Escalation Protocol

### Mandatory Escalation (Do NOT implement):
- External dependency workarounds
- Performance optimizations
- After 2 failed fix attempts

### Escalation Format:
```markdown
## Escalation Report

**Issue**: [Brief description]
**Classification**: [External/Performance/Failed Fix]

**Analysis**:
[What was found]

**Proposed Solution**:
[Recommended approach with pros/cons]

**Why Escalating**:
[Cannot implement without approval / 2 attempts failed / etc.]

**Recommended Action**:
[ ] Approve proposed solution
[ ] Provide alternative direction
[ ] Take over fix manually
```

### Escalation Hierarchy:
1. Haiku agent → Supervisor Sonnet
2. Sonnet agent → Supervisor Opus
3. Opus agent → Human user

---

## Debug Log Trap Protocol

### Adding Traps:
```python
# [DEBUG-TRAP] Investigating issue #123 - REMOVE AFTER FIX
logger.debug("[DEBUG-TRAP] Variable state: %s", variable)
```

### Trap Requirements:
- ALL traps prefixed with `[DEBUG-TRAP]`
- Comment explaining what we're looking for
- Include issue reference if applicable

### Removing Traps (MANDATORY after fix):
```bash
# Search for all traps
grep -r "DEBUG-TRAP" ./src/

# Verify count is ZERO before committing fix
```

### Trap Cleanup Checklist:
- [ ] `grep -r "DEBUG-TRAP"` returns empty
- [ ] No debug-only code remains
- [ ] Log levels back to normal
- [ ] Debug mode disabled in config
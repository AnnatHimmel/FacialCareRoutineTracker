# /6-ModifyLoop - Modify Existing Codebase

## Purpose
Handle modification requests to an existing codebase while maintaining alignment with design documents. Analyzes impact, updates documentation, creates tasks, and executes changes.

## When to Use
- User wants to add a feature to existing code
- User wants to change existing behavior
- User wants to fix a bug
- User wants to refactor part of the system

## Prerequisites
```
REQUIRED (existing project with documentation):
- .\doc\FUNCTIONALITY.md exists
- .\doc\ARCHITECTURE.md exists
- .\doc\WORKPLAN.md exists
- Source code exists in src/

IF any missing:
    → "This command is for modifying existing projects."
    → "For new projects, start with /1-Functionality"
```

## Modification Loop Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MODIFICATION LOOP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  USER REQUEST                                                                │
│       │                                                                      │
│       ▼                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 1: ANALYZE REQUEST                                              │   │
│  │  - Understand what user wants                                         │   │
│  │  - Identify type: Feature / Change / Bug / Refactor                   │   │
│  │  - Ask clarifying questions if needed                                 │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 2: IMPACT ANALYSIS                                              │   │
│  │  - Read current FUNCTIONALITY.md, ARCHITECTURE.md                     │   │
│  │  - Identify affected components                                       │   │
│  │  - Identify affected files                                            │   │
│  │  - Check for conflicts with existing design                           │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 3: DESIGN ALIGNMENT (via /2a-Architect logic)                   │   │
│  │  - Propose minimal architecture changes needed                        │   │
│  │  - Ensure modification fits existing patterns                         │   │
│  │  - Update ARCHITECTURE.md with changes                                │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 4: UPDATE DOCUMENTATION                                         │   │
│  │  - Update FUNCTIONALITY.md if new feature                             │   │
│  │  - Update ARCHITECTURE.md with changes                                │   │
│  │  - Update UI_DESIGN.md if UI changes (UI projects)                    │   │
│  │  - Log in DECISIONS.md                                                │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 5: CREATE WORK PLAN (via /3-Workplan logic)                     │   │
│  │  - Create modification tasks in WORKPLAN.md                           │   │
│  │  - Tasks marked as MOD-XXX (not TASK-XXX)                             │   │
│  │  - Include test updates                                               │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 6: EXECUTE (via /4-Execution logic)                             │   │
│  │  - Run TDD cycle for each MOD task                                    │   │
│  │  - NO STOPPING between tasks                                          │   │
│  │  - Update tests for changed behavior                                  │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  STEP 7: VERIFY                                                       │   │
│  │  - Run all tests (not just new ones)                                  │   │
│  │  - Check no regressions                                               │   │
│  │  - Verify modification works as requested                             │   │
│  └───────────────────────────────┬──────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│                         MODIFICATION COMPLETE                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Instructions

### Step 1: Analyze Request

When user describes a modification:

```
1. Parse the request to understand:
   - WHAT: What change is being requested?
   - WHY: What problem does this solve?
   - SCOPE: How big is this change?

2. Classify the modification type:
   □ NEW_FEATURE - Adding new capability
   □ CHANGE - Modifying existing behavior
   □ BUG_FIX - Fixing incorrect behavior
   □ REFACTOR - Improving code without changing behavior
   □ PERFORMANCE - Optimizing speed/memory
   □ UI_CHANGE - Modifying user interface

3. If request is unclear, ask ONE clarifying question
   (Loop until clear, but don't over-ask)
```

### Step 2: Impact Analysis

Read existing documentation and code to determine impact:

```markdown
## Modification Impact Analysis

**Request**: [User's request summary]
**Type**: [NEW_FEATURE / CHANGE / BUG_FIX / REFACTOR / PERFORMANCE / UI_CHANGE]

### Affected Components
| Component | Impact Level | Changes Needed |
|-----------|--------------|----------------|
| [Component from ARCHITECTURE.md] | High/Medium/Low | [Description] |

### Affected Files
| File | Type | Changes |
|------|------|---------|
| src/[file].py | Modify | [What changes] |
| test/test_[file].py | Modify | [Test updates needed] |
| [new file if needed] | Create | [Purpose] |

### Design Compatibility
- [ ] Fits existing architecture? [Yes/No - explain]
- [ ] Follows existing patterns? [Yes/No - explain]
- [ ] Requires architecture changes? [Yes/No - what]

### Risk Assessment
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| [Risk] | H/M/L | [How to handle] |

### Dependencies
- Depends on: [existing components]
- Affects: [downstream components]
```

### Step 3: Design Alignment

Invoke architect logic to ensure modification fits:

```
IF modification requires architecture changes:
    1. Propose minimal architecture changes
    2. Ensure changes don't break existing functionality
    3. Maintain consistency with existing patterns

IF modification conflicts with current design:
    1. Explain the conflict
    2. Propose resolution options:
       a) Modify the request to fit architecture
       b) Update architecture to accommodate request
    3. Proceed based on best option (no asking, use judgment)
```

### Step 4: Update Documentation

Update all affected documents:

#### FUNCTIONALITY.md Updates (if new feature)
```markdown
## [New/Modified Section]
**Added**: [Date] via modification request
**Request**: [Original request]

[New functionality description]
```

#### ARCHITECTURE.md Updates
```markdown
## [Affected Section]
**Modified**: [Date]
**Reason**: [Modification request summary]

[Updated architecture details]
```

#### DECISIONS.md Entry
```markdown
### MOD-DEC-XXX: [Modification Decision]
**Date**: [Date]
**Request**: [Original user request]
**Decision**: [What was decided]
**Impact**: [Components affected]
**Rationale**: [Why this approach]
```

### Step 5: Create Work Plan

Add modification tasks to WORKPLAN.md:

```markdown
## Modification: [Request Summary]
**Requested**: [Date]
**Type**: [Type]
**Impact**: [High/Medium/Low]

### MOD-001: [Task Name]
**Description**: [What to do]
**Depends On**: None
**Files to Modify**:
- src/[file].py - [changes]
- test/test_[file].py - [test updates]

**Acceptance Criteria**:
- [ ] [Criterion related to modification]
- [ ] Existing tests still pass
- [ ] New behavior verified

**Prompt for Agent**:
```
[Self-contained prompt for this modification task]
```

---

### MOD-002: Update Tests
**Description**: Update/add tests for new behavior
**Depends On**: MOD-001
...
```

### Step 6: Execute Modification

```
╔════════════════════════════════════════════════════════════════╗
║  EXECUTE ALL MOD TASKS - NO STOPPING                           ║
╠════════════════════════════════════════════════════════════════╣
║                                                                 ║
║  FOR each MOD-XXX task:                                         ║
║    1. RED: Write/update failing test for new behavior           ║
║       → Run it — it MUST fail before proceeding                 ║
║         (if it passes, the test doesn't capture the change)     ║
║    2. GREEN: Implement the modification                         ║
║    3. REFACTOR: Clean up if needed                              ║
║    4. VERIFY: All tests pass (including existing!)              ║
║                                                                 ║
║  NO PAUSING - NO ASKING - JUST EXECUTE                          ║
║                                                                 ║
╚════════════════════════════════════════════════════════════════╝
```

### Step 7: Verify Modification

After all MOD tasks complete:

```
VERIFICATION CHECKLIST:
═══════════════════════════════════════════════════════════════

✅/❌ Modification works as requested?
✅/❌ All existing tests still pass?
✅/❌ New tests added for new behavior?
✅/❌ No regressions introduced?
✅/❌ Documentation updated?
✅/❌ Code follows existing patterns?

IF any check fails:
    → Fix immediately (no asking)
    → Re-verify

WHEN all pass:
    → CHECK ERROR LIST:
      IF .\doc\ErrorList.md exists AND has other PENDING entries:
          → Display: "Found [N] more pending error reports. Processing..."
          → FOR each PENDING entry (HIGH priority first):
              a. Update status → IN_PROGRESS
              b. Process via this same ModifyLoop flow
              c. Update status → RESOLVED
          → Re-verify after all processed
      IF no PENDING entries:
          → Display completion summary
```

## Completion Output

```
═══════════════════════════════════════════════════════════════
              MODIFICATION COMPLETE ✅
═══════════════════════════════════════════════════════════════

**Request**: [Original request]
**Type**: [Type]

### Changes Made
| File | Change |
|------|--------|
| [file] | [what changed] |

### Documentation Updated
- [x] FUNCTIONALITY.md (if applicable)
- [x] ARCHITECTURE.md
- [x] DECISIONS.md
- [x] WORKPLAN.md

### Tests
- Existing tests: [N] passing
- New tests added: [N]
- Total tests: [N] passing

### Verification
All checks passed. Modification complete.

═══════════════════════════════════════════════════════════════
```

## Special Cases

### Bug Fix Flow
```
1. Analyze bug report
2. Identify root cause in code
3. Check if bug is in spec (FUNCTIONALITY.md) or implementation
4. If spec bug: Update FUNCTIONALITY.md first
5. Create MOD task to fix
6. Write regression test that reproduces the bug
   → Run it — confirm it FAILS before proceeding
7. Execute fix
8. Verify the regression test now passes
```

### Feature Addition Flow
```
1. Analyze feature request
2. Check how it fits with existing features
3. Update FUNCTIONALITY.md with new feature
4. Update ARCHITECTURE.md with new component/changes
5. Create MOD tasks
6. Execute with TDD
```

### Refactoring Flow
```
1. Analyze refactoring goal
2. Ensure no behavior change intended
3. Create MOD tasks for refactoring
4. Execute (tests should pass before AND after)
5. No FUNCTIONALITY.md changes needed
```

## Auto-Continue Behavior

```
CRITICAL: This command runs the full loop automatically

User provides request
    → Analyze (may ask 1 clarifying question)
    → Impact analysis
    → Design alignment
    → Doc updates
    → Work plan creation
    → Execute ALL tasks (no stopping)
    → Verify
    → DONE

Only stops for:
- Clarifying question (if truly needed)
- Human escalation (all agents failed)
```

## Do NOT:
- Ask permission to continue between steps
- Stop to summarize progress (just log it)
- Wait for approval on obvious changes
- Break existing tests without fixing them
- Skip documentation updates
- Make changes that conflict with architecture without updating it

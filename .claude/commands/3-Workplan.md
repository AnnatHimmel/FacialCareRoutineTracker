# /3-Workplan - Work Planning & Task Breakdown

## Purpose
Transform Architecture (and UI Design if applicable) into atomic, executable tasks. Loop until work plan is complete and all tasks are properly sized.

## Prerequisites
```
REQUIRED:
- .\doc\FUNCTIONALITY.md exists
- .\doc\ARCHITECTURE.md exists
- IF UI/Hybrid: .\doc\UI_DESIGN.md exists

IF Architecture missing:
    → "No architecture found. Running /2a-Architect first..."
    → AUTO-EXECUTE /2a-Architect
```

## Behavior: Work Planning Loop Until Perfect

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORK PLANNING LOOP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │    LOAD      │────▶│   CREATE     │────▶│   VALIDATE   │    │
│  │  All Docs    │     │    TASKS     │     │  Task Sizes  │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                              ▲                     │             │
│                              │   TASKS TOO LARGE   │             │
│                              │   → SPLIT THEM      │             │
│                              └─────────────────────┘             │
│                                          │ ALL VALID             │
│                                          ▼                       │
│                              ┌──────────────────────┐           │
│                              │  AUTO-CONTINUE to    │           │
│                              │  /4-Execution        │           │
│                              └──────────────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Instructions

### Step 1: Load All Context
```
1. Read .\doc\FUNCTIONALITY.md
2. Read .\doc\ARCHITECTURE.md
3. Read .\doc\UI_DESIGN.md (if exists)
4. Extract: Build order, components, interfaces, data models
```

### Step 2: Create Work Plan Documents

#### Document 1: WORKPLAN.md
```markdown
# Work Plan
Project: [Name]
Created: [Date]
Total Tasks: [N]

## Overview
[Summary of what will be built]

## Phase 1: Foundation
### TASK-001: [Task Name]
**Description**: [What to build]
**Depends On**: None
**Files to Create/Modify** (TDD order — test first, then implementation):
- test/test_[file1].py  ← written first (RED: must fail before proceeding)
- src/[file1].py        ← written after test fails (GREEN)

**Acceptance Criteria**:
- [ ] [Specific testable criterion]
- [ ] [Specific testable criterion]

**Context Files** (max 3):
- .\doc\ARCHITECTURE.md#Section-2.2
- [Any existing file needed]

**Prompt for Agent**:
```
[Self-contained prompt that can be given to a fresh agent context]
[Include all necessary information - no external references]
[Max 500 words]
```

---

### TASK-002: [Task Name]
**Depends On**: TASK-001
[... same structure ...]

---

## Phase 2: Core Features
[Continue with tasks...]

## Phase 3: Integration
[Continue with tasks...]

## Dependency Graph
```
TASK-001 ──┬──▶ TASK-002 ──▶ TASK-004
           │
           └──▶ TASK-003 ──▶ TASK-005
                              │
TASK-006 ◀────────────────────┘
```

## Critical Path
[Longest sequence of dependent tasks]
TASK-001 → TASK-002 → TASK-004 → TASK-006 (4 tasks)

## Parallelizable Tasks
[Tasks that can run simultaneously]
- TASK-002 and TASK-003 (both depend only on TASK-001)
```

#### Document 2: PROGRESS.md
```markdown
# Progress Tracker
Project: [Name]
Last Updated: [Timestamp]

## Summary
| Status | Count |
|--------|-------|
| Pending | [N] |
| In Progress | [N] |
| Completed | [N] |
| Blocked | [N] |

## Task Status

| Task | Status | Started | Completed | Notes |
|------|--------|---------|-----------|-------|
| TASK-001 | Pending | - | - | - |
| TASK-002 | Pending | - | - | Blocked by TASK-001 |
| ... | | | | |

## Current Blockers
[None or list of blocking issues]

## Recent Activity
- [Timestamp]: [Activity description]
```

#### Document 3: DECISIONS.md
```markdown
# Technical Decisions Log
Project: [Name]

## Purpose
Persists decisions across task contexts. Each task reads relevant decisions before starting.

## Decisions

### [Module/Component Name]

#### DEC-001: [Decision Title]
**Date**: [Date]
**Context**: [Why this decision was needed]
**Decision**: [What was decided]
**Rationale**: [Why this choice]
**Alternatives Rejected**: [What else was considered]
**Affects Tasks**: TASK-XXX, TASK-YYY

---

[More decisions as they're made during execution]
```

#### Document 4: LEARNINGS.md
```markdown
# Learnings & Patterns
Project: [Name]

## Purpose
Compound knowledge flywheel. Captures patterns and gotchas discovered during execution.

## Patterns

### [Category]

#### LEARN-001: [Pattern Name]
**Discovered**: [Date] during TASK-XXX
**Pattern**: [What was learned]
**Example**:
```
[Code or configuration example]
```
**Apply When**: [When to use this pattern]

---

## Gotchas

### GOTCHA-001: [Issue Name]
**Discovered**: [Date] during TASK-XXX
**Problem**: [What went wrong]
**Solution**: [How to avoid/fix]
**Symptoms**: [How to recognize this issue]

---
```

### Step 3: Validate Task Sizes
```
FOR each task in WORKPLAN.md:
    CHECK:
    - [ ] Task prompt ≤ 500 words
    - [ ] Context files ≤ 3
    - [ ] Single clear deliverable
    - [ ] Testable acceptance criteria
    - [ ] Dependencies are explicit

    IF any check fails:
        → SPLIT the task into smaller tasks
        → Update dependency graph
```

### Step 4: Validation Checklist
```
WORK PLAN VALIDATION:
═══════════════════════════════════════════════════════════════

✅/❌ All Architecture components have tasks?
✅/❌ All UI screens have tasks? (if UI project)
✅/❌ All tasks have acceptance criteria?
✅/❌ All tasks have self-contained prompts?
✅/❌ All task prompts ≤ 500 words?
✅/❌ All tasks need ≤ 3 context files?
✅/❌ Dependency graph is acyclic?
✅/❌ Critical path identified?
✅/❌ PROGRESS.md initialized?
✅/❌ DECISIONS.md template ready?
✅/❌ LEARNINGS.md template ready?

RESULT: [X/11 checks passed]
═══════════════════════════════════════════════════════════════
```

### Step 5: Loop Until Valid
```
WHILE validation < 11/11:
    1. Identify issues
    2. Fix work plan (split tasks, add details, fix deps)
    3. Re-validate

WHEN validation = 11/11:
    → Save all documents
    → Auto-continue
```

### Step 6: Auto-Continue
```
CRITICAL - NO QUESTIONS:

→ Display summary:
    "Work Plan complete:
    - Total tasks: [N]
    - Phases: [N]
    - Critical path: [N] tasks
    - Estimated parallelizable: [N] tasks

    Continuing to Execution..."

→ do not move to next phase. display results to human and ask for permission to continue to next phase: /4-Execution
```

## Task Sizing Rules

### Maximum Task Size
- Prompt: 500 words max
- Context files: 3 files max
- Deliverable: 1 clear output
- Duration: Should be completable in fresh context

### When to Split
```
SPLIT IF:
- Task touches > 3 files
- Task has multiple distinct deliverables
- Task has complex conditional logic
- Task prompt exceeds 500 words
- Task requires extensive background

SPLIT INTO:
- Setup task (create structure)
- Implementation task (write code)
- Integration task (connect components)
```

## Do NOT:
- Write implementation code
- Execute any tasks
- Ask permission to continue
- Create tasks too large for fresh context
- Leave TBD in any task prompt

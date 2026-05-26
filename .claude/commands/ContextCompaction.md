# /ContextCompaction - Compact Context for Next Phase

## Purpose
Compact the conversation context by summarizing completed work and preserving only what's necessary for the next phase. Use this before `/compact` to ensure critical project state is retained.

## When to Use
- Before running `/compact` to reduce context window usage
- When switching between workflow phases
- When conversation is getting long and you need to preserve project state

## Behavior

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONTEXT COMPACTION                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Detect current phase from existing docs                      │
│  2. Summarize completed work                                     │
│  3. Identify next phase                                          │
│  4. Output compact context block                                 │
│  5. User runs /compact                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Instructions

### Step 1: Detect Current State
Check which documents exist to determine completed phases:

```
.\doc\FUNCTIONALITY.md    → Phase 1 complete
.\doc\ARCHITECTURE.md     → Phase 2a complete
.\doc\UI_DESIGN.md        → Phase 2b complete (if UI project)
.\doc\WORKPLAN.md         → Phase 3 complete
.\doc\PROGRESS.md         → Phase 4 in progress/complete
```

### Step 2: Generate Context Summary
Output a compact summary block in this format:

```
═══════════════════════════════════════════════════════════════
PROJECT CONTEXT SUMMARY (for /compact)
═══════════════════════════════════════════════════════════════

PROJECT: [Name from FUNCTIONALITY.md]
TYPE: [CLI / UI / Hybrid / API / Library]
CURRENT PHASE: [Phase name]
NEXT PHASE: [Next phase to execute]

COMPLETED PHASES:
- [x] Phase 1: Functionality - [one-line summary]
- [x] Phase 2a: Architecture - [one-line summary]
- [ ] Phase 2b: UI Design - [status]
- [ ] Phase 3: Workplan - [status]
- [ ] Phase 4: Execution - [status]
- [ ] Phase 5: Review - [status]

KEY DECISIONS MADE:
1. [Critical decision 1]
2. [Critical decision 2]
3. [Critical decision 3]

ACTIVE TASK (if in execution):
- Task: [Current task description]
- Status: [in_progress / blocked / pending]
- Files touched: [list]

BLOCKING ISSUES (if any):
- [Issue 1]

NEXT ACTION:
→ Run /[X]-[Name] to continue

═══════════════════════════════════════════════════════════════
```

### Step 3: Read Key Files for Summary
```
1. Read headers/summaries from each existing doc (not full content)
2. Extract: project name, type, key decisions, current task
3. Check PROGRESS.md for execution state
4. Identify any blocking issues or open questions
```

### Step 4: Recommend Next Steps
```
After outputting the context block:

1. Tell user: "Context summary generated. You can now run /compact"
2. Remind: "After /compact, run /[X]-[Name] to continue"
```

## What to PRESERVE (Critical)
- Project name and type
- Current phase and next phase
- Key architectural decisions
- Active task details (if in execution)
- Blocking issues
- File paths being modified

## What to DISCARD (Safe to lose)
- Interview Q&A details (captured in FUNCTIONALITY.md)
- Design iteration discussions (captured in docs)
- Debugging conversations (issues resolved)
- Exploratory searches (findings documented)

## Example Output

```
═══════════════════════════════════════════════════════════════
PROJECT CONTEXT SUMMARY (for /compact)
═══════════════════════════════════════════════════════════════

PROJECT: AmazonAds Optimization System
TYPE: Hybrid (CLI + UI)
CURRENT PHASE: /4-Execution (Task 12/45)
NEXT PHASE: Continue /4-Execution

COMPLETED PHASES:
- [x] Phase 1: Functionality - Ad optimization with AI recommendations
- [x] Phase 2a: Architecture - Dash UI + Python API + Rule Engine
- [x] Phase 2b: UI Design - Dashboard with KPIs, tables, decision panel
- [x] Phase 3: Workplan - 45 tasks across 6 components

KEY DECISIONS MADE:
1. Use Dash + Mantine for UI (not Streamlit)
2. 7-day attribution window for ACOS calculations
3. Rule engine with condition/action pattern
4. CSV data files at V:\Amazon\Automation\AdsAPI\SavedData\

ACTIVE TASK:
- Task: Implement campaign budget modification
- Status: in_progress
- Files touched: src/api/campaigns.py, src/ui/callbacks/

BLOCKING ISSUES:
- None

NEXT ACTION:
→ Continue with /4-Execution

═══════════════════════════════════════════════════════════════

Context summary generated. You can now run /compact
After /compact, run /4-Execution to continue from Task 12.
```

## Do NOT:
- Include full file contents in summary
- Preserve debugging conversations
- Keep exploratory dead-ends
- Output more than the compact block format
- Run /compact automatically (user must do this)

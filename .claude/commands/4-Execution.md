# /4-Execution - Autonomous Task Execution

## Purpose
Execute ALL tasks from WORKPLAN.md using TDD cycle. Runs to completion WITHOUT stopping for permission.

## CRITICAL BEHAVIOR: NO STOPPING

```
╔═══════════════════════════════════════════════════════════════════╗
║                     AUTONOMOUS EXECUTION MODE                      ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║   DO NOT:                                                          ║
║   ❌ Ask "Should I continue?"                                      ║
║   ❌ Ask "Ready for the next task?"                                ║
║   ❌ Wait for permission between tasks                             ║
║   ❌ Stop to summarize progress (just log it)                      ║
║   ❌ Pause for user confirmation                                   ║
║                                                                    ║
║   DO:                                                              ║
║   ✅ Execute task after task automatically                         ║
║   ✅ Log progress to PROGRESS.md                                   ║
║   ✅ Handle failures with retry/escalation                         ║
║   ✅ Continue until ALL tasks complete                             ║
║   ✅ Only stop on HUMAN ESCALATION (all retries exhausted)         ║
║                                                                    ║
╚═══════════════════════════════════════════════════════════════════╝
```

## Prerequisites
```
REQUIRED:
- .\doc\WORKPLAN.md exists with tasks
- .\doc\PROGRESS.md exists
- .\doc\DECISIONS.md exists
- .\doc\LEARNINGS.md exists

IF WORKPLAN missing:
    → "No work plan found. Running /3-Workplan first..."
    → AUTO-EXECUTE /3-Workplan
```

## Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  AUTONOMOUS EXECUTION LOOP                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  START                                                           │
│    │                                                             │
│    ▼                                                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  GET NEXT TASK (dependency-order, not blocked)           │   │
│  └────────────────────────┬─────────────────────────────────┘   │
│                           │                                      │
│             ┌─────────────┼─────────────┐                       │
│             │ No tasks    │ Task found  │                       │
│             │ remaining   │             │                       │
│             ▼             ▼             │                       │
│     ┌─────────────┐ ┌───────────────┐  │                       │
│     │ ALL DONE!   │ │ EXECUTE TASK  │  │                       │
│     │ → /5-Review │ │ (TDD Cycle)   │  │                       │
│     └─────────────┘ └───────┬───────┘  │                       │
│                             ▼          │                       │
│                    ┌───────────────┐   │                       │
│                    │    SUCCESS?   │   │                       │
│                    └───────┬───────┘   │                       │
│                            │           │                       │
│              ┌─────────────┼───────────┤                       │
│              │ YES         │ NO        │                       │
│              ▼             ▼           │                       │
│     ┌─────────────┐ ┌───────────────┐  │                       │
│     │ Update      │ │ RETRY/ESCALATE│  │                       │
│     │ PROGRESS.md │ │ (auto)        │  │                       │
│     │ Mark done   │ └───────┬───────┘  │                       │
│     └──────┬──────┘         │          │                       │
│            │                │          │                       │
│            └────────────────┴──────────┘                       │
│                    │                                            │
│                    │  LOOP BACK (no pause, no question)         │
│                    └────────────────────────────────────────────│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## TDD Cycle Per Task

For EACH task, execute this cycle:

### Phase 1: RED (Write Failing Test)
```
Agent: test-writer (Haiku)
Supervisor: supervisor-sonnet

Input:
- Task acceptance criteria from WORKPLAN.md
- Relevant DECISIONS.md entries

Output:
- Failing test in test/

Retry: Up to 2 attempts
Escalate: → supervisor-sonnet tries → supervisor-opus tries → HUMAN
```

### Phase 2: GREEN (Make Test Pass)
```
Agent: coder (Sonnet)
Supervisor: supervisor-opus

Input:
- ONLY the failing test (context isolation!)
- Relevant LEARNINGS.md patterns

Output:
- Minimal implementation that passes test

Retry: Up to 2 attempts
Escalate: → supervisor-opus tries → HUMAN
```

### Phase 3: REFACTOR (Improve Code)
```
Agent: refactorer (Haiku)
Supervisor: supervisor-sonnet

Input:
- Working code + passing test

Output:
- Improved code OR "no changes needed"

Retry: Up to 2 attempts (revert if breaks tests)
Escalate: → Skip refactoring (acceptable outcome)
```

### Phase 4: VERIFY (All Tests Pass)
```
Agent: test-runner (Haiku)

Input:
- Full test suite

Output:
- All tests passing confirmation

If any test fails:
- Identify which task broke it
- Fix immediately before continuing
```

## Automatic Progress Logging

After EACH task (success or failure), update:

### PROGRESS.md
```markdown
| TASK-XXX | ✅ Completed | [timestamp] | [timestamp] | TDD cycle: 1 attempt |
```

### DECISIONS.md (if decisions were made)
```markdown
### DEC-XXX: [Decision made during task]
**Date**: [Now]
**Context**: [Why]
**Decision**: [What]
**Affects Tasks**: [Which]
```

### LEARNINGS.md (if patterns discovered)
```markdown
### LEARN-XXX: [Pattern discovered]
**Discovered**: [Now] during TASK-XXX
**Pattern**: [What was learned]
```

## Escalation Protocol (Automatic)

```
FAILURE HANDLING (NO HUMAN PAUSE UNTIL EXHAUSTED):

Task fails (attempt 1)
    │
    ▼ [AUTO-RETRY]
Task fails (attempt 2)
    │
    ▼ [AUTO-ESCALATE to supervisor]
Supervisor analyzes and either:
    ├── Gives better instructions → Worker retries (2 more attempts)
    └── Takes over task → Supervisor attempts (2 attempts)
           │
           ▼ [IF supervisor fails]
    Higher supervisor takes over
           │
           ▼ [IF all supervisors fail]
    ╔════════════════════════════════════════╗
    ║  🚨 HUMAN ESCALATION                   ║
    ║  (ONLY stopping point)                 ║
    ╚════════════════════════════════════════╝
```

### Human Escalation Format (Only Time Execution Stops)
```markdown
## 🚨 HUMAN INPUT REQUIRED

**Task**: TASK-XXX - [Description]
**Phase**: [RED/GREEN/REFACTOR]
**Attempts**: [Total attempts by all agents]

### What Was Tried
| Agent | Model | Attempts | Result |
|-------|-------|----------|--------|
| test-writer | Haiku | 2 | Failed: [reason] |
| supervisor-sonnet | Sonnet | 2 | Failed: [reason] |
| supervisor-opus | Opus | 2 | Failed: [reason] |

### Root Cause Analysis
[Why all agents failed]

### Options for Human
1. **Provide guidance**: [Specific question]
2. **Skip this task**: Mark as blocked, continue with non-dependent tasks
3. **Modify requirements**: Task may be impossible as specified

### Waiting for human response...
```

## Parallel Execution (When Possible)

```
IF multiple tasks have no dependencies on each other:
    → Execute in parallel using Task tool
    → Wait for all to complete
    → Update progress for all
    → Continue to next batch
```

## End of Execution

When ALL tasks in WORKPLAN.md are complete:

```
DO NOT ASK - AUTO-CONTINUE:

1. Display summary:
   "═══════════════════════════════════════════════════════════════
    EXECUTION COMPLETE
    ═══════════════════════════════════════════════════════════════
    Tasks completed: [N/N]
    Tests passing: [N]
    Decisions logged: [N]
    Learnings captured: [N]"

2. CHECK ERROR LIST (before continuing):
   IF .\doc\ErrorList.md exists AND has PENDING entries:
       → Display: "Found [N] pending error reports. Processing before review..."
       → FOR each PENDING entry (HIGH priority first):
           a. Update status → IN_PROGRESS
           b. Run /6-ModifyLoop with error description
           c. Update status → RESOLVED
       → Display: "All error reports processed."

3. Display: "Continuing to Review..."
4. AUTO-EXECUTE /5-Review
```

## Context Isolation Rules (CRITICAL)

| Phase | Agent Receives | Agent Does NOT Receive |
|-------|----------------|------------------------|
| RED | Acceptance criteria ONLY | Implementation hints |
| GREEN | Failing test ONLY | Original requirements |
| REFACTOR | Working code + test | Original requirements |

**Why**: Prevents test design from being influenced by implementation ideas.

## Recovery From Failures

### Test Failure Mid-Execution
```
IF a previously-passing test fails:
    1. Identify which recent change caused it
    2. Create hotfix task
    3. Execute hotfix immediately
    4. Re-run all tests
    5. Continue with original task queue
```

### Blocked Task
```
IF task is blocked by incomplete dependency:
    1. Skip to next non-blocked task
    2. Return to blocked tasks when dependencies complete
```

## Do NOT:
- Stop to ask permission
- Pause between tasks
- Wait for user confirmation
- Ask "should I continue"
- Stop for progress summaries (just log them)
- Stop unless HUMAN ESCALATION is needed

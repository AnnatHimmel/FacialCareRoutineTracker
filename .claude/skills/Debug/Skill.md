---
name: Debug
description: Diagnostic investigation skill. Finds root cause of unknown problems and reports findings. NEVER fixes - only diagnoses and recommends. Handoff to /fix-code after user approval. TRIGGER when: user reports a bug, describes unexpected behavior, mentions an error or exception, says something is broken/wrong/not working, or asks why something is not behaving as expected. SKIP when: user explicitly asks to fix a known bug (use Fix-Code instead).
---

# Debug Skill

## Core Identity
> **Diagnostic & Report ONLY** - Never fixes, only finds and recommends.

This skill is for when something is wrong but you **don't know what or where**.
For known bugs with clear location, use `/fix-code` directly.

---

## Phase 1: GATHER SYMPTOMS

### Ask Questions ONLY If Missing Info
Before investigating, ensure you know:
- [ ] What is the observed behavior? (exact error, unexpected output, etc.)
- [ ] What is the expected behavior?
- [ ] When did it start? What changed recently?
- [ ] Is it reproducible? (Always / Sometimes / Rare)
- [ ] Any error messages or logs available?

```
IF all info available:
    → Proceed to Phase 2
ELSE:
    → Ask user for missing info (ONE round of questions)
    → THEN proceed to Phase 2
```

**Rule**: Ask once, then run autonomously. Don't keep asking.

---

## Phase 2: THINK HARD - FORM HYPOTHESES

### Use Extended Thinking
Trigger deep analysis with "think hard" to:
1. List ALL possible causes based on symptoms
2. Rank by likelihood (most probable first)
3. Identify what evidence would confirm/rule out each

### Hypothesis Template
```markdown
## Hypotheses (Ranked by Likelihood)

### H1: [Most likely cause]
- Why likely: [reasoning]
- Evidence needed: [what to check]
- How to confirm: [test/check method]

### H2: [Second most likely]
- Why likely: [reasoning]
- Evidence needed: [what to check]
- How to confirm: [test/check method]

### H3: [Third possibility]
...
```

**Rule**: Generate at least 3 hypotheses before investigating.

---

## Phase 3: INVESTIGATE

### Scope: Everything Relevant
Investigation includes ALL of:
- Source code
- Configuration files
- Environment variables
- Log files
- Data/input files
- External dependencies
- System state

### Investigation Techniques

#### 1. Log Analysis
```
IF logs exist:
    → Search for errors, warnings, anomalies
    → Check timestamps around reported issue time
    → Look for patterns
```

#### 1a. MANDATORY: Server-Data Errors → Read the LATEST Logged Response
**Trigger**: Any error that could plausibly be caused by data returned from
a server/API/external source — `KeyError`, `TypeError`, missing-field errors,
shape-mismatch errors, parse failures, schema-related exceptions, "unexpected
None", etc.

**Rule**: Before forming hypotheses about parser code, ALWAYS read the
**most recent logged response from the server for the relevant team /
entity / id**, in `logs/` (or the project's configured log directory).
Schemas drift over time — old log entries record OLD contracts. The
current contract is whatever the server emitted in the user's most
recent session. Fixtures, decision docs, and recent commits can lie —
verify against real bytes from the current session.

**How**:
1. Identify the log file(s) likely to contain server responses
   (e.g. `logs/update.log`, search for log entries with `Received` /
   `response` / the relevant URL or endpoint).
2. **Find the LAST entry, not the first.** Long-lived log files may span
   weeks and contain MULTIPLE schema versions. The first entry is the
   oldest contract; the last entry is the live one. Sort by timestamp
   if needed. If the log spans a server-host change (different IP/URL),
   only entries from the current host count — earlier entries record a
   server that may no longer exist.
3. Cross-check: pick the most recent 2–3 responses (different teams or
   entities, same session) and confirm they share the same shape. If
   they diverge, ask the user which server they're hitting now.
4. Read the full JSON/payload, not just a snippet — schema bugs hide in
   field-name typos, nested envelopes, and value-type changes
   (string ↔ integer).
5. Compare the real payload field-by-field against what the parser code
   expects. Note EVERY mismatch, not just the one that caused the visible
   crash — silent fallbacks (`.get(key, default)`, `?.field || ""`) will
   mask additional bugs that surface only after the crash is fixed.

**Anti-pattern**: Reading the top of the log (first entry) to "get a
sample" of the schema. This is how diagnosis goes wrong — the first
entry may be from a contract that was replaced weeks ago. Always read
the LAST entry.

**Why this is mandatory**: Diagnosing a parser bug from commits, fixtures,
or decision documents alone is unreliable — the fixture or doc may itself
be the source of the bug, OR the contract may have evolved past what
they describe. The most-recent log entry is the only authoritative
source for what the live server emits today.

#### 2. Code Reading
```
→ Trace the data flow from input to output
→ Identify decision points where behavior diverges
→ Check recent changes (git diff, git log)
```

#### 3. Binary Search Isolation
```
→ If large codebase: comment out half, does it still fail?
→ Narrow down to smallest failing unit
→ Isolate: Input problem? Processing? Output? Environment?
```

#### 4. State Inspection
```
→ Add debug prints at checkpoints
→ Verify variables have expected values
→ Check state before/after suspected code
```

#### 5. Environment Check
```
→ Works in other environments?
→ Dependencies versions correct?
→ Config differences?
```

### Adding Debug Traps (If Needed)
When problem can't be reproduced or traced:

```python
# [DEBUG-TRAP] Investigating: [brief description] - REMOVE AFTER DIAGNOSIS
logger.debug("[DEBUG-TRAP] checkpoint_name: var=%s, state=%s", var, state)
```

**Trap Rules**:
- ALL traps prefixed with `[DEBUG-TRAP]`
- Document what you're looking for
- Traps will be cleaned by `/fix-code` after fix

---

## Phase 4: NARROW DOWN

### Elimination Process
```
For each hypothesis:
    → Gather evidence
    → Does evidence support or refute?
    → IF refuted: Cross off, move to next
    → IF supported: Dig deeper to confirm
```

### Follow the Data
```
Input → [Transform 1] → [Transform 2] → ... → Output
         ↑               ↑
         Check here      Check here

Find where actual diverges from expected
```

### Confirm Root Cause Criteria
- [ ] Can reproduce the problem reliably
- [ ] Understand WHY it happens (not just WHERE)
- [ ] Know the exact location (file, line, function)
- [ ] Can explain the cause-effect chain

---

## Phase 5: REPORT FINDINGS

### Diagnosis Report (MANDATORY OUTPUT)

```markdown
## 🔍 Debug Diagnosis Report

### Symptoms
[What was observed - user's original complaint]

### Investigation Summary
[What was checked, what was found]

### Root Cause
[Confirmed cause with clear explanation]

### Location
- **File(s)**: [path(s)]
- **Line(s)**: [number(s)]
- **Function/Module**: [name(s)]

### Evidence
[Logs, traces, reproduction steps that confirm this]
```
[Code snippet showing the problem if applicable]
```

### Problem Classification
- [ ] Typo/Simple Error
- [ ] Logic Error (code doesn't match intent)
- [ ] Design Gap (design doesn't cover this case)
- [ ] External Dependency Issue
- [ ] Performance Issue
- [ ] Environment/Configuration Issue
- [ ] Data/Input Issue

### Suggested Solution
[Recommended fix approach - be specific]

### Debug Traps Status
- [ ] None added
- [ ] Traps added at: [list locations]
  (Will be cleaned by /fix-code)

### Confidence Level
- [ ] HIGH - Root cause confirmed, solution clear
- [ ] MEDIUM - Likely root cause, solution should work
- [ ] LOW - Best hypothesis, needs verification

---
**Next Step**: User approve → Run `/fix-code`
```

---

## Phase 6: HANDOFF

### After Report
```
STOP and present report to user

IF user approves solution:
    → Invoke /fix-code with:
      - Clear problem definition
      - Confirmed location
      - Suggested solution
      - Classification for routing

IF user wants different approach:
    → Update solution based on feedback
    → Re-present for approval

IF user wants more investigation:
    → Return to Phase 3 with new direction
```

**Rule**: Debug skill ENDS with report. Fixing happens in `/fix-code`.

---

## Escalation Triggers

### Escalate When:
- [ ] All hypotheses exhausted, no root cause found
- [ ] 2 investigation cycles with no progress
- [ ] Issue requires access/permissions you don't have
- [ ] External system issue (3rd party API, service)
- [ ] Need domain expertise beyond code

### Escalation Report
```markdown
## ⚠️ Debug Escalation

### Issue
[What was being investigated]

### Investigation Done
[What was checked]

### Hypotheses Tested
[What was ruled out and why]

### Current Best Guess
[If any]

### Why Escalating
[Specific reason - access needed, expertise needed, etc.]

### Recommended Next Step
[What human/supervisor should do]
```

---

## Quick Reference

### Debug vs Fix-Code

| Aspect | /debug | /fix-code |
|--------|--------|-----------|
| Purpose | Find the problem | Fix the problem |
| Modifies code? | Only debug traps | Yes - actual fix |
| Needs SRS? | No | Yes |
| Output | Diagnosis report | Working code |
| Ends with | Report + recommendation | Verified fix |

### Debug Techniques Checklist
- [ ] Symptom gathering complete
- [ ] Hypotheses formed (3+ minimum)
- [ ] Logs checked
- [ ] Code traced
- [ ] Recent changes reviewed
- [ ] Binary search isolation tried
- [ ] State inspection done
- [ ] Environment compared
- [ ] Root cause confirmed
- [ ] Report generated

### Common Root Cause Categories
1. **Input issues** - Bad data, wrong format, edge cases
2. **Logic errors** - Wrong condition, off-by-one, wrong operator
3. **State issues** - Race condition, stale data, wrong initialization
4. **Environment** - Config mismatch, version mismatch, permissions
5. **External** - API changed, service down, network issues
6. **Resource** - Memory, disk, connections exhausted

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        /debug WORKFLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                               │
│  │   GATHER     │  Ask questions ONLY if missing info           │
│  │   SYMPTOMS   │  (What? When? Reproducible?)                  │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │   THINK      │  "think hard" - form hypotheses               │
│  │   HARD       │  Rank by likelihood (3+ minimum)              │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ INVESTIGATE  │  Read code, logs, configs, environment        │
│  │              │  Add [DEBUG-TRAP] if can't reproduce          │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │   NARROW     │  Binary search isolation                      │
│  │   DOWN       │  Follow data flow, confirm root cause         │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │   REPORT     │  Diagnosis report + suggested solution        │
│  │   FINDINGS   │  ──► User approves ──► /fix-code              │
│  └──────────────┘                                               │
│                                                                 │
│  [Escalate if: hypotheses exhausted, 2 cycles no progress,      │
│   access needed, external issue, domain expertise needed]       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

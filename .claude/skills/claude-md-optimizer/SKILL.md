---
name: claude-md-optimizer
description: Optimize and shrink CLAUDE.md files to minimize context window usage while preserving essential project context. Use when a user wants to audit, trim, refactor, or optimize their CLAUDE.md file, when context window is filling up too fast, when starting a new project and wanting a lean CLAUDE.md, or when migrating bloated CLAUDE.md content into referenced files. Triggers include mentions of "shrink CLAUDE.md", "optimize context", "CLAUDE.md too long", "context window management", or "lean CLAUDE.md".
---

# CLAUDE.md Optimizer

Audit and optimize CLAUDE.md files to maximize context window efficiency.

## Core Principle

Every line in CLAUDE.md competes for attention with actual work. Only include what Claude needs in >30% of sessions. Everything else goes into referenced files.

## Workflow

### 1. Analyze Current CLAUDE.md

Read the existing CLAUDE.md and categorize every section using the criteria in `references/keep-vs-remove.md`.

### 2. Score Each Section

For each section, determine:
- **Frequency**: Is this needed in >30% of sessions? → KEEP in CLAUDE.md
- **Inferrable**: Can Claude figure this out from reading the code? → REMOVE
- **Deterministic**: Should a linter/formatter handle this? → REMOVE, use hooks instead
- **Depth**: Is this reference material vs. actionable instruction? → MOVE to reference file

### 3. Restructure

Create optimized output following this target structure (aim for <100 lines total):

```markdown
# [Project Name]
[One-line description with tech stack]

## Commands
[Only commands Claude will actually run — no explanations]

## Structure
[3-5 key directories with one-line purpose each]

## Critical Rules
[Only things Claude keeps getting wrong — use IMPORTANT prefix]

## References
[Pointers to deeper docs — "For X, see path/to/file.md"]
```

### 4. Extract to Reference Files

For each removed section, determine if it should be:
- **Deleted entirely** — Claude can infer it or a linter handles it
- **Moved to a reference file** — still valuable but only on-demand
  - Place in project's `docs/` or `.claude/` directory
  - Add a one-line pointer in CLAUDE.md under `## References`

### 5. Report

Present a before/after summary:
- Line count: before → after
- Estimated token savings
- What was removed and why
- What was moved to reference files
- Any recommendations for hooks/linters to replace removed rules

## Quality Checks

After optimization, verify:
- [ ] CLAUDE.md is under 100 lines (ideal) or 150 lines (max)
- [ ] Every line passes the "30% of sessions" test
- [ ] No code style rules that a linter could handle
- [ ] No full documentation — only pointers
- [ ] No generic advice ("write clean code", "follow best practices")
- [ ] All moved content is properly referenced
- [ ] Commands are exact copy-paste ready (no prose explanations)

# Keep vs Remove Decision Matrix

## KEEP in CLAUDE.md (needed >30% of sessions)

| Category | Example | Why |
|----------|---------|-----|
| Project identity | "Next.js 14 app with Prisma ORM" | Orients every session |
| Build/test/run commands | `npm run build`, `pytest -x` | Claude runs these constantly |
| Key directory map | `src/api/` — route handlers | Prevents wrong-file edits |
| Gotchas & footguns | "IMPORTANT: Never use ORM for bulk inserts" | Prevents repeated mistakes |
| Doc pointers | "For auth flow, see docs/auth.md" | Enables on-demand deep context |
| Environment quirks | "Use Node 20, not 22 — breaks X" | Prevents setup failures |

## MOVE to reference files (needed <30% but still valuable)

| Category | Example | Move to |
|----------|---------|---------|
| API documentation | Full endpoint specs | `docs/api-reference.md` |
| Architecture decisions | Why we chose X over Y | `docs/architecture.md` |
| Database schemas | Table structures | `docs/schema.md` |
| Deployment procedures | Step-by-step deploy guide | `docs/deploy.md` |
| Complex business logic | Domain rules, edge cases | `docs/domain-rules.md` |
| Onboarding context | Team conventions, history | `docs/conventions.md` |

## REMOVE entirely (wasteful context)

| Category | Example | Why remove |
|----------|---------|------------|
| Code style rules | "Use 2-space indent" | Use prettier/eslint instead |
| Formatting preferences | "Always use single quotes" | Linter handles this |
| Generic best practices | "Write clean, readable code" | Claude already knows |
| Obvious patterns | "Use async/await for promises" | Inferrable from codebase |
| Lengthy explanations | Paragraphs explaining why X | Not actionable |
| Redundant commands | Commands with prose explanations | Keep command, remove prose |
| Version history | "We migrated from X to Y in 2024" | Rarely relevant |
| Team member info | "Ask John for DB access" | Claude can't contact humans |

## Decision Flowchart

```
For each line in CLAUDE.md:
│
├─ Does Claude need this in >30% of sessions?
│  ├─ YES → KEEP
│  └─ NO ─┐
│          │
├─ Can Claude infer this from reading the code?
│  ├─ YES → REMOVE
│  └─ NO ─┐
│          │
├─ Can a linter/formatter/hook handle this?
│  ├─ YES → REMOVE (add hook instead)
│  └─ NO ─┐
│          │
├─ Is this still valuable for specific tasks?
│  ├─ YES → MOVE to reference file + add pointer
│  └─ NO → REMOVE
```

## Anti-patterns to Flag

1. **@-file embeds**: `@docs/full-api.md` loads entire file every session → replace with pointer
2. **Negative-only rules**: "Never use X" without alternative → add "prefer Y instead"
3. **Wall of commands**: 20+ commands listed → keep only top 5, move rest to `docs/commands.md`
4. **Style guide dump**: Full style guide pasted in → replace with linter config
5. **Auto-generated bloat**: `/init` output kept verbatim → trim to essentials

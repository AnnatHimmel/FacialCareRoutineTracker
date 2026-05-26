# /1-Functionality - Functionality Discovery Interview

## Purpose
Interactive interview to discover, document, and refine project functionality. The LLM conducts a conversation with the user until the functionality document is complete.

## Behavior: Interview Loop with Scoring

```
┌─────────────────────────────────────────────────────────────────┐
│                 FUNCTIONALITY INTERVIEW LOOP                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  START → Check for existing doc → Interview → Score → Loop      │
│                                                                  │
│  ┌──────────────┐                                               │
│  │ Load/Create  │                                               │
│  │ FUNCTIONALITY│                                               │
│  │    .md       │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   INTERVIEW  │────▶│    SCORE     │────▶│   COMPLETE?  │    │
│  │  Ask questions│     │  0-100%      │     │   ≥90%?      │    │
│  │  about gaps   │     │  Show gaps   │     │              │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│         ▲                                         │             │
│         │              NO (< 90%)                 │             │
│         └─────────────────────────────────────────┘             │
│                                          │ YES (≥ 90%)          │
│                                          ▼                      │
│                                   ┌──────────────┐              │
│                                   │ Save & AUTO  │              │
│                                   │ CONTINUE to  │              │
│                                   │ /SH-2a-Arch  │              │
│                                   └──────────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Instructions

### Step 1: Initialize
```
1. Check for existing .\doc\FUNCTIONALITY.md
2. IF exists: Load and assess current completeness
3. IF not exists: Create template and start fresh interview
```

### Step 2: Interview Categories
Ask about these areas (track completion per category):

| Category | Weight | Key Questions |
|----------|--------|---------------|
| **Core Purpose** | 15% | What does this do? What problem does it solve? |
| **Project Type** | 10% | CLI / UI / Hybrid / API / Library? |
| **Target Users** | 10% | Who uses this? Technical level? |
| **Inputs** | 15% | What data comes in? Formats? Sources? Validation? |
| **Outputs** | 15% | What does it produce? Formats? Destinations? |
| **Core Features** | 15% | What are the main features? Priority order? |
| **Edge Cases** | 10% | What can go wrong? Error handling? |
| **Constraints** | 10% | Platform? Performance? Security? Dependencies? |

### Step 3: Conduct Interview
```
FOR each incomplete category:
    1. Ask 1-3 focused questions about that category
    2. Listen to user response
    3. Update FUNCTIONALITY.md with new information
    4. Mark what's still unclear or missing
    5. Continue to next gap
```

### Interview Style Guidelines
- Ask ONE focused question at a time (not multiple)
- Summarize what you understood before moving on
- If user is vague, probe deeper with follow-ups
- Suggest options when user seems unsure
- Accept "I don't know yet" - mark as TBD

### Step 4: Score Completeness
After each exchange, calculate and display:

```
═══════════════════════════════════════════════════════════════
FUNCTIONALITY COMPLETENESS: [XX]%
═══════════════════════════════════════════════════════════════

✅ Core Purpose      [15/15] - Clear problem statement
✅ Project Type      [10/10] - CLI confirmed
⚠️ Target Users      [5/10]  - Missing: technical level
✅ Inputs            [15/15] - All formats defined
⚠️ Outputs           [10/15] - Missing: error output format
✅ Core Features     [15/15] - 5 features prioritized
❌ Edge Cases        [0/10]  - Not discussed yet
⚠️ Constraints       [7/10]  - Missing: performance targets

TOTAL: 77/100

GAPS TO ADDRESS:
1. What technical level are your users? (developers, power users, general?)
2. What format should error messages use?
3. What edge cases should we handle?
4. Any performance requirements?

═══════════════════════════════════════════════════════════════
```

### Step 5: Loop Until Complete
```
WHILE completeness < 90%:
    1. Show current score
    2. Ask about highest-priority gap
    3. Update document
    4. Recalculate score

WHEN completeness >= 90%:
    1. Show final document summary
    2. Save FUNCTIONALITY.md
    3. AUTO-CONTINUE to /SH-2a-Architect
```

## Document Template: FUNCTIONALITY.md

```markdown
# Functionality Specification
Project: [Name]
Created: [Date]
Completeness: [XX]%

## 1. Core Purpose
**Problem Statement**: [What problem does this solve?]
**Solution Summary**: [One sentence description]

## 2. Project Type
- [ ] CLI (Command Line Interface)
- [ ] UI (Graphical User Interface)
- [ ] Hybrid (CLI + UI)
- [ ] API/Service
- [ ] Library/Package

## 3. Target Users
**Primary Users**: [Who?]
**Technical Level**: [Developer / Power User / General User]
**Use Context**: [When/where do they use this?]

## 4. Inputs
| Input | Format | Source | Validation |
|-------|--------|--------|------------|
| [Name] | [Type] | [Where from] | [Rules] |

## 5. Outputs
| Output | Format | Destination | Example |
|--------|--------|-------------|---------|
| [Name] | [Type] | [Where to] | [Sample] |

## 6. Core Features (Priority Order)
1. **[Feature 1]**: [Description]
2. **[Feature 2]**: [Description]
3. **[Feature 3]**: [Description]

## 7. Edge Cases & Error Handling
| Scenario | Expected Behavior |
|----------|-------------------|
| [Case] | [Response] |

## 8. Constraints
- **Platform**: [OS, environment]
- **Performance**: [Speed, memory requirements]
- **Security**: [Requirements]
- **Dependencies**: [External systems, libraries]

## 9. Open Questions (TBD)
- [Question 1]
- [Question 2]
```

## Auto-Continue Rule

**CRITICAL: When completeness reaches 90% or higher:**
```
DO NOT ask "Should I continue?"
DO NOT wait for permission
DO automatically:
    1. Save final FUNCTIONALITY.md
    2. Display: "Functionality complete (XX%). Continuing to Architecture..."
    3. Execute /SH-2a-Architect
```

## Quick Start Prompts

If user provides no initial context, start with:
> "Let's define what you want to build. In one sentence, what problem are you trying to solve?"

If user provides a description, start with:
> "I see you want to build [summary]. Let me make sure I understand correctly..."

If existing doc found, start with:
> "I found an existing functionality document at XX% complete. Let me continue from where we left off..."

## Do NOT:
- Ask multiple questions at once
- Move on without confirming understanding
- Skip the scoring display
- Ask permission to continue to next phase
- Create SRS yet (that comes from Architecture)

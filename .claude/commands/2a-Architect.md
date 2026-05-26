# /2a-Architect - System Architecture Design

## Purpose
Create comprehensive system architecture from FUNCTIONALITY.md. Loop until architecture is complete and internally consistent.

## Behavior: Architecture Loop Until Perfect

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE LOOP                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │    LOAD      │────▶│   DESIGN     │────▶│   VALIDATE   │    │
│  │ Functionality│     │ Architecture │     │ Completeness │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                              ▲                     │             │
│                              │    GAPS FOUND       │             │
│                              └─────────────────────┘             │
│                                          │ ALL VALID             │
│                                          ▼                       │
│                              ┌──────────────────────┐           │
│                              │ Project Type Check   │           │
│                              └──────────┬───────────┘           │
│                                         │                        │
│                         ┌───────────────┼───────────────┐       │
│                         ▼               ▼               ▼       │
│                    ┌────────┐     ┌──────────┐    ┌────────┐   │
│                    │  CLI   │     │ UI/Hybrid│    │  API   │   │
│                    │        │     │          │    │        │   │
│                    └────┬───┘     └────┬─────┘    └────┬───┘   │
│                         │              │               │        │
│                         │              ▼               │        │
│                         │     ┌──────────────┐        │        │
│                         │     │/2b-UI-Design │        │        │
│                         │     └──────┬───────┘        │        │
│                         │            │                │        │
│                         └────────────┼────────────────┘        │
│                                      ▼                          │
│                              ┌──────────────┐                   │
│                              │/3-Workplan   │                   │
│                              └──────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites
```
REQUIRED: .\doc\FUNCTIONALITY.md exists with completeness >= 90%

IF missing:
    → "No functionality document found. Running /1-Functionality first..."
    → AUTO-EXECUTE /1-Functionality
```

## Instructions

### Step 1: Load Context
```
1. Read .\doc\FUNCTIONALITY.md completely
2. Extract: Project Type, Core Features, Inputs, Outputs, Constraints
3. Read CLAUDE.md for project conventions
```

### Step 2: Design Architecture
Create `.\doc\ARCHITECTURE.md` with ALL sections:

```markdown
# System Architecture
Project: [Name]
Version: 1.0
Date: [Date]

## 1. System Overview
[High-level description of what the system does and why]

### 1.1 Architecture Style
[Monolith / Microservices / Layered / Event-Driven / etc.]

### 1.2 Key Design Decisions
| Decision | Rationale | Alternatives Considered |
|----------|-----------|-------------------------|
| [Choice] | [Why] | [What else was considered] |

## 2. Component Structure

### 2.1 Component Diagram
```
[ASCII diagram of components and their relationships]
```

### 2.2 Component Descriptions
| Component | Responsibility | Dependencies |
|-----------|---------------|--------------|
| [Name] | [What it does] | [What it needs] |

### 2.3 Interface Contracts
[For each component, define inputs/outputs/errors]

## 3. Data Architecture

### 3.1 Data Models
[Define all data structures]

### 3.2 Data Flow
[How data moves through the system]

### 3.3 Storage Strategy
[Files / Database / Memory / External]

## 4. Technology Stack
| Layer | Technology | Justification |
|-------|------------|---------------|
| Language | [e.g., Python 3.11+] | [Why] |
| Framework | [e.g., None/Click/FastAPI] | [Why] |
| Storage | [e.g., SQLite/Files/Redis] | [Why] |
| Testing | [e.g., pytest] | [Why] |

## 5. Error Handling Strategy
| Error Category | Handling Approach | User Feedback |
|----------------|-------------------|---------------|
| Input validation | [Approach] | [Message format] |
| Runtime errors | [Approach] | [Message format] |
| External failures | [Approach] | [Message format] |

## 6. Security Considerations
[Authentication, authorization, data protection, input sanitization]

## 7. Performance Considerations
[Scalability, caching, optimization strategies]

## 8. UI-Relevant Contracts (if UI/Hybrid)
[API contracts, state management, event handling for UI]

## 9. File Structure
```
project/
├── src/
│   └── [module structure]
├── test/
├── doc/
└── [other directories]
```

## 10. Build Order
[Recommended implementation sequence based on dependencies]

1. [Component A] - Foundation, no dependencies
2. [Component B] - Depends on A
3. [Component C] - Depends on A, B
...

## 11. Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | H/M/L | H/M/L | [Strategy] |

## 12. Traceability
| Functionality Requirement | Architecture Component |
|--------------------------|------------------------|
| [Feature from FUNCTIONALITY.md] | [Component that implements it] |
```

### Step 3: Validate Architecture
Run validation checklist:

```
ARCHITECTURE VALIDATION:
═══════════════════════════════════════════════════════════════

✅/❌ All functionality features mapped to components?
✅/❌ All components have clear interfaces?
✅/❌ All data flows defined?
✅/❌ Technology stack justified?
✅/❌ Error handling comprehensive?
✅/❌ Build order is dependency-valid?
✅/❌ No circular dependencies?
✅/❌ Security addressed?
✅/❌ Performance considered?

RESULT: [X/9 checks passed]
═══════════════════════════════════════════════════════════════
```

### Step 4: Loop Until Valid
```
WHILE validation < 9/9:
    1. Identify gaps
    2. Fix architecture document
    3. Re-validate

WHEN validation = 9/9:
    → Save ARCHITECTURE.md
    → Check project type for routing
```

### Step 5: Auto-Continue Based on Project Type
```
CRITICAL - NO QUESTIONS, AUTO-CONTINUE:

IF project_type == 'CLI' OR project_type == 'API':
    → Display: "Architecture complete. CLI/API project - skipping UI. Continuing to Work Planning..."
    → AUTO-EXECUTE /3-Workplan

ELSE IF project_type == 'UI' OR project_type == 'Hybrid':
    → Display: "Architecture complete. UI project - continuing to UI Design..."
    → AUTO-EXECUTE /2b-UI-Design
```

## Quality Checklist (Internal)

Before marking complete, verify:
- [ ] Every feature from FUNCTIONALITY.md appears in traceability
- [ ] Component interfaces are specific (not vague)
- [ ] Data models match input/output specs
- [ ] Build order respects dependencies
- [ ] No "TBD" or placeholder sections remain

## Do NOT:
- Write implementation code
- Create task lists (that's /3-Workplan)
- Design UI layouts (that's /2b-UI-Design)
- Ask permission to continue
- Leave incomplete sections

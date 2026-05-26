# /2b-UI-Design - UI/UX Design

## Purpose
Create comprehensive UI design from ARCHITECTURE.md. Only runs for UI or Hybrid projects. Loops until design is complete.

## Activation Condition
```
ONLY execute if project_type IN ['UI', 'Hybrid']

IF project_type == 'CLI' OR project_type == 'API':
    → Display: "CLI/API project - no UI design needed."
    → AUTO-EXECUTE /3-Workplan
```

## Prerequisites
```
REQUIRED:
- .\doc\FUNCTIONALITY.md exists
- .\doc\ARCHITECTURE.md exists
- Project type is UI or Hybrid

IF Architecture missing:
    → "No architecture found. Running /2a-Architect first..."
    → AUTO-EXECUTE /2a-Architect
```

## Behavior: UI Design Loop Until Perfect

```
┌─────────────────────────────────────────────────────────────────┐
│                      UI DESIGN LOOP                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │    LOAD      │────▶│   DESIGN     │────▶│   VALIDATE   │    │
│  │ Architecture │     │     UI       │     │ Completeness │    │
│  └──────────────┘     └──────────────┘     └──────┬───────┘    │
│                              ▲                     │             │
│                              │    GAPS FOUND       │             │
│                              └─────────────────────┘             │
│                                          │ ALL VALID             │
│                                          ▼                       │
│                              ┌──────────────────────┐           │
│                              │  AUTO-CONTINUE to    │           │
│                              │  /3-Workplan         │           │
│                              └──────────────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Instructions

### Step 1: Load Context
```
1. Read .\doc\ARCHITECTURE.md (especially Section 8: UI-Relevant Contracts)
2. Read .\doc\FUNCTIONALITY.md for user requirements
3. Extract: Data models, API contracts, user types
```

### Step 2: Design UI
Create `.\doc\UI_DESIGN.md` with ALL sections:

```markdown
# UI Design Specification
Project: [Name]
Version: 1.0
Date: [Date]

## 1. Design Overview

### 1.1 Design Philosophy
[Minimalist / Feature-rich / Wizard-style / Dashboard / etc.]

### 1.2 Target Platforms
- [ ] Desktop Web
- [ ] Mobile Web
- [ ] Desktop App (Electron/Tauri)
- [ ] Mobile App (React Native/Flutter)

### 1.3 Responsive Breakpoints
| Breakpoint | Width | Layout Adjustments |
|------------|-------|-------------------|
| Mobile | < 768px | [Changes] |
| Tablet | 768-1024px | [Changes] |
| Desktop | > 1024px | [Changes] |

## 2. Screen Inventory

### 2.1 Screen List
| Screen | Purpose | Entry Points | Exit Points |
|--------|---------|--------------|-------------|
| [Name] | [What user does here] | [How they get here] | [Where they go next] |

### 2.2 Screen Specifications

#### Screen: [Screen Name]
**Purpose**: [What user accomplishes here]

**Wireframe**:
```
┌────────────────────────────────────────────┐
│  Header / Navigation                       │
├────────────────────────────────────────────┤
│                                            │
│  [ASCII wireframe of layout]               │
│                                            │
│  ┌──────────┐  ┌──────────────────────┐   │
│  │ Sidebar  │  │   Main Content       │   │
│  │          │  │                      │   │
│  └──────────┘  └──────────────────────┘   │
│                                            │
├────────────────────────────────────────────┤
│  Footer / Actions                          │
└────────────────────────────────────────────┘
```

**Elements**:
| Element | Type | Data Source | Actions |
|---------|------|-------------|---------|
| [Name] | [Button/Input/List/etc.] | [From Architecture] | [What happens on interact] |

**States**:
- Loading: [What shows while loading]
- Empty: [What shows when no data]
- Error: [What shows on error]
- Success: [What shows on success]

[Repeat for each screen]

## 3. Component Library

### 3.1 Component List
| Component | Usage | Variants |
|-----------|-------|----------|
| Button | Actions | Primary, Secondary, Danger, Disabled |
| Input | Data entry | Text, Number, Email, Password |
| [etc.] | | |

### 3.2 Component Specifications
[For each component: props, states, behavior]

## 4. User Flows

### 4.1 Primary Flow: [Main User Journey]
```
[Screen A] → [Action] → [Screen B] → [Action] → [Screen C]
```

### 4.2 Secondary Flows
[Other important journeys]

### 4.3 Error Flows
[What happens when things go wrong]

## 5. Style Guide

### 5.1 Colors
| Purpose | Color | Hex | Usage |
|---------|-------|-----|-------|
| Primary | [Name] | #XXXXXX | Main actions, highlights |
| Secondary | [Name] | #XXXXXX | Secondary elements |
| Background | [Name] | #XXXXXX | Page backgrounds |
| Text | [Name] | #XXXXXX | Body text |
| Error | [Name] | #XXXXXX | Error states |
| Success | [Name] | #XXXXXX | Success states |

### 5.2 Typography
| Element | Font | Size | Weight |
|---------|------|------|--------|
| H1 | [Font] | [Size] | [Weight] |
| H2 | [Font] | [Size] | [Weight] |
| Body | [Font] | [Size] | [Weight] |
| Button | [Font] | [Size] | [Weight] |

### 5.3 Spacing
[Spacing scale: 4px, 8px, 16px, 24px, 32px, etc.]

### 5.4 Icons
[Icon library to use, key icons needed]

## 6. Accessibility Requirements

### 6.1 WCAG Level
- [ ] Level A (minimum)
- [ ] Level AA (recommended)
- [ ] Level AAA (enhanced)

### 6.2 Accessibility Checklist
- [ ] Keyboard navigation for all interactions
- [ ] Focus indicators visible
- [ ] Color contrast meets requirements
- [ ] Screen reader labels on all elements
- [ ] Error messages announced
- [ ] Form labels associated with inputs

## 7. Interaction Patterns

### 7.1 Loading States
[How loading is indicated]

### 7.2 Form Validation
[When validation happens, how errors show]

### 7.3 Confirmations
[When confirmations are needed, modal vs inline]

### 7.4 Notifications
[Toast, banner, modal - when to use each]

## 8. Traceability

| Functionality Requirement | UI Screen/Component |
|--------------------------|---------------------|
| [Feature from FUNCTIONALITY.md] | [Where it appears in UI] |

## 9. Proposed Additions (if any)
[Features suggested by UI design not in original FUNCTIONALITY.md]
[THESE REQUIRE EXPLICIT USER APPROVAL]
```

### Step 3: Validate UI Design
Run validation checklist:

```
UI DESIGN VALIDATION:
═══════════════════════════════════════════════════════════════

✅/❌ All functionality features have UI representation?
✅/❌ All screens have wireframes?
✅/❌ All screens have state definitions (loading/empty/error)?
✅/❌ Component library covers all needed elements?
✅/❌ User flows are complete and logical?
✅/❌ Style guide is complete?
✅/❌ Accessibility requirements defined?
✅/❌ Responsive breakpoints specified?
✅/❌ Traceability complete?

RESULT: [X/9 checks passed]
═══════════════════════════════════════════════════════════════
```

### Step 4: Loop Until Valid
```
WHILE validation < 9/9:
    1. Identify gaps
    2. Fix UI design document
    3. Re-validate

WHEN validation = 9/9:
    → Save UI_DESIGN.md
    → Auto-continue
```

### Step 5: Auto-Continue
```
CRITICAL - NO QUESTIONS:

→ Display: "UI Design complete. Continuing to Work Planning..."
→ AUTO-EXECUTE /3-Workplan
```

## Do NOT:
- Write implementation code
- Create component code
- Ask permission to continue
- Leave incomplete sections
- Add features without flagging in "Proposed Additions"

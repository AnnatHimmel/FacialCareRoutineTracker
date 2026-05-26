# Learnings & Patterns
Project: Skincare Routine Tracker

## Purpose
Compound knowledge flywheel. Captures patterns, gotchas, and verified solutions discovered during implementation. Each task executor should read relevant entries before starting and add new discoveries upon completion.

---

## Patterns

*(Populated during execution — add entries here as tasks complete.)*

### Flutter / Drift

#### LEARN-001: Template — Drift DAO Reactive Pattern
**Discovered**: [Date] during TASK-XXX
**Pattern**: [What was learned]
**Example**:
```dart
// Pattern to add here after TASK-008
```
**Apply When**: Any time a screen needs live-updating data from a Drift table.

---

### RTL / BiDi

#### LEARN-002: Template — BiDi Product Name Handling
**Discovered**: [Date] during TASK-019
**Pattern**: [What was learned about Hebrew+Latin bidi rendering]
**Example**:
```dart
// Pattern to add here after TASK-019
```
**Apply When**: Rendering any product name or category name in a Flutter widget.

---

### Riverpod

#### LEARN-003: Template — Family Provider with Drift Stream
**Discovered**: [Date] during TASK-018
**Pattern**: [How to combine Drift stream + master content + selections into a family StreamProvider]
**Example**:
```dart
// Pattern to add here after TASK-018
```
**Apply When**: Any per-day or per-slot derived data stream.

---

## Gotchas

*(Populated during execution — add entries here as issues are encountered.)*

### GOTCHA-001: Template — sqlite3 WASM Initialization Timing
**Discovered**: [Date] during TASK-007 or TASK-035
**Problem**: [Description of any timing or WASM loading issue]
**Solution**: [How it was resolved]
**Symptoms**: [What error or behavior indicates this issue]

---

### GOTCHA-002: Template — iOS Safari IndexedDB Quota
**Discovered**: [Date] during TASK-034
**Problem**: [Description of storage quota behavior]
**Solution**: [Workaround or handling]
**Symptoms**: [What error surfaces]

---

### GOTCHA-003: Template — RTL ReorderableListView Drag Handle Position
**Discovered**: [Date] during TASK-023
**Problem**: [Any drag handle rendering issues in RTL]
**Solution**: [Fix applied]
**Symptoms**: [What the symptom looks like]

---

## Performance Notes

*(Add during implementation if any performance optimizations were needed.)*

---

## Testing Insights

*(Add any non-obvious testing patterns discovered during unit or widget test writing.)*

---

## Instructions for Executors

When you complete a task and discover something non-obvious:
1. Add a LEARN-XXX entry under the relevant category.
2. Add a GOTCHA-XXX entry if you hit a bug or surprising behavior.
3. Use the next available number in the sequence.
4. Be specific — include the file path, the symptom, and the exact fix.
5. Future agents will read this file; write for someone who has no context from your session.

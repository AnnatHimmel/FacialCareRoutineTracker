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

### GOTCHA-004: Android Emulator Blank Window on Dual-GPU Laptop
**Discovered**: 2026-05-28 while first running the app on Android
**Problem**: On a dual-GPU laptop (Intel UHD + NVIDIA RTX 4060) with a single 1536x864 display, the emulator (`Pixel_3_XL_API_34`) shows on the taskbar but the screen is blank. The app, Flutter toolchain, and GPU rendering are all fine — it is purely a host-window issue. The emulator restores its window at a negative Y coordinate (e.g. `(118,-1083)`), parking it entirely *above* the top of the monitor — leftover from a past multi-monitor layout. There is no saved geometry in the registry (`HKCU\Software\Android Open Source Project\Emulator\set` holds prefs but no x/y), so it cannot be reset there. A related instability: the layered-window present (`UpdateLayeredWindowIndirect ... device not functioning`) can crash the emulator under the cross-GPU display path.
**Solution**:
1. Do NOT chase GPU render modes (`-gpu host/swiftshader_indirect/angle_indirect` all behave the same — the guest renders fine in every mode).
2. Confirm the guest is rendering with `adb shell screencap -p /sdcard/x.png` then `adb pull` (NOT PowerShell `>` redirect — it corrupts binary via UTF-16 BOM).
3. Move the window onto the monitor with a Win32 `EnumWindows`+`MoveWindow` snippet targeting the window titled `Android Emulator ...`, placing it at `(40,0)`:
```powershell
Add-Type 'using System;using System.Runtime.InteropServices;using System.Text;public class W{[DllImport("user32.dll")]public static extern bool EnumWindows(EnumWindowsProc c,IntPtr l);public delegate bool EnumWindowsProc(IntPtr h,IntPtr l);[DllImport("user32.dll")]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);[DllImport("user32.dll")]public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int t,bool r);public static void Fix(){EnumWindows((h,l)=>{var s=new StringBuilder(256);GetWindowText(h,s,256);if(s.ToString().StartsWith("Android Emulator"))MoveWindow(h,40,0,448,864,true);return true;},IntPtr.Zero);}}'; [W]::Fix()
```
4. A transient "System UI isn't responding" ANR right after cold boot clears on its own — tap Wait, then relaunch the app.
**Symptoms**: Emulator on taskbar but nothing on screen; `boot_completed: 1` and a successful build/install with no errors; emulator log shows `Critical: UpdateLayeredWindowIndirect failed for ptDst=(x,-NNNN)` with negative Y.

**Related env setup**: `JAVA_HOME` must point to Android Studio's JBR (`C:\Program Files\Android\Android Studio\jbr`, JDK 17) and be on PATH. Running `flutter run` as a backgrounded/piped process triggers `Error waiting for a debug connection: log reader stopped unexpectedly` (the APK still builds/installs); for hot reload, run `flutter run -d emulator-5554` in a normal terminal. `flutter run -d chrome` works cleanly (Web is a first-class target).

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

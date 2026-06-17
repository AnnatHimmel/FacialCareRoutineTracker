# Learnings & Patterns
Project: Skincare Routine Tracker

## Purpose
Compound knowledge flywheel. Captures patterns, gotchas, and verified solutions discovered during implementation. Each task executor should read relevant entries before starting and add new discoveries upon completion.

---

## Patterns

*(Populated during execution — add entries here as tasks complete.)*

### Flutter / Dart

#### LEARN-001: Always `await ref.read(provider.future)` for FutureProviders — Never `.valueOrNull`
**Discovered**: 2026-06-17 during barcode master-product matching
**Pattern**: When reading a `FutureProvider<T>` inside an async method, use `await ref.read(provider.future)` — NOT `ref.read(provider).valueOrNull`. The `.valueOrNull` shorthand returns `null` if the provider hasn't resolved yet (it's in `AsyncLoading` state), which silently skips logic that depends on the data. `await ...future` correctly waits for resolution.
**Example**:
```dart
// ❌ WRONG — returns null if provider is still loading
final content = ref.read(masterContentProvider).valueOrNull;

// ✅ CORRECT — waits for the async provider to resolve
MasterContent? content;
try {
  content = await ref.read(masterContentProvider.future);
} catch (_) {}
```
**Apply When**: Any async method (e.g., `_performLookup`, `_addProduct`) that needs data from a `FutureProvider`. Use `.valueOrNull` ONLY for synchronous reads where null is the intended fallback.

---

#### LEARN-002: Cache Version Guard — Bundled Asset as Floor for Cached Content
**Discovered**: 2026-06-17 during barcode field rollout
**Pattern**: When a `SharedPreferences` cache exists for bundled content that evolves across releases, always compare the cached `contentVersion` with the bundled `contentVersion`. If the bundled version is newer, discard the stale cache. The bundled asset is the floor; a Supabase refresh can push above the floor.
**Example**:
```dart
// In RemoteCachedMasterContentRepositoryImpl.load():
final bundled = await _bundled.load();  // fast — MasterContentRepositoryImpl caches in-memory
final cached = await _cache.read();
if (cached != null && _compareVersions(cached.manifest.contentVersion,
    bundled.manifest.contentVersion) >= 0) {
  _inMemory = cached;
  return cached;  // cache is at least as new as bundled — use it
}
await _cache.clear();  // stale cache — discard
_inMemory = bundled;
return bundled;
```
**Apply When**: Any time bundled content gains new fields across app releases and a cache may exist from a prior release. Version-guard the cache instead of assuming it is always current.

---

### RTL / BiDi

#### LEARN-002b: Hot Restart vs. Bundled Asset Changes
**Discovered**: 2026-06-17 during barcode field debugging
**Pattern**: `flutter hot restart` reloads Dart code but does NOT rebundle assets (JSON files in `assets/`). If you update a JSON asset (e.g., add the `barcodes` field to `master_products.json`), you must do a full `flutter run` (cold start) for the asset change to take effect. Hot restart will continue loading the old asset bytes.
**Symptoms**: Debug print shows `0/33 products have barcodes` after editing the JSON and hot restarting — the JSON was not re-read from disk.
**Apply When**: Debugging any behavior that depends on bundled JSON asset content.

---

### Riverpod

#### LEARN-003: RemoteCachedMasterContentRepositoryImpl Load Order
**Discovered**: 2026-06-15 during Supabase integration
**Pattern**: The three-tier content loading chain (in-memory → SharedPrefs cache → bundled JSON → Supabase background refresh) must be implemented so that the UI is never blocked waiting for network. Supabase refresh runs in background AFTER the first `load()` returns; it writes to cache and updates `_inMemory`. The next app launch will find the Supabase-fetched content in the cache. This means a cold launch on first install always uses bundled JSON; subsequent launches use cached (potentially Supabase-fresh) content.
**Apply When**: Any feature that reads from `masterContentProvider` — understand that on first install, content comes from the bundle, not Supabase.

---

## Gotchas

*(Populated during execution — add entries here as issues are encountered.)*

### GOTCHA-001: SharedPreferences Cache Returns Stale Content After Field Migration
**Discovered**: 2026-06-17 during barcode field rollout
**Problem**: After adding `barcodes: List<String>` to `MasterProduct` and populating the bundled JSON, the debug output showed `0/33 products have barcodes`. The cache in SharedPreferences was written before the `barcodes` field existed, so all products deserialized with `barcodes: []`.
**Solution**: Added a `contentVersion` comparison in `RemoteCachedMasterContentRepositoryImpl.load()`. Bumped `contentVersion` in `changelog.json` from `1.0.0` to `1.0.1`. On next cold start, the cache was detected as stale and cleared. See LEARN-002.
**Symptoms**: Debug print `[Barcode:X] master check: no match (0/N products have barcodes)` despite the JSON having barcodes populated.

---

### GOTCHA-002: `await ref.read(masterContentProvider.future)` Completes Before Camera Log Lines
**Discovered**: 2026-06-17 during barcode scan debugging
**Problem**: When debugging the master check, the `[Barcode:X] master check:` print was not visible in the log near the camera close events. It appeared to be missing. Conclusion was that the master check was being skipped.
**Solution**: `masterContentProvider` is already loaded in memory after app start, so `await ...future` returns almost instantly (the future is already complete). The debug print fires BEFORE the camera close messages arrive in logcat (those are async Android system events). Scroll UP in the log past the camera messages to find the Flutter debug output. It was there all along.
**Symptoms**: Searching for `master check:` near camera log lines fails — look earlier in the log.

---

### GOTCHA-003: Barcode Scan `_onDetect` Fires Multiple Times
**Discovered**: 2026-06-17
**Problem**: `MobileScannerController` can fire `_onDetect` multiple times for the same barcode before the first call completes. Without a guard, `_performLookup` would be called multiple times concurrently.
**Solution**: Check `if (_state != _ScanState.scanning) return;` at the top of `_onDetect` and call `_controller.stop()` immediately on the first detection. The state change gates subsequent calls.
**Symptoms**: Multiple external API calls fired in logs for a single scan.

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

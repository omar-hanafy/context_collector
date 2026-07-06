# Focus Bug History

Last updated: 2026-06-30

This is a working dossier, not the final truth. It records the focus and platform-view bugs that are currently known from local repo history, package changelogs, tests, and prior investigation notes. When the full issue history arrives, use this file as the first map to challenge, correct, and rebuild from the ground up.

## Ground Rules For The Later Review

- Separate keyboard focus, native WebView focus, DOM Monaco focus, Flutter focus, pointer capture, and content binding. Several bugs looked like one thing and were another.
- Treat "Monaco reports focused" as weaker than "input-ready". A focused-looking editor can still ignore typing or paste.
- Preserve the split between user intent and maintenance. Direct user entry into the editor may reclaim input; background sync, route recovery, content updates, and lifecycle hooks must not steal focus.
- Do not fix app symptoms by reaching around `flutter_monaco` unless the package cannot express the invariant. Text input handoff belongs in `flutter_monaco`.
- Do not remove old focus helpers until their original bug is understood. Several helpers are load-bearing.

## Current Core Invariants

- `MonacoFocusIntent.user` means the user intentionally interacted with Monaco and the package may release stale Flutter text input before focusing the editor.
- `MonacoFocusIntent.maintenance` means background work may keep editor input alive only if the editor already owns the keyboard.
- Secondary and middle mouse clicks must not trigger editor focus nudges.
- Repeated primary clicks while Windows editor focus is fresh must not replay native focus.
- Primary clicks after stale native input readiness must recover editor input.
- Hidden tabs are not valid keyboard owners.
- `context_collector` must not call `TextInput.hide`, `SystemChannels.textInput`, or depend directly on WebView plugins for Monaco focus handoff.
- Monaco writeback is allowed only when the selection state says Monaco is bound to the active file.

## Fixed Bugs And Workarounds

### 1. Route, Dialog, And App-Switch Focus Recovery

Status: fixed in app, later partially generalized in `flutter_monaco`.

Known commits:
- `8fda639` in `context_collector`: improved editor focus recovery after dialogs and route changes.
- `flutter_monaco` `1.0.0` changelog: reliable typing after route and app switches on macOS and Windows, plus optional `MonacoFocusGuard`.

Symptoms:
- Returning from dialogs, routes, or app switches could leave Monaco visually present but not reliably ready for typing.
- In some cases the user needed an extra click or right-click to make input work again.

Decision taken:
- Add route/app lifecycle recovery instead of making the user manually re-enter the editor.
- Use route observers, post-frame recovery, and focus guard behavior around page return/resume events.

Workaround shape:
- App-level recovery hooks were acceptable early because the package did not yet expose the sharper focus-intent API.
- Later work moved the real handoff distinction into `flutter_monaco`.

Remaining concern:
- These hooks can become focus-stealing bugs if they run as unconditional focus calls. They must stay gated behind keyboard ownership and native readiness.

### 2. Background Focus Nudges Stealing Keyboard From Flutter Text Inputs

Status: fixed in app and package.

Known commits:
- `2c8d80f` in `context_collector`: stopped Monaco refocus nudges from stealing focus from text inputs.
- `777d2db` in `context_collector`: gated every Monaco focus path behind keyboard ownership.
- `ba64e15` / `b6bc8b2` in `flutter_monaco`: never steal the keyboard from a focused Flutter text input.

Symptoms:
- A dialog `TextField`, popup, button, menu, or other Flutter surface could own focus, then Monaco maintenance code would reclaim the keyboard.
- On Windows this was especially dangerous because WebView2 native focus could silently take OS keyboard input.

Root decision:
- The editor may only claim the keyboard when nobody else owns it, or when the request is direct user intent.

Workaround shape:
- `editorMayClaimKeyboard(primaryFocus, platformViewFocus)` became the app-level ownership gate.
- Maintenance paths such as content sync, route recovery, option changes, and lifecycle recovery must stand down when another Flutter focus node owns the keyboard.

Tests:
- `test/features/editor/editor_may_claim_keyboard_test.dart`.
- `test/features/editor/monaco_focus_boundary_test.dart` also guards that app code delegates text-input handoff to `flutter_monaco`.

### 3. Windows Right-Click Flicker And Repeated Left-Click Focus Replay

Status: fixed in app wrapper and package wrapper.

Known commits:
- `0eb0f42` in `context_collector`: fixed Monaco editor focus flicker and native-focus desync on Windows.
- `f50c493` / `5350848` in `flutter_monaco`: fixed Windows Monaco focus flicker on right-click and repeated clicks.
- `flutter_monaco` `2.0.0` changelog: Windows editor focus recovers after native-focus loss, avoids replaying focus on right-click or repeated clicks, and no longer steals from Flutter text inputs.

Symptoms:
- Right-click could make the cursor "double blink" and the context menu open and close immediately.
- Repeated primary clicks could spam native focus and cause mouse flicker.

Direct cause:
- Pointer-down was treated as "claim typing focus" too broadly.
- Both `context_collector` and `flutter_monaco` had focus nudges above the WebView layer.

Decision taken:
- Focus only when entering editor focus, not on every pointer down.
- Secondary and middle mouse clicks must never trigger focus recovery.
- Repeated primary clicks while both Flutter and Monaco focus are already current must not replay native focus.

Workaround removed or narrowed:
- `context_collector` previously had a duplicate path where `ensureEditorFocus()` effectively did native focus plus DOM focus back-to-back. That duplication was removed/narrowed.
- `webview_windows` was intentionally left alone for this bug class because the bad replay lived in wrappers above it.

Tests:
- Repeated-primary-click and secondary-click coverage in `editor_may_claim_keyboard_test.dart`.

### 4. Windows WebView2 Native Focus Loss And Host Window Deactivation

Status: fixed in the maintained Windows WebView package, then consumed through `flutter_monaco`.

Known package:
- `webview_flutter_windows` `1.0.0`, maintained fork/rebuild of upstream `webview_windows`.

Symptoms:
- Clicking a WebView could deactivate the host window, leaving a gray title bar and dead Flutter shortcuts.
- Clicking Flutter UI outside the WebView did not reliably return keyboard focus to Flutter.
- Pressing `Tab` past the page's last focusable element could stay trapped inside the page.
- A Flutter text input could visually own focus while the WebView still held native keyboard focus.

Decisions taken:
- Add explicit native focus APIs and state:
  - `WebviewController.focus()`
  - `WebviewController.releaseFocus()`
  - `onFocusChanged`
  - `hasNativeFocus`
- Enforce the invariant from both directions: while a Flutter text input owns Flutter focus, no WebView should keep native keyboard focus.
- Reparent WebView2 to the Flutter view window and surface focus state back to Dart.

Workaround status:
- This moved from app/package workaround territory into the lower native layer where it belongs.
- Real Windows runtime verification remains the strongest proof. macOS code review can only confirm shape.

### 5. macOS Monaco Looks Focused But Typing And Paste Are Ignored

Status: fixed in `flutter_monaco`, consumed by app.

Known commits:
- `454b3b0` in `context_collector`: fixed macOS Monaco stale focus input.
- `d7312b8` in `context_collector`: used `flutter_monaco` focus intent API.
- `9a97e1c` / `6ec4323` in `flutter_monaco`: `2.1.0` focus release.
- `bb46ec5` / `6b4e987` in `flutter_monaco`: `2.1.1` focus handoff release.

Symptoms:
- Monaco could look focused on macOS, but typing and paste did nothing.
- A stale Flutter text-input client from a dialog or text field could still swallow input after the editor visually regained focus.

Direct cause:
- Monaco DOM focus, WKWebView visual focus, and native input readiness were not the same state.
- `requestNativeFocus()` is meaningful on Windows WebView2, but macOS needed package-owned input replay and stale text-input cleanup.

Decisions taken:
- Add `MonacoFocusIntent` to distinguish user focus from maintenance focus.
- User focus may release stale Flutter text input and replay the in-page Monaco focus path.
- Maintenance focus stays cooperative and must not steal from Flutter text inputs.

Workaround moved:
- The app must not call `TextInput.hide` itself. `flutter_monaco` owns that handoff for user-intent editor entry.

Tests:
- App tests assert no direct `TextInput.hide`, no `SystemChannels.textInput`, and no direct WebView plugin dependencies.

### 6. Native Input Readiness Modeled In The App

Status: fixed in app.

Known commit:
- `f712ca3` in `context_collector`: modeled Monaco native input readiness.

Symptoms:
- Route/window/app focus recovery could not tell "editor was truly input-ready" from "editor focus signals are stale".
- Recovery paths risked either doing too little after a real native boundary or doing too much while another surface owned the keyboard.

Decision taken:
- Model input readiness as state:
  - `noEditorTarget`
  - `foreignKeyboardOwner`
  - `ready`
  - `stale`
- Convert stale readiness into `MonacoFocusIntent.user`; keep non-stale background recovery as maintenance.

Workaround shape:
- `invalidateInputReadinessAfterNativeFocusBoundary()` marks the editor stale after native focus boundaries.
- `recoverKeyboardFocusAfterNativeFocusBoundary()` chooses intent from readiness.

Important later correction:
- This first modeled macOS strongly. The tab-switch fix later extended desktop stale tracking to Windows and Linux as well.

### 7. Multiple Tabs: Focus Lost After Switching Tabs, Click Does Nothing Until Right-Click

Status: fixed and pushed on 2026-06-30.

Known commit:
- `6211baa` in `context_collector`: fixed Monaco focus recovery after tab switches.

Symptoms:
- After switching tabs, the same focus-lost bug happened.
- Left click did nothing.
- Right-click could wake the editor.

Direct cause:
- After an `IndexedStack` tab switch, Flutter focus and Monaco focus could both still look true, but native input readiness was stale.
- The Windows no-replay gate saw "already focused" and refused to run user focus recovery.

Deep cause:
- Tab visibility was not part of the keyboard ownership model. A hidden session could carry "fresh focus" across tab activation.

Decisions taken:
- Make tab visibility part of the service's keyboard model.
- Exactly one active session is visible for keyboard input.
- Hidden sessions cannot own the keyboard.
- Tab activation is treated as a native input-readiness boundary.
- A primary click with stale native readiness replays user focus, but secondary clicks still do not nudge focus.

Tests:
- `editorPointerFocusIntent` now covers stale Windows tab visibility boundaries.
- `editorTracksNativeInputReadinessStaleness` covers macOS, Windows, and Linux desktop tracking.
- `monaco_focus_boundary_test.dart` source-guards that tab switching uses `recoverKeyboardFocusAfterNativeFocusBoundary()`.

### 8. Monaco Copy, Paste, And Writeback Bugs That Presented Like Focus Bugs

Status: fixed in app, focus-adjacent.

Known commit:
- `776d72b` in `context_collector`: guarded Monaco writeback with editor binding.

Symptoms:
- Copy worked only after toggling View All.
- User-reported flow bundled right-click, copy paths, keyboard not working, and paste not adding content to Monaco.
- Opening some files could write blank content back and mark them edited.

Root decision:
- Treat copy, paste, focus, and editor binding as one state class until proven separate.
- Writeback cannot key only on `activeFileId`; it must know Monaco is bound to the active file.

Fix shape:
- Build selected combined content on demand rather than reading a lazy cache.
- Add explicit binding between Monaco and the active file.
- Distinguish unloaded file content from intentionally empty file content.
- Keep old binding long enough to flush previous file text before rebinding.

Why it belongs in this file:
- It is not pure keyboard focus, but it repeatedly surfaced next to focus symptoms and right-click behavior. It can mislead future debugging if left out.

### 9. Splitter Drag / Platform View Pointer Loss Near Monaco

Status: fixed in `resizable_splitter` package; app adopted package versions.

Known package fixes:
- `resizable_splitter` `2.1.1`: armed platform-view shield on pointer-down so a release over a platform view cannot strand drag state.
- `resizable_splitter` `2.1.2`: painted the platform-view shield so a release over it is not swallowed.

Symptoms:
- Divider next to a WebView could stay stuck in dragging state when pointer release occurred over the platform view.
- `controller.isDragging` stayed true and the divider kept tracking as if the button were still held.

Direct cause:
- Platform views can sit above Flutter in the compositor and swallow pointer release events.
- A fully transparent barrier may paint nothing, leaving no Flutter layer above the platform view.

Workaround and final shape:
- Use a platform-view shield during drag.
- Arm the shield on pointer-down, not only after drag recognition.
- Paint an imperceptible layer above platform views. A fully transparent layer may be optimized away; a minimal alpha paint is deliberate.
- Keep a watchdog / authoritative drag state machine for swallowed releases.

Decision:
- This is a real platform-view shielding pattern, not random UI decoration.
- It still needs platform-specific caution on iOS and web, where a painted Flutter layer may not intercept platform-view input.

### 10. Divider Hover And Cursor Flicker At The Monaco Edge

Status: audited, app-side fix recommendation recorded, live validation was still called out.

Known file:
- `HOVER_FLICKER_AUDIT.md`.

Symptoms:
- Resize cursor and divider hover color blink near the editor splitter divider.
- The flicker happens on the editor/WebView side, not the pure Flutter file-tree side.

Direct cause:
- `interactiveExtent == thickness == 6` left zero slop.
- The visible Flutter divider sat flush against the native WKWebView edge, creating a contested seam for cursor and pointer ownership.

Recommended app workaround:
- Restore a small grab buffer by raising `interactiveExtent` above `thickness`, for example `12` to `20`.
- Use the smallest value that stops flicker so the resize cursor does not intrude too far into Monaco.

Package-side optional robustness:
- Hover hysteresis can stabilize hover color, but the OS cursor handoff is primarily app/platform-view geometry.

Open caution:
- The audit explicitly asked for live macOS validation. Do not treat the recommendation as fully proven unless that happened later.

## Reverted Or Rejected Directions

- Do not solve focus bugs as keyboard shortcut bugs by default. Some earlier keyboard/paste work was reverted, and later fixes moved toward input-readiness and focus ownership.
- Do not blindly copy app workarounds into `flutter_monaco`. The package fix must be based on the platform mechanics.
- Do not add direct app calls to `TextInput.hide` for Monaco recovery. That belongs to package-owned user focus handoff.
- Do not remove route/app recovery hooks merely because a newer focus gate exists. They preserve older real fixes.
- Do not treat `webview_windows` as the source for every click flicker. Some flicker lived in wrappers above WebView2.

## Current File And Test Anchors

In `context_collector`:

- `lib/src/features/editor/data/monaco_service.dart`
  - `editorMayClaimKeyboard`
  - `editorPointerFocusIntent`
  - `editorInputReadinessForFocusSignals`
  - `editorTracksNativeInputReadinessStaleness`
  - `setVisibleForKeyboardInput`
  - `recoverKeyboardFocusAfterNativeFocusBoundary`
- `lib/src/app/tab_shell.dart`
  - `_syncKeyboardVisibleSession`
  - `_restoreSessionFocus(... afterNativeFocusBoundary: true)`
  - `_handleSelectTab`
- `test/features/editor/editor_may_claim_keyboard_test.dart`
- `test/features/editor/monaco_focus_boundary_test.dart`
- `HOVER_FLICKER_AUDIT.md`

In `flutter_monaco`:

- `MonacoFocusIntent`
- `MonacoController.ensureEditorFocus`
- `MonacoController.focus`
- `MonacoEditorView` pointer focus gate
- `MonacoFocusGuard`
- Changelog sections `1.0.0`, `2.0.0`, `2.1.0`, `2.1.1`

In `webview_flutter_windows`:

- `WebviewController.focus`
- `WebviewController.releaseFocus`
- `onFocusChanged`
- `hasNativeFocus`
- Changelog section `1.0.0`

In `resizable_splitter`:

- platform-view drag shield
- painted shield layer
- pointer-down arming
- hardware primary-button release recovery
- changelog sections `2.1.1`, `2.1.2`

## Open Questions For The Wide-Angle Review

- Which early app-level focus recoveries are still needed after `flutter_monaco` `2.1.1` and `webview_flutter_windows` `1.0.0`?
- Can `context_collector` stop rendering the raw `controller.webViewWidget` and use the package widget without losing app-specific keyboard shortcut behavior?
- Should tab visibility be modeled by a reusable package API instead of app-only `setVisibleForKeyboardInput`?
- Are there still content-update paths that call focus recovery too eagerly after file selection or View All changes?
- Which fixes are true lower-layer invariants, and which are still app workarounds waiting to move down?
- Is Linux actually covered by the current desktop stale-readiness model once a Linux WebView implementation exists?
- Did the divider hover `interactiveExtent` recommendation receive live macOS validation, or is it still an audit hypothesis?

## Minimal Timeline

- 2025-09-15: app and early `flutter_monaco` route/app focus recovery.
- 2026-06-12: app focus ownership gate prevents maintenance nudges from stealing Flutter text-input focus.
- 2026-06-20: Windows right-click and repeated-left-click replay narrowed in app and package.
- 2026-06-20: `flutter_monaco` `2.0.0` ships Windows focus recovery and no-replay behavior.
- 2026-06-21: `flutter_monaco` `2.1.0` adds `MonacoFocusIntent` and macOS input-readiness recovery.
- 2026-06-21: `flutter_monaco` `2.1.1` fixes stale Flutter text-input client handoff before Monaco user focus.
- 2026-06-22: app models native input readiness.
- 2026-06-23: app guards Monaco writeback with explicit editor binding.
- 2026-06-30: app treats tab switches as native input-readiness boundaries.

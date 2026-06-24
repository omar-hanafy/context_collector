# Divider hover/cursor flicker - context_collector audit

**Scope:** context_collector (app) side. Companion to the package-side report at
`resizable_splitter/HOVER_FLICKER_AUDIT.md`.

**Verdict for this side:** PRIMARY / required. The divider config here is the
trigger, and the only lever for the *cursor* flicker lives on this side.

**Status:** Root cause confirmed by code inspection. The recommended fix needs a
~2-minute live validation on macOS (see "Validate").

---

## Symptom

When the mouse is on/near the editor splitter divider, the resize cursor and the
divider's hover color blink/flicker. Only on the **right (editor) edge** of the
divider - the left (file-tree) edge is calm.

## Where

`lib/src/features/editor/ui/screens/editor_screen.dart:541-584`

```dart
ResizableSplitter(
  controller: _splitterController,
  ...
  divider: const SplitterDividerStyle(
    thickness: 6,
    interactiveExtent: 6,   // <-- the trigger
  ),
  ...
  end: DecoratedBox(
    ...
    child: const MonacoEditorIntegrated(), // native WKWebView (flutter_monaco)
  ),
)
```

- End pane = `MonacoEditorIntegrated` -> `flutter_monaco` -> native **WKWebView**
  on macOS, composited *above* Flutter and managing its own cursor/events
  ("Important on macOS: don't claim the primary click; let WKWebView win it" -
  `lib/src/features/editor/data/monaco_service.dart:182`).
- Start pane = file tree (pure Flutter, no platform view -> no flicker there).
- Axis: horizontal (default).

## Root cause

`interactiveExtent == thickness == 6` makes the divider's grab **slop = 0**
(`(6 - 6) / 2 = 0`). With zero slop, three things collapse onto the same 6px
strip:

1. The Flutter `MouseRegion` (which sets the resize cursor),
2. the hover-color zone (the package highlights only the visible bar; with zero
   slop the bar *is* the whole region), and
3. the divider's hit-test box.

That 6px Flutter strip sits **knife-edge flush** against the WKWebView's left
edge. As the mouse moves along that seam, macOS arbitrates pixel-by-pixel whether
the pointer is over the 6px Flutter divider or the native WKWebView (which owns
its own frame's cursor + events). Each flip fires `MouseRegion` exit -> enter, so
the cursor blinks (resize <-> WebView cursor) and, because hover and cursor share
the same region when slop is 0, the hover color blinks with it.

**Why a thicker default would not do this:** the package default
`interactiveExtent: 48` gives 21px of slop - a Flutter-owned grab buffer that
overlaps the panes, with hover intentionally *off* in the slop. The visible bar
is then never flush against the WebView; the contested seam is pushed ~21px into
the editor where it is cursor-only and far from the divider. Setting
`interactiveExtent: 6` (reasonably, to stop the grab area intruding into Monaco)
removed that buffer and dragged the contested seam onto the visible divider.

## Fix (this side)

**Restore a grab buffer:** raise `interactiveExtent` above `thickness` so the
divider is no longer flush against the WebView. The visible bar stays 6px; the
buffer (slop) overlaps Monaco's left edge instead.

```dart
divider: const SplitterDividerStyle(
  thickness: 6,
  interactiveExtent: 20, // ~7px slop each side; tune to taste
),
```

This is the only lever for the **cursor** flicker (the OS owns the cursor; the
package cannot debounce it). It should also remove the **color** blink on the
visible bar, because hover is off in the slop and the bar is now buffered away
from the contested seam.

**Trade-off:** the resize cursor now appears a few px into Monaco's left edge
(this is exactly why `interactiveExtent: 6` was chosen originally). Pick the
smallest `interactiveExtent` that stops the flicker - likely 12-20.

## Validate (do this live - it is the one unconfirmed point)

On macOS, the WKWebView composites on top, so it is **not proven** that a Flutter
slop laid over the WebView actually takes the cursor. Test before committing:

1. Set `interactiveExtent: 20`, run on macOS, hot reload.
2. Move the mouse slowly along the divider/editor seam.
3. Expect: stable resize cursor + stable hover color on the visible bar; any
   residual cursor handoff happens further into the editor, not on the bar.
4. If the slop-over-WebView does **not** take the cursor (cursor still flips at
   the bar), the buffer alone is insufficient - fall back to the package-side
   hover hysteresis (color stays stable even if the cursor still flips) and
   accept that the cursor flicker is a macOS platform-view limitation. See the
   package report.

## Relationship to the package side

- This side = the **trigger + primary fix** (buffer -> cursor + color).
- Package side = **optional robustness** (hover hysteresis stops the color blink
  even with zero slop) + a docs warning. Not required if the buffer works here.

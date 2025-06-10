#\!/usr/bin/env bash
# Refactor: flatten & clean editor feature structure
set -euo pipefail

OLD="lib/src/features/editor"         # current location
NEW="lib/features/editor"             # target location

# —— helper that "moves + renames" (uses git if available) ————————————
move () {
  local from="$1" to="$2"
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    git mv -k "$from" "$to"
  else
    mv "$from" "$to"
  fi
  echo "✔︎ $from  →  $to"
}

# —— 1. create new folder tree ————————————————————————————————
mkdir -p "$NEW"/{bridge,core/{model,scripts},data,platform}
mkdir -p "$NEW"/ui/{screens,widgets/settings,dialogs}
echo "🗂  Folder skeleton ready under $NEW"

# —— 2. move + rename files ——————————————————————————————
move "$OLD/bridge/monaco_bridge_platform.dart"          "$NEW/bridge/bridge.dart"
move "$OLD/bridge/platform_webview_controller.dart"     "$NEW/bridge/webview_controller.dart"

move "$OLD/domain/editor_constants.dart"                "$NEW/core/model/editor_constants.dart"
move "$OLD/domain/editor_settings.dart"                 "$NEW/core/model/editor_settings.dart"
move "$OLD/domain/keybinding_manager.dart"              "$NEW/core/model/keybinding_manager.dart"
move "$OLD/domain/theme_manager.dart"                   "$NEW/core/model/theme_manager.dart"
move "$OLD/domain/monaco_scripts.dart"                  "$NEW/core/scripts/monaco_scripts.dart"

move "$OLD/services/editor_settings_service.dart"       "$NEW/data/settings_service.dart"
move "$OLD/services/unified_monaco_service.dart"        "$NEW/data/monaco_service.dart"
move "$OLD/services/monaco_editor_providers.dart"       "$NEW/data/providers.dart"

move "$OLD/presentation/ui/monaco_editor_container.dart"     "$NEW/ui/widgets/monaco_editor_container.dart"
move "$OLD/presentation/ui/monaco_editor_integrated.dart"    "$NEW/ui/widgets/monaco_editor_integrated.dart"
move "$OLD/presentation/ui/global_monaco_container.dart"     "$NEW/ui/widgets/monaco_container.dart"
move "$OLD/presentation/ui/monaco_editor_info_bar.dart"      "$NEW/ui/widgets/info_bar.dart"

move "$OLD/presentation/ui/editor_screen.dart"               "$NEW/ui/screens/editor_screen.dart"
move "$OLD/presentation/ui/enhanced_editor_settings_dialog.dart" "$NEW/ui/dialogs/settings_dialog.dart"

move "$OLD/presentation/ui/settings_widgets/settings_widgets.dart"     "$NEW/ui/widgets/settings/settings_widgets.dart"
move "$OLD/presentation/ui/settings_widgets/settings_form_fields.dart" "$NEW/ui/widgets/settings/form_fields.dart"

move "$OLD/utils/webview_platform_utils.dart"                "$NEW/platform/webview_platform_utils.dart"

echo -e "\n🎉  Done.  Run  'dart fix --apply'  then  'dart format .'  to clean imports."

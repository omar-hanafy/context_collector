# GitHub Release Guide

This guide explains how to publish Context Collector releases on GitHub.

## Overview

Context Collector uses GitHub releases for distribution. The app does not include an in-app automatic updater, so users get new versions by downloading the latest release from GitHub or the Microsoft Store, depending on platform.

## Release Process

### 1. Update Version

Update version in `pubspec.yaml`:

```yaml
version: 1.2.0+1
```

### 2. Build Releases

Build for each platform:

```bash
# macOS
flutter build macos --release
cd build/macos/Build/Products/Release
zip -r ContextCollector-macos-1.2.0.zip "Context Collector.app"

# Windows
flutter build windows --release
# Create installer or zip the exe
```

### 3. Create GitHub Release

1. Go to GitHub > Releases > "Create a new release".
2. Tag version: `v1.2.0` to match your pubspec version.
3. Release title: `Context Collector v1.2.0`.
4. Describe changes in the release notes.
5. Upload your build artifacts:
   - `ContextCollector-macos-1.2.0.zip`
   - `ContextCollector-windows-1.2.0.exe` or `.zip`
6. Publish release.

## File Naming Convention

Use platform identifiers in release asset names so users can find the right installer:

- macOS: include `macos`, `darwin`, or `.dmg` in the filename.
- Windows: include `windows`, `win`, or `.exe` in the filename.

Examples:

- `ContextCollector-macos-1.2.0.zip`
- `ContextCollector-windows-1.2.0.exe`
- `context-collector-1.2.0-darwin.zip`

Avoid names like `ContextCollector-1.2.0.zip` because they do not identify a platform.

## Troubleshooting

### GitHub Release Assets Missing

- Verify the release is published, not a draft.
- Ensure asset filenames include platform identifiers.
- Re-upload the asset if the original upload failed or has the wrong version.

### GitHub Pages Not Working

If you still use GitHub Pages for release metadata:

- Check Settings > Pages is enabled.
- Wait a few minutes for GitHub Pages to deploy.
- Check Actions tab for workflow errors.

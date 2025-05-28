# GitHub Release Guide for Auto Updates

This guide explains how to use GitHub releases with automatic updates for Context Collector.

## Overview

Context Collector uses GitHub releases for distribution and GitHub Pages for hosting the update feed (`appcast.xml`). The auto-updater checks this feed to find new versions.

## How It Works

1. **GitHub Releases**: You create releases on GitHub with your app binaries
2. **GitHub Actions**: Automatically generates `appcast.xml` from your releases
3. **GitHub Pages**: Hosts the `appcast.xml` file
4. **Auto Updater**: The app checks the GitHub Pages URL for updates

## Setup (One-time)

### 1. Enable GitHub Pages

1. Go to your repository Settings → Pages
2. Set Source to "Deploy from a branch"
3. Set Branch to `gh-pages` (will be created automatically)
4. Save the settings

### 2. Generate Signing Keys (Optional but Recommended)

For signed updates, generate keys:

```bash
dart run auto_updater:generate_keys
```

Then:
- **macOS**: Add public key to `macos/Runner/Info.plist`
- **Windows**: Add public key to `windows/runner/Runner.rc`

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

1. Go to GitHub → Releases → "Create a new release"
2. Tag version: `v1.2.0` (match your pubspec version)
3. Release title: `Context Collector v1.2.0`
4. Describe changes in the release notes
5. Upload your build artifacts:
   - `ContextCollector-macos-1.2.0.zip`
   - `ContextCollector-windows-1.2.0.exe` (or .zip)
6. Publish release

### 4. Automatic appcast.xml Generation

Once you publish the release:
1. GitHub Actions will automatically run
2. It generates `appcast.xml` from your releases
3. Publishes it to GitHub Pages
4. Your app will find updates at: `https://omar-hanafy.github.io/context_collector/appcast.xml`

## File Naming Convention

For the auto-updater to find your assets, name them with platform identifiers:

- **macOS**: Include `macos`, `darwin`, or `.dmg` in the filename
- **Windows**: Include `windows`, `win`, or `.exe` in the filename

Examples:
- ✅ `ContextCollector-macos-1.2.0.zip`
- ✅ `ContextCollector-windows-1.2.0.exe`
- ✅ `context-collector-1.2.0-darwin.zip`
- ❌ `ContextCollector-1.2.0.zip` (no platform identifier)

## Testing Updates

1. Install an older version of your app
2. Open the app and go to Settings → Updates
3. Click "Check for Updates"
4. The app should find and download the new version

## Troubleshooting

### Updates Not Found
- Check if `appcast.xml` is accessible at the GitHub Pages URL
- Verify your release is not marked as pre-release or draft
- Ensure asset filenames include platform identifiers

### GitHub Pages Not Working
- Check Settings → Pages is enabled
- Wait a few minutes for GitHub Pages to deploy
- Check Actions tab for any workflow errors

### Signing Issues (if using signed updates)
- Verify public keys are correctly added to Info.plist/Runner.rc
- Ensure private keys are used to sign the releases

## Notes

- The GitHub Actions workflow runs automatically on new releases
- Updates are checked every 6 hours or manually via Settings
- Users need internet access to check for and download updates
- The update feed URL is: `https://omar-hanafy.github.io/context_collector/appcast.xml`
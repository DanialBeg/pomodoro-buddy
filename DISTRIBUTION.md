# Distribution Guide for Pomodoro Buddy

## For Non-Technical Users

### Easy Download Options:

1. **Direct Download (Recommended)**
   - Download `pomodoro-buddy-v1.0.zip` from GitHub Releases
   - Double-click the zip file to extract
   - Drag `pomodoro-buddy.app` to your Applications folder
   - Right-click the app → Open (first time only, due to unsigned app)

2. **Installation Steps:**
   ```
   1. Download the zip file
   2. Extract by double-clicking
   3. Move app to Applications folder
   4. First launch: Right-click → Open → Open (to bypass Gatekeeper)
   5. Subsequent launches: Normal double-click
   ```

### What Users Will See:
- ⚠️ "App cannot be opened because it is from an unidentified developer"
- **Solution**: Right-click → Open → Open (one-time approval)

## For Better User Experience (Future)

### Option 1: Code Signing (Requires Apple Developer Account - $99/year)
```bash
# Sign with Developer ID
codesign --force --options runtime --sign "Developer ID Application: Your Name" dist/pomodoro-buddy.app

# Create installer package  
productbuild --component dist/pomodoro-buddy.app /Applications --sign "Developer ID Installer: Your Name" dist/PomodoroTracker-Installer.pkg

# Notarize with Apple
xcrun notarytool submit dist/PomodoroTracker-Installer.pkg --keychain-profile "notarytool"
```

### Option 2: Homebrew Distribution
```bash
# Create Homebrew formula
brew tap your-username/pomodoro-buddy
brew install pomodoro-buddy
```

### Option 3: GitHub Releases Automation
```yaml
# .github/workflows/release.yml
- name: Build and Release
  run: |
    xcodebuild archive -project pomodoro-buddy.xcodeproj -scheme pomodoro-buddy
    zip -r pomodoro-buddy-${{ github.ref_name }}.zip build/Release/pomodoro-buddy.app
    gh release create ${{ github.ref_name }} pomodoro-buddy-${{ github.ref_name }}.zip
```

## Current Status
✅ **Ready for distribution**: Built app available in `dist/` folder
❌ **Not signed**: Users will see security warning on first launch
❌ **Not notarized**: Requires manual approval by users

## Recommended Next Steps
1. Upload `dist/pomodoro-buddy-v1.0.zip` to GitHub Releases
2. Add clear installation instructions for users
3. Consider getting Apple Developer account for signing
# Changelog

All notable changes to IdentityKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-05-03

### Added
- **Google Sign-In**: Full support for Google authentication on iOS and macOS
- **GoogleSignIn SDK**: Added as a dependency for native Google Sign-In flow
- **Error Cases**: New authentication errors (`googleSignInFailed`, `googleSignInCancelled`, `missingGoogleIDToken`)

### Changed
- Improved error handling in Google Sign-In button with user-facing alerts
- Better window detection on iOS for multi-scene support

### Documentation
- Added Google Sign-In setup guide to README
- URL schemes configuration instructions
- Firebase Console setup instructions

## [0.3.1] - 2026-05-03

### Changed
- Updated target platforms: iOS 26+, macOS 26+
- Updated Swift tools version: 6.2 (required for iOS 26)
- Updated Xcode requirement: 26+

## [0.3.0] - 2026-05-03

### Added
- **AccountView**: Built-in account screen displaying user account status with guest/authenticated states, upgrade functionality, sign out, and account deletion options
- **PlatformProxy**: Cross-platform abstraction layer for iOS/macOS UI handling (navigation, text, toolbar, background)
- **AuthenticationError.upgradeCancelled**: New error case for cancelled account upgrades

### Fixed
- Cross-platform build issues (iOS/macOS compatibility)
- UIKit import issues in macOS context
- SocialAuthenticationButtonStyle bundle resolution
- Color.secondarySystemBackground availability on macOS

### Changed
- Updated to Firebase 12.x
- Agent guidelines: Added planning and branch strategy with conventional commits

## [0.2.0] - 2024-XX-XX

### Added
- Basic configuration options for authentication providers
- Firebase 12.x support

### Changed
- Initial release structure
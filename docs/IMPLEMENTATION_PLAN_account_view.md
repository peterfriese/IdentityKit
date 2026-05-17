# AccountView Redesign - Implementation Plan

## Overview
Redesign the AccountView to match Apple's iOS Settings Account screen aesthetic with drill-down navigation for profile management.

## Final List Structure

```
List {
  // Section 1: Header (transparent background row)
  accountHeaderSection  // Avatar + Name + Email

  // Section 2: No header - TWO rows
  Section {
    Row("Personal Information") → → PersonalInformationView
    Row("Sign-In & Security") → → SignInSecurityView
  }

  // Section 3: Danger Zone
  dangerZoneSection
}
```

## Components

### 1. Header Section
- Avatar centered at top (80x80)
- User's name below (`.title2`, bold)
- Email below name (`.subheadline`, secondary)
- When `displayName` is nil, show email instead of "Apple ID"

### 2. Personal Information Row
- SF Symbol: `person.text.rectangle`
- Label: "Personal Information"
- Chevron: `.chevron.right`
- Navigation to: `PersonalInformationView`

### 3. Sign-In & Security Row
- SF Symbol: `key.fill`
- Label: "Sign-In & Security"
- Chevron: `.chevron.right`
- Navigation to: `SignInSecurityView`

### 4. Danger Zone Section
- "Sign Out" button - red label, centered
- "Delete Account" button - red label, centered
- Fix: `.frame(maxWidth: .infinity)` on button labels

---

## Drill-Down Views

### PersonalInformationView
- Avatar (large, centered) + "Change Photo" button
- Name row → `NameEditView`
- Email row → `EmailEditView`

### SignInSecurityView
- Linked providers list (read-only with checkmarks)
- "Connect Other Sign-In Methods" button → `AuthenticationScreen`

### NameEditView
- First Name text field
- Last Name text field
- Firebase: `createProfileChangeRequest().displayName = "First Last"`

### EmailEditView
- New Email text field
- Confirm Email text field
- Reauthentication flow
- Firebase: `user.updateEmail()`
- ReauthenticationView sheet for password verification

### AvatarEditView
- PhotosPicker for library selection
- Save/Remove Photo buttons
- Firebase: `createProfileChangeRequest().photoURL`

---

## New Files Created

| File | Purpose |
|------|---------|
| `PersonalInformationView.swift` | Drill-down: avatar, name, email |
| `SignInSecurityView.swift` | Drill-down: providers + connect |
| `NameEditView.swift` | First/Last name editing |
| `EmailEditView.swift` | Email change with reauth |
| `AvatarEditView.swift` | Photo picker for avatar |
| `StorageService.swift` | Avatar upload/delete via Firebase Storage |
| `AuthenticationLinkResult.swift` | Account linking result enum (created in Phase 10, removed in Phase 12) |
| `AccountLinkConflictDialog.swift` | Optional pre-built dialog component (Phase 11) |

## Modified Files

| File | Changes |
|------|---------|
| `AccountView.swift` | Restructured with drill-down rows |
| `AuthenticationError.swift` | Added storage error cases |
| `PlatformTypes.swift` | Added PlatformImage typealias |
| `PlatformProxy+ListStyle.swift` | Simplified listStyle method |
| `Package.swift` | Added FirebaseStorage dependency |
| `AvatarEditView.swift` | Uses StorageService instead of temp files |
| `README.md` | Documented Firebase Storage setup |

---

## Implementation Phases

### Phase 1: AccountView.swift Restructure
- [x] Remove old sections
- [x] Add Section 2 with two drill-down rows
- [x] Update header fallback (show email when no displayName)
- [x] Fix danger zone button dividers

### Phase 2: PersonalInformationView
- [x] Create view file
- [x] Display avatar, name, email
- [x] Navigation links to edit views

### Phase 3: SignInSecurityView
- [x] Create view file
- [x] Linked providers list
- [x] Connect button

### Phase 4: NameEditView
- [x] Create view file
- [x] First/Last text fields
- [x] Firebase integration

### Phase 5: EmailEditView
- [x] Create view file
- [x] Email fields with validation
- [x] Reauthentication flow

### Phase 6: AvatarEditView
- [x] Create view file
- [x] PhotosPicker
- [x] Firebase integration

### Phase 7: Integration
- [x] Wire navigation
- [x] Build verification
- [x] Platform-specific modifiers

### Phase 8: Code Consistency Refactoring
- [x] Remove `platformListStyle` computed property from AccountView.swift
- [x] Create `PlatformListStyle` enum for type-safe style selection
- [x] Use `.platform.listStyle(.insetGrouped)` pattern consistently
- [x] Update PersonalInformationView and SignInSecurityView to use platform pattern
- [x] Verify build passes

### Phase 9: Firebase Storage for Avatar Upload
- [x] Add `FirebaseStorage` dependency to Package.swift
- [x] Add storage error cases to AuthenticationError.swift
- [x] Create StorageService.swift with upload/delete functionality
- [x] Implement image resizing (512×512 max, 0.8 JPEG quality)
- [x] Add graceful error handling for unconfigured Storage
- [x] Update AvatarEditView.swift to use StorageService
- [x] Update README.md with Firebase Storage setup instructions
- [x] Verify build passes

### Phase 10: SF Symbol Toolbar Buttons
- [x] Add checkmark/xmark SF Symbols to toolbar buttons
- [x] AvatarEditView: Done → checkmark
- [x] AccountView: Close → xmark
- [x] EmailEditView: Cancel → xmark, Save/Next/Continue buttons
- [x] NameEditView: Cancel → xmark, Save → checkmark
- [x] Verify build passes

### Phase 11: UI Polish
- [x] SignInSecurityView: "password" → "Email / Password"
- [x] SignInSecurityView: Sentence case "Connect other sign-in methods"
- [x] Verify build passes

### Phase 10: Account Linking - Already Linked Dialog
- [x] Create `AuthenticationLinkResult.swift` with result enum
- [x] Update `AuthenticationService+Google.swift` to return `AuthenticationLinkResult`
- [x] Update `AuthenticationService+Apple.swift` to return `AuthenticationLinkResult`
- [x] Update `AuthenticationService+Email.swift` to return `AuthenticationLinkResult`
- [x] Add logging for `credentialAlreadyInUse` scenarios
- [x] Verify build passes

### Phase 11: App-Controlled Account Conflict Resolution
- [x] Add `ProviderDisplayName` utility for readable provider names
- [x] Add `UserDataService` protocol with `FirestoreUserDataService` default
- [x] Add `FirebaseFirestore` dependency to Package.swift
- [x] Add `switchAccount(with:)` to AuthenticationService
- [x] Add `userDataService` property to AuthenticationService
- [x] Add `AuthenticationError.credentialAlreadyLinked` error case
- [x] Update `AuthenticationLinkResult` enum cases
- [x] Create `AccountLinkConflictDialog` component
- [x] Simplify button views (remove auto-dialogs, throw errors instead)
- [x] Verify build passes

### Phase 12: Rollback to Phase 11
- [x] Rolled back to Phase 11 state (removed all Phase 12/13 account linking code)
- [x] Reverted to previous version without account linking dialogs
- [x] Verified build passes

---

## Notes

- `updateEmail(to:)` is deprecated in Firebase - future versions should use `sendEmailVerification(beforeUpdatingEmail:)` instead
- PhotosPicker is iOS 16+ only
- All views use platform-aware modifiers for iOS/macOS compatibility
- Avatar images are stored in Firebase Storage (not local temp files)
- Toolbar buttons use SF Symbols (checkmark/xmark) for visual consistency
- Account linking with conflict dialogs was rolled back in Phase 12 to simplify the implementation
- `AuthenticationLinkResult.swift` was created in Phase 10 and removed in Phase 12
- `AccountLinkConflictDialog` provided as optional pre-built dialog component (available but not integrated)
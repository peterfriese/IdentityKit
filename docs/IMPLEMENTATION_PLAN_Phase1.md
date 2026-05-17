# Phase 1: Critical Fixes - Implementation Plan

## Overview
Phase 1 addresses 4 critical issues that need immediate attention:
1. Add docc comments to all public APIs
2. Fix deprecated `updateEmail(to:)` API
3. Fix typo `errorMesage` → `errorMessage`
4. Configure docc generation

## Implementation Phases

- [ ] Phase 1.1: Fix typo and deprecated API (Quick fixes)
- [ ] Phase 1.2: Add docc comments to all public types and methods
- [ ] Phase 1.3: Configure docc generation in Package.swift

## Files

| File | Purpose |
|------|---------|
| `Sources/IdentityKit/Views/Email/EmailPasswordAuthenticationView.swift` | Fix typo errorMesage → errorMessage |
| `Sources/IdentityKit/Service/AccountService.swift` | Replace deprecated updateEmail(to:) |
| `Sources/IdentityKit/*.swift` | Add docc to all public APIs |
| `Package.swift` | Add docc target configuration |

---

## Phase 1.1: Quick Fixes

### Task 1.1.1: Fix typo
**File:** `Sources/IdentityKit/Views/Email/EmailPasswordAuthenticationView.swift:41`

**Change:**
```swift
// Before
errorMesage

// After
errorMessage
```

### Task 1.1.2: Fix deprecated API
**File:** `Sources/IdentityKit/Service/AccountService.swift:65`

**Current code:**
```swift
try await user.updateEmail(to: email)
```

**Replace with:** Use `sendEmailVerification(beforeUpdatingEmail:)` which handles reauthentication automatically.

---

## Phase 1.2: Add docc comments

### Public Types to Document

All public types in `Sources/IdentityKit/`:

1. **Main export**
   - `IdentityKit` (module)

2. **Services**
   - `AuthenticationService` + protocol extensions
   - `AccountService` + extensions

3. **Error types**
   - `AuthenticationError` enum

4. **Views**
   - `AccountView`
   - `EmailPasswordAuthenticationView`
   - `PasswordEditView`
   - `PasswordPolicyView`
   - `SignInView`
   - `SignUpView`
   - Various row/helper views

5. **Models/Utilities**
   - `PasswordPolicy`
   - `PasswordValidator`
   - `PlatformProxy`

### Documentation Template

Use this template for each public type:

```swift
/// A brief description of what this type does.
///
/// A more detailed explanation if needed, covering common use cases
/// and important behavior.
///
/// ## Topics
/// ### Initializers
/// - ``init()``
///
/// ### Properties
/// - ``someProperty``
public struct SomeType { }
```

### @unstable Markers
Per BACKLOG.md, add `@unstable` markers to docc comments for all public APIs to indicate API stability is pending review.

---

## Phase 1.3: Configure docc generation

### Option A: Add to Package.swift

Add a documentation target:

```swift
.target(
  name: "IdentityKitDocs",
  dependencies: ["IdentityKit"],
  path: "Sources/IdentityKit",
  plugins: [.plugin(name: "SwiftDocumentation", package: "swift-docc")]
)
```

### Option B: GitHub Actions Workflow

Create `.github/workflows/docc.yml` for automated docc generation and hosting.

---

## Verification

After completing each task:
1. Run `swift build` to verify no compilation errors
2. Run `swift test` to ensure tests pass
3. For docc: Run `swift package generate-documentation` to verify docs build
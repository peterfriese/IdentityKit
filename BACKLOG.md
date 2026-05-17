# IdentityKit Backlog

## Current Feature

_(No active feature - see backlog below)_

## Implementation Phases

### Phase 1: Critical Fixes

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| Critical | Add docc comments to all public APIs | Completed | Phase 1 - Document all public types, methods, add @unstable markers |
| Critical | Fix deprecated `updateEmail(to:)` API | Completed | Phase 1 - Use `sendEmailVerification(beforeUpdatingEmail:)` |
| Critical | Fix typo `errorMesage` → `errorMessage` | Completed | Phase 1 - EmailPasswordAuthenticationView.swift:41 |
| Critical | Configure docc generation | Completed | Phase 1 - Add docc to Package.swift or CI workflow |

### Phase 2: Platform Parity

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| High | macOS email/password reauthentication UI | Not Started | Phase 2 - Remove #if canImport(UIKit) guard |
| High | Enable macOS account deletion | Not Started | Phase 2 - Implement EmailPasswordDeleteUserOperation for macOS |

### Phase 3: Backlog (Existing Items)

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| High | Password linking for social accounts | Not Started | Phase 3 - Use `link()` instead of `updatePassword()` |
| High | Set password UI for social accounts | Not Started | Phase 3 - Enable form in PasswordEditView for Apple/Google |
| High | Email pre-population in reauthentication mode | Not Started | Phase 3 - Populate email field from currentUser |
| Medium | Password validation debounce race condition fix | Not Started | Phase 3 - Add task cancellation in validation |

### Phase 4: Testing

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| High | PasswordValidator tests | Not Started | Phase 4 - New file: PasswordValidatorTests.swift |
| High | AuthenticationError tests | Not Started | Phase 4 - New file: AuthenticationErrorTests.swift |
| High | AuthenticationService state tests | Not Started | Phase 4 - New file: AuthenticationServiceTests.swift |
| High | AccountService tests | Not Started | Phase 4 - New file: AccountServiceTests.swift |

### Phase 5: Documentation & Polish

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| Medium | Update README with new APIs | Not Started | Phase 5 - Document all public APIs |
| Medium | Update BACKLOG.md | Not Started | Phase 5 - Reflect completed items |
| Medium | Add API stability markers | Not Started | Phase 5 - Add @unstable to docc comments |

---

## Technical Debt

| Issue | Status | Notes |
|-------|--------|-------|
| Email/Password account deletion only works on iOS | Not Started | `#if canImport(UIKit)` guard in AccountService+Email.swift blocks on macOS |
| Firebase `updateEmail(to:)` deprecated | Completed | Should use `sendEmailVerification(beforeUpdatingEmail:)` instead |
| Password linking for social accounts (PR #27) | Not Started | `updatePassword()` fails for users without password provider - use `link()` instead |
| Set password UI hidden for social accounts (PR #27) | Not Started | PasswordEditView hides form in .setPassword mode for Apple/Google users |
| Reauthentication email empty (PR #27) | Not Started | Email field not populated in reauthentication mode |
| Password validation debounce race condition (PR #27) | Not Started | Tasks spawn without cancelling previous ones |
| Public APIs lack documentation | Completed | All public types and methods need docc comments |
| Test suite empty | Not Started | Only placeholder test exists in IdentityKitTests.swift |
| Typo: errorMesage | Completed | EmailPasswordAuthenticationView.swift:41 |

---

## Completed

| Feature | Date | Notes |
|---------|------|-------|
| Phase 1: Critical Fixes | 2026-05-17 | Docc comments, fix deprecated API, typo fix, CI docc deployment |
| AccountView Redesign | 2026-05-17 | Complete UI overhaul with drill-down navigation |
| Password management | 2026-05-17 | Password policy, change password, password edit view |
| Sign in with Apple fix (post-deletion re-auth) | 2026-05-16 | Fixed stale Firebase session issue after account deletion |
| Firebase Storage for avatar upload | 2026-04-20 | Image upload/delete via Firebase Storage |

---

## Documentation

| File | Purpose |
|------|---------|
| `README.md` | Package documentation and setup |
| `AGENTS.md` | Agent guidelines and process rules |
| `BACKLOG.md` | Feature backlog and technical debt |
| `docs/IMPLEMENTATION_PLAN.md` | Detailed implementation plan for current feature |
| `CHANGELOG.md` | Version history and changes |
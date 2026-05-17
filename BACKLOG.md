# IdentityKit Backlog

## Current Feature

_(No active feature - see backlog below)_

## Backlog

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| High | Password linking for social accounts | Not Started | - |
| High | Set password UI for social accounts | Not Started | - |
| High | Email pre-population in reauthentication mode | Not Started | - |
| Medium | Password validation debounce race condition fix | Not Started | - |
| Medium | Email/Password Reauthentication UI for macOS | Not Started | - |
| Low | [Future feature] | Not Started | - |

## Technical Debt

| Issue | Status | Notes |
|-------|--------|-------|
| Email/Password account deletion only works on iOS | Not Started | `#if canImport(UIKit)` guard in AccountService+Email.swift blocks on macOS |
| Firebase `updateEmail(to:)` deprecated | Not Started | Should use `sendEmailVerification(beforeUpdatingEmail:)` instead |
| Password linking for social accounts (PR #27) | Not Started | `updatePassword()` fails for users without password provider - use `link()` instead |
| Set password UI hidden for social accounts (PR #27) | Not Started | PasswordEditView hides form in .setPassword mode for Apple/Google users |
| Reauthentication email empty (PR #27) | Not Started | Email field not populated in reauthentication mode |
| Password validation debounce race condition (PR #27) | Not Started | Tasks spawn without cancelling previous ones |

## Completed

| Feature | Date | Notes |
|---------|------|-------|
| AccountView Redesign | 2026-05-17 | Complete UI overhaul with drill-down navigation |
| Password management | 2026-05-17 | Password policy, change password, password edit view |
| Sign in with Apple fix (post-deletion re-auth) | 2026-05-16 | Fixed stale Firebase session issue after account deletion |
| Firebase Storage for avatar upload | 2026-04-20 | Image upload/delete via Firebase Storage |

## Documentation

| File | Purpose |
|------|---------|
| `README.md` | Package documentation and setup |
| `AGENTS.md` | Agent guidelines and process rules |
| `BACKLOG.md` | Feature backlog and technical debt |
| `docs/IMPLEMENTATION_PLAN.md` | Detailed implementation plan for current feature |
| `CHANGELOG.md` | Version history and changes |
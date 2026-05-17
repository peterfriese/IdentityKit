# IdentityKit Backlog

## Current Feature

| Feature | Status | Implementation Plan |
|---------|--------|---------------------|
| AccountView Redesign | In Progress | See `IMPLEMENTATION_PLAN.md` |

## Backlog

| Priority | Feature | Status | Implementation Plan |
|----------|---------|--------|---------------------|
| Medium | Email/Password Reauthentication UI for macOS | Not Started | - |
| Low | [Future feature] | Not Started | - |

## Technical Debt

| Issue | Status | Notes |
|-------|--------|-------|
| Email/Password account deletion only works on iOS | Not Started | `#if canImport(UIKit)` guard in AccountService+Email.swift blocks on macOS |
| Firebase `updateEmail(to:)` deprecated | Not Started | Should use `sendEmailVerification(beforeUpdatingEmail:)` instead |

## Completed

| Feature | Date | Notes |
|---------|------|-------|
| Sign in with Apple fix (post-deletion re-auth) | 2026-05-16 | Fixed stale Firebase session issue after account deletion |
| AccountView redesign (Phase 1-11) | 2026-05-03 | Complete UI overhaul with drill-down navigation |
| Firebase Storage for avatar upload | 2026-04-20 | Image upload/delete via Firebase Storage |

## Documentation

- **AGENTS.md** - Agent guidelines and process rules
- **IMPLEMENTATION_PLAN.md** - Detailed plan for current feature
- **README.md** - Package documentation and setup instructions
- **CHANGELOG.md** - Version history and changes